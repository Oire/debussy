# Fixer prompt

Use this for the fixer agent after collecting review findings (replace `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `FINDINGS_LIST`, and `SKILL_SCRIPTS` — `SKILL_SCRIPTS` is the absolute path to the `plan-exec` scripts directory):

```
Code review found the following issues. Verify and fix them.

Accessibility-friendly output: do NOT use ASCII diagrams, tables, box-drawing characters, or pseudographics in your terminal output. Prefer plain prose and simple bullet lists.

Plan file: PLAN_FILE_PATH (read it to find validation commands in the "## Validation Commands" section)
Progress file: PROGRESS_FILE_PATH (read it for context on what previous iterations found and fixed)

FINDINGS:
FINDINGS_LIST

STEP 1 - VERIFY:
For each finding, read the actual code at the specified file:line. Check 20-30 lines of context. Classify as:
- CONFIRMED: real issue, fix it
- FALSE POSITIVE: doesn't exist or already mitigated, discard

STEP 2 - FIX:
- Fix all confirmed issues (including adding missing tests if flagged)

STEP 3 - VALIDATE (MANDATORY — code MUST compile and tests MUST pass):
- Build, test, and run validation commands from PLAN_FILE_PATH
- If anything fails: fix it and re-run everything
- NEVER leave broken code — do NOT report success if the build is red or tests fail

STEP 4 - LOG PROGRESS:
Log details: echo "- confirmed: <list>
- false positives: <list>
- fixes: <what changed>
- validation: <what passed>" | bash SKILL_SCRIPTS/append-progress.sh PROGRESS_FILE_PATH
IMPORTANT: Use ONLY the append-progress.sh script. Do NOT use cat >>, echo >>, or heredocs directly.

STEP 5 - REPORT (MANDATORY — this is your return value to the parent):
Do NOT commit, stage, or push anything — the user handles all git operations.
Your final response MUST include a structured summary starting with "FIXES:" on its own line, followed by one line per fix:
FIXES:
- fixed: <file>:<line> — <what was fixed>
- fixed: <file>:<line> — <what was fixed>
- false positive: <description> — <why discarded>

This report is shown to the user. Be specific about what changed.
```
