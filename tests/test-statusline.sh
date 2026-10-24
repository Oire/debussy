#!/usr/bin/env bash
# Tests for statusline/statusline.sh
#
# The cases live in tests/cases/statusline.tsv and are shared with the
# PowerShell suite (tests/test-statusline.ps1), so the two scripts are held to
# exactly the same output. Add a case to the table, not to this file.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
STATUSLINE="$REPO_ROOT/statusline/statusline.sh"
CASES="$SCRIPT_DIR/cases/statusline.tsv"

# Guards against a reader bug that would silently run nothing and pass.
MIN_CASES=8

passed=0
failed=0
count=0

pass() { echo "  PASS: $1"; passed=$((passed + 1)); }
fail() { echo "  FAIL: $1"; failed=$((failed + 1)); echo "    expected: $2"; echo "    output:   $out"; }

if [ ! -f "$STATUSLINE" ]; then
    echo "missing script: $STATUSLINE" >&2
    exit 1
fi
if [ ! -f "$CASES" ]; then
    echo "missing case table: $CASES" >&2
    exit 1
fi

echo "testing statusline.sh"
echo "====================="

if [ -z "$(command -v jq || true)" ]; then
    out="$(printf '{}' | bash "$STATUSLINE" compact 2>&1)"
    if [ "$out" = "Status line needs jq." ]; then
        echo "  PASS: without jq it says so"
        echo "  SKIP: the case table (needs jq)"
        exit 0
    fi
    echo "  FAIL: without jq it says so"
    echo "    output: $out"
    exit 1
fi

while IFS=$'\t' read -r zone mode json expected label <&3 || [ -n "${zone:-}" ]; do
    case "$zone" in
        '#>'*)
            echo ""
            echo "-- ${zone#\#> }"
            continue
            ;;
        '#'* | '')
            continue
            ;;
    esac

    count=$((count + 1))

    if [ "$mode" = - ]; then
        out="$(printf '%s' "$json" | TZ=UTC bash "$STATUSLINE" 2>&1)"
    else
        out="$(printf '%s' "$json" | TZ=UTC bash "$STATUSLINE" "$mode" 2>&1)"
    fi

    if [ "$out" = "$expected" ]; then
        pass "$label"
    else
        fail "$label" "$expected"
    fi
done 3<"$CASES"

echo ""
echo "====================="
if [ "$count" -lt "$MIN_CASES" ]; then
    echo "only $count cases read from $CASES (expected at least $MIN_CASES) -- the table or its reader is broken"
    exit 1
fi
echo "results: $passed passed, $failed failed ($count table cases run)"
[ "$failed" -gt 0 ] && exit 1
exit 0
