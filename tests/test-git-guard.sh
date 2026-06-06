#!/usr/bin/env bash
# Tests for plugins/conventions/hooks/cross-platform/check-git-guard.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_ROOT/plugins/conventions/hooks/cross-platform/check-git-guard.sh"

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

echo "testing check-git-guard.sh"
echo "=========================="

run_hook '{"tool_input":{"command":"git commit -m wip"}}';  assert_exit "git commit blocked" 2
run_hook '{"tool_input":{"command":"git add -A"}}';         assert_exit "git add blocked" 2
run_hook '{"tool_input":{"command":"git stage foo"}}';      assert_exit "git stage blocked" 2
run_hook '{"tool_input":{"command":"git mv a b"}}';         assert_exit "git mv blocked" 2
run_hook '{"tool_input":{"command":"git rm old.txt"}}';     assert_exit "git rm blocked" 2
run_hook '{"tool_input":{"command":"git -C /tmp/x commit -m y"}}'; assert_exit "git -C path commit blocked" 2

run_hook '{"tool_input":{"command":"git status"}}';         assert_exit "git status allowed" 0
run_hook '{"tool_input":{"command":"git diff --stat"}}';    assert_exit "git diff allowed" 0
run_hook '{"tool_input":{"command":"git log --oneline"}}';  assert_exit "git log allowed" 0
run_hook '{"tool_input":{"command":"echo legitimate adder"}}'; assert_exit "non-git lookalike allowed" 0
run_hook '';                                                assert_exit "empty input allowed" 0

echo ""
echo "=========================="
echo "results: $passed passed, $failed failed"
[ "$failed" -gt 0 ] && exit 1
exit 0
