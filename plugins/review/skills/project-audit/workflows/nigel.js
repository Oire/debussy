export const meta = {
  name: 'project-audit-nigel',
  description: 'Fan Nigel out over four focus groups, then have a skeptic per group try to refute each finding against the files',
  whenToUse: 'Run by the project-audit skill for its Nigel phase. Treat it as a template: the skill passes the prompts and focus groups as args.',
  phases: [
    { title: 'Audit', detail: 'one Nigel per focus group' },
    { title: 'Verify', detail: 'one skeptic per group checks its findings' },
  ],
}

// args, prompt text resolved by the skill:
//   nigel    prompts/nigel-focus.md, with a FOCUS placeholder
//   skeptic  prompts/nigel-skeptic.md, with FOCUS and FINDINGS placeholders
//   groups   optional [{ name, focus }] to replace the default four

const GROUPS = args.groups || [
  { name: 'code', focus: 'code quality and consistency, API design and developer experience' },
  { name: 'a11y', focus: 'accessibility (WCAG 2.2 AA, desktop automation and mnemonics) and visual design and polish' },
  { name: 'docs', focus: 'developer and end-user documentation, project structure and packaging, CI/CD' },
  { name: 'safety', focus: 'testing quality, security and robustness, performance' },
]

const SEVERITIES = ['critical', 'serious', 'moderate', 'nitpick', 'suggestion']

const FINDINGS = {
  type: 'object',
  properties: {
    stack: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          severity: { type: 'string', enum: SEVERITIES },
          what: { type: 'string' },
          where: { type: 'string' },
          evidence: { type: 'string' },
          status: { type: 'string', enum: ['confirmed', 'suspected'] },
          why: { type: 'string' },
          fix: { type: 'string' },
        },
        required: ['severity', 'what', 'where', 'evidence', 'status', 'fix'],
      },
    },
    coverage: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          area: { type: 'string' },
          item: { type: 'string' },
          verdict: { type: 'string', enum: ['fails', 'passes', 'not-applicable', 'not-tested'] },
          note: { type: 'string' },
        },
        required: ['area', 'item', 'verdict'],
      },
    },
  },
  required: ['findings', 'coverage'],
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
          verdict: { type: 'string', enum: ['confirmed', 'suspected', 'refuted'] },
          reason: { type: 'string' },
        },
        required: ['id', 'verdict', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

const results = await pipeline(
  GROUPS,
  g => agent(args.nigel.split('FOCUS').join(g.focus), {
    label: `nigel:${g.name}`, phase: 'Audit', agentType: 'review:project-analyst', schema: FINDINGS,
  }),
  (report, g) => {
    if (!report) return null
    const findings = report.findings.map((f, i) => ({ ...f, group: g.name, id: `${g.name}-${i + 1}` }))
    // Suggestions are ideas, not claims about the code; there is nothing to refute.
    const claims = findings.filter(f => f.severity !== 'suggestion')
    const coverage = (report.coverage || []).map(c => ({ ...c, group: g.name }))
    if (claims.length === 0) return { findings, coverage, verdicts: [] }
    return agent(
      args.skeptic.split('FOCUS').join(g.focus).split('FINDINGS').join(JSON.stringify(claims, null, 2)),
      { label: `verify:${g.name}`, phase: 'Verify', schema: VERDICTS },
    ).then(v => ({ findings, coverage, verdicts: v ? v.verdicts : null }))
  },
)

const confirmed = [], suspected = [], refuted = [], coverage = [], failedGroups = []
results.forEach((r, i) => {
  if (!r) {
    failedGroups.push(GROUPS[i].name)
    return
  }
  coverage.push(...r.coverage)
  if (r.verdicts === null) log(`${GROUPS[i].name}: the skeptic did not return; keeping Nigel's own status`)
  const verdicts = new Map((r.verdicts || []).map(v => [v.id, v]))
  for (const f of r.findings) {
    const v = verdicts.get(f.id)
    const status = v ? v.verdict : f.status
    const out = v ? { ...f, status, verifierNote: v.reason } : f
    if (status === 'refuted') refuted.push(out)
    else if (status === 'confirmed') confirmed.push(out)
    else suspected.push(out)
  }
})
if (failedGroups.length) log(`No report from: ${failedGroups.join(', ')} — those areas were not covered`)
log(`${confirmed.length} confirmed, ${suspected.length} suspected, ${refuted.length} refuted`)
const untested = coverage.filter(c => c.verdict === 'not-tested')
if (untested.length) log(`${untested.length} coverage item(s) not tested`)

const bySeverity = (a, b) => SEVERITIES.indexOf(a.severity) - SEVERITIES.indexOf(b.severity)
return {
  confirmed: confirmed.sort(bySeverity),
  suspected: suspected.sort(bySeverity),
  refuted,
  coverage,
  failedGroups,
}
