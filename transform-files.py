#!/usr/bin/env python3
"""
Transform framework files for different AI coding assistants.
Reads Claude-format files and outputs OpenCode/Cursor format.
"""

import sys
import re
from pathlib import Path

# Command descriptions for OpenCode
COMMAND_DESCRIPTIONS = {
    "1_research_codebase.md": "research rpi",
    "2_create_plan.md": "create rpi plan",
    "3_validate_plan.md": "validate rpi plan",
    "4_implement_plan.md": "implement rpi plan",
    "5_save_progress.md": "save rpi progress",
    "6_resume_work.md": "resume previously saved rpi work",
    "7_research_cloud.md": "research cloud infra",
    "8_define_test_cases.md": "define rpi tests",
}

def transform_skill_file(content, skill_name, target_format):
    """Transform a skill file to the target format."""
    # All platforms (Claude Code, Cursor, OpenCode) now support the same Agent Skills format!
    # OpenCode reads from .opencode/skills/, .claude/skills/, and .agents/skills/
    # No transformation needed for any platform
    return content

def transform_agent_file(content, target_format):
    """Transform an agent file to the target format."""
    if target_format == "opencode":
        # Parse Claude frontmatter
        match = re.match(r'^---\n(.*?)\n---\n(.*)$', content, re.DOTALL)
        if not match:
            return content
        
        frontmatter_text, body = match.groups()
        
        # Extract fields
        description = ""
        tools = []
        for line in frontmatter_text.split('\n'):
            if line.startswith('description:'):
                description = line.split(':', 1)[1].strip()
            elif line.startswith('tools:'):
                tools_str = line.split(':', 1)[1].strip()
                tools = [t.strip() for t in tools_str.split(',')]
        
        # Map tool names: capitalize -> lowercase, LS -> list
        tool_mapping = {
            'Grep': 'grep',
            'Glob': 'glob',
            'LS': 'list',
            'Read': 'read',
        }
        
        # Build OpenCode frontmatter
        new_frontmatter = f"""---
description: {description}
mode: subagent
tools:
"""
        for tool in tools:
            tool_name = tool_mapping.get(tool, tool.lower())
            new_frontmatter += f"  {tool_name}: true\n"
        
        new_frontmatter += "---\n"
        
        return new_frontmatter + body
    elif target_format == "cursor":
        # Cursor uses the same agent frontmatter format as Claude:
        # - name, description, tools are all compatible
        # - Cursor adds optional fields (model, readonly, is_background) but doesn't require them
        # So Claude format works as-is
        return content
    else:  # claude
        return content

def transform_file(input_path, output_path, target_format):
    """Transform a single file from Claude format to target format."""
    input_file = Path(input_path)
    output_file = Path(output_path)
    
    # Read input
    content = input_file.read_text()
    
    # Determine file type
    if '/skills/' in str(input_path) and input_file.name == 'SKILL.md':
        # Skills are in subdirectories, get skill name from parent directory
        skill_name = input_file.parent.name
        transformed = transform_skill_file(content, skill_name, target_format)
    elif '/agents/' in str(input_path):
        transformed = transform_agent_file(content, target_format)
    else:
        # Unknown type, just copy
        transformed = content
    
    # Write output
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(transformed)

def main():
    if len(sys.argv) != 4:
        print("Usage: transform-files.py <input-file> <output-file> <target-format>")
        print("  target-format: claude, opencode, cursor")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    target_format = sys.argv[3]
    
    if target_format not in ['claude', 'opencode', 'cursor']:
        print(f"Error: Invalid target format '{target_format}'")
        print("  Must be one of: claude, opencode, cursor")
        sys.exit(1)
    
    transform_file(input_path, output_path, target_format)

if __name__ == '__main__':
    main()
