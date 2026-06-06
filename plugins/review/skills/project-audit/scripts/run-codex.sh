#!/bin/bash
# run codex review and return output
# usage: run-codex.sh "<prompt>"
# outputs codex response to stdout
# copied from plan-exec — keep in sync if you change one.

set -e

prompt="$1"
if [ -z "$prompt" ]; then
    echo "error: usage: run-codex.sh '<prompt>'" >&2
    exit 1
fi

# `echo "" |` closes stdin for codex. Without it, codex blocks forever
# waiting on stdin when invoked from non-interactive contexts (Claude
# Code bash tasks, CI runners, etc.) — stdin is inherited from the
# parent and never reaches EOF. Portable across bash / Git Bash /
# PowerShell / cmd; avoids the `< /dev/null` Unix-ism.
echo "" | codex exec \
    --sandbox read-only \
    -c "model=${CODEX_MODEL:-gpt-5.4}" \
    -c "model_reasoning_effort=high" \
    -c "stream_idle_timeout_ms=3600000" \
    -c "project_doc=$HOME/.claude/CLAUDE.md" \
    -c "project_doc=./CLAUDE.md" \
    "$prompt"
