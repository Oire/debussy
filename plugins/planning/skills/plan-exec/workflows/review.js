export const meta = {
  name: 'plan-exec-review',
  description: 'Review the branch diff through parallel lenses, verify each finding adversarially, fix what survives, repeat on critical issues',
  whenToUse: 'Run by the plan-exec skill after all plan tasks are done. Treat it as a template: the skill passes the prompts, lenses, and round limit as args.',
  phases: [
    { title: 'Review', detail: 'one read-only reviewer per lens' },
    { title: 'Verify', detail: 'one skeptic per file tries to refute its findings' },
    { title: 'Fix', detail: 'one fixer applies confirmed findings, validates, commits' },
  ],
}

// args, all prompt text already resolved through the override chain and with
// PLAN_FILE_PATH, PROGRESS_FILE_PATH, DEFAULT_BRANCH, GIT_MODE, SKILL_SCRIPTS
// substituted by the skill:
//   preamble      shared reviewer instructions (prompts/reviewer.md)
//   lenses        [{ name, prompt }] from agents/*.txt
//   criticalNote  extra instruction for re-check rounds
//   criticalLenses lens names used on re-check rounds
//   verifier      prompts/verifier.md, with a FINDINGS placeholder
//   fixer         prompts/fixer.md, with a FINDINGS_LIST placeholder
//   maxRounds     review-fix rounds before giving up (default 3)
//   startCritical true to skip the full sweep and run re-check rounds only

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['critical', 'major', 'minor'] },
          title: { type: 'string' },
          detail: { type: 'string' },
          fix: { type: 'string' },
        },
        required: ['file', 'severity', 'title', 'detail'],
      },
    },
  },
  required: ['findings'],
}

const VERDICTS = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string', enum: ['confirmed', 'refuted'] },
          reason: { type: 'string' },
        },
        required: ['id', 'verdict', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

const FIXES = {
  type: 'object',
  properties: {
    fixes: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          status: { type: 'string', enum: ['fixed', 'not-fixed'] },
          change: { type: 'string' },
        },
        required: ['id', 'status', 'change'],
      },
    },
    validation: { type: 'string' },
    commit: { type: 'string' },
  },
  required: ['fixes', 'validation'],
}

const maxRounds = args.maxRounds || 3
const key = f => `${f.file}:${f.line || 0}:${f.title.toLowerCase()}`
const refutedKeys = new Set()
const rounds = []
let clean = false

for (let round = 1; round <= maxRounds; round++) {
  const critical = args.startCritical || round > 1
  const lenses = critical
    ? args.lenses.filter(l => args.criticalLenses.includes(l.name))
    : args.lenses
  const kind = critical ? 'critical re-check' : 'full sweep'
  log(`Round ${round}: ${kind} with ${lenses.map(l => l.name).join(', ')}`)

  const reports = await parallel(lenses.map(l => () =>
    agent(
      [args.preamble, critical ? args.criticalNote : '', l.prompt].filter(Boolean).join('\n\n'),
      { label: `review:${l.name}`, phase: 'Review', schema: FINDINGS },
    ).then(r => r && r.findings.map(f => ({ ...f, lens: l.name })))))

  // Barrier: dedupe across every lens before paying for verification.
  const byKey = new Map()
  for (const f of reports.filter(Boolean).flat()) {
    const k = key(f)
    if (refutedKeys.has(k)) continue
    if (byKey.has(k)) byKey.get(k).lens += `, ${f.lens}`
    else byKey.set(k, f)
  }
  const found = [...byKey.values()].map((f, i) => ({ ...f, id: `R${round}-${i + 1}` }))
  if (found.length === 0) {
    log(`Round ${round}: no findings`)
    rounds.push({ round, kind, found: [], confirmed: [], refuted: [], fixes: [] })
    clean = true
    break
  }

  // One skeptic per file, so each reads the file once and judges its findings together.
  const byFile = new Map()
  for (const f of found) {
    if (!byFile.has(f.file)) byFile.set(f.file, [])
    byFile.get(f.file).push(f)
  }
  const verdictSets = await parallel([...byFile.entries()].map(([file, fs]) => () =>
    agent(
      args.verifier.split('FINDINGS').join(JSON.stringify(fs, null, 2)),
      { label: `verify:${file}`, phase: 'Verify', schema: VERDICTS },
    )))
  const verdicts = new Map()
  for (const set of verdictSets.filter(Boolean)) {
    for (const v of set.verdicts) verdicts.set(v.id, v)
  }
  // A finding whose skeptic died unanswered goes to the fixer, who checks it again.
  const confirmed = found.filter(f => (verdicts.get(f.id) || { verdict: 'confirmed' }).verdict === 'confirmed')
  const refuted = found
    .filter(f => !confirmed.includes(f))
    .map(f => ({ ...f, reason: verdicts.get(f.id).reason }))
  refuted.forEach(f => refutedKeys.add(key(f)))
  log(`Round ${round}: ${found.length} found, ${confirmed.length} confirmed, ${refuted.length} refuted`)

  if (confirmed.length === 0) {
    rounds.push({ round, kind, found, confirmed, refuted, fixes: [] })
    clean = true
    break
  }

  const fix = await agent(
    args.fixer.split('FINDINGS_LIST').join(JSON.stringify(confirmed, null, 2)),
    { label: `fix:round-${round}`, phase: 'Fix', schema: FIXES },
  )
  rounds.push({ round, kind, found, confirmed, refuted, fixes: fix ? fix.fixes : [], validation: fix && fix.validation, commit: fix && fix.commit })
  if (!fix) {
    log(`Round ${round}: the fixer did not return; stopping`)
    break
  }
}

if (!clean) log(`Stopped after ${rounds.length} round(s); the last round's fixes have not been re-reviewed`)
return { clean, rounds }
