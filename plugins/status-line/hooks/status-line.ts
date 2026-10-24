import type { EngineInterface, Register, SessionRateLimit } from 'claude-code'

// claude-opus-5-5, claude-sonnet-4-5-20250929, us.anthropic.claude-haiku-4-5-v1:0
const FAMILY_FIRST = /claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?!\d)/
// claude-3-5-sonnet-20241022
const VERSION_FIRST = /claude-(\d+)(?:-(\d{1,2}))?-([a-z]+)/

const capitalize = (word: string): string => word.charAt(0).toUpperCase() + word.slice(1)

const version = (major: string, minor: string | undefined): string =>
  minor === undefined ? major : `${major}.${minor}`

export const modelName = (id: string): string => {
  const familyFirst = FAMILY_FIRST.exec(id)
  if (familyFirst !== null) {
    return `${capitalize(familyFirst[1])} ${version(familyFirst[2], familyFirst[3])}`
  }

  const versionFirst = VERSION_FIRST.exec(id)
  if (versionFirst !== null) {
    return `${capitalize(versionFirst[3])} ${version(versionFirst[1], versionFirst[2])}`
  }

  return id
}

const percentUsed = (limits: SessionRateLimit[], kind: string): number | undefined =>
  limits.find(limit => limit.kind === kind)?.percentUsed

export const statusText = (
  model: string,
  context: number | undefined,
  limits: SessionRateLimit[],
): string => {
  const session = percentUsed(limits, 'five_hour')
  const week = percentUsed(limits, 'seven_day')

  return [
    modelName(model),
    context === undefined ? undefined : `Ctx ${Math.round(context)}`,
    session === undefined ? undefined : `Session ${Math.round(session)}`,
    week === undefined ? undefined : `Week ${Math.round(week)}`,
  ]
    .filter(part => part !== undefined)
    .map(part => `${part}.`)
    .join(' ')
}

const show = async ($: EngineInterface): Promise<void> => {
  const [model, usage] = await Promise.all([$.session.model(), $.session.usage()])

  $.ui.status(statusText(model, usage.context.percent, usage.rateLimits))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const started = await next(e)
    await show($)

    return started
  })

  // A model picked with /model shows from the next prompt on.
  on('turn.start', async ($, e, next) => {
    const started = await next(e)
    if (e.agentId === undefined) {
      await show($)
    }

    return started
  })

  on('session.measure', async ($, e, next) => {
    const measured = await next(e)
    await show($)

    return measured
  })
}
