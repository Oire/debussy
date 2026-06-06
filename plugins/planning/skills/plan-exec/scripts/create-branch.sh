#!/bin/bash
# create a feature branch from plan file name if currently on the default branch
# usage: create-branch.sh <plan-file-path>
# exits 0 if branch created or already on a feature branch
# outputs branch name to stdout
#
# plan files are named like "001-feature-name.md" or "042-bug-fix.md" — the
# leading digit sequence + dash is stripped from the branch name. legacy
# date-prefixed files like "20260329-feature-name.md" are also handled by
# the same regex since it matches any run of leading digits followed by "-".
# git-only.

set -e

if [ -z "${1:-}" ]; then
    echo "error: plan file path required" >&2
    exit 1
fi

plan_file="$1"

# derive branch name from plan file path
# e.g. docs/plans/001-feature-name.md -> feature-name
derive_branch_name() {
    local name
    name=$(basename "$1" .md)
    # strip leading digit run + dash (handles 001-, 042-, 20260329-, etc.)
    # shellcheck disable=SC2001 # prefix strip with a quantified class
    name=$(echo "$name" | sed 's/^[0-9]\{1,\}-//')
    echo "$name"
}

current_branch=$(git branch --show-current)

# detect the default branch using local-only checks (no network calls)
default_branch=""
# 1. cached remote HEAD — only read it if the ref actually exists
if git show-ref --verify --quiet refs/remotes/origin/HEAD; then
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
fi
# 2. fall back to common default branch names found locally
if [ -z "$default_branch" ]; then
    for candidate in main master trunk develop; do
        if git show-ref --verify --quiet "refs/heads/$candidate"; then
            default_branch="$candidate"
            break
        fi
    done
fi

# if already on a feature branch (not the default and not detached), just report it
if [ -n "$current_branch" ] && [ -n "$default_branch" ] && [ "$current_branch" != "$default_branch" ]; then
    echo "$current_branch"
    exit 0
fi

# fallback if no default detected — if the current branch is not main/master, treat it as a feature branch
if [ -n "$current_branch" ] && [ -z "$default_branch" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
    echo "$current_branch"
    exit 0
fi

branch_name=$(derive_branch_name "$plan_file")

if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git checkout "$branch_name"
else
    git checkout -b "$branch_name"
fi

echo "$branch_name"
