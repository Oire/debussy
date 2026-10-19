#!/bin/bash
# initialize the progress file with a header, or note a resumed run in it
# usage: init-progress.sh <progress-file> <plan-path> <branch-name>
# creates the parent directory if needed. a file that already has content is
# a stopped run being picked up, so it is kept and gets a "Resumed" line: what
# it recorded is what the resumed run reads to know where it stands.

set -e

file="$1"
plan="$2"
branch="$3"

if [ -z "$file" ] || [ -z "$plan" ] || [ -z "$branch" ]; then
    echo "error: usage: init-progress.sh <progress-file> <plan-path> <branch-name>" >&2
    exit 1
fi

mkdir -p "$(dirname "$file")"

if [ -s "$file" ]; then
    echo "Resumed: $(date '+%Y-%m-%d %H:%M:%S') on $branch" >> "$file"
    echo "$file"
    exit 0
fi

cat > "$file" <<EOF
# progress
Plan: $plan
Branch: $branch
Started: $(date '+%Y-%m-%d %H:%M:%S')
---
EOF

echo "$file"
