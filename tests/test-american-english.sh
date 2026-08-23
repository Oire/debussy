#!/usr/bin/env bash
# Tests for plugins/conventions/hooks/cross-platform/check-american-english.sh
# Feeds fake PreToolUse payloads on stdin and asserts exit code + message.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_ROOT/plugins/conventions/hooks/cross-platform/check-american-english.sh"

passed=0
failed=0

run_hook() { out="$(printf '%s' "$1" | bash "$HOOK" 2>&1)"; rc=$?; }

assert_exit() {
    local name="$1" want="$2"
    if [ "$rc" = "$want" ]; then
        echo "  PASS: $name (exit $rc)"; passed=$((passed + 1))
    else
        echo "  FAIL: $name -- expected exit $want, got $rc"; failed=$((failed + 1)); echo "    output: $out"
    fi
}

assert_contains() {
    local name="$1" needle="$2"
    case "$out" in
        *"$needle"*) echo "  PASS: $name"; passed=$((passed + 1));;
        *) echo "  FAIL: $name -- output missing '$needle'"; failed=$((failed + 1)); echo "    output: $out";;
    esac
}

echo "testing check-american-english.sh"
echo "================================="

run_hook '{"tool_input":{"content":"We should optimise the colour behaviour."}}'
assert_exit "british content blocked" 2
assert_contains "names the replacement" "colour -> color"

run_hook '{"tool_input":{"content":"We should optimize the color behavior."}}'
assert_exit "american content allowed" 0

run_hook '{"tool_input":{"new_string":"raise a surprise, exercise the license"}}'
assert_exit "look-alike words not flagged" 0

run_hook '{"tool_input":{"new_string":"normalise the input"}}'
assert_exit "new_string scanned" 2

run_hook '{"tool_input":{"edits":[{"new_string":"clean"},{"new_string":"behaviour here"}]}}'
assert_exit "multiedit edits scanned" 2

run_hook ''
assert_exit "empty input allowed" 0

run_hook 'not json at all'
assert_exit "malformed json allowed" 0

# --- path-based skips -------------------------------------------------------
# The cases live in tests/cases/american-english-paths.tsv and are shared with
# the PowerShell suite, so the two runners are held to the same verdicts.
#
# The offending word is assembled at runtime so this file does not trip the very
# hook it tests (see the hooks README, "Authoring gotcha"). These cases must
# pass with AND without jq installed -- the hook falls back to reading the path
# out of the raw JSON, and a silent regression there disables every skip below.
BAD="behavi""our"
payload() {
    # A backslash in the path has to survive as one through JSON.
    esc=$(printf '%s' "$1" | sed 's/\\/\\\\/g')
    printf '{"tool_input":{"file_path":"%s","content":"%s"}}' "$esc" "$BAD"
}

CASES="$SCRIPT_DIR/cases/american-english-paths.tsv"
MIN_PATH_CASES=10
path_cases=0

if [ ! -f "$CASES" ]; then
    echo "missing case table: $CASES" >&2
    exit 1
fi

while IFS=$'\t' read -r expect path label <&3 || [ -n "${expect:-}" ]; do
    case "$expect" in '#'* | '') continue ;; esac
    path_cases=$((path_cases + 1))
    run_hook "$(payload "$path")"
    assert_exit "$label" "$expect"
done 3<"$CASES"

if [ "$path_cases" -lt "$MIN_PATH_CASES" ]; then
    echo "only $path_cases path cases read from $CASES -- the table or its reader is broken"
    exit 1
fi

echo ""
echo "================================="
echo "results: $passed passed, $failed failed"
[ "$failed" -gt 0 ] && exit 1
exit 0
