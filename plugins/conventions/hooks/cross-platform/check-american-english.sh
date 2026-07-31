#!/usr/bin/env bash
# Pre-write hook: blocks Write/Edit/MultiEdit/NotebookEdit calls whose new
# content contains British English spellings. The user's global convention is
# American English throughout — comments, docs, plan files, identifiers,
# everything.
#
# This is the Unix (Linux/macOS) counterpart of check-american-english.ps1.
# Both share ONE word map; keep them in sync. The repo build step extracts the
# map from the .ps1, so if you edit spellings, edit the .ps1 and regenerate, or
# edit both. On a match the hook exits 2 and writes a stderr message naming the
# offending words and their American equivalents; Claude sees it and fixes them.
#
# Wired in settings.json (user scope) under hooks.PreToolUse with matcher
# "Write|Edit|MultiEdit|NotebookEdit". To disable temporarily: run /hooks in
# Claude Code, or remove the entry from settings.json.
#
# JSON parsing: uses jq when available (precise -- only scans content fields).
# Falls back to scanning the raw stdin blob when jq is absent; British words in
# the escaped JSON still match, so the check degrades gracefully rather than
# failing open silently. Portable to bash 3.2 (macOS system bash) -- no
# associative arrays. Deliberately null-device-free (closes fd 2 with 2>&-
# rather than redirecting to the null device) to honor the no-null-redirect
# convention this repo also ships.

set -u

# British -> American map (single space separated, one pair per line).
# Generated from check-american-english.ps1 -- keep the two in sync.
WORDMAP=$(cat <<'MAP'
behaviour behavior
behaviours behaviors
behavioural behavioral
colour color
colours colors
coloured colored
colouring coloring
organise organize
organised organized
organises organizes
organising organizing
organisation organization
organisations organizations
organisational organizational
recognise recognize
recognised recognized
recognises recognizes
recognising recognizing
unrecognised unrecognized
localise localize
localised localized
localises localizes
localising localizing
localisation localization
normalise normalize
normalised normalized
normalises normalizes
normalising normalizing
normalisation normalization
sanitise sanitize
sanitised sanitized
sanitises sanitizes
sanitising sanitizing
sanitisation sanitization
customise customize
customised customized
customises customizes
customising customizing
customisation customization
prioritise prioritize
prioritised prioritized
prioritises prioritizes
prioritising prioritizing
prioritisation prioritization
finalise finalize
finalised finalized
finalises finalizes
finalising finalizing
optimise optimize
optimised optimized
optimises optimizes
optimising optimizing
optimisation optimization
emphasise emphasize
emphasised emphasized
emphasises emphasizes
emphasising emphasizing
parameterise parameterize
parameterised parameterized
parameterises parameterizes
parameterising parameterizing
parameterisation parameterization
parametrise parametrize
parametrised parametrized
parametrisation parametrization
specialise specialize
specialised specialized
specialises specializes
specialising specializing
standardise standardize
standardised standardized
standardises standardizes
standardising standardizing
standardisation standardization
generalise generalize
generalised generalized
generalises generalizes
generalising generalizing
generalisation generalization
memorise memorize
memorised memorized
memorises memorizes
memorising memorizing
capitalise capitalize
capitalised capitalized
capitalises capitalizes
capitalising capitalizing
capitalisation capitalization
materialise materialize
materialised materialized
materialises materializes
materialising materializing
categorise categorize
categorised categorized
categorises categorizes
categorising categorizing
categorisation categorization
tokenise tokenize
tokenised tokenized
tokenises tokenizes
tokenising tokenizing
serialise serialize
serialised serialized
serialises serializes
serialising serializing
serialisation serialization
initialise initialize
initialised initialized
initialises initializes
initialising initializing
initialisation initialization
authorise authorize
authorised authorized
authorises authorizes
authorising authorizing
authorisation authorization
analyse analyze
analysed analyzed
analyses analyzes
analysing analyzing
favour favor
favours favors
favoured favored
favouring favoring
favourite favorite
favourites favorites
honour honor
honours honors
honoured honored
honourable honorable
labour labor
labours labors
laboured labored
labouring laboring
neighbour neighbor
neighbours neighbors
neighbourhood neighborhood
harbour harbor
harbours harbors
valour valor
vapour vapor
rumour rumor
rumours rumors
odour odor
odours odors
tumour tumor
tumours tumors
saviour savior
endeavour endeavor
endeavours endeavors
endeavoured endeavored
flavour flavor
flavours flavors
flavoured flavored
centre center
centred centered
centring centering
centres centers
metre meter
metres meters
theatre theater
theatres theaters
fibre fiber
fibres fibers
sabre saber
sabres sabers
spectre specter
spectres specters
sombre somber
calibre caliber
calibres calibers
litre liter
litres liters
manoeuvre maneuver
manoeuvres maneuvers
manoeuvred maneuvered
manoeuvring maneuvering
travelled traveled
travelling traveling
traveller traveler
travellers travelers
labelled labeled
labelling labeling
modelled modeled
modelling modeling
signalled signaled
signalling signaling
cancelled canceled
cancelling canceling
fuelled fueled
fuelling fueling
enrolment enrollment
enrolments enrollments
fulfilment fulfillment
fulfilments fulfillments
grey gray
greys grays
greyed grayed
aluminium aluminum
programme program
programmes programs
practise practice
practised practiced
practising practicing
whilst while
amongst among
aeon eon
aeons eons
defence defense
defences defenses
licence license
licences licenses
offence offense
offences offenses
pretence pretense
pretences pretenses
cheque check
cheques checks
tyre tire
tyres tires
kerb curb
kerbs curbs
plough plow
ploughs plows
sceptic skeptic
sceptics skeptics
sceptical skeptical
mould mold
moulds molds
moulded molded
moulding molding
moustache mustache
moustaches mustaches
jewellery jewelry
catalogue catalog
catalogues catalogs
dialogue dialog
dialogues dialogs
analogue analog
analogues analogs
monologue monolog
monologues monologs
draught draft
draughts drafts
sulphur sulfur
sulphate sulfate
sulphates sulfates
MAP
)

# --- read tool-call JSON from stdin -----------------------------------------
raw=$(cat)
[ -z "${raw//[$' \t\n\r']/}" ] && exit 0

# Detect jq once (no null-device redirect); reused for the target path below
# and the prose fields further down.
jqbin=$(command -v jq || true)

# --- locate the file the tool is about to write -----------------------------
# jq is precise, but it is absent often enough to matter (notably Git Bash on
# Windows), and with no path every skip rule below silently stops applying --
# the failure is invisible, so it went unnoticed. Fall back to lifting the
# first file_path/notebook_path out of the raw JSON by hand, then undo JSON's
# backslash escaping and normalize separators so a Windows path compares the
# same as a POSIX one. (A path containing an escaped quote survives imperfectly;
# no real project has one.)
fp=""
if [ -n "$jqbin" ]; then
  fp=$("$jqbin" -r '.tool_input.file_path? // .tool_input.notebook_path? // empty' <<<"$raw" 2>&-)
fi
if [ -z "$fp" ]; then
  fp=$(printf '%s' "$raw" \
       | grep -oE '"(file_path|notebook_path)"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
       | head -n 1 \
       | sed -E 's/^"[a-z_]+"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi
fp=$(printf '%s' "$fp" | sed -e 's/\\\\/\\/g' -e 's#\\#/#g')

# --- skip files that never hold the author's English prose ------------------
# By convention English source text is embedded in code (via __()), never in a
# lang(s)/*.php file -- those always hold translations. Likewise .po/.pot/.xlf/
# .xliff and Apple's .strings/.stringsdict/.xcstrings are translation-only
# formats. Foreign words in such files routinely collide with the word map, so
# skip them outright.
#
# Apple's catalogs are skipped for every locale, English included, because their
# KEYS are identifiers the author cannot rename: a key naming an operation that
# was stopped, or a settings catalog, matches the map whatever language the
# values are written in. Same trade-off .po already makes by carrying English
# msgids.
case "$fp" in
  */lang/*.php|*/langs/*.php) exit 0 ;;
  *.po|*.pot|*.xlf|*.xliff) exit 0 ;;
  *.strings|*.stringsdict|*.xcstrings) exit 0 ;;
esac

# --- skip translations identified by their locale directory -----------------
# Translation formats no list can enumerate (JSON, YAML, XML, Markdown) are
# still recognizable by where they sit. Only unambiguous directory shapes count.
#
# A bare two-letter name is deliberately NOT enough on its own: many ISO 639-1
# codes double as everyday directory names -- integration tests, shell scripts,
# shared objects, TypeScript, C#, Perl and machine learning all collide with a
# real language code. And the two errors are not symmetrical: a wrong skip fails
# silently forever, while a wrong block is loud and self-correcting. So a bare
# code counts only inside a known i18n container.
is_locale_dir() (
  LC_ALL=C
  dir=$1
  parent=$2

  # Apple bundles: fr.lproj, zh-Hans.lproj. English and Base stay checked.
  case "$dir" in
    en.lproj|en-*.lproj|en_*.lproj|Base.lproj|base.lproj) return 1 ;;
    *.lproj) return 0 ;;
  esac

  # Region- or script-suffixed: fr-FR, pt_BR, es-419, zh-Hant. Case matters --
  # an uppercase region is what separates a locale from a name like sub-dir.
  case "$dir" in
    en-*|en_*) return 1 ;;
    [a-z][a-z][-_][A-Z][A-Z]|[a-z][a-z][a-z][-_][A-Z][A-Z]) return 0 ;;
    [a-z][a-z][-_][0-9][0-9][0-9]|[a-z][a-z][a-z][-_][0-9][0-9][0-9]) return 0 ;;
    [a-z][a-z][-_][A-Z][a-z][a-z][a-z]|[a-z][a-z][a-z][-_][A-Z][a-z][a-z][a-z]) return 0 ;;
  esac

  # Android resource qualifiers: values-fr, values-pt-rBR. Density, night and
  # version qualifiers (values-hdpi, values-night, values-v21) do not match.
  case "$dir" in
    values-en|values-en-r[A-Z][A-Z]) return 1 ;;
    values-[a-z][a-z]|values-[a-z][a-z][a-z]) return 0 ;;
    values-[a-z][a-z]-r[A-Z][A-Z]|values-[a-z][a-z][a-z]-r[A-Z][A-Z]) return 0 ;;
  esac

  # Bare code, honored only directly inside a recognized i18n container.
  case "$parent" in
    locale|locales|_locales|lang|langs|i18n|intl|translation|translations)
      case "$dir" in
        en) return 1 ;;
        [a-z][a-z]|[a-z][a-z][a-z]) return 0 ;;
      esac
      ;;
  esac

  return 1
)

case "$fp" in
  */*)
    fpdir=${fp%/*}
    fpparent=${fpdir%/*}
    if is_locale_dir "${fpdir##*/}" "${fpparent##*/}"; then
      exit 0
    fi
    ;;
esac

# --- collect the prose the tool is about to write ---------------------------
if [ -n "$jqbin" ]; then
  text=$("$jqbin" -r '
    [ .tool_input.content?,
      .tool_input.new_string?,
      .tool_input.new_source?,
      (.tool_input.edits[]?.new_string?)
    ] | map(select(. != null)) | join("\n")
  ' <<<"$raw" 2>&-)
  # If jq failed to parse, fall back to the raw blob rather than skipping.
  [ -z "$text" ] && text="$raw"
else
  text="$raw"
fi

[ -z "${text//[$' \t\n\r']/}" ] && exit 0

# --- skip non-English HTML documents ----------------------------------------
# A document declaring <html lang="fr"> (or any non-en code) is not the user's
# English prose. A missing or en* lang attribute leaves the check in force.
htmllang=$(printf '%s' "$text" \
  | grep -oiE '<html[^>]*\blang[[:space:]]*=[[:space:]]*["'"'"'][a-z]+([_-][a-z0-9]+)?' 2>&- \
  | head -n 1 \
  | sed -E 's/.*["'"'"']//' \
  | tr '[:upper:]' '[:lower:]')
case "$htmllang" in
  ''|en|en-*|en_*) : ;;
  *) exit 0 ;;
esac

# --- build alternation of British words, find matches -----------------------
british=$(printf '%s\n' "$WORDMAP" | awk 'NF{print $1}')
alternation=$(printf '%s' "$british" | paste -sd '|' -)
[ -z "$alternation" ] && exit 0

# -o only-matching, -i case-insensitive, -w word-boundary, -E extended regex.
hits=$(printf '%s' "$text" | grep -oiwE "$alternation" 2>&- \
       | tr '[:upper:]' '[:lower:]' | sort -u)
[ -z "$hits" ] && exit 0

# --- report on stderr, exit 2 ----------------------------------------------
{
  echo "American-English convention violated. The content about to be written contains British spellings that need replacement first:"
  echo
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    american=$(printf '%s\n' "$WORDMAP" | awk -v w="$hit" '$1==w{print $2; exit}')
    [ -z "$american" ] && american="<american equivalent>"
    echo "  - $hit -> $american"
  done <<EOF
$hits
EOF
  echo
  echo "Convention: American English everywhere (see this repo's CLAUDE.md or your global convention)."
  echo "Replace the words listed above with their American forms and retry the operation."
} >&2
exit 2
