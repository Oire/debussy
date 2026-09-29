# Git workflow

How a debussy skill takes its work from a clean base branch to a pull request.
Every debussy plugin that writes to git ships an identical copy of this file;
the skill that loaded it adds only what is specific to it (when to commit, what
to name the branch, what to do on an existing branch).

## Settings

`settings.md`, beside this file, defines `git` (how far the work goes),
`baseBranch`, and `aiAttribution`. Resolve them before anything below.

With `git` set to `none`, skip everything below except the attribution rule.

## Branch

Work starts on a new branch cut from the up-to-date base branch, not from
whatever happens to be checked out:

```
git switch <base>
git pull --ff-only
git switch -c <branch>
```

Skip the pull when there is no `origin` remote. If it refuses because the local
base has diverged from the remote, stop and ask. If `<branch>` already exists
locally, this is a resumed run: `git switch <branch>` and carry on. Branch
names are short, lowercase, and hyphenated, and describe the change.

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

- `push`: after the final commit, a plain `git push`. With
  `push.autoSetupRemote` on, that also creates the remote branch and tracks
  it. If git answers that the branch has no upstream, run
  `git push -u origin HEAD`, which does the same. Never name the branch or add
  a refspec. If the remote rejects the push, stop and report; do not force.
- `pr`: if `gh` is installed and authenticated (`gh auth status`), open the pull
  request with `gh pr create --base <base> --head <branch> --title "<title>"
  --body-file <file>`, writing the body to a temporary file first. The body
  says what changed and why, how it was verified, and what the reviewer should
  look at. Without `gh`, push and give the user the compare URL instead.
- Finish by telling the user the branch, the commits (subject lines), and the
  pull request URL.
