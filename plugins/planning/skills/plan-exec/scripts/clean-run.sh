#!/bin/bash
# remove a finished run's scratch state
# usage: clean-run.sh <progress-file>
# deletes the progress file and the codex prompt, then progress/ and
# .claude/exec-plan/ if that left them empty. the project's prompt and lens
# overrides live in .claude/exec-plan/ too, so nothing else there is touched.

set -e

file="$1"

case "$file" in
    *..*) file="" ;;
esac
case "$file" in
    .claude/exec-plan/progress/*.txt) ;;
    *)
        echo "error: usage: clean-run.sh .claude/exec-plan/progress/<plan-stem>.txt" >&2
        exit 1
        ;;
esac

rm -f "$file" .claude/exec-plan/codex-prompt.txt

for dir in .claude/exec-plan/progress .claude/exec-plan; do
    if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
        rmdir "$dir"
    fi
done
