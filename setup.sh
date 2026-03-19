#!/bin/bash

# Research-Plan-Implement Framework Setup Script
# This script helps you adopt the framework in your repository
# Supports multiple AI coding assistants: Claude Code, Cursor, OpenCode

set -e

# Default to Claude Code
AGENT_DIR=".claude"
AGENT_NAME="Claude Code"
AGENT_MD="CLAUDE.md"
TARGET_FORMAT="claude"

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --cursor)
            # Cursor has native compatibility with .claude/ directories
            # Use .claude to allow both Claude Code and Cursor to work
            AGENT_DIR=".claude"
            AGENT_NAME="Cursor"
            AGENT_MD="CURSOR.md"
            TARGET_FORMAT="claude"
            shift
            ;;
        --opencode)
            # OpenCode reads from .opencode/, .claude/, and .agents/
            # Use .claude for compatibility with Claude Code
            AGENT_DIR=".claude"
            AGENT_NAME="OpenCode"
            AGENT_MD="OPENCODE.md"
            TARGET_FORMAT="opencode"
            shift
            ;;
        --claude)
            AGENT_DIR=".claude"
            AGENT_NAME="Claude Code"
            AGENT_MD="CLAUDE.md"
            TARGET_FORMAT="claude"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [TARGET_DIR]"
            echo ""
            echo "Options:"
            echo "  --claude     Install for Claude Code (default)"
            echo "  --cursor     Install for Cursor"
            echo "  --opencode   Install for OpenCode"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --cursor /path/to/repo"
            echo "  $0 --opencode ~/my-project"
            exit 0
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

echo "🚀 $AGENT_NAME Framework Setup"
echo "================================"
echo ""

# Get source directory (if invoked from elsewhere)
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Get target directory
if [ -z "$TARGET_DIR" ]; then
    read -p "Enter the path to your repository: " TARGET_DIR
fi

# Remove trailing slash for cleaner output
TARGET_DIR="${TARGET_DIR%/}"

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Check if agent directory already exists
if [ -d "$TARGET_DIR/$AGENT_DIR" ]; then
    echo "ℹ️  $AGENT_DIR directory already exists in $TARGET_DIR"

    # Check for existing commands and agents
    if [ -d "$TARGET_DIR/$AGENT_DIR/commands" ] || [ -d "$TARGET_DIR/$AGENT_DIR/agents" ]; then
        echo "📦 Found existing framework installation"
        echo ""
        echo "What would you like to do?"
        echo "1) Update framework (overwrite with latest versions)"
        echo "2) Skip existing files (only add new ones)"
        echo "3) Cancel"
        read -p "Choose option (1/2/3): " INSTALL_OPTION
        
        case $INSTALL_OPTION in
            1)
                echo "📥 Updating framework to latest version..."
                UPDATE_MODE="true"
                ;;
            2)
                echo "🔀 Adding new files only, keeping existing ones..."
                UPDATE_MODE="false"
                ;;
            *)
                echo "Setup cancelled"
                exit 0
                ;;
        esac
    fi
else
    # Create agent directory if it doesn't exist
    mkdir -p "$TARGET_DIR/$AGENT_DIR"
    UPDATE_MODE="false"
fi

# Check if thoughts already exists
if [ -d "$TARGET_DIR/thoughts" ]; then
    echo "⚠️  Warning: thoughts directory already exists in $TARGET_DIR"
    read -p "Do you want to merge with existing thoughts? (y/N): " MERGE
    if [ "$MERGE" != "y" ] && [ "$MERGE" != "Y" ]; then
        echo "Setup cancelled"
        exit 0
    fi
fi

echo ""
echo "📁 Creating directory structure..."

# Create directories if they don't exist
mkdir -p "$TARGET_DIR/$AGENT_DIR/agents"
mkdir -p "$TARGET_DIR/$AGENT_DIR/skills"
mkdir -p "$TARGET_DIR/thoughts/shared/research"
mkdir -p "$TARGET_DIR/thoughts/shared/plans"
mkdir -p "$TARGET_DIR/thoughts/shared/sessions"
mkdir -p "$TARGET_DIR/thoughts/shared/cloud"

echo "📝 Copying framework files..."

# Copy skills - handle update vs skip mode
echo "  Installing skills..."
for skill_dir in $SOURCE_DIR/.claude/skills/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    target_dir="$TARGET_DIR/$AGENT_DIR/skills/$skill_name"
    target_file="$target_dir/SKILL.md"
    
    mkdir -p "$target_dir"
    
    if [ -f "$target_file" ]; then
        if [ "$UPDATE_MODE" = "true" ]; then
            # In update mode, overwrite existing files
            "$SOURCE_DIR/transform-files.py" "$skill_file" "$target_file" "$TARGET_FORMAT"
            echo "    🔄 Updated $skill_name"
        else
            echo "    ⚠️  $skill_name already exists, skipping..."
        fi
    else
        "$SOURCE_DIR/transform-files.py" "$skill_file" "$target_file" "$TARGET_FORMAT"
        echo "    ✅ Installed $skill_name"
    fi
done

# Copy agents - handle update vs skip mode
echo "  Installing agents..."
for agent_file in $SOURCE_DIR/.claude/agents/*.md; do
    filename=$(basename "$agent_file")
    target_file="$TARGET_DIR/$AGENT_DIR/agents/$filename"
    
    if [ -f "$target_file" ]; then
        if [ "$UPDATE_MODE" = "true" ]; then
            # In update mode, overwrite existing files
            "$SOURCE_DIR/transform-files.py" "$agent_file" "$target_file" "$TARGET_FORMAT"
            echo "    🔄 Updated $filename"
        else
            echo "    ⚠️  $filename already exists, skipping..."
        fi
    else
        "$SOURCE_DIR/transform-files.py" "$agent_file" "$target_file" "$TARGET_FORMAT"
        echo "    ✅ Installed $filename"
    fi
done

# Copy playbook if it doesn't exist or ask to update
if [ -f "$TARGET_DIR/PLAYBOOK.md" ]; then
    echo ""
    read -p "PLAYBOOK.md already exists. Update it? (y/N): " UPDATE_PLAYBOOK
    if [ "$UPDATE_PLAYBOOK" = "y" ] || [ "$UPDATE_PLAYBOOK" = "Y" ]; then
        cp $SOURCE_DIR/PLAYBOOK.md "$TARGET_DIR/"
        echo "✅ Updated PLAYBOOK.md"
    else
        echo "ℹ️  Kept existing PLAYBOOK.md"
    fi
else
    cp $SOURCE_DIR/PLAYBOOK.md "$TARGET_DIR/"
    echo "✅ Installed PLAYBOOK.md"
fi

# Check if agent config file exists and offer to append framework section
if [ -f "$TARGET_DIR/$AGENT_MD" ]; then
    echo ""
    echo "📝 $AGENT_MD Configuration"
    echo "=========================="
    echo ""
    echo "$AGENT_MD already exists in the target repository."
    read -p "Would you like to append a section about the Research-Plan-Implement framework commands? (y/N): " APPEND_CONFIG

    if [ "$APPEND_CONFIG" = "y" ] || [ "$APPEND_CONFIG" = "Y" ]; then
        echo "" >> "$TARGET_DIR/$AGENT_MD"
        echo "## Research-Plan-Implement Framework" >> "$TARGET_DIR/$AGENT_MD"
        echo "" >> "$TARGET_DIR/$AGENT_MD"
        echo "This repository uses the Research-Plan-Implement framework with the following workflow commands:" >> "$TARGET_DIR/$AGENT_MD"
        echo "" >> "$TARGET_DIR/$AGENT_MD"
        echo "1. \`/research_codebase\` - Deep codebase exploration with parallel AI agents" >> "$TARGET_DIR/$AGENT_MD"
        echo "2. \`/create_plan\` - Create detailed, phased implementation plans" >> "$TARGET_DIR/$AGENT_MD"
        echo "3. \`/implement_plan\` - Execute plan systematically" >> "$TARGET_DIR/$AGENT_MD"
        echo "4. \`/validate_plan\` - Verify implementation matches plan" >> "$TARGET_DIR/$AGENT_MD"
        echo "5. \`/save_progress\` - Save work session state" >> "$TARGET_DIR/$AGENT_MD"
        echo "6. \`/resume_work\` - Resume from saved session" >> "$TARGET_DIR/$AGENT_MD"
        echo "7. \`/research_cloud\` - Analyze cloud infrastructure (READ-ONLY)" >> "$TARGET_DIR/$AGENT_MD"
        echo "8. \`/define_test_cases\` - Design acceptance test cases" >> "$TARGET_DIR/$AGENT_MD"
        echo "" >> "$TARGET_DIR/$AGENT_MD"
        echo "Research findings are saved in \`thoughts/shared/research/\`" >> "$TARGET_DIR/$AGENT_MD"
        echo "Implementation plans are saved in \`thoughts/shared/plans/\`" >> "$TARGET_DIR/$AGENT_MD"
        echo "Session summaries are saved in \`thoughts/shared/sessions/\`" >> "$TARGET_DIR/$AGENT_MD"
        echo "Cloud analyses are saved in \`thoughts/shared/cloud/\`" >> "$TARGET_DIR/$AGENT_MD"
        echo "✅ Appended framework section to $AGENT_MD"
    else
        echo "ℹ️  Skipping $AGENT_MD modification"
    fi
else
    echo ""
    echo "ℹ️  No $AGENT_MD found in target repository."
    echo "    Consider creating one to provide $AGENT_NAME with project-specific guidance."
fi

# Create a sample research template
echo "📚 Creating sample templates..."

cat > "$TARGET_DIR/thoughts/shared/research/TEMPLATE.md" << 'EOF'
---
date: YYYY-MM-DD HH:MM:SS
researcher: Claude
topic: "Research Topic"
tags: [research, codebase]
status: complete
---

# Research: [Topic]

## Research Question
[What we're investigating]

## Summary
[High-level findings]

## Detailed Findings
[Specific discoveries with code references]

## Architecture Insights
[Patterns and design decisions]

## Open Questions
[Areas needing further investigation]
EOF

cat > "$TARGET_DIR/thoughts/shared/plans/TEMPLATE.md" << 'EOF'
# Implementation Plan Template

## Overview
[What we're building and why]

## Current State Analysis
[What exists now]

## Desired End State
[What success looks like]

## Phase 1: [Name]

### Changes Required:
- [File]: [Changes needed]

### Success Criteria:
#### Automated:
- [ ] Tests pass
- [ ] Linting passes

#### Manual:
- [ ] Feature works as expected

## Testing Strategy
[How we'll verify this works]
EOF

echo ""
if [ "$UPDATE_MODE" = "true" ]; then
    echo "🎉 Framework Updated Successfully!"
    echo "===================================="
    echo ""
    echo "Framework updated in: $TARGET_DIR"
    echo "Agent directory: $AGENT_DIR"
    echo ""
    echo "📋 Update Summary:"
    echo "- Commands and agents updated to latest versions"
    echo "- Your research documents and plans are preserved"
    echo ""
    echo "📖 To update framework in the future:"
    if [ "$AGENT_DIR" != ".claude" ]; then
        echo "- Run: ./setup.sh --${AGENT_DIR#.} $TARGET_DIR"
    else
        echo "- Run: ./setup.sh $TARGET_DIR"
    fi
    echo "- Choose option 1 (Update framework)"
else
    echo "🎉 Setup Complete!"
    echo "=================="
    echo ""
    echo "Framework installed in: $TARGET_DIR"
    echo "Agent directory: $AGENT_DIR"
    echo ""
    echo "📖 Next Steps:"
    echo "1. Review $TARGET_DIR/PLAYBOOK.md for usage instructions"
    echo "2. Try the workflow with a simple task:"
    echo "   - /research_codebase"
    echo "   - /create_plan"
    echo "   - /implement_plan"
    if [ "$APPEND_CONFIG" = "y" ] || [ "$APPEND_CONFIG" = "Y" ]; then
        echo "3. Framework commands have been added to your $AGENT_MD"
    fi
    echo ""
    echo "💡 Tips:"
    echo "- Skills follow a recommended workflow: research → plan → implement → validate"
    echo "- Research documents accumulate in thoughts/shared/research/"
    echo "- Plans serve as technical specifications"
    echo "- Use parallel agents for faster research"
    echo "- Use git to track and manage framework changes"
    echo ""
    echo "🔄 To update framework in the future:"
    if [ "$AGENT_DIR" != ".claude" ]; then
        echo "- Run: ./setup.sh --${AGENT_DIR#.} $TARGET_DIR"
    else
        echo "- Run: ./setup.sh $TARGET_DIR"
    fi
    echo "- Choose option 1 (Update framework)"
fi
echo ""
echo "Happy coding! 🚀"
