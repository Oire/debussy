# Codex audit prompt

This is the prompt sent to Codex for the project-audit skill. Replace `DIFF_COMMAND` before passing.

- If reviewing a diff vs the default branch: `DIFF_COMMAND` = `git diff <default>...HEAD`
- If reviewing uncommitted changes: `DIFF_COMMAND` = `git diff HEAD`
- If reviewing the whole project (no diff exists): substitute `DIFF_COMMAND` with the literal string `FULL PROJECT` and the prompt will instruct Codex to walk the tree instead.

Run: `bash ${CLAUDE_PLUGIN_ROOT}/skills/project-audit/scripts/run-codex.sh "<prompt>"` with `run_in_background: true`. You will be notified when done — do NOT poll or sleep.

If `codex` is not installed, skip this phase.

## Prompt

Review the project for code-level issues. Accessibility-friendly output: do NOT use ASCII diagrams, tables, box-drawing characters, or pseudographics — use plain prose and simple bullet lists. Do NOT commit, stage, or push anything.

Scope: DIFF_COMMAND.

- If the scope is a diff command: run it to see the changes, then read the surrounding source files for context.
- If the scope is `FULL PROJECT`: walk the repository tree and focus on the main source directories. Skip generated code, vendored dependencies, and build artifacts.

Look for: bugs, security issues, race conditions, error handling (including mishandled exceptions in C#/PHP), resource leaks, concurrency issues, input validation gaps, code quality problems that are likely to cause real failures. Do NOT report style nitpicks, naming preferences, or documentation/packaging issues — those are handled by a separate reviewer.

Report findings as: `file:line - <severity>: <description>`. Use severities: critical, major, minor. Group findings by severity. If nothing found: `NO ISSUES FOUND`.
