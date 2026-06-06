# Custom Rules for plan-exec

Custom rules let you inject project-specific or personal conventions into the plan-exec workflow. Rules are free-form markdown loaded at skill invocation time and applied as additional instructions alongside the skill's built-in behavior.

## File Locations

Two levels, checked in order (first-found-wins, never merged):

1. **Project-level**: `.claude/planning-rules.md` in the current working directory
2. **User-level**: `${CLAUDE_PLUGIN_DATA}/planning-rules.md`

When both non-empty files exist, only the project-level file is used. Empty files are treated as absent and fall through to the next level.

## Resolution

The skill runs `scripts/resolve-rules.sh planning-rules.md` via Bash at startup. The script outputs the first file found (project, then user) or empty output if neither exists.

## Managing Rules

You manage rules manually by editing the files directly:

- **show rules** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/resolve-rules.sh planning-rules.md ${CLAUDE_PLUGIN_DATA}`
- **add/update project rules** — edit `.claude/planning-rules.md`
- **add/update user rules** — edit `${CLAUDE_PLUGIN_DATA}/planning-rules.md`
- **clear** — delete the file

## Example Content

```markdown
## testing conventions
- use xUnit for C# tests, PHPUnit for PHP tests
- mock external dependencies with Moq (C#) or Mockery (PHP)
- aim for 80% coverage minimum on new code

## naming
- C#: PascalCase for types and public members, camelCase for locals
- PHP: PascalCase for classes, camelCase for methods and properties
- keep method names under 30 characters

## plan structure preferences
- max 5 checkboxes per task
- always include rollback steps for migrations

## accessibility
- never use ASCII diagrams, tables, or pseudographics in terminal output
- prefer plain prose and simple bullet lists
```

## How Rules Apply

- **plan-exec**: rules propagate to task subagents via the `USER_RULES` placeholder in `prompts/task.md`. They supplement — never replace — the built-in instructions.
