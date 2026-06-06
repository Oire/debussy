#!/bin/bash
# detect the default branch name of the current repository
# outputs the branch name to stdout
# avoids network calls — only reads local refs
# git-only.

set -e

branch=""

# 1. cached remote HEAD — only read it if the ref actually exists
if git show-ref --verify --quiet refs/remotes/origin/HEAD; then
    branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
fi

# 2. common default branch names found locally
if [ -z "$branch" ]; then
    for candidate in main master trunk develop; do
        if git show-ref --verify --quiet "refs/heads/$candidate"; then
            branch="$candidate"
            break
        fi
    done
fi

# 3. final fallback
if [ -z "$branch" ]; then
    branch="main"
fi

echo "$branch"
