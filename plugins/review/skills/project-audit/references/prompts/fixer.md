# Fixer prompt

The prompt for the subagent that implements the findings the user chose, one
fixer per triage round. Substitute `REVIEWER` (Nigel or Codex), `USER_FILES`
(the files that held the user's uncommitted changes when the audit started, or
"none"), `GIT_MODE`, and `SKILL_REFS` = `${CLAUDE_PLUGIN_ROOT}/skills/project-audit/references`,
and fill `FINDINGS_LIST` with the chosen findings: id, severity, status, what,
where, evidence, fix, and the skeptic's note. Pass on only the `## Prompt`
section.

## Prompt

The user chose the findings below from a REVIEWER review of this project.
Implement them, validate, and commit.

FINDINGS:
FINDINGS_LIST

1. Look at the code behind each finding before changing anything. If one does
   not hold up (already fixed, a misreading, handled elsewhere), mark it
   not-fixed and say why; do not force a change. Suspected findings need this
   most.
2. If a finding needs a decision it doesn't make for you (an API shape,
   behavior a user would notice, a choice between fixes with different costs),
   don't guess: mark it not-fixed with the question as the reason, starting
   with "DECISION:". The user answers, and another fixer takes it from there.
3. Fix the rest, each scoped to what its finding asks, with no drive-by
   refactoring. Don't launch the app or open any window; the user may be
   working with a screen reader, and a window takes focus.
4. Build and run the project's tests and linters, using the commands in
   CLAUDE.md, the README, or the CI configuration. Finish with the build green
   and the tests passing. If you cannot get there, say so plainly instead of
   reporting success.
5. These files held the user's own uncommitted changes before the audit
   started: USER_FILES. Edit them when a fix requires it, but never stage or
   commit them, and name each one you touched in your report.
6. Git mode is GIT_MODE. Unless it is `none`, make one commit following the
   Commits section of SKILL_REFS/git.md: stage named paths only, a subject
   naming the reviewer and what was fixed (for example "Fix Nigel findings:
   README examples, missing mnemonics"), and a body listing the changes. Do not
   push.
7. Report one line per finding, `fixed` or `not-fixed`, with its id, where, and
   what changed or why not; then the validation commands and their result, the
   commit hash, and the files you left uncommitted.

Write plain prose and bullet lists; no ASCII tables, diagrams, or box drawing.
