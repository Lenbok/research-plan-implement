# Platform Support

This framework supports multiple AI coding assistants with automatic file transformation during installation.

## Supported Platforms

### Claude Code (Default)
- **Directory**: `.claude/`
- **Installation**: `./setup.sh /path/to/repo` or `./setup.sh --claude /path/to/repo`
- **Config File**: `CLAUDE.md`
- **Status**: ✅ Fully supported (native format)

**Agent Format**:
```yaml
---
name: agent-name
description: Agent description
tools: Grep, Glob, LS, Read
---
```

**Skill Format**: YAML frontmatter with name and description
```yaml
---
name: skill-name
description: What this skill does and when to use it
---
```

### Cursor
- **Directory**: `.claude/` (for compatibility)
- **Installation**: `./setup.sh --cursor /path/to/repo`
- **Config File**: `CURSOR.md`
- **Status**: ✅ Fully compatible via `.claude/` directory

**Why `.claude/`?**: Cursor has native support for `.claude/` directories for both agents and skills. Using `.claude/` allows both Claude Code and Cursor to work in the same repository without conflicts.

**Agent Format**: Same as Claude Code (optionally supports additional fields: `model`, `readonly`, `is_background`)

**Skill Format**: Same as Claude Code (Cursor uses the same SKILL.md format with optional additional frontmatter fields)

### OpenCode
- **Directory**: `.claude/` (for compatibility)
- **Installation**: `./setup.sh --opencode /path/to/repo`
- **Config File**: `OPENCODE.md`
- **Status**: ✅ Fully compatible with agent transformation

**Why `.claude/`?**: OpenCode supports the Agent Skills standard and can read from `.claude/skills/`, `.opencode/skills/`, and `.agents/skills/`. Using `.claude/` allows all three tools (Claude Code, Cursor, OpenCode) to work in the same repository.

**Agent Format** (transformed from Claude format):
```yaml
---
description: Agent description
mode: subagent
tools:
  grep: true
  glob: true
  list: true
  read: true
---
```

**Skill Format**: Same as Claude Code (uses Agent Skills standard - no transformation needed!)

**Transformations Applied**:
- **Agents**: Removes `name`, adds `mode: subagent`, converts `tools` to YAML object with lowercase names
- **Skills**: No transformation (Agent Skills standard compatible)

## File Transformation

The framework uses `transform-files.py` to automatically convert files during installation:

- **Claude → Claude**: No transformation (source format)
- **Claude → Cursor**: No transformation (Cursor reads `.claude/` directly with Agent Skills standard)
- **Claude → OpenCode**:
  - **Skills**: No transformation (OpenCode supports Agent Skills standard)
  - **Agents**: Transforms frontmatter to OpenCode subagent format

## Multi-Platform Support

All three platforms (Claude Code, Cursor, and OpenCode) can work in the same repository using a single `.claude/` directory:

```bash
# Install for any platform (all create .claude/ directory)
./setup.sh /path/to/repo                    # Claude Code
./setup.sh --cursor /path/to/repo           # Cursor
./setup.sh --opencode /path/to/repo         # OpenCode

# All three can use the same .claude/ directory thanks to Agent Skills standard
# Just create CLAUDE.md, CURSOR.md, and/or OPENCODE.md for platform-specific instructions
```

## Configuration Files

Each platform can have its own configuration file for platform-specific instructions:

- `CLAUDE.md` - Instructions for Claude Code
- `CURSOR.md` - Instructions for Cursor
- `OPENCODE.md` - Instructions for OpenCode

These files are not created automatically but will be offered for update if they already exist.

## Directory Structure

All platforms now use the same `.claude/` directory structure:

```
.claude/
├── agents/
│   ├── codebase-locator.md          (OpenCode: transformed to subagent format)
│   ├── codebase-analyzer.md         (OpenCode: transformed to subagent format)
│   └── codebase-pattern-finder.md   (OpenCode: transformed to subagent format)
└── skills/
    ├── 1_research_codebase/SKILL.md (Agent Skills standard - works on all platforms)
    ├── 2_create_plan/SKILL.md       (Agent Skills standard - works on all platforms)
    └── ...
```

**Note**: Skills use the Agent Skills open standard and work across all three platforms without modification. Only agents require transformation for OpenCode.

## References

- [Cursor Subagents Documentation](https://cursor.com/docs/subagents)
- [Cursor Rules Documentation](https://cursor.com/help/customization/rules)
- [Cursor Skills Documentation](https://cursor.com/help/customization/skills)
