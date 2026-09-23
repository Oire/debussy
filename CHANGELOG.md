# Changelog

All notable changes to this repo are recorded here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.12.1] - 2026-09-24

Plugins: review 0.4.1.

### Fixed
- The web scanner misjudged focus indicators in two cases. A link with no
  visible indicator read as having one, because Chromium's own link styles
  change `outline-offset` on focus while the outline stays `none`; undrawn
  outlines and borders no longer count. And an element that holds focus (a
  one-element trap) was compared with itself, still focused, and read as
  having none; the comparison now waits until focus has really moved.

## [0.12.0] - 2026-09-23

Plugins: review 0.4.0.

### Added
- **Nigel measures web UIs in a real browser.** A bundled scanner
  (`plugins/review/scripts/web-scan/`) runs in Chromium's headless shell, which
  never shows a window, and gathers evidence rather than verdicts:
  - axe-core violations in the page and in every visible iframe;
  - the accessibility tree as the browser computes it, with landmarks and
    headings;
  - text contrast against the composited background, flagged where an image,
    gradient, filter, or blend mode makes the number uncertain;
  - the real Tab order: stops with no visible focus change, stops hidden under
    sticky or fixed content (2.4.11), and focus traps;
  - reflow at the viewport a browser zoom actually produces, text clipped
    inside overflow-hidden boxes, and text drawn over text;
  - the 1.4.12 text-spacing overrides, reporting only what they break;
  - pointer targets under 24 pixels that also fail the spacing exception
    (2.5.8).

  `setup.mjs` installs Playwright, axe-core, and the headless shell once into
  the plugin's data directory (about 150 MB). A new
  `references/project-analyst/web-checks.md` tells Nigel how to run it and
  which browser checks mislead. Nigel's skeptic now treats a finding that rests
  only on a script's say-so as unconfirmed.

## [0.11.0] - 2026-09-23

Plugins: review 0.3.0, planning 0.3.1, write-manual 0.4.1.

### Fixed
- **Nigel and write-manual opened windows without asking.** A launched desktop
  app, or a browser that is not headless, takes focus from whatever the user is
  doing, which with a screen reader means losing your place. Nigel now runs web
  checks in Playwright's headless shell and opens a window only when its prompt
  allows it. project-audit asks once, up front, and passes the answer to every
  Nigel. write-manual says what will open and for how long before each launch,
  and treats every launch as needing its own yes.

### Added
- **Nigel reports its coverage.** Every review ends with what was checked. For
  an app with a user interface, each WCAG 2.2 AA criterion gets a verdict:
  fails, passes, not applicable, or not tested. For other areas, what was
  checked and found fine. Not-tested criteria are how whole areas get missed,
  since no scan flags them; project-audit lists them at triage.
- **Resume by name.** write-manual answers to "continue the manual" and plan-exec
  to "resume the plan", picking up from their progress files.

### Changed
- Nigel reports a defect repeated in many places as one finding listing its
  places.
- Counts in user-facing output are written as a sentence ("seven serious, three
  moderate") rather than a column of numbers.
- CLAUDE.md states that everything in the repo is public, and what that rules
  out.

## [0.10.0] - 2026-09-23

Plugins: planning 0.3.0, review 0.2.1, write-manual 0.4.0.

### Added
- **Notes left during manual review are acted on, all of them.** When you
  review a plan (plan-make) or a manual (write-manual) by hand, leave notes in
  the file with a marker. When you say "done", "go", or "continue", the skill
  finds every note and every unmarked edit (through `git diff` when the file is
  committed). It carries out each note and removes it, then searches again to
  confirm none remain. At the slightest doubt it stops and asks rather than
  guessing: a note that reads two ways, conflicts with another, or needs a
  decision it does not make. The marker is `!USERNOTE!` by default and is set
  by `noteMarkers` in `.claude/debussy.json`. An entry is either a single token
  (`@@`, `%%%`) or an opening and closing pair (`[usernote]...[/usernote]`).
  The procedure is one shared `references/manual-review.md`.

### Changed
- The settings moved out of `git.md` into their own shared `settings.md`, since
  they now cover more than git.

### Fixed
- **Codex received a mangled prompt.** Both Codex prompts contain backticks,
  and both skills pasted them into a double-quoted shell argument, so the shell
  ran the report-format instruction as a command substitution and Codex never
  saw it. `run-codex.sh` now takes a prompt file, written with the Write tool.
- **A failed or empty Codex run counted as clean.** A non-zero exit, no output,
  or output with neither `NO ISSUES FOUND` nor a severity tag is now reported
  as a reviewer failure. plan-exec's Codex loop also stops after the first round
  with no critical or major findings, once its minor findings are fixed.
- **plan-exec accepted a task whose commit failed.** Ticked checkboxes were the
  only success signal, so the next task swept the earlier task's changes into
  its own commit. A task now also has to move HEAD.
- **Uncommitted leftovers went unreported.** After each task and each fixer,
  plan-exec warns about uncommitted paths; the reviews read the committed diff
  and would never see them.
- `run-codex.sh` replaces its shell with Codex, so stopping the task stops
  Codex. Its defaults are now `gpt-5.5` at `xhigh` effort (`CODEX_MODEL`,
  `CODEX_EFFORT`), and `CODEX_NO_OVERRIDES=1` drops the `-c` overrides for Codex
  proxies that reject them.

The Codex fixes are adapted from [cc-thingz](https://github.com/umputun/cc-thingz),
which found the same problems in its planning plugin.

## [0.9.0] - 2026-09-23

Plugins: write-manual 0.3.0.

### Changed
- **write-manual glossaries live in the project.** They used to sit inside the
  installed plugin, where a plugin update overwrote whatever a run had added.
  They now live in `glossaries/` in the project's help directory (`base.json`
  plus one `<lang>.json` per language) and are committed with the manuals. A
  first run creates `base.json` from the product brief; flagged translation
  terms go into the language files when the user agrees. The bundled ExampleApp
  glossaries moved to `references/glossaries/examples/` and serve only as a
  format reference. The writer and verifier now also get the English glossary
  when a project has one. Glossaries added to an earlier plugin version's
  install directory are not migrated; copy them into `help/glossaries/` by hand.

## [0.8.0] - 2026-09-23

Plugins: planning 0.2.0, review 0.2.0, write-manual 0.2.0, dotnet-tools 0.1.1.

### Changed
- **Skills now take their work to a pull request.** `plan-make`, `plan-exec`,
  `project-audit`, and `write-manual` used to leave everything uncommitted.
  They now start on a new branch cut from the current tip of the base branch
  (`main`, `master`, or whatever `origin/HEAD` names), commit at verified
  boundaries, push, and open a pull request with `gh`. `plan-make` branches and
  commits the plan; `plan-exec` commits once per task and once per review round,
  moves the plan to `completed/`, and opens the pull request; `project-audit`
  commits once per triage round and never commits files that held the user's
  own changes. Nothing written to git mentions AI, Claude, or session links.

  All of it is set in `.claude/debussy.json` (project) or
  `~/.claude/debussy.json` (user): `git` is `none`, `commit`, `push`, or `pr`
  (the default); `baseBranch` overrides detection; `aiAttribution` defaults to
  `false`. `"git": "none"` restores the old behavior. The contract lives in one
  `references/git.md`, shipped identically in each of the three skills.
- **Instructions rewritten for Claude 5 models**, following Anthropic's guidance
  for Opus 5.5 and the Claude 5 generation. Each skill and plan now states what
  done looks like and when to stop and ask. Absolute rules repeated in capitals
  gave way to judgment with its reason. Generic checklists a capable model
  already knows were cut, keeping what is specific to Oire. Agent descriptions,
  which load into every session, went from multi-example essays to a few lines.
- **plan-exec review is a workflow.** Reviewers read the branch in parallel
  through up to six lenses (quality, implementation, testing, simplification,
  documentation, conventions), scaled to the size of the diff. A skeptic per
  file then tries to refute each finding, and one fixer handles what survives,
  validates, and commits. Re-check rounds cover critical problems only.
  Refuted findings are reported with their reasons rather than dropped. The
  separate smells phase became a lens, and the Codex loop is capped at three
  rounds instead of ten. Without the Workflow tool, the skill runs the same
  steps with plain subagents.
- **Nigel is verified.** `project-audit` fans Nigel out over four focus areas
  and has a skeptic check each area's findings against the files. Every finding
  carries its evidence and a status, confirmed or suspected. Nigel runs the
  app and screenshots it when it can, instead of judging visual design from
  layout code alone. The per-stack checklists moved to reference files, read
  after the stack is detected.
- **write-manual** keeps a progress file so a run can resume after a restart,
  and can screenshot the app so the researcher and verifier work from the real
  UI.
- **plan-make** asks only what the request and the code leave open, in one
  round, instead of four fixed questions. Plans gain "Done when" and
  "Validation commands" sections.

### Fixed
- The plan-exec fixer read a "Validation Commands" section that no plan ever
  had.
- Subagents were launched with a `mode: "bypassPermissions"` parameter the
  Agent tool does not take; permission prompts on destructive commands now
  apply as configured.
- A plan's final task moved the plan file while plan-exec was still re-reading
  it at its old path. plan-exec now moves it after the last task.
- plan-exec's Codex runner lacked the closed-stdin fix that project-audit's
  copy had, so Codex could hang when run from a background task.
- The .NET style corrector carried a hardcoded memory path from the project it
  was extracted from, and gave the wrong syntax for using declarations.
- Stale names: the `Task` tool (now `Agent`), `/plan-make` without its plugin
  prefix, a date-based plan filename in brainstorm, a nonexistent `plan.md` in
  plan-review, and WCAG 2.4.11 labeled as Focus Appearance (it is Focus Not
  Obscured).

### Added
- `validate-repo.py` checks that the shared copies of `git.md` and
  `run-codex.sh` stay identical, and that workflow scripts start with their
  `meta` export.

## [0.7.0] - 2026-09-02

### Changed
- **conventions:** `check-git-guard` now allows the three operations a stacked
  branch cannot be maintained without — `git rebase`, `git commit --amend`, and
  `git push --force-with-lease`. Stacked pull requests conflict by
  construction: when the parent branch merges or moves, every branch above it
  has to be replayed onto the new base and re-pushed. The old guard left that
  entirely to the user, on every branch, in every repo.

  The reversibility test the guard is built on turns out to allow all three.
  A rebase and an amend rewrite history, but they do not destroy it: the
  pre-rebase tip stays in `ORIG_HEAD` and the reflog, so
  `git reset --hard ORIG_HEAD` puts the branch back. That is a different
  category from `restore` or `clean -f`, which delete content git never held a
  copy of.

  `--force-with-lease` is the same distinction on the remote. `--force` is now
  matched as a whole token rather than as a prefix, so the leased variants get
  through. A bare `--force` overwrites the remote branch sight unseen —
  including a commit a colleague pushed a minute ago — while a leased push
  refuses to run unless the remote is still where the local repo last saw it.
  What is left is a rewrite of your own history.

  Still blocked: bare `--force` / `-f`, `--delete` / `-d`, `--mirror`,
  `--prune`, `+refspec`, `reset --hard`, `restore`, destructive `checkout`,
  `clean -f`, bulk staging, and `git mv` / `git rm`.

  Newly blocked: `git rebase -i` / `--interactive`. Not on reversibility
  grounds — an interactive rebase waits on an editor for its todo list, and the
  harness has no terminal to give it, so the command hangs instead of running.
  A block that says so beats a stalled session. The long rebase flags that
  merely contain an `i` (`--ignore-date`, `--ignore-whitespace`) are matched as
  whole tokens and stay allowed.

  Caveat now documented in the hook README: a lease is only as good as what the
  local repo has seen, since `git fetch` renews it against commits nobody
  looked at. `--force-if-includes` (git 2.30+) closes that gap and is allowed
  alongside the lease.

### Added
- **CI:** the workflow now tests what the repo actually ships. It ran green on
  every commit while covering one shell on one operating system; the
  PowerShell runners — half of every cross-platform hook, and the only runner
  the Windows install path uses — had no tests at all, which is how the
  line-break bug fixed in 0.6.0 reached master.

  Jobs: repo structure; ShellCheck; the Bash suites on Linux and macOS,
  invoked as `/bin/bash` so macOS exercises the bash 3.2 floor the runners
  claim; a Linux run with `jq` hidden, because the raw-payload fallback is the
  real path on machines that never installed it; and the PowerShell suites on
  Windows (5.1 *and* 7) and Linux (7). A single `CI` gate job aggregates them
  for branch protection. Also added `permissions: contents: read`, a
  concurrency group, and `workflow_dispatch`.
- **tests:** PowerShell suites for all three hooks —
  `test-git-guard.ps1`, `test-american-english.ps1`, and
  `test-no-null-redirect.ps1`, the last covering a hook that had never been
  tested. Each suite tests whichever PowerShell edition starts it.
- **tests:** `validate-repo.py` (116 checks) enforces what the docs ask for and
  nobody remembers: plugin names matching their directories, marketplace
  entries resolving to real directories, semver versions, skill frontmatter
  matching its directory, `hooks.json` pointing at files that exist, no
  hardcoded `~/.claude` paths in components, cross-platform runners shipping in
  `.ps1`/`.sh` pairs, and the two American English word maps agreeing entry for
  entry. It replaces the inline Python in the workflow, so it can be run
  locally.
- **tests:** shared case tables in `tests/cases/`. A hook's two runners now read
  the same cases, so adding one covers both and a verdict can only diverge
  deliberately. Rows a runner cannot answer are marked and skipped rather than
  quietly absent. Both readers fail if they read fewer cases than expected.
- `.gitattributes` pinning text files to LF. The repo is developed on Windows
  and its shell runners execute on Linux in CI, where a CRLF `.sh` fails in
  ways that are invisible locally.

### Fixed
- **conventions 0.5.1:** `check-no-null-redirect.ps1` could fail to parse under
  Windows PowerShell 5.1 — the interpreter the plugin's own Windows wiring
  uses. 5.1 reads a BOM-less `.ps1` using the system ANSI code page, so the
  em dash in a message string arrived as mojibake whose third byte (`0x94`) is
  a closing smart quote in CP1252; PowerShell honors smart quotes as string
  delimiters, the string ended early, and the script died with a parse error.
  A hook that fails to parse exits 1, which Claude Code treats as a hook error
  rather than a block — so on an affected machine the convention silently
  stopped being enforced. Both PowerShell hooks are now pure ASCII, and
  `validate-repo.py` fails if any `.ps1` stops being. Found by the new Windows
  CI job on its first run; it had been shipping since 0.1.0.
- **CI:** the frontmatter validator printed its success line after
  `sys.exit()`, so it never ran, and it skipped any path containing `.git` —
  which includes `.github`. Both are gone with the inline script.

### Notes
- `conventions` plugin bumped to 0.6.0 (hook behavior changed); marketplace
  bumped to 0.7.0. Other plugin versions unchanged.
- The git relaxation widens what Claude may do to history it can put back, and
  nothing else. If you want the previous behavior — no rebase, no amend, no
  leased push — stay on conventions 0.5.x.
- The git-guard case table grows from 58 cases to 76: the allowed rebase,
  amend and leased-push forms, the interactive rebase that is still blocked,
  and regression cases for the near misses (`--force-if-includes`,
  `--ignore-date`, `git pull --rebase`).

## [0.6.0] - 2026-08-23

### Changed
- **conventions:** `check-git-guard` now allows `git push`. The 0.5.0 rebuild
  moved the guard onto *reversibility* but kept push on the blocked list out of
  the older "publishing is the user's call" framing. Those two rules disagree: a
  plain push only ever adds commits to a remote, and a commit that should not
  have gone out comes back with a revert — the same standard that made a local
  commit acceptable. So a plain push is allowed, along with `-u`,
  `--set-upstream`, `--tags`, `--follow-tags`, and `-n`.

  What stays blocked is the push that *removes* history rather than adding to
  it: `--force` / `-f`, `--delete` / `-d`, `--mirror`, `--prune`, and a
  `+refspec`. `--force` is matched as a prefix, so `--force-with-lease` and
  `--force-if-includes` are blocked too — the lease makes the race safe, not the
  history rewrite. Everything else in the guard is untouched: amend, rebase,
  `reset --hard`, `restore`, destructive `checkout`, `clean -f`, bulk staging,
  and `git mv` / `git rm` are all still blocked.

### Fixed
- **conventions:** in the PowerShell runner, the scan for a blocked flag could
  run past a line break and pick one up from the *next* command in a multi-line
  script — so a `rm -f` two lines down could block the push above it. It now
  stops at the line break, matching the Bash runner, where grep already matched
  one line at a time.

### Added
- **tests:** the git-guard suite grows from 39 cases to 58 — nine allowed push
  forms, nine blocked ones, and both on the raw-payload path.

### Notes
- `conventions` plugin bumped to 0.5.0 (hook behavior changed); marketplace
  bumped to 0.6.0. Other plugin versions unchanged.
- The push relaxation is deliberately one-way: it widens what Claude may do on
  the remote only where the change is additive. If you want the 0.5.0 behavior
  back, stay on conventions 0.4.x.

## [0.5.0] - 2026-08-13

### Changed
- **conventions:** `check-git-guard` was rebuilt around *reversibility* rather
  than around "git writes" as a category. Claude may now stage explicitly named
  paths and commit locally — a commit is undone with
  `git reset --soft HEAD~1`, so the review checkpoint it used to protect is
  still available after the fact. Everything that publishes or destroys stays
  blocked, and several operations that were never guarded at all now are.

  Blocked at every level: `git push` (previously only prose in `CLAUDE.md` told
  Claude not to — the hook never checked), `commit --amend` and `rebase`
  (history rewriting), `reset --hard`, `restore`, `checkout -- <path>` /
  `checkout -f` and `clean -f` (discard work irrecoverably), bulk staging
  (`add -A` / `.` / `--all`, `commit -a`), and `git mv` / `git rm` (unchanged).

  Bulk staging is the counterweight to allowing commits: naming paths is what
  makes a delegated commit reviewable, and it keeps a sweeping add from
  quietly staging scratch output or a file with a secret in it. The
  non-destructive neighbors stay available — `reset --soft`, plain branch
  `checkout`, `checkout -b`, `clean -n`, `add -u`.

  There is deliberately no setting for this — no environment variable, no
  levels. A guard with a knob on it is a guard you have to remember the state
  of, and the point of a convention hook is that you set it up once and stop
  thinking about it. Anyone who wants Claude out of git entirely turns the hook
  off with `/hooks` or stays on conventions 0.3.x.

### Added
- **tests:** the git-guard suite grows from 11 cases to 39, covering each newly
  blocked operation and its non-destructive neighbor.

### Fixed
- **tests:** the git-guard suite now asserts the same verdicts on both
  extraction paths — the bare command (with `jq`) and the raw JSON payload
  (without it). The first draft of the token matcher passed on one and silently
  allowed `git add -A`, `git add .`, and `git clean -fd` on the other, which is
  the same failure mode `check-american-english` hit in 0.4.0.

### Notes
- `conventions` plugin bumped to 0.4.0 (hook behavior changed); marketplace
  bumped to 0.5.0. Other plugin versions unchanged.
- Existing installs pick this up on `/plugin update conventions@debussy` (or
  auto-update). Anyone who wants the old behavior stays on 0.3.x.

## [0.4.0] - 2026-08-01

### Fixed
- **conventions:** `check-american-english` (Bash runner) only applied its
  path-based skips when `jq` happened to be installed. Without `jq` the hook
  could not read `file_path` at all, fell back to scanning the raw payload, and
  every skip added in 0.2.0 silently stopped applying — a `.po` file was still
  blocked. The failure was invisible and untested, so it went unnoticed since
  0.2.0. The runner now lifts the path out of the raw JSON when `jq` is absent
  (Git Bash on Windows, typically) and normalizes Windows backslash paths
  before matching.

### Added
- **conventions:** `check-american-english` now also skips Apple localization
  catalogs (`.strings`, `.stringsdict`, `.xcstrings`) and files sitting in an
  unambiguous locale directory — `fr.lproj`, `fr-FR`, `pt_BR`, `zh-Hant`,
  `es-419`, Android's `values-fr`/`values-pt-rBR`, and a bare code like `fr`
  directly inside `locales/`, `_locales/`, `lang(s)/`, `i18n/`, `intl/` or
  `translations/`. English locales stay checked.

  A bare two-letter directory is deliberately not a skip signal by itself: many
  ISO 639-1 codes double as ordinary directory names (`it` is Maven's
  integration-test directory; `sh`, `so`, `ts`, `cs`, `pl`, `ml`, `gl`, `hr`,
  `el`, `id`, `is`, `no` are all codes too). A wrong skip fails silently and
  permanently; a wrong block is loud and self-correcting, so skipping carries
  the higher bar.

  Apple's catalogs are skipped for every locale including English, because their
  keys are identifiers the author cannot rename and match the word map whatever
  language the values use — the trade-off `.po` already makes with its English
  msgids.
- **tests:** 17 cases covering the path skips, which previously had none. They
  assert both directions (skipped vs still checked) and pass with and without
  `jq`, so a regression in path extraction fails the suite instead of quietly
  disabling the feature.

### Notes
- `conventions` plugin bumped to 0.3.0 (hook behavior changed); marketplace
  bumped to 0.4.0. Other plugin versions unchanged.

## [0.3.0] - 2026-07-12

### Changed
- **Positioning / docs:** reframed the marketplace as a public, general-purpose
  set of plugins rather than one person's machine setup. The root `README` and
  `CLAUDE.md` no longer describe debussy as customizations for a specific
  machine, and the **conventions** plugin is now explicitly labeled *opinionated
  Oire conventions* (organization policy, opt-in) to set it apart from the
  everyone-friendly plugins (planning, review, write-manual, dotnet-tools).
- **conventions hooks README:** documented a third wiring path — enable the
  plugin for the cross-platform hooks and add only the Windows-only
  `check-no-null-redirect` via a single `settings.json` entry that points at the
  plugin's own shipped script, so it tracks marketplace auto-updates instead of
  drifting from an `install.ps1` copy. Added a "don't double-wire" caution (the
  plugin's `.sh` runners plus the PowerShell runners of the same hook fire
  twice) and noted the plugin-storage-path trade-off. Verified the PowerShell
  no-null-redirect wiring end to end on Windows 11 with Git Bash.

### Notes
- Marketplace version bumped to 0.3.0 (`marketplace.json` metadata). Individual
  plugin versions are unchanged — no plugin behavior changed, only docs and
  positioning.

## [0.2.0] - 2026-07-12

### Changed
- **conventions:** `check-american-english` (Bash and PowerShell) now skips
  files that never hold the author's English prose — `lang(s)/*.php`,
  `*.po`/`*.pot`/`*.xlf`/`*.xliff`, and any HTML document whose root
  `<html lang="…">` is not `en*`. Translated content (message catalogs and
  localized pages) no longer trips the hook as a false positive. English source
  files, including HTML with `lang="en"`, are still checked.

## [0.1.0] - 2026-06-06

### Added
- Plugin marketplace (`.claude-plugin/marketplace.json`) exposing five plugins:
  - **planning** — brainstorm, plan-make, plan-review, plan-exec.
  - **review** — project-analyst (Nigel) + project-audit.
  - **write-manual** — accessible user-manual pipeline.
  - **dotnet-tools** — Oire .NET style corrector.
  - **conventions** — opt-in convention hooks with a `hooks/hooks.json`.
- Hooks (in the conventions plugin), organized by applicability:
  - `cross-platform/check-american-english` — PowerShell + Bash runners sharing
    one word map (the Bash map is generated from the PowerShell source).
  - `cross-platform/check-git-guard` — blocks `git commit`/`add`/`stage` and
    `git mv`/`git rm` (PowerShell + Bash).
  - `windows-only/check-no-null-redirect` — Windows-only; not ported to Unix.
- Manual hook path: `settings/` snippets (Windows + Unix) and
  `install.* / sync.* / uninstall.*` helpers that copy the convention hooks
  into/out of `~/.claude/hooks`.
- `CLAUDE.md`, human-facing `README.md`, `.gitignore`, and
  `docs/marketplace-plan.md` (the packaging rationale).
- LICENSE attribution filled in (Apache-2.0, Copyright 2026 André Polykanine).
- Attribution to [cc-thingz by Umputun](https://github.com/umputun/cc-thingz):
  the `planning` plugin is adapted from his MIT-licensed work. Added `NOTICE`
  (retaining his MIT notice; Apache-2.0 and MIT are compatible), README credits,
  and a per-plugin attribution note.
- CI workflow (`.github/workflows/ci.yml`): YAML-frontmatter validation, JSON
  manifest validation, ShellCheck, and the hook test suite.
- `tests/` — bash tests for the cross-platform convention hooks
  (`test-american-english.sh`, `test-git-guard.sh`).
- `plugin.json` polish: `homepage`, `repository`, `license` on every plugin.

### Fixed
- **Plugins now work when installed.** Skills referenced scripts at
  `~/.claude/skills/...` (the old file-copy path), which broke under plugin
  install; switched to `${CLAUDE_PLUGIN_ROOT}` across planning/review/
  write-manual, and moved user-level custom rules to `${CLAUDE_PLUGIN_DATA}`
  (plugin-aware `resolve-rules.sh`, adapted from cc-thingz).
- `plan-review` agent: quoted its YAML frontmatter (was invalid strict YAML) and
  corrected a stale `/action:plan` reference to `/planning:plan-make`.

### Notes
- This repo enforces its own conventions on itself (American English; no
  null-device redirects on Windows; no Claude-side git commits/staging or
  `git mv`/`git rm`), so authoring sometimes works around the very hooks it
  ships — see `plugins/conventions/hooks/README.md`.
- `check-no-null-redirect` is intentionally Windows-only and is not auto-wired
  by the conventions plugin (a plugin `hooks.json` can't branch on OS).
