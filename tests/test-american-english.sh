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

echo ""
echo "================================="
echo "results: $passed passed, $failed failed"
[ "$failed" -gt 0 ] && exit 1
exit 0
