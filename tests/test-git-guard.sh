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

echo ""
echo "-- staging named paths and committing is allowed"
run_hook '{"tool_input":{"command":"git commit -m wip"}}';            assert_exit "git commit allowed" 0
run_hook '{"tool_input":{"command":"git add src/foo.ts src/bar.ts"}}'; assert_exit "git add <paths> allowed" 0
run_hook '{"tool_input":{"command":"git add ./src/foo.ts"}}';         assert_exit "git add ./path allowed" 0
run_hook '{"tool_input":{"command":"git -C /tmp/x commit -m y"}}';    assert_exit "git -C path commit allowed" 0
run_hook '{"tool_input":{"command":"git commit -m \"add the adder\""}}'; assert_exit "commit message wording allowed" 0

echo ""
echo "-- bulk staging is blocked"
run_hook '{"tool_input":{"command":"git add -A"}}';                   assert_exit "git add -A blocked" 2
run_hook '{"tool_input":{"command":"git add ."}}';                    assert_exit "git add . blocked" 2
run_hook '{"tool_input":{"command":"git add --all"}}';                assert_exit "git add --all blocked" 2
run_hook '{"tool_input":{"command":"git commit -am wip"}}';           assert_exit "git commit -am blocked" 2
run_hook '{"tool_input":{"command":"git commit -a -m wip"}}';         assert_exit "git commit -a blocked" 2

echo ""
echo "-- publishing and history rewriting are blocked"
run_hook '{"tool_input":{"command":"git push"}}';                     assert_exit "git push blocked" 2
run_hook '{"tool_input":{"command":"git push origin master"}}';       assert_exit "git push origin blocked" 2
run_hook '{"tool_input":{"command":"git -C /tmp/x push"}}';           assert_exit "git -C path push blocked" 2
run_hook '{"tool_input":{"command":"git commit --amend -m x"}}';      assert_exit "git commit --amend blocked" 2
run_hook '{"tool_input":{"command":"git rebase master"}}';            assert_exit "git rebase blocked" 2

echo ""
echo "-- discarding work is blocked"
run_hook '{"tool_input":{"command":"git reset --hard HEAD"}}';        assert_exit "git reset --hard blocked" 2
run_hook '{"tool_input":{"command":"git restore src/foo.ts"}}';       assert_exit "git restore blocked" 2
run_hook '{"tool_input":{"command":"git checkout -- src/foo.ts"}}';   assert_exit "git checkout -- <path> blocked" 2
run_hook '{"tool_input":{"command":"git checkout -f main"}}';         assert_exit "git checkout -f blocked" 2
run_hook '{"tool_input":{"command":"git clean -fd"}}';                assert_exit "git clean -fd blocked" 2

echo ""
echo "-- their non-destructive neighbors are allowed"
run_hook '{"tool_input":{"command":"git reset --soft HEAD~1"}}';      assert_exit "git reset --soft allowed" 0
run_hook '{"tool_input":{"command":"git checkout my-feature"}}';      assert_exit "git checkout <branch> allowed" 0
run_hook '{"tool_input":{"command":"git checkout -b new-branch"}}';   assert_exit "git checkout -b allowed" 0
run_hook '{"tool_input":{"command":"git clean -n"}}';                 assert_exit "git clean -n allowed" 0
run_hook '{"tool_input":{"command":"git add -u"}}';                   assert_exit "git add -u allowed" 0

echo ""
echo "-- file operations are blocked"
run_hook '{"tool_input":{"command":"git mv a b"}}';                   assert_exit "git mv blocked" 2
run_hook '{"tool_input":{"command":"git rm old.txt"}}';               assert_exit "git rm blocked" 2

echo ""
echo "-- read-only git and non-git commands are untouched"
run_hook '{"tool_input":{"command":"git status"}}';                   assert_exit "git status allowed" 0
run_hook '{"tool_input":{"command":"git diff --stat"}}';              assert_exit "git diff allowed" 0
run_hook '{"tool_input":{"command":"git log --oneline"}}';            assert_exit "git log allowed" 0
run_hook '{"tool_input":{"command":"echo legitimate adder"}}';        assert_exit "non-git lookalike allowed" 0
run_hook '';                                                          assert_exit "empty input allowed" 0

echo ""
echo "-- same verdicts on the extracted-command path (what jq hands over)"
# Without jq the hook scans the raw JSON payload, so a flag is followed by a
# quote; with jq it sees the bare command, where the flag ends the string. Both
# have to reach the same verdict, or the guard silently loosens on one of them.
run_hook 'git add -A';                                                assert_exit "bare: git add -A blocked" 2
run_hook 'git add .';                                                 assert_exit "bare: git add . blocked" 2
run_hook 'git clean -fd';                                             assert_exit "bare: git clean -fd blocked" 2
run_hook 'git checkout -- src/foo.ts';                                assert_exit "bare: git checkout -- blocked" 2
run_hook 'git add .gitignore';                                        assert_exit "bare: git add .gitignore allowed" 0
run_hook 'git add src/foo.ts';                                        assert_exit "bare: git add <path> allowed" 0
run_hook 'git commit -m wip';                                         assert_exit "bare: git commit allowed" 0

echo ""
echo "=========================="
echo "results: $passed passed, $failed failed"
[ "$failed" -gt 0 ] && exit 1
exit 0
