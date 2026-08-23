#!/usr/bin/env bash
# Tests for plugins/conventions/hooks/cross-platform/check-git-guard.sh
#
# The cases live in tests/cases/git-guard.tsv and are shared with the
# PowerShell suite (tests/test-git-guard.ps1), so the two runners are held to
# exactly the same verdicts. Add a case to the table, not to this file.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$REPO_ROOT/plugins/conventions/hooks/cross-platform/check-git-guard.sh"
CASES="$SCRIPT_DIR/cases/git-guard.tsv"

# Guards against a reader bug that would silently run nothing and pass.
MIN_CASES=50

passed=0
failed=0
count=0
skipped=0

run_hook() { out="$(printf '%s' "$1" | bash "$HOOK" 2>&1)"; rc=$?; }

pass() { echo "  PASS: $1"; passed=$((passed + 1)); }
fail() { echo "  FAIL: $1"; failed=$((failed + 1)); echo "    output: $out"; }

if [ ! -f "$HOOK" ]; then
    echo "missing hook: $HOOK" >&2
    exit 1
fi
if [ ! -f "$CASES" ]; then
    echo "missing case table: $CASES" >&2
    exit 1
fi

echo "testing check-git-guard.sh"
echo "=========================="

while IFS=$'\t' read -r expect mode command label title <&3 || [ -n "${expect:-}" ]; do
    case "$expect" in
        '#>'*)
            echo ""
            echo "-- ${expect#\#> }"
            continue
            ;;
        '#'* | '')
            continue
            ;;
    esac

    if [ "$mode" = parsed ] && [ -z "$(command -v jq || true)" ]; then
        echo "  SKIP: $label (needs jq to extract the command)"
        skipped=$((skipped + 1))
        continue
    fi

    count=$((count + 1))

    if [ "$mode" = json ] || [ "$mode" = parsed ]; then
        # Only the double quotes need escaping: a '\n' in the table is already
        # the JSON escape for a line break, and is meant to survive as one.
        escaped=$(printf '%s' "$command" | sed 's/"/\\"/g')
        run_hook "{\"tool_input\":{\"command\":\"$escaped\"}}"
    else
        # printf %b turns the table's '\n' into a real line break.
        run_hook "$(printf '%b' "$command")"
    fi

    if [ "$rc" != "$expect" ]; then
        fail "$label -- expected exit $expect, got $rc"
        continue
    fi

    if [ -n "${title:-}" ]; then
        case "$out" in
            *"$title"*) pass "$label (exit $rc, $title)" ;;
            *) fail "$label -- blocked, but not by '$title'" ;;
        esac
    else
        pass "$label (exit $rc)"
    fi
done 3<"$CASES"

echo ""
echo "-- degenerate input"
run_hook ''
if [ "$rc" = 0 ]; then pass "empty input allowed (exit $rc)"; else fail "empty input allowed"; fi
run_hook 'not json at all'
if [ "$rc" = 0 ]; then pass "non-JSON, non-git input allowed (exit $rc)"; else fail "non-JSON input allowed"; fi

echo ""
echo "=========================="
if [ "$count" -lt "$MIN_CASES" ]; then
    echo "only $count cases read from $CASES (expected at least $MIN_CASES) -- the table or its reader is broken"
    exit 1
fi
echo "results: $passed passed, $failed failed, $skipped skipped ($count table cases run)"
[ "$failed" -gt 0 ] && exit 1
exit 0
