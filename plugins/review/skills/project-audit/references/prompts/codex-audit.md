# Codex audit prompt

This is the prompt sent to Codex for the project-audit skill. Replace `DIFF_COMMAND` before passing.

- Reviewing a branch against the base branch: `DIFF_COMMAND` = `git diff <base>...HEAD`
- Reviewing uncommitted changes: `DIFF_COMMAND` = `git diff HEAD`
- Reviewing the whole project (no diff): substitute the literal string `FULL PROJECT`, and the prompt tells Codex to walk the tree instead.

Write the `## Prompt` section to a file with the Write tool and run `bash ${CLAUDE_PLUGIN_ROOT}/skills/project-audit/scripts/run-codex.sh <file>` in the background; SKILL.md has the details.

## Prompt

Review the project for code-level issues. Write plain prose and simple bullet lists, with no ASCII diagrams, tables, box-drawing characters, or pseudographics, because the reader may use a screen reader.

Scope: DIFF_COMMAND.

- If the scope is a diff command: run it to see the changes, then read the surrounding source files for context.
- If the scope is `FULL PROJECT`: walk the repository tree and focus on the main source directories. Skip generated code, vendored dependencies, and build artifacts.

Look for bugs, security issues, race conditions, error handling (including mishandled exceptions in C# and PHP), resource leaks, concurrency issues, input validation gaps, and code quality problems likely to cause real failures. Leave out style nitpicks, naming preferences, and documentation or packaging issues; a separate reviewer handles those.

Report each finding as `file:line - <severity>: <description>`, with severity critical, major, or minor, grouped by severity. If nothing is found, reply `NO ISSUES FOUND`.
