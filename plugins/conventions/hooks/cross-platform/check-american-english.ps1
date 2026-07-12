# Pre-write hook: blocks Write/Edit/MultiEdit/NotebookEdit calls whose new
# content contains British English spellings. The user's global convention
# (this repo's CLAUDE.md, also installed as a user-global rule) is American
# English throughout — comments, docs, plan files, identifiers, everything.
#
# This hook converts the rule from "Claude has to remember" into "the harness
# enforces it." On a match it exits with code 2 and writes a stderr message
# naming the offending words and their American equivalents; Claude sees the
# message and is expected to fix the words and retry.
#
# Installed user-globally — fires in every project on this machine.
# To audit / edit:
#   - This file: ~/.claude/hooks/cross-platform/check-american-english.ps1
#   - The British → American word map is inline below (single source of
#     truth). Add or remove entries by editing the $wordMap hashtable.
#   - The hook is wired in ~/.claude/settings.json (user scope) under
#     hooks.PreToolUse with matcher "Write|Edit|MultiEdit|NotebookEdit".
# To disable temporarily: run /hooks in Claude Code, or comment out / remove
# the entry from ~/.claude/settings.json.
#
# Implementation note: PowerShell instead of bash because Git Bash on this
# machine has no jq. PowerShell ships native JSON parsing and is fine for
# a Windows-only project. Forced -NonInteractive via Claude's hook runner.

$ErrorActionPreference = 'Stop'

# Explicit British → American map. Word-boundary, case-insensitive matching.
# Prefer adding common forms (singular + plural + -ed + -ing) when adding a
# new entry — the matcher uses exact words, not stems, on purpose to avoid
# false positives (raise, surprise, exercise etc. all LOOK British-ending
# but are correct in both dialects).
$wordMap = [ordered]@{
    'behaviour'        = 'behavior'
    'behaviours'       = 'behaviors'
    'behavioural'      = 'behavioral'
    'colour'           = 'color'
    'colours'          = 'colors'
    'coloured'         = 'colored'
    'colouring'        = 'coloring'
    'organise'         = 'organize'
    'organised'        = 'organized'
    'organises'        = 'organizes'
    'organising'       = 'organizing'
    'organisation'     = 'organization'
    'organisations'    = 'organizations'
    'organisational'   = 'organizational'
    'recognise'        = 'recognize'
    'recognised'       = 'recognized'
    'recognises'       = 'recognizes'
    'recognising'      = 'recognizing'
    'unrecognised'     = 'unrecognized'
    'localise'         = 'localize'
    'localised'        = 'localized'
    'localises'        = 'localizes'
    'localising'       = 'localizing'
    'localisation'     = 'localization'
    'normalise'        = 'normalize'
    'normalised'       = 'normalized'
    'normalises'       = 'normalizes'
    'normalising'      = 'normalizing'
    'normalisation'    = 'normalization'
    'sanitise'         = 'sanitize'
    'sanitised'        = 'sanitized'
    'sanitises'        = 'sanitizes'
    'sanitising'       = 'sanitizing'
    'sanitisation'     = 'sanitization'
    'customise'        = 'customize'
    'customised'       = 'customized'
    'customises'       = 'customizes'
    'customising'      = 'customizing'
    'customisation'    = 'customization'
    'prioritise'       = 'prioritize'
    'prioritised'      = 'prioritized'
    'prioritises'      = 'prioritizes'
    'prioritising'     = 'prioritizing'
    'prioritisation'   = 'prioritization'
    'finalise'         = 'finalize'
    'finalised'        = 'finalized'
    'finalises'        = 'finalizes'
    'finalising'       = 'finalizing'
    'optimise'         = 'optimize'
    'optimised'        = 'optimized'
    'optimises'        = 'optimizes'
    'optimising'       = 'optimizing'
    'optimisation'     = 'optimization'
    'emphasise'        = 'emphasize'
    'emphasised'       = 'emphasized'
    'emphasises'       = 'emphasizes'
    'emphasising'      = 'emphasizing'
    'parameterise'     = 'parameterize'
    'parameterised'    = 'parameterized'
    'parameterises'    = 'parameterizes'
    'parameterising'   = 'parameterizing'
    'parameterisation' = 'parameterization'
    'parametrise'      = 'parametrize'
    'parametrised'     = 'parametrized'
    'parametrisation'  = 'parametrization'
    'specialise'       = 'specialize'
    'specialised'      = 'specialized'
    'specialises'      = 'specializes'
    'specialising'     = 'specializing'
    'standardise'      = 'standardize'
    'standardised'     = 'standardized'
    'standardises'     = 'standardizes'
    'standardising'    = 'standardizing'
    'standardisation'  = 'standardization'
    'generalise'       = 'generalize'
    'generalised'      = 'generalized'
    'generalises'      = 'generalizes'
    'generalising'     = 'generalizing'
    'generalisation'   = 'generalization'
    'memorise'         = 'memorize'
    'memorised'        = 'memorized'
    'memorises'        = 'memorizes'
    'memorising'       = 'memorizing'
    'capitalise'       = 'capitalize'
    'capitalised'      = 'capitalized'
    'capitalises'      = 'capitalizes'
    'capitalising'     = 'capitalizing'
    'capitalisation'   = 'capitalization'
    'materialise'      = 'materialize'
    'materialised'     = 'materialized'
    'materialises'     = 'materializes'
    'materialising'    = 'materializing'
    'categorise'       = 'categorize'
    'categorised'      = 'categorized'
    'categorises'      = 'categorizes'
    'categorising'     = 'categorizing'
    'categorisation'   = 'categorization'
    'tokenise'         = 'tokenize'
    'tokenised'        = 'tokenized'
    'tokenises'        = 'tokenizes'
    'tokenising'       = 'tokenizing'
    'serialise'        = 'serialize'
    'serialised'       = 'serialized'
    'serialises'       = 'serializes'
    'serialising'      = 'serializing'
    'serialisation'    = 'serialization'
    'initialise'       = 'initialize'
    'initialised'      = 'initialized'
    'initialises'      = 'initializes'
    'initialising'     = 'initializing'
    'initialisation'   = 'initialization'
    'authorise'        = 'authorize'
    'authorised'       = 'authorized'
    'authorises'       = 'authorizes'
    'authorising'      = 'authorizing'
    'authorisation'    = 'authorization'
    'analyse'          = 'analyze'
    'analysed'         = 'analyzed'
    'analyses'         = 'analyzes'
    'analysing'        = 'analyzing'
    'favour'           = 'favor'
    'favours'          = 'favors'
    'favoured'         = 'favored'
    'favouring'        = 'favoring'
    'favourite'        = 'favorite'
    'favourites'       = 'favorites'
    'honour'           = 'honor'
    'honours'          = 'honors'
    'honoured'         = 'honored'
    'honourable'       = 'honorable'
    'labour'           = 'labor'
    'labours'          = 'labors'
    'laboured'         = 'labored'
    'labouring'        = 'laboring'
    'neighbour'        = 'neighbor'
    'neighbours'       = 'neighbors'
    'neighbourhood'    = 'neighborhood'
    'harbour'          = 'harbor'
    'harbours'         = 'harbors'
    'valour'           = 'valor'
    'vapour'           = 'vapor'
    'rumour'           = 'rumor'
    'rumours'          = 'rumors'
    'odour'            = 'odor'
    'odours'           = 'odors'
    'tumour'           = 'tumor'
    'tumours'          = 'tumors'
    'saviour'          = 'savior'
    'endeavour'        = 'endeavor'
    'endeavours'       = 'endeavors'
    'endeavoured'      = 'endeavored'
    'flavour'          = 'flavor'
    'flavours'         = 'flavors'
    'flavoured'        = 'flavored'
    'centre'           = 'center'
    'centred'          = 'centered'
    'centring'         = 'centering'
    'centres'          = 'centers'
    'metre'            = 'meter'
    'metres'           = 'meters'
    'theatre'          = 'theater'
    'theatres'         = 'theaters'
    'fibre'            = 'fiber'
    'fibres'           = 'fibers'
    'sabre'            = 'saber'
    'sabres'           = 'sabers'
    'spectre'          = 'specter'
    'spectres'         = 'specters'
    'sombre'           = 'somber'
    'calibre'          = 'caliber'
    'calibres'         = 'calibers'
    'litre'            = 'liter'
    'litres'           = 'liters'
    'manoeuvre'        = 'maneuver'
    'manoeuvres'       = 'maneuvers'
    'manoeuvred'       = 'maneuvered'
    'manoeuvring'      = 'maneuvering'
    'travelled'        = 'traveled'
    'travelling'       = 'traveling'
    'traveller'        = 'traveler'
    'travellers'       = 'travelers'
    'labelled'         = 'labeled'
    'labelling'        = 'labeling'
    'modelled'         = 'modeled'
    'modelling'        = 'modeling'
    'signalled'        = 'signaled'
    'signalling'       = 'signaling'
    'cancelled'        = 'canceled'
    'cancelling'       = 'canceling'
    'fuelled'          = 'fueled'
    'fuelling'         = 'fueling'
    'enrolment'        = 'enrollment'
    'enrolments'       = 'enrollments'
    'fulfilment'       = 'fulfillment'
    'fulfilments'      = 'fulfillments'
    'grey'             = 'gray'
    'greys'            = 'grays'
    'greyed'           = 'grayed'
    'aluminium'        = 'aluminum'
    'programme'        = 'program'
    'programmes'       = 'programs'
    'practise'         = 'practice'
    'practised'        = 'practiced'
    'practising'       = 'practicing'
    'whilst'           = 'while'
    'amongst'          = 'among'
    'aeon'             = 'eon'
    'aeons'            = 'eons'
    'defence'          = 'defense'
    'defences'         = 'defenses'
    'licence'          = 'license'
    'licences'         = 'licenses'
    'offence'          = 'offense'
    'offences'         = 'offenses'
    'pretence'         = 'pretense'
    'pretences'        = 'pretenses'
    'cheque'           = 'check'
    'cheques'          = 'checks'
    'tyre'             = 'tire'
    'tyres'            = 'tires'
    'kerb'             = 'curb'
    'kerbs'            = 'curbs'
    'plough'           = 'plow'
    'ploughs'          = 'plows'
    'sceptic'          = 'skeptic'
    'sceptics'         = 'skeptics'
    'sceptical'        = 'skeptical'
    'mould'            = 'mold'
    'moulds'           = 'molds'
    'moulded'          = 'molded'
    'moulding'         = 'molding'
    'moustache'        = 'mustache'
    'moustaches'       = 'mustaches'
    'jewellery'        = 'jewelry'
    'catalogue'        = 'catalog'
    'catalogues'       = 'catalogs'
    'dialogue'         = 'dialog'
    'dialogues'        = 'dialogs'
    'analogue'         = 'analog'
    'analogues'        = 'analogs'
    'monologue'        = 'monolog'
    'monologues'       = 'monologs'
    'draught'          = 'draft'
    'draughts'         = 'drafts'
    'sulphur'          = 'sulfur'
    'sulphate'         = 'sulfate'
    'sulphates'        = 'sulfates'
}

# Read tool-call JSON from stdin
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
} catch {
    # Malformed JSON shouldn't block edits; let the operation through.
    exit 0
}

# Skip files that never hold the user's English prose (mirrors the .sh
# counterpart). By convention English source text is embedded in code, never in
# a lang(s)/*.php file -- those always hold translations. Likewise .po/.pot/
# .xlf/.xliff are translation-only formats. Foreign words in such files
# routinely collide with British spellings, so skip them outright.
$targetPath = $null
if ($null -ne $payload.tool_input) {
    if ($payload.tool_input.file_path) {
        $targetPath = [string]$payload.tool_input.file_path
    } elseif ($payload.tool_input.notebook_path) {
        $targetPath = [string]$payload.tool_input.notebook_path
    }
}
if ($targetPath) {
    $normalizedPath = $targetPath -replace '\\', '/'
    if ($normalizedPath -match '/langs?/.+\.php$' -or $normalizedPath -match '\.(po|pot|xlf|xliff)$') {
        exit 0
    }
}

# Collect the prose the tool is about to write. Each tool puts content in a
# different place; we glob them all together and scan as a single blob.
#   Write          → tool_input.content
#   Edit           → tool_input.new_string
#   MultiEdit      → tool_input.edits[].new_string
#   NotebookEdit   → tool_input.new_source
$parts = New-Object System.Collections.Generic.List[string]
$toolInput = $payload.tool_input
if ($null -ne $toolInput) {
    foreach ($field in @('content', 'new_string', 'new_source')) {
        $value = $toolInput.$field
        if ($null -ne $value -and -not [string]::IsNullOrEmpty([string]$value)) {
            $parts.Add([string]$value)
        }
    }
    if ($null -ne $toolInput.edits) {
        foreach ($edit in $toolInput.edits) {
            if ($null -ne $edit.new_string -and -not [string]::IsNullOrEmpty([string]$edit.new_string)) {
                $parts.Add([string]$edit.new_string)
            }
        }
    }
}

if ($parts.Count -eq 0) {
    exit 0
}

$newText = [string]::Join("`n", $parts)

# Skip non-English HTML documents (root <html lang="xx"> where xx is not en).
# A missing or en* lang attribute leaves the check in force.
$htmlLangPattern = '<html[^>]*\blang\s*=\s*["' + [char]39 + ']([a-z]+(?:[-_][a-z0-9]+)?)'
$htmlLangMatch = [Regex]::Match($newText, $htmlLangPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($htmlLangMatch.Success) {
    $htmlLang = $htmlLangMatch.Groups[1].Value.ToLowerInvariant()
    if ($htmlLang -ne 'en' -and -not $htmlLang.StartsWith('en-') -and -not $htmlLang.StartsWith('en_')) {
        exit 0
    }
}

# Build a single word-boundary alternation regex from the map's keys, then
# extract distinct matches preserving case-insensitivity.
$britishWords = @($wordMap.Keys)
$alternation = ($britishWords | ForEach-Object { [Regex]::Escape($_) }) -join '|'
$pattern = "\b($alternation)\b"
$regex = [Regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$matchResults = $regex.Matches($newText)
if ($matchResults.Count -eq 0) {
    exit 0
}

# De-duplicate (case-folded) so each offending word is reported once even
# when it appears many times.
$hits = $matchResults | ForEach-Object { $_.Value.ToLowerInvariant() } | Sort-Object -Unique

# Print the rejection message on stderr — that's the stream Claude sees on
# a code-2 exit.
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("American-English convention violated. The content about to be written contains British spellings that need replacement first:")
$lines.Add("")
foreach ($hit in $hits) {
    if ($wordMap.Contains($hit)) {
        $american = $wordMap[$hit]
    } else {
        $american = "<american equivalent>"
    }
    $lines.Add("  - $hit -> $american")
}
$lines.Add("")
$lines.Add("Convention: American English everywhere (comments, docs, identifiers).")
$lines.Add("Replace the words listed above with their American forms and retry the operation.")

[Console]::Error.WriteLine([string]::Join("`n", $lines))
exit 2
