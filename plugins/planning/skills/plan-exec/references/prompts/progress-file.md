# Progress file

The run's memory on disk: `.claude/exec-plan/progress/<plan-stem>.txt` (`001-fix-issues.md` becomes `001-fix-issues.txt`). Task subagents, reviewers, the fixer, and Codex all read it to see what happened before them, and it is what lets a run be picked up again after the context has been compacted. `init-progress.sh` creates it with this header:

```
# progress
Plan: <plan-file-path>
Branch: <branch-name>
Started: <timestamp>
---
```

Everything after that is appended through `append-progress.sh`, never with `cat >>`, `echo >>`, or a heredoc. The script timestamps a one-line message, or appends stdin verbatim when given no message.

What the orchestrator appends:
- `task N: <title> - completed`, or `- failed (retry N)`, or `- blocked: <question>` and later the user's answer
- `review round N (<full sweep | critical re-check>)`, followed by what was confirmed, what was refuted and why, and what was fixed
- `codex round N` with Codex's findings, then the fixer's report
- `completed` at the end

Task subagents and the fixer append their own details: files modified, tests, validation, and what was fixed and what was not.

The file lives under `.claude/`, so it is never committed.
