// bench-harness v1 — generic React component benchmark. Copy together with bench-compare.ts; keep the version line.
// Rules it implements: REACT-PERF-11..17 (React - Performance Measurement).
// Dependencies: jsdom, react, react-dom (React 18.3+ or 19, development build). No project imports.
//
//   bun bench/my-component.bench.ts                         run, print the table
//   bun bench/my-component.bench.ts --json bench/base.json  also save a bench-result/v1 file
//   bun bench/my-component.bench.ts --compare bench/base.json [--gate] [--threshold 10]
//   --case <text> / --scenario <text> run only matching ids
//
// Env: BENCH_ITERATIONS (5), BENCH_MOUNT_ITERATIONS (3), BENCH_WARMUP (1), BENCH_THRESHOLD (10).
// Import this file BEFORE anything that loads react-dom: it installs the DOM globals first.

import { execSync } from 'node:child_process'
import { mkdir, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { cpus } from 'node:os'
import { dirname } from 'node:path'
import { performance } from 'node:perf_hooks'
import { JSDOM } from 'jsdom'
import { act, createElement, Profiler, type ReactElement, version as reactVersion } from 'react'
import {
  type BenchEnvironment,
  type BenchFile,
  compareResults,
  formatTable,
  HARNESS_VERSION,
  printComparison,
  RESULT_SCHEMA,
  readBenchFile,
  type ScenarioResult,
  type Spread,
} from './bench-compare'

export type { BenchFile, ScenarioResult } from './bench-compare'

const dom = new JSDOM('<!doctype html><html><body></body></html>', {
  pretendToBeVisual: true,
  url: 'http://localhost',
})
installDom(dom)

if (process.env.NODE_ENV === 'production') {
  throw new Error('bench-harness needs the React development build (act). Unset NODE_ENV=production.')
}
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true
const { createRoot } = await import('react-dom/client')
type Root = ReturnType<typeof createRoot>

function installDom(jsdom: InstanceType<typeof JSDOM>) {
  const window = jsdom.window as unknown as Window & typeof globalThis & Record<string, unknown>
  const proto = window.Element.prototype as unknown as Record<string, unknown>
  proto.scrollIntoView ??= () => undefined
  proto.getAnimations ??= () => []
  window.matchMedia ??= (query: string) =>
    ({
      addEventListener() {},
      addListener() {},
      dispatchEvent: () => false,
      matches: false,
      media: query,
      onchange: null,
      removeEventListener() {},
      removeListener() {},
    }) as unknown as MediaQueryList
  class NoopObserver {
    readonly root = null
    readonly rootMargin = '0px'
    readonly thresholds = [0]
    disconnect() {}
    observe() {}
    takeRecords() {
      return []
    }
    unobserve() {}
  }
  window.ResizeObserver ??= NoopObserver as unknown as typeof ResizeObserver
  window.IntersectionObserver ??= NoopObserver as unknown as typeof IntersectionObserver
  window.PointerEvent ??= window.MouseEvent as unknown as typeof PointerEvent

  const override = new Set(['AbortController', 'AbortSignal', 'CustomEvent', 'Event', 'EventTarget', 'navigator'])
  const target = globalThis as unknown as Record<string, unknown>
  for (const key of Object.getOwnPropertyNames(window)) {
    if (key in target && !override.has(key)) continue
    let value: unknown
    try {
      value = window[key]
    } catch {
      continue
    }
    const bound =
      typeof value === 'function' && !/^[A-Z]/.test(key) ? (value as () => unknown).bind(window) : value
    try {
      Object.defineProperty(target, key, { configurable: true, value: bound, writable: true })
    } catch {}
  }
  Object.defineProperty(target, 'window', { configurable: true, value: window, writable: true })
}

const counts = new Map<string, number>()
const registered = new Set<string>()
let profilerMs = 0
let commits = 0

export function countRenders<Args extends unknown[], Result>(
  fn: (...args: Args) => Result,
  counter = 'renders',
): (...args: Args) => Result {
  registered.add(counter)
  const counted = (...args: Args) => {
    counts.set(counter, (counts.get(counter) ?? 0) + 1)
    return fn(...args)
  }
  Object.defineProperty(counted, 'name', { value: fn.name || counter })
  return counted
}

export function seededRandom(seed: number) {
  let state = seed
  return () => {
    state = (state + 0x6d2b79f5) | 0
    let value = Math.imul(state ^ (state >>> 15), 1 | state)
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296
  }
}

export const fire = {
  click(element: Element, init: MouseEventInit = {}) {
    element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, ...init }))
  },
  keyDown(element: Element, init: KeyboardEventInit) {
    element.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true, cancelable: true, ...init }))
  },
  input(element: HTMLInputElement | HTMLTextAreaElement, value: string) {
    const proto = Object.getPrototypeOf(element) as object
    Object.getOwnPropertyDescriptor(proto, 'value')?.set?.call(element, value)
    element.dispatchEvent(new Event('input', { bubbles: true }))
  },
  dispatch(element: Element, event: Event) {
    element.dispatchEvent(event)
  },
}

export interface MountTools {
  render(element: ReactElement): void
}

export interface BenchCase<Handle> {
  id: string
  mount(container: HTMLElement, tools: MountTools): Handle | Promise<Handle>
  unmount?(handle: Handle): void
}

export interface ScenarioContext {
  index: number
  container: HTMLElement
}

export interface BenchScenario<Handle> {
  name: string
  cases?: string[]
  iterations?: number
  warmup?: number
  setup?(handle: Handle, context: ScenarioContext): void | Promise<void>
  run(handle: Handle, context: ScenarioContext): void | Promise<void>
}

export interface BenchOptions<Handle> {
  name: string
  cases: BenchCase<Handle>[]
  scenarios: BenchScenario<Handle>[]
  mount?: boolean | { cases?: string[]; iterations?: number }
  seed?: number | string
}

interface Sample {
  wallMs: number
  profilerMs: number | null
  renders: Record<string, number>
  heapMb?: number
}

interface Mounted<Handle> {
  container: HTMLElement
  handle: Handle
  profiled: boolean
  root: Root | null
}

const envNumber = (name: string, fallback: number) => {
  const value = Number(process.env[name])
  return Number.isFinite(value) && value >= 0 && process.env[name] !== '' && process.env[name] !== undefined
    ? value
    : fallback
}

function spread(values: number[]): Spread {
  const sorted = [...values].sort((a, b) => a - b)
  const middle = Math.floor(sorted.length / 2)
  const at = (index: number) => sorted[index] ?? 0
  return {
    max: at(sorted.length - 1),
    median: sorted.length % 2 ? at(middle) : (at(middle - 1) + at(middle)) / 2,
    min: at(0),
    p95: at(Math.min(sorted.length - 1, Math.ceil(sorted.length * 0.95) - 1)),
  }
}

function heapMb(): number | undefined {
  const bun = (globalThis as { Bun?: { gc(force: boolean): void } }).Bun
  const gc = bun ? () => bun.gc(true) : (globalThis as { gc?: () => void }).gc
  if (!gc) return undefined
  gc()
  gc()
  return process.memoryUsage().heapUsed / 1024 / 1024
}

function environment(seed: number | string | undefined): BenchEnvironment {
  const require = createRequire(import.meta.url)
  const versionOf = (pkg: string) => {
    try {
      return (require(`${pkg}/package.json`) as { version: string }).version
    } catch {
      return 'unknown'
    }
  }
  const bun = (globalThis as { Bun?: { version: string } }).Bun
  const cpu = cpus()
  let commit: string | undefined
  try {
    commit = String(execSync('git rev-parse --short HEAD', { stdio: ['ignore', 'pipe', 'ignore'] })).trim() || undefined
  } catch {}
  return {
    cpu: `${cpu[0]?.model?.trim() ?? 'unknown'} x${cpu.length}`,
    date: new Date().toISOString(),
    dom: 'jsdom (no layout)',
    domVersion: versionOf('jsdom'),
    nodeEnv: process.env.NODE_ENV ?? 'development (unset)',
    platform: `${process.platform}-${process.arch}`,
    react: reactVersion,
    runtime: bun ? 'bun' : 'node',
    runtimeVersion: bun ? bun.version : process.versions.node,
    ...(seed === undefined ? {} : { seed }),
    ...(commit ? { commit } : {}),
  }
}

async function measure(action: () => void | Promise<void>, profiled: () => boolean): Promise<Sample> {
  counts.clear()
  profilerMs = 0
  commits = 0
  const start = performance.now()
  await act(async () => {
    await action()
  })
  const wallMs = performance.now() - start
  const renders: Record<string, number> = Object.fromEntries([...registered].map((c) => [c, counts.get(c) ?? 0]))
  if (profiled()) renders.commits = commits
  return { profilerMs: profiled() ? profilerMs : null, renders, wallMs }
}

async function mountCase<Handle>(benchCase: BenchCase<Handle>, measured: boolean) {
  const container = document.createElement('div')
  document.body.appendChild(container)
  const state = { profiled: false, root: null as Root | null }
  const tools: MountTools = {
    render(element) {
      state.profiled = true
      state.root ??= createRoot(container)
      state.root.render(
        createElement(
          Profiler,
          {
            id: benchCase.id,
            onRender: (_id: string, _phase: string, actualDuration: number) => {
              profilerMs += actualDuration
              commits += 1
            },
          },
          element,
        ),
      )
    },
  }
  let handle: Handle | undefined
  const before = measured ? heapMb() : undefined
  const sample = await measure(
    async () => {
      handle = await benchCase.mount(container, tools)
    },
    () => state.profiled,
  )
  const after = measured ? heapMb() : undefined
  const mounted: Mounted<Handle> = { container, handle: handle as Handle, ...state }
  if (before !== undefined && after !== undefined) sample.heapMb = after - before
  return { mounted, sample }
}

async function unmountCase<Handle>(benchCase: BenchCase<Handle>, mounted: Mounted<Handle>) {
  await act(async () => {
    mounted.root?.unmount()
  })
  benchCase.unmount?.(mounted.handle)
  mounted.container.remove()
}

function summarize(
  benchCase: string,
  scenario: string,
  kind: ScenarioResult['kind'],
  warmup: number,
  samples: Sample[],
): ScenarioResult {
  const counters = [...new Set(samples.flatMap((s) => Object.keys(s.renders)))].sort()
  const renders = Object.fromEntries(
    counters.map((counter) => {
      const values = samples.map((s) => s.renders[counter] ?? 0)
      const { median, min, max } = spread(values)
      return [counter, { max, median, min }]
    }),
  )
  const profiler = samples.flatMap((s) => (s.profilerMs === null ? [] : [s.profilerMs]))
  const heap = samples.flatMap((s) => (s.heapMb === undefined ? [] : [s.heapMb]))
  return {
    case: benchCase,
    kind,
    n: samples.length,
    profilerMs: profiler.length === samples.length ? spread(profiler) : null,
    renders,
    scenario,
    wallMs: spread(samples.map((s) => s.wallMs)),
    warmup,
    ...(heap.length ? { heapMb: spread(heap).median } : {}),
  }
}

export function createBench<Handle>(options: BenchOptions<Handle>) {
  async function run(argv = process.argv.slice(2)): Promise<BenchFile> {
    const value = (name: string) => {
      const index = argv.indexOf(name)
      return index === -1 ? undefined : argv[index + 1]
    }
    const iterations = envNumber('BENCH_ITERATIONS', 5)
    const mountIterations = envNumber(
      'BENCH_MOUNT_ITERATIONS',
      typeof options.mount === 'object' ? (options.mount.iterations ?? 3) : 3,
    )
    const warmup = envNumber('BENCH_WARMUP', 1)
    const threshold = Number(value('--threshold') ?? envNumber('BENCH_THRESHOLD', 10))
    const comparePath = value('--compare')
    const gate = argv.includes('--gate')
    if (gate && !comparePath) {
      console.error('--gate needs --compare <baseline.json>')
      process.exit(2)
    }
    const caseFilter = value('--case')
    const scenarioFilter = value('--scenario')
    const mountCases = typeof options.mount === 'object' ? options.mount.cases : undefined
    const results: ScenarioResult[] = []

    for (const benchCase of options.cases) {
      if (caseFilter && !benchCase.id.includes(caseFilter)) continue
      const mountOn = options.mount !== false && (!mountCases || mountCases.includes(benchCase.id))
      if (mountOn && (!scenarioFilter || 'mount'.includes(scenarioFilter))) {
        const samples: Sample[] = []
        for (let index = 0; index < mountIterations; index++) {
          const { mounted, sample } = await mountCase(benchCase, true)
          samples.push(sample)
          await unmountCase(benchCase, mounted)
        }
        results.push(summarize(benchCase.id, 'mount', 'mount', 0, samples))
        console.error(`done ${benchCase.id} | mount`)
      }
      for (const scenario of options.scenarios) {
        if (scenario.cases && !scenario.cases.includes(benchCase.id)) continue
        if (scenarioFilter && !scenario.name.includes(scenarioFilter)) continue
        const { mounted } = await mountCase(benchCase, false)
        const context = (index: number): ScenarioContext => ({ container: mounted.container, index })
        if (scenario.setup) {
          await act(async () => {
            await scenario.setup?.(mounted.handle, context(-1))
          })
        }
        const count = scenario.iterations ?? iterations
        const skip = scenario.warmup ?? warmup
        const samples: Sample[] = []
        for (let index = 0; index < skip + count; index++) {
          const sample = await measure(
            () => scenario.run(mounted.handle, context(index)),
            () => mounted.profiled,
          )
          if (index >= skip) samples.push(sample)
        }
        await unmountCase(benchCase, mounted)
        results.push(summarize(benchCase.id, scenario.name, 'interaction', skip, samples))
        console.error(`done ${benchCase.id} | ${scenario.name}`)
      }
    }

    const file: BenchFile = {
      config: { iterations, mountIterations, threshold, warmup },
      environment: environment(options.seed),
      harness: HARNESS_VERSION,
      name: options.name,
      results,
      schema: RESULT_SCHEMA,
    }
    printResults(file)

    const jsonPath = value('--json')
    if (jsonPath) {
      await mkdir(dirname(jsonPath), { recursive: true })
      await writeFile(jsonPath, `${JSON.stringify(file, null, 2)}\n`)
      console.error(`wrote ${jsonPath}`)
    }
    let failed = false
    if (comparePath) {
      console.log('')
      const comparison = compareResults(await readBenchFile(comparePath), file, { threshold })
      printComparison(comparison, gate)
      failed = gate && comparison.failed
    }
    dom.window.close()
    process.exit(failed ? 1 : 0)
  }
  return { run }
}

function printResults(file: BenchFile) {
  const env = file.environment
  const fixed = (n: number | undefined, digits = 1) => (n === undefined ? '-' : n.toFixed(digits))
  console.log(
    `${file.name} — ${file.harness} · ${env.date.slice(0, 10)} · ${env.runtime} ${env.runtimeVersion} · ` +
      `${env.dom} ${env.domVersion} · react ${env.react} · NODE_ENV ${env.nodeEnv}` +
      (env.seed === undefined ? '' : ` · seed ${env.seed}`),
  )
  console.log(
    `iterations=${file.config.iterations} mount=${file.config.mountIterations} (fresh container, no warmup) ` +
      `warmup=${file.config.warmup} · ms unless noted · renders gate, timing reports`,
  )
  const rows = file.results.map((r) => [
    r.case,
    r.scenario,
    String(r.n),
    fixed(r.wallMs.median),
    fixed(r.wallMs.p95),
    fixed(r.profilerMs?.median),
    fixed(r.profilerMs?.p95),
    Object.entries(r.renders)
      .map(([counter, stats]) => `${counter}=${stats.median}${stats.min === stats.max ? '' : '~'}`)
      .join(' ') || '-',
    fixed(r.heapMb),
  ])
  console.log(
    formatTable(
      ['case', 'scenario', 'n', 'wall med', 'wall p95', 'prof med', 'prof p95', 'renders', 'heap MB'],
      rows,
    ),
  )
  if (file.results.some((r) => r.n < 20)) {
    console.log('p95 with n < 20 is the slowest sample; "~" marks a render count that varied across iterations')
  }
}
