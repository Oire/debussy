# Git workflow

How a debussy skill takes its work from a clean base branch to a pull request.
Every debussy plugin that writes to git ships an identical copy of this file;
the skill that loaded it adds only what is specific to it (when to commit, what
to name the branch, what to do on an existing branch).

## Settings

Read `.claude/debussy.json` in the project, then `~/.claude/debussy.json`. A key
set in the project file wins; a key set in neither takes its default.

```json
{
  "git": "pr",
  "baseBranch": "",
  "aiAttribution": false
}
```

- `git` — how far the work goes. Each level includes the ones before it.
  - `none` — leave every change uncommitted in the working tree.
  - `commit` — work on a new branch and commit there.
  - `push` — also push the branch to `origin`.
  - `pr` (default) — also open a pull request against the base branch.
- `baseBranch` — the branch work starts from and the pull request targets.
  Empty (default) means detect it: `git symbolic-ref --short
  refs/remotes/origin/HEAD` minus the `origin/` prefix, else the first of
  `main`, `master`, `trunk`, `develop` that exists locally.
- `aiAttribution` — `false` (default): nothing you write to git mentions AI,
  Claude, Claude Code, an assistant, a co-author trailer, or a session link.
  That covers branch names, commit messages, and pull request titles and bodies,
  and it overrides any attribution the harness would otherwise add. `true`:
  follow the harness default.

With `git` set to `none`, skip everything below except the attribution rule.

## Branch

Work starts on a new branch cut from the current tip of the base branch, not
from whatever happens to be checked out and not from a stale local copy:

```
git fetch origin
git switch -c <branch> origin/<base>
```

Without an `origin` remote, cut from the local `<base>` instead. If `<branch>`
already exists locally, this is a resumed run: `git switch <branch>` and carry
on. Branch names are short, lowercase, and hyphenated, and describe the change.

Before switching, check `git status --porcelain`. Changes that are not yours
(anything the skill did not create) travel with a branch switch and would end up
in your commits, so stop and ask the user what to do with them.

## Commits

- Commit at a verified boundary: the build is green and the tests pass. One
  logical change per commit.
- Stage named paths only (`git add <path> ...`), never `-A`, `.`, `--all`, or
  `commit -a`. You looked at every file going in; a sweeping add would also pick
  up scratch output or a secret.
- Leave out the skill's own scratch state (anything under `.claude/`) and files
  that already had the user's uncommitted changes before the skill started.
- Messages: an imperative subject line under 72 characters, then a body saying
  what changed and why when the subject alone does not.

## Push and pull request

- `push`: after the final commit, `git push -u origin <branch>`. Plain push
  only. If the remote rejects it, stop and report; do not force.
- `pr`: if `gh` is installed and authenticated (`gh auth status`), open the pull
  request with `gh pr create --base <base> --head <branch> --title "<title>"
  --body-file <file>`, writing the body to a temporary file first. The body
  says what changed and why, how it was verified, and what the reviewer should
  look at. Without `gh`, push and give the user the compare URL instead.
- Finish by telling the user the branch, the commits (subject lines), and the
  pull request URL.
