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
# The offending word is assembled at runtime so this file does not trip the very
# hook it tests (see the hooks README, "Authoring gotcha"). These cases must
# pass with AND without jq installed -- the hook falls back to reading the path
# out of the raw JSON, and a silent regression there disables every skip below.
BAD="behavi""our"
payload() { printf '{"tool_input":{"file_path":"%s","content":"%s"}}' "$1" "$BAD"; }

run_hook "$(payload '/proj/lang/fr.php')"
assert_exit "lang/*.php skipped" 0

run_hook "$(payload '/proj/messages.po')"
assert_exit "gettext catalog skipped" 0

run_hook "$(payload '/proj/fr/Localizable.strings')"
assert_exit "apple strings catalog skipped" 0

run_hook "$(payload '/proj/en/Localizable.stringsdict')"
assert_exit "apple catalog skipped even under en (keys are identifiers)" 0

run_hook "$(payload 'C:\\proj\\locales\\fr\\messages.json')"
assert_exit "windows backslash path normalized" 0

run_hook "$(payload '/proj/locales/fr/messages.json')"
assert_exit "bare code inside locales/ skipped" 0

run_hook "$(payload '/proj/locales/en/messages.json')"
assert_exit "english locale still checked" 2

run_hook "$(payload '/proj/src/it/java/Foo.java')"
assert_exit "integration-test dir not mistaken for Italian" 2

run_hook "$(payload '/proj/fr-FR/app.json')"
assert_exit "region-suffixed locale dir skipped" 0

run_hook "$(payload '/proj/zh-Hant/app.json')"
assert_exit "script-suffixed locale dir skipped" 0

run_hook "$(payload '/proj/en-GB/app.json')"
assert_exit "en-GB still checked (it is English)" 2

run_hook "$(payload '/proj/sub-dir/app.json')"
assert_exit "hyphenated non-locale dir still checked" 2

run_hook "$(payload '/proj/fr.lproj/InfoPlist.title')"
assert_exit "lproj bundle skipped" 0

run_hook "$(payload '/proj/Base.lproj/InfoPlist.title')"
assert_exit "Base.lproj still checked" 2

run_hook "$(payload '/proj/res/values-fr/strings.xml')"
assert_exit "android locale qualifier skipped" 0

run_hook "$(payload '/proj/res/values-night/themes.xml')"
assert_exit "android night qualifier still checked" 2

run_hook "$(payload '/proj/docs/notes.md')"
assert_exit "ordinary file still checked" 2

echo ""
echo "================================="
echo "results: $passed passed, $failed failed"
[ "$failed" -gt 0 ] && exit 1
exit 0
