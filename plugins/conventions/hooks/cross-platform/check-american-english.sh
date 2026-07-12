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

# --- skip files that never hold the user's English prose --------------------
# By convention English source text is embedded in code (via __()), never in a
# lang(s)/*.php file -- those always hold translations. Likewise .po/.pot/.xlf/
# .xliff are translation-only formats with no English variant. Foreign words in
# such files routinely collide with British spellings, so skip them outright.
fp=""
if [ -n "$jqbin" ]; then
  fp=$("$jqbin" -r '.tool_input.file_path? // .tool_input.notebook_path? // empty' <<<"$raw" 2>&-)
fi

case "$fp" in
  */lang/*.php|*/langs/*.php) exit 0 ;;
  *.po|*.pot|*.xlf|*.xliff) exit 0 ;;
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
