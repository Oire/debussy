# Settings

Debussy skills read their settings from `.claude/debussy.json` in the project,
then `~/.claude/debussy.json`. A key set in the project file wins; a key set in
neither takes its default. Every debussy plugin that reads settings ships an
identical copy of this file.

```json
{
  "git": "pr",
  "baseBranch": "",
  "aiAttribution": false,
  "noteMarkers": ["!USERNOTE!"]
}
```

- `git` — how far a skill takes its work. Each level includes the ones before
  it. `git.md` says what each step involves.
  - `none` — leave every change uncommitted in the working tree.
  - `commit` — work on a new branch and commit there.
  - `push` — also push the branch to `origin`.
  - `pr` (default) — also open a pull request against the base branch.
- `baseBranch` — the branch work starts from and the pull request targets.
  Empty (default) means detect it: `git symbolic-ref --short
  refs/remotes/origin/HEAD` minus the `origin/` prefix, else the first of
  `main`, `master`, `trunk`, `develop` that exists locally.
- `aiAttribution` — `false` (default): nothing written to git mentions AI,
  Claude, Claude Code, an assistant, a co-author trailer, or a session link.
  That covers branch names, commit messages, and pull request titles and bodies,
  and it overrides any attribution the harness would otherwise add. `true`:
  follow the harness default.
- `noteMarkers` — how the user marks notes in a file they review by hand
  (`manual-review.md` says what happens to them). A list, so a user can keep
  more than one convention. Each entry is one of:
  - a single token, such as `!USERNOTE!`, `@@`, or `%%%`: the note runs from the
    token to the end of its line, and on into following lines that plainly
    continue it;
  - an opening and closing pair written with `...` between them, such as
    `[usernote]...[/usernote]`: the note is everything between the two, across
    lines if need be.

  Default: `["!USERNOTE!"]`.
