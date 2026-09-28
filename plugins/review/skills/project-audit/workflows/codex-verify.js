export const meta = {
  name: 'project-audit-codex-verify',
  description: 'Have a skeptic per file try to refute each Codex finding against the code before triage',
  whenToUse: 'Run by the project-audit skill after a Codex review that reported findings. The skill parses them and passes them with the skeptic prompt as args.',
  phases: [
    { title: 'Verify', detail: 'one skeptic per file checks its findings' },
  ],
}

// args, prompt text resolved by the skill:
//   skeptic   prompts/codex-skeptic.md, with a FINDINGS placeholder
//   findings  [{ id, file, line, severity, description }] parsed from Codex's
//             output; file is empty for a finding Codex gave no location

const SEVERITIES = ['critical', 'major', 'minor']

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

// One skeptic per file, so each reads the file once and judges its findings together.
const byFile = new Map()
for (const f of args.findings) {
  const file = f.file || '(no location)'
  if (!byFile.has(file)) byFile.set(file, [])
  byFile.get(file).push(f)
}
const sets = await parallel([...byFile.entries()].map(([file, fs]) => () =>
  agent(
    args.skeptic.split('FINDINGS').join(JSON.stringify(fs, null, 2)),
    { label: `verify:${file}`, phase: 'Verify', schema: VERDICTS },
  )))

const verdicts = new Map()
const unchecked = []
;[...byFile.keys()].forEach((file, i) => {
  if (!sets[i]) unchecked.push(file)
  else for (const v of sets[i].verdicts) verdicts.set(v.id, v)
})
if (unchecked.length) log(`No verdict for ${unchecked.join(', ')}; those findings stay suspected`)

// A finding nobody could check is suspected, never confirmed.
const confirmed = [], suspected = [], refuted = []
for (const f of args.findings) {
  const v = verdicts.get(f.id)
  const out = { ...f, status: v ? v.verdict : 'suspected', verifierNote: v ? v.reason : 'not checked: no verdict came back' }
  if (out.status === 'refuted') refuted.push(out)
  else if (out.status === 'confirmed') confirmed.push(out)
  else suspected.push(out)
}
log(`${confirmed.length} confirmed, ${suspected.length} suspected, ${refuted.length} refuted`)

const bySeverity = (a, b) => SEVERITIES.indexOf(a.severity) - SEVERITIES.indexOf(b.severity)
return {
  confirmed: confirmed.sort(bySeverity),
  suspected: suspected.sort(bySeverity),
  refuted,
}
