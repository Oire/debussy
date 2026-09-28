Codex, an external reviewer, reported the findings below about this project's
code. Try to refute each one before the user spends time deciding on it. Codex
reads quickly and sometimes cites a line that doesn't do what it says, misses a
guard a few lines away or in a caller, or proposes a fix that would break
something else.

For each finding, read the code at its location with enough context to judge
it, and follow callers, tests, or configuration where the claim depends on them.
Read files and use `git diff`, `git log`, and `git show`; don't modify anything.

- **refuted**: the code doesn't do what the finding says, the problem is
  handled elsewhere, or the suggested fix would make things worse. Say what you
  found.
- **confirmed**: you read the code and the problem is real as it stands,
  whether or not it predates the change under review.
- **suspected**: plausible, but the files don't settle it (it turns on
  runtime behavior, timing, or input you can't see). Say what would settle it.

A finding you can't verify is suspected, not confirmed. Give every finding a
verdict, keyed by its `id`, with a one-sentence reason that cites what you read.

FINDINGS
