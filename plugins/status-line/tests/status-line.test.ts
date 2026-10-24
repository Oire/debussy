import { expect, test } from 'claude-code/testing'
import { modelName } from '../hooks/status-line'

const FIVE_HOUR = { kind: 'five_hour', percentUsed: 12.4 }
const SEVEN_DAY = { kind: 'seven_day', percentUsed: 30.5 }

test('model ids read as their family and version', () => {
  expect(modelName('claude-opus-5-5')).toBe('Opus 5.5')
  expect(modelName('claude-fable-5-1[1m]')).toBe('Fable 5.1')
  expect(modelName('claude-sonnet-4-5-20250929')).toBe('Sonnet 4.5')
  expect(modelName('claude-opus-4-20250514')).toBe('Opus 4')
  expect(modelName('us.anthropic.claude-haiku-4-5-20251001-v1:0')).toBe('Haiku 4.5')
  expect(modelName('claude-3-5-sonnet-20241022')).toBe('Sonnet 3.5')
  expect(modelName('some-other-model')).toBe('some-other-model')
})

test('a fresh session shows the model alone', async ($, on) => {
  const shown: (string | undefined)[] = []
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('session.usage', () => ({
    value: { startedAt: 0, context: { window: 1000000 }, rateLimits: [] },
  }))
  on('ui.status', (_, e) => (shown.push(e.text), { value: undefined }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  expect(shown.at(-1)).toBe('Opus 5.5.')
})

test('a measurement shows context and both rate limits, rounded', async ($, on) => {
  const shown: (string | undefined)[] = []
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      context: { window: 1000000, tokens: 42000, percent: 4 },
      rateLimits: [SEVEN_DAY, FIVE_HOUR],
    },
  }))
  on('ui.status', (_, e) => (shown.push(e.text), { value: undefined }))
  on('session.measure', (_, e) => ({ changed: e.changed }))

  await $.session.measure({
    context: { window: 1000000, tokens: 42000, percent: 4 },
    rateLimits: [SEVEN_DAY, FIVE_HOUR],
    changed: ['context', 'rateLimits'],
  })

  expect(shown.at(-1)).toBe('Opus 5.5. Ctx 4. Session 12. Week 31.')
})
