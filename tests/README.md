# tests

Everything here runs locally exactly as it runs in CI
([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)). No test framework,
no dependencies beyond `bash`, PowerShell, and Python with PyYAML.

## Running them

```bash
bash tests/test-american-english.sh
bash tests/test-git-guard.sh
python3 tests/validate-repo.py
```

```powershell
pwsh -NoProfile -File tests/test-git-guard.ps1
pwsh -NoProfile -File tests/test-american-english.ps1
pwsh -NoProfile -File tests/test-no-null-redirect.ps1
```

On Windows, run the `.ps1` suites with `powershell` as well as `pwsh`. Each
suite tests the interpreter it is started with, and the wiring in
[`settings/settings.windows.example.json`](../settings/settings.windows.example.json)
uses `powershell.exe` — Windows PowerShell 5.1, which differs from 7 in ways
that have bitten these hooks (native stderr arrives as an error record).

## Layout

| File | Covers |
| --- | --- |
| `test-american-english.{sh,ps1}` | `check-american-english`, both runners |
| `test-git-guard.{sh,ps1}` | `check-git-guard`, both runners |
| `test-no-null-redirect.ps1` | `check-no-null-redirect` (Windows-only, so no `.sh`) |
| `validate-repo.py` | Manifests, component frontmatter, hook wiring, runner parity |
| `cases/*.tsv` | Case tables shared by a hook's two suites |

## Why the case tables exist

Each cross-platform hook ships two runners that must agree. A hand-maintained
suite per runner drifts — and did: the `.ps1` git guard once scanned past a
line break where the `.sh` did not, and no test noticed. The shared tables in
`cases/` mean adding a case covers both runners at once, and a verdict can only
diverge if someone makes it diverge on purpose.

Add cases to the table, not to the suites. Both readers refuse to pass if they
read fewer cases than expected, so a broken table fails loudly instead of
quietly testing nothing.

Rows a runner genuinely cannot answer are marked and skipped rather than
deleted: `bare` rows in `cases/git-guard.tsv` describe the Bash runner's no-`jq`
fallback, which the PowerShell runner has no equivalent of, and `parsed` rows
need a real JSON parse, which the Bash runner only has when `jq` is installed.

## Where the words went

The suites for `check-american-english` never write a flagged word literally —
they pull one out of the runner's own word map at run time, or assemble it from
fragments. A file containing the literal word would trip the very hook it
tests. Same reason `cases/american-english-paths.tsv` holds only paths.

## What CI adds

- Bash suites on Linux **and** macOS, invoked as `/bin/bash` — macOS ships
  bash 3.2, the portability floor the runners claim to hold to.
- A Linux run with `jq` hidden, because the raw-payload fallback is the real
  path on any machine that never installed `jq`.
- PowerShell suites on Windows (5.1 and 7) and on Linux (7).
- `validate-repo.py`, which checks the things prose asks for and nobody
  remembers: plugin names matching directories, marketplace entries resolving,
  skill frontmatter matching its directory, `hooks.json` pointing at files that
  exist, no hardcoded `~/.claude` paths in components, and the two American
  English word maps agreeing entry for entry.
