#!/bin/bash
# run a read-only codex review and print its response
# usage: run-codex.sh <prompt-file>
# shipped identically by plan-exec and project-audit; validate-repo.py keeps them in sync.
#
# the prompt comes from a file, never from the command line: review prompts
# contain backticks (the report format is `file:line - severity: ...`), and a
# prompt pasted into a double-quoted argument would have them run as command
# substitutions before codex saw it. write the file with the Write tool, not
# echo or an unquoted heredoc, which expand them at write time.
#
# environment:
#   CODEX_MODEL         model to use (default: whatever codex picks from its
#                       config.toml, else its own default)
#   CODEX_EFFORT        reasoning effort (default: likewise)
#   CODEX_NO_OVERRIDES  set to 1 to pass no -c overrides at all, for codex
#                       proxies and wrappers that reject them

set -e

prompt_file="$1"
if [ -z "$prompt_file" ] || [ ! -s "$prompt_file" ]; then
    echo "error: usage: run-codex.sh <prompt-file> (the file must exist and not be empty)" >&2
    exit 1
fi
prompt=$(cat "$prompt_file")

args=(exec --sandbox read-only)
if [ "${CODEX_NO_OVERRIDES:-}" != 1 ]; then
    if [ -n "${CODEX_MODEL:-}" ]; then
        args+=(-c "model=$CODEX_MODEL")
    fi
    if [ -n "${CODEX_EFFORT:-}" ]; then
        args+=(-c "model_reasoning_effort=$CODEX_EFFORT")
    fi
    args+=(
        -c "stream_idle_timeout_ms=3600000"
        -c "project_doc=$HOME/.claude/CLAUDE.md"
        -c "project_doc=./CLAUDE.md"
    )
fi

# codex exec reads stdin even when given a prompt argument, so an inherited
# pipe that never closes (a background task, CI) would block it forever. the
# here-string hands it an empty line and EOF; it is portable to Git Bash on
# Windows, where the null device is spelled differently. exec replaces this
# shell, so stopping the task stops codex itself.
exec codex "${args[@]}" "$prompt" <<< ""
