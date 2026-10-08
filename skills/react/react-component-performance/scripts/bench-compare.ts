// bench-harness v1 — bench-compare.ts. Copy together with bench-harness.ts; keep the version line.
// Compares two bench-result/v1 files. Render counts gate (REACT-PERF-11); timing only warns (REACT-PERF-12).
//
//   bun bench-compare.ts <baseline.json> <current.json> [--gate] [--threshold 10]
//
// Exit codes: 0 pass (or no --gate), 1 gate failed, 2 usage or unreadable file.

export const HARNESS_VERSION = 'bench-harness v1'
export const RESULT_SCHEMA = 'bench-result/v1'

export interface Spread {
  median: number
  p95: number
  min: number
  max: number
}

export interface ScenarioResult {
  case: string
  scenario: string
  kind: 'mount' | 'interaction'
  n: number
  warmup: number
  wallMs: Spread
  profilerMs: Spread | null
  renders: Record<string, { median: number; min: number; max: number }>
  heapMb?: number
}

export interface BenchEnvironment {
  date: string
  runtime: string
  runtimeVersion: string
  dom: string
  domVersion: string
  react: string
  nodeEnv: string
  platform: string
  cpu: string
  seed?: number | string
  commit?: string
}

export interface BenchFile {
  schema: typeof RESULT_SCHEMA
  harness: string
  name: string
  environment: BenchEnvironment
  config: {
    iterations: number
    mountIterations: number
    warmup: number
    threshold: number
  }
  results: ScenarioResult[]
}

export interface Finding {
  level: 'fail' | 'warn' | 'info'
  key: string
  message: string
}

export interface Comparison {
  rows: string[][]
  header: string[]
  findings: Finding[]
  failed: boolean
}

export const resultKey = (result: Pick<ScenarioResult, 'case' | 'scenario'>) =>
  `${result.case} | ${result.scenario}`

const pct = (current: number, previous: number | undefined) =>
  previous === undefined || previous === 0
    ? undefined
    : ((current - previous) / previous) * 100

const signed = (value: number | undefined) => {
  if (value === undefined) return '-'
  const rounded = Math.round(value)
  return `${rounded > 0 ? '+' : ''}${rounded === 0 ? 0 : rounded}%`
}

const ENV_FIELDS: (keyof BenchEnvironment)[] = [
  'runtime',
  'runtimeVersion',
  'dom',
  'domVersion',
  'react',
  'nodeEnv',
  'cpu',
]

export function compareResults(
  baseline: BenchFile,
  current: BenchFile,
  options: { threshold?: number } = {},
): Comparison {
  const threshold = options.threshold ?? current.config?.threshold ?? 10
  const findings: Finding[] = []
  const before = new Map(baseline.results.map((r) => [resultKey(r), r]))
  const seen = new Set<string>()

  if (baseline.harness !== current.harness) {
    findings.push({
      level: 'warn',
      key: '-',
      message: `harness differs (${baseline.harness} vs ${current.harness}): re-run both with the same harness (REACT-PERF-13)`,
    })
  }
  for (const field of ENV_FIELDS) {
    if (baseline.environment?.[field] !== current.environment?.[field]) {
      findings.push({
        level: 'warn',
        key: '-',
        message: `environment.${field} differs (${baseline.environment?.[field]} vs ${current.environment?.[field]}): timing deltas are not comparable`,
      })
    }
  }

  const header = [
    'case',
    'scenario',
    'renders before',
    'renders after',
    'wall before',
    'wall after',
    'd wall',
    'prof before',
    'prof after',
    'd prof',
  ]
  const rows: string[][] = []

  for (const result of current.results) {
    const key = resultKey(result)
    seen.add(key)
    const previous = before.get(key)
    const counters = Object.keys(result.renders)
    const rendersAfter = counters
      .map((c) => `${c}=${result.renders[c]?.median}`)
      .join(' ')

    for (const counter of counters) {
      const stats = result.renders[counter]
      if (stats && stats.min !== stats.max) {
        findings.push({
          level: 'warn',
          key,
          message: `renders.${counter} varies across iterations (${stats.min}..${stats.max}): the scenario is not deterministic, fix it before gating on it`,
        })
      }
    }

    if (!previous) {
      findings.push({ level: 'info', key, message: 'new scenario, no baseline' })
      rows.push([
        result.case,
        result.scenario,
        '-',
        rendersAfter,
        '-',
        result.wallMs.median.toFixed(1),
        '-',
        '-',
        result.profilerMs?.median.toFixed(1) ?? '-',
        '-',
      ])
      continue
    }

    for (const counter of counters) {
      const now = result.renders[counter]?.median ?? 0
      const was = previous.renders[counter]?.median
      if (was === undefined) {
        findings.push({ level: 'info', key, message: `counter ${counter} has no baseline` })
      } else if (now > was) {
        findings.push({ level: 'fail', key, message: `renders.${counter} rose ${was} -> ${now}` })
      }
    }
    for (const counter of Object.keys(previous.renders)) {
      if (!(counter in result.renders)) {
        findings.push({ level: 'fail', key, message: `counter ${counter} disappeared from the current run` })
      }
    }

    const dWall = pct(result.wallMs.median, previous.wallMs.median)
    const dProf =
      result.profilerMs && previous.profilerMs
        ? pct(result.profilerMs.median, previous.profilerMs.median)
        : undefined
    for (const [label, delta] of [['wall', dWall], ['profiler', dProf]] as const) {
      if (delta !== undefined && delta > threshold) {
        findings.push({
          level: 'warn',
          key,
          message: `${label} median +${delta.toFixed(0)}% (above the ${threshold}% noise threshold; re-run before believing it)`,
        })
      }
    }

    const rendersBefore = Object.keys(previous.renders)
      .map((c) => `${c}=${previous.renders[c]?.median}`)
      .join(' ')
    rows.push([
      result.case,
      result.scenario,
      rendersBefore,
      rendersAfter,
      previous.wallMs.median.toFixed(1),
      result.wallMs.median.toFixed(1),
      signed(dWall),
      previous.profilerMs?.median.toFixed(1) ?? '-',
      result.profilerMs?.median.toFixed(1) ?? '-',
      signed(dProf),
    ])
  }

  for (const key of before.keys()) {
    if (!seen.has(key)) {
      findings.push({ level: 'fail', key, message: 'scenario missing from the current run: the gate lost coverage' })
    }
  }

  return { header, rows, findings, failed: findings.some((f) => f.level === 'fail') }
}

export function formatTable(header: string[], rows: string[][], leftColumns = 2) {
  const widths = header.map((title, column) =>
    Math.max(title.length, ...rows.map((row) => (row[column] ?? '').length)),
  )
  const line = (row: string[]) =>
    row
      .map((value, column) =>
        column < leftColumns
          ? value.padEnd(widths[column] ?? 0)
          : value.padStart(widths[column] ?? 0),
      )
      .join('  ')
  return [line(header), widths.map((w) => '-'.repeat(w)).join('  '), ...rows.map(line)].join('\n')
}

export function printComparison(comparison: Comparison, gate: boolean) {
  console.log(formatTable(comparison.header, comparison.rows))
  console.log('')
  for (const finding of comparison.findings) {
    const tag = finding.level === 'fail' ? (gate ? 'FAIL' : 'fail') : finding.level
    console.log(`[${tag}] ${finding.key} — ${finding.message}`)
  }
  const fails = comparison.findings.filter((f) => f.level === 'fail').length
  const warns = comparison.findings.filter((f) => f.level === 'warn').length
  console.log(
    gate
      ? `gate: ${comparison.failed ? 'FAILED' : 'passed'} (${fails} render regression(s), ${warns} warning(s); timing never fails the gate)`
      : `${fails} render regression(s), ${warns} warning(s) — pass --gate to fail on render regressions`,
  )
}

export async function readBenchFile(path: string): Promise<BenchFile> {
  const { readFile } = await import('node:fs/promises')
  const parsed = JSON.parse(await readFile(path, 'utf8')) as BenchFile
  if (parsed.schema !== RESULT_SCHEMA) {
    throw new Error(`${path}: expected schema ${RESULT_SCHEMA}, got ${String(parsed.schema)}`)
  }
  return parsed
}

if ((import.meta as { main?: boolean }).main) {
  const args = process.argv.slice(2)
  const value = (name: string) => {
    const index = args.indexOf(name)
    return index === -1 ? undefined : args[index + 1]
  }
  const thresholdArg = value('--threshold')
  const files = args.filter(
    (arg, index) => !arg.startsWith('--') && args[index - 1] !== '--threshold',
  )
  if (files.length !== 2) {
    console.error('usage: bun bench-compare.ts <baseline.json> <current.json> [--gate] [--threshold 10]')
    process.exit(2)
  }
  try {
    const [baseline, current] = await Promise.all(files.map(readBenchFile))
    const gate = args.includes('--gate')
    const comparison = compareResults(baseline as BenchFile, current as BenchFile, {
      threshold: thresholdArg ? Number(thresholdArg) : undefined,
    })
    printComparison(comparison, gate)
    process.exit(gate && comparison.failed ? 1 : 0)
  } catch (error) {
    console.error(String(error instanceof Error ? error.message : error))
    process.exit(2)
  }
}
