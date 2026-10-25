#!/usr/bin/env node
// Elysia static scan over a project's TypeScript, on the TypeScript compiler API (AST, not regex).
//
//   node elysia-scan.mjs <dir> [--only route,lifecycle,schema,openapi,eden] [--json]
//
// Each finding names the ELYSIA-* rule, file:line and a confidence:
//   high      — the shape is the defect (a hook registered after the route it should affect).
//   candidate — the shape is suspicious; confirm by reading or by a test.
// The scan never claims a defect is absent: it reports what it could see.
// `typescript` is resolved from the scanned project's node_modules, then from next to this script.
import { createRequire } from 'node:module'
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs'
import { join, relative, resolve } from 'node:path'

const args = process.argv.slice(2)
const root = resolve(args.find((a) => !a.startsWith('--')) ?? '.')
const ALL = ['route', 'lifecycle', 'schema', 'openapi', 'eden']
const only = new Set((args.includes('--only') ? args[args.indexOf('--only') + 1] : ALL.join(',')).split(','))
const asJson = args.includes('--json')

let ts
for (const base of [join(root, 'package.json'), join(process.cwd(), 'package.json'), import.meta.url]) {
  try { ts = createRequire(base)('typescript'); break } catch {}
}
if (!ts) {
  console.log('SKIPPED: the AST scan needs the `typescript` package (not found from ' + root + '). Install it as a dev dependency, or read the code by hand.')
  process.exit(0)
}

// ---------- files ----------
const SKIP = new Set(['node_modules', 'dist', 'build', '.git', 'coverage', '.next', 'out'])
const files = []
;(function walkDir(dir) {
  let entries = []
  try { entries = readdirSync(dir) } catch { return }
  for (const e of entries) {
    if (SKIP.has(e) || e.startsWith('.')) continue
    const p = join(dir, e)
    let s; try { s = statSync(p) } catch { continue }
    if (s.isDirectory()) walkDir(p)
    else if (/\.(ts|tsx|mts|cts)$/.test(e) && !/\.d\.ts$/.test(e)) files.push(p)
  }
})(root)
const sources = files.map((f) => ts.createSourceFile(f, readFileSync(f, 'utf8'), ts.ScriptTarget.Latest, true,
  f.endsWith('x') ? ts.ScriptKind.TSX : ts.ScriptKind.TS))

const findings = []
const seen = new Set()
const add = (group, id, conf, sf, node, msg) => {
  // a call in a chain starts where the chain starts: point at the method name instead
  const at = ts.isCallExpression(node) && ts.isPropertyAccessExpression(node.expression) ? node.expression.name : node
  const { line } = sf.getLineAndCharacterOfPosition(at.getStart(sf))
  const key = `${id}|${sf.fileName}|${line}|${msg}`
  if (seen.has(key)) return
  seen.add(key)
  findings.push({ group, id, confidence: conf, file: relative(root, sf.fileName), line: line + 1, message: msg })
}
const isTest = (sf) => /\.(test|spec)\.[cm]?tsx?$/.test(sf.fileName) || /(^|\/)(test|tests|__tests__)\//.test(relative(root, sf.fileName))
const walk = (node, fn, parents = []) => { fn(node, parents); ts.forEachChild(node, (c) => walk(c, fn, [...parents, node])) }
const objProp = (obj, key) => obj && ts.isObjectLiteralExpression(obj)
  ? obj.properties.find((p) => (ts.isPropertyAssignment(p) || ts.isShorthandPropertyAssignment(p) || ts.isMethodDeclaration(p)) && p.name && p.name.getText() === key)
  : undefined
const propValue = (p) => p && (ts.isPropertyAssignment(p) ? p.initializer : ts.isShorthandPropertyAssignment(p) ? p.name : p)
const isFn = (n) => n && (ts.isArrowFunction(n) || ts.isFunctionExpression(n) || ts.isFunctionDeclaration(n) || ts.isMethodDeclaration(n))
const strip = (n) => { while (n && (ts.isParenthesizedExpression(n) || ts.isAwaitExpression(n) || ts.isNonNullExpression(n) || ts.isAsExpression(n) || ts.isSatisfiesExpression?.(n))) n = n.expression; return n }

// imports per file, and project-wide signals
const importsOf = (sf) => sf.statements.filter(ts.isImportDeclaration).map((d) => ({ from: d.moduleSpecifier.text, decl: d }))
const projectImports = new Set(sources.flatMap((sf) => importsOf(sf).map((i) => i.from)))
let pkgDeps = {}
try { const pj = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')); pkgDeps = { ...pj.dependencies, ...pj.devDependencies } } catch {}
const usesQuery = [...projectImports].some((m) => m.startsWith('@tanstack/')) || Object.keys(pkgDeps).some((m) => m.startsWith('@tanstack/'))
const usesOtel = projectImports.has('@elysia/opentelemetry') || projectImports.has('@elysiajs/opentelemetry')

// ---------- Elysia chains ----------
// A chain: new Elysia(cfg).a(...).b(...)  or  ident.a(...).b(...) where ident is bound to new Elysia(...)
const ROUTES = new Set(['get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'all', 'route', 'ws'])
const ORDERED_HOOKS = new Set(['onBeforeHandle', 'onAfterHandle', 'onError', 'onTransform', 'onParse', 'mapResponse', 'onAfterResponse', 'derive', 'resolve', 'guard'])
const SCOPABLE = new Set(['onBeforeHandle', 'onAfterHandle', 'onError', 'onTransform', 'onParse', 'mapResponse', 'onAfterResponse', 'derive', 'resolve'])
const isNewElysia = (n) => n && ts.isNewExpression(n) && ts.isIdentifier(n.expression) && n.expression.text === 'Elysia'
const elysiaVars = new Map() // name -> { sf, decl, init }
for (const sf of sources) walk(sf, (n) => {
  if (ts.isVariableDeclaration(n) && ts.isIdentifier(n.name) && n.initializer) {
    let base = strip(n.initializer)
    while (base && ts.isCallExpression(base) && ts.isPropertyAccessExpression(base.expression)) base = strip(base.expression.expression)
    if (isNewElysia(base)) elysiaVars.set(n.name.text, { sf, decl: n, init: n.initializer })
  }
})
function flatten(top) {
  const calls = []
  let cur = top
  while (cur) {
    cur = strip(cur)
    if (ts.isCallExpression(cur) && ts.isPropertyAccessExpression(cur.expression)) {
      calls.unshift({ name: cur.expression.name.text, args: cur.arguments, node: cur })
      cur = cur.expression.expression
      continue
    }
    if (isNewElysia(cur)) return { base: 'new', ctor: cur, calls }
    if (ts.isIdentifier(cur)) return { base: cur.text, calls }
    return null
  }
  return null
}
const chains = [] // { sf, top, base, ctor, calls, varName, exported }
for (const sf of sources) walk(sf, (n, parents) => {
  if (!ts.isCallExpression(n) || !ts.isPropertyAccessExpression(n.expression)) return
  const p = n.parent
  if (p && ts.isPropertyAccessExpression(p) && p.expression === n) return // not the top of the chain
  const ch = flatten(n)
  if (!ch) return
  if (ch.base !== 'new' && !elysiaVars.has(ch.base)) return
  const decl = parents.slice().reverse().find((x) => ts.isVariableDeclaration(x))
  const varName = decl && decl.initializer && strip(decl.initializer) === n && ts.isIdentifier(decl.name) ? decl.name.text : (ch.base !== 'new' ? ch.base : null)
  const stmt = parents.find((x) => ts.isVariableStatement(x))
  const exported = !!stmt?.modifiers?.some((m) => m.kind === ts.SyntaxKind.ExportKeyword)
  const ctor = ch.ctor ?? (elysiaVars.get(ch.base) && (() => { let b = strip(elysiaVars.get(ch.base).init); while (ts.isCallExpression(b)) b = strip(b.expression.expression); return b })())
  chains.push({ sf, top: n, base: ch.base, ctor, calls: ch.calls, varName, exported })
})
const ctorCfg = (c) => c.ctor?.arguments?.[0]
// identity of an identifier: the file that declares it (same file, or followed through a relative import)
const declaredIn = (sf, name) => {
  if (elysiaVars.get(name)?.sf === sf) return sf.fileName
  for (const i of importsOf(sf)) {
    const nb = i.decl.importClause?.namedBindings
    const names = [i.decl.importClause?.name?.text, ...(nb && ts.isNamedImports(nb) ? nb.elements.map((e) => e.name.text) : [])]
    if (!names.includes(name) || !i.from.startsWith('.')) continue
    const base = resolve(sf.fileName, '..', i.from).replace(/\.(ts|tsx|js|mjs)$/, '')
    const hit = sources.find((s) => s.fileName.replace(/\.(ts|tsx|mts|cts)$/, '') === base || s.fileName.replace(/\.(ts|tsx|mts|cts)$/, '') === base + '/index')
    if (hit) return hit.fileName
  }
  return elysiaVars.get(name)?.sf.fileName ?? null
}
const usedIn = new Map() // "file:identifier" -> chains that .use() it
for (const c of chains) for (const call of c.calls) if (call.name === 'use' && call.args[0] && ts.isIdentifier(strip(call.args[0]))) {
  const name = strip(call.args[0]).text
  const key = `${declaredIn(c.sf, name)}:${name}`
  ;(usedIn.get(key) ?? usedIn.set(key, []).get(key)).push(c)
}
const usesOf = (c) => usedIn.get(`${c.sf.fileName}:${c.varName}`) ?? []
const exportedTypeOf = new Set()
for (const sf of sources) for (const st of sf.statements)
  if (ts.isTypeAliasDeclaration(st) && st.modifiers?.some((m) => m.kind === ts.SyntaxKind.ExportKeyword) && ts.isTypeQueryNode(st.type))
    exportedTypeOf.add(st.type.exprName.getText(sf))
const isPlugin = (c) => c.varName && (usesOf(c).length > 0 || (c.exported && !exportedTypeOf.has(c.varName) && !c.calls.some((x) => x.name === 'listen')))
const routeParts = (call) => {
  if (call.name === 'route') return { path: call.args[1], handler: call.args[2], opts: call.args[3] }
  if (call.name === 'ws') return { path: call.args[0], handler: null, opts: call.args[1] }
  return { path: call.args[0], handler: call.args[1], opts: call.args[2] }
}
const pathText = (sf, p) => (p && ts.isStringLiteralLike(p) ? p.text : p?.getText(sf)) ?? '?'
// status(code, …) calls inside a function; returns { returned: Set, thrown: Set, rawReturn: bool }
function statusUse(fn) {
  const out = { returned: new Set(), thrown: new Set(), rawReturn: false }
  if (!fn || !isFn(fn)) return out
  const codeOf = (e) => {
    e = strip(e)
    if (e && ts.isCallExpression(e) && ts.isIdentifier(e.expression) && e.expression.text === 'status' && e.arguments[0]) {
      const a = e.arguments[0]
      return ts.isNumericLiteral(a) ? Number(a.text) : ts.isStringLiteral(a) ? a.text : '?'
    }
    return null
  }
  const visit = (n) => {
    if (n !== fn && isFn(n)) return // nested functions are not this handler's returns
    if (ts.isReturnStatement(n) && n.expression) {
      const c = codeOf(n.expression); if (c !== null) out.returned.add(c); else out.rawReturn = true
    }
    if (ts.isThrowStatement(n)) { const c = codeOf(n.expression); if (c !== null) out.thrown.add(c) }
    ts.forEachChild(n, visit)
  }
  if (fn.body && !ts.isBlock(fn.body)) { const c = codeOf(fn.body); if (c !== null) out.returned.add(c); else out.rawReturn = true }
  else if (fn.body) ts.forEachChild(fn.body, visit)
  return out
}
const responseMap = (opts) => {
  const r = propValue(objProp(opts, 'response'))
  if (!r) return { kind: 'none' }
  if (ts.isObjectLiteralExpression(r) && r.properties.every((p) => p.name && /^\d+$/.test(p.name.getText())))
    return { kind: 'map', codes: new Set(r.properties.map((p) => Number(p.name.getText()))), node: r }
  return { kind: 'single', node: r }
}
const zodLike = new Set()
for (const sf of sources) for (const i of importsOf(sf)) if (/^(zod|valibot|effect|@effect\/schema|arktype)/.test(i.from)) {
  const cl = i.decl.importClause
  if (cl?.name) zodLike.add(cl.name.text)
  const nb = cl?.namedBindings
  if (nb && ts.isNamespaceImport(nb)) zodLike.add(nb.name.text)
  if (nb && ts.isNamedImports(nb)) for (const e of nb.elements) zodLike.add(e.name.text)
}
const zodMajor = (() => { const v = pkgDeps.zod; const m = v && String(v).match(/(\d+)/); return m ? Number(m[1]) : null })()
const vendorsWithoutJsonSchema = () => {
  const v = []
  if (projectImports.has('zod') && zodMajor !== null && zodMajor < 4) v.push('zod 3')
  if (projectImports.has('zod/v3')) v.push('zod/v3')
  if ([...projectImports].some((m) => m === 'valibot')) v.push('valibot')
  if ([...projectImports].some((m) => m === 'effect' || m.startsWith('@effect/schema'))) v.push('effect')
  return v
}
const isStandardSchema = (e) => { e = strip(e); while (e && (ts.isCallExpression(e) || ts.isPropertyAccessExpression(e))) e = ts.isCallExpression(e) ? e.expression : e.expression; return e && ts.isIdentifier(e) && zodLike.has(e.text) }

const stdRoutes = []
// ================= GROUP: route (elysia-build) =================
if (only.has('route') || only.has('lifecycle')) {
  for (const sf of sources) {
    for (const i of importsOf(sf)) {
      if (i.from === 'elysia' && i.decl.importClause?.namedBindings && ts.isNamedImports(i.decl.importClause.namedBindings))
        for (const e of i.decl.importClause.namedBindings.elements) if (e.name.text === 'error' && !e.propertyName)
          add('route', 'ELYSIA-APP-02', 'high', sf, e, '`error` is imported from elysia — removed in 1.4; the export is `status`')
      if (i.from === '@elysiajs/swagger') add('openapi', 'ELYSIA-APP-07', 'high', sf, i.decl, '@elysiajs/swagger is discontinued — use @elysia/openapi')
    }
    const importsElysia = importsOf(sf).some((i) => i.from === 'elysia')
    walk(sf, (n) => {
      if (importsElysia && !isTest(sf) && ts.isPropertyAccessExpression(n) && n.getText(sf) === 'process.env')
        add('route', 'ELYSIA-APP-09', 'candidate', sf, n, 'process.env read in application code — use the `env` export of elysia (not in a Cloudflare Worker: there it is cloudflare:workers)')
      if (!isTest(sf) && ts.isPropertyAssignment(n) && /^(secret|secrets)$/.test(n.name.getText(sf))) {
        const v = n.initializer
        const lits = ts.isArrayLiteralExpression(v) ? v.elements : [v]
        if (lits.some((x) => ts.isStringLiteralLike(x) && x.text.length >= 4))
          add('route', 'ELYSIA-APP-08', 'high', sf, n, 'a literal secret in the code — load it from the environment at startup')
      }
    })
  }
  // APP-01: instance bound to a variable, then extended in separate statements
  for (const [name, v] of elysiaVars) {
    const { sf } = v
    walk(sf, (n) => {
      if (ts.isExpressionStatement(n)) {
        const ch = flatten(n.expression)
        if (ch && ch.base === name && ch.calls.length && (ROUTES.has(ch.calls[0].name) || ['use', 'state', 'decorate', 'derive', 'resolve', 'onBeforeHandle', 'onError', 'guard', 'group', 'model', 'macro'].includes(ch.calls[0].name)))
          add('route', 'ELYSIA-APP-01', 'high', sf, n, `\`${name}.${ch.calls[0].name}(…)\` in a separate statement — the result is discarded, so \`typeof ${name}\` (and Eden) never sees what it registers`)
      }
    })
  }
  if (chains.some((c) => c.calls.some((x) => ROUTES.has(x.name))) && !exportedTypeOf.size && projectImports.has('@elysia/eden') === false)
    for (const c of chains.filter((c) => c.calls.some((x) => x.name === 'listen')).slice(0, 1))
      add('route', 'ELYSIA-APP-05', 'candidate', c.sf, c.top, 'no `export type App = typeof app` anywhere — an Eden client has nothing to import')
  for (const c of chains) {
    const { sf } = c
    let firstRoute = null
    for (const call of c.calls) {
      if (ROUTES.has(call.name) || call.name === 'group') { firstRoute ??= call; continue }
      if (firstRoute && ORDERED_HOOKS.has(call.name))
        add('lifecycle', 'ELYSIA-CORE-01', 'high', sf, call.node, `.${call.name}() is registered after ${firstRoute.name.toUpperCase()} ${pathText(sf, routeParts(firstRoute).path)} — it does not apply to the routes above it`)
      if (firstRoute && call.name === 'use')
        add('lifecycle', 'ELYSIA-CORE-01', 'candidate', sf, call.node, `.use(${call.args[0]?.getText(sf).slice(0, 40)}) after ${firstRoute.name.toUpperCase()} ${pathText(sf, routeParts(firstRoute).path)} — its hooks (if any) do not reach the routes above`)
    }
    for (const call of c.calls) {
      if (call.name === 'onError') {
        const fn = call.args.find(isFn)
        if (fn) walk(fn, (n) => {
          if (ts.isPropertyAccessExpression(n) && n.name.text === 'message' && /^(error|err|e)$/.test(n.expression.getText(sf))) {
            const inReturn = (() => { let p = n.parent; while (p && p !== fn) { if (ts.isReturnStatement(p) || p === fn.body) return true; if (ts.isCallExpression(p) && /console|log|logger/.test(p.expression.getText(sf))) return false; p = p.parent } return false })()
            if (inReturn) add('route', 'ELYSIA-CORE-07', 'high', sf, n, 'onError puts error.message in the response — an UNKNOWN error leaks paths, queries and table names; log it and answer generically')
          }
        })
      }
      if (!ROUTES.has(call.name)) continue
      const { path, handler, opts } = routeParts(call)
      const where = `${call.name.toUpperCase()} ${pathText(sf, path)}`
      if (handler && (ts.isIdentifier(handler) || ts.isPropertyAccessExpression(handler)) && !/^(file|form)$/.test(handler.getText(sf)))
        add('route', 'ELYSIA-CORE-02', 'candidate', sf, handler, `${where} hands the whole context to an external function \`${handler.getText(sf)}\` — destructure inline and pass values`)
      if (!isFn(handler)) continue
      const p0 = handler.parameters[0]
      if (p0?.type && /\bContext\b/.test(p0.type.getText(sf)))
        add('route', 'ELYSIA-CORE-02', 'high', sf, p0, `${where}: a handler annotated with Context erases the inference the schema produced`)
      if (p0 && ts.isObjectBindingPattern(p0.name)) for (const el of p0.name.elements) {
        const key = (el.propertyName ?? el.name).getText(sf)
        if (key === 'error') add('route', 'ELYSIA-APP-02', 'high', sf, el, `${where} destructures \`error\` from the context — removed in 1.4; it is \`status\``)
        if (key === 'store' && ts.isObjectBindingPattern(el.name) && /\bstore\.\w+\s*(\+\+|--|[-+*/]?=[^=])/.test(handler.getText(sf)))
          add('lifecycle', 'ELYSIA-LIFE-06', 'high', sf, el, `${where} destructures store primitives and also writes the store — the destructured value is a snapshot that misses the write; use store.x`)
      }
      const rm = responseMap(opts)
      const su = statusUse(handler)
      let setStatus = null
      walk(handler, (n) => { if (ts.isBinaryExpression(n) && n.operatorToken.kind === ts.SyntaxKind.EqualsToken && n.left.getText(sf) === 'set.status') setStatus ??= n })
      if (setStatus) add('route', 'ELYSIA-CORE-04', rm.kind === 'none' ? 'candidate' : 'high', sf, setStatus, `${where}: set.status is not checked against the response schema — return status(code, value)`)
      if (su.thrown.size) add('route', 'ELYSIA-CORE-03', 'candidate', sf, handler, `${where} throws status(${[...su.thrown].join(', ')}) — a thrown status leaves the route's type; return it if the client must see it typed`)
      if (handler.asteriskToken) {
        let yielded = false
        walk(handler, (n) => {
          if (ts.isYieldExpression(n)) yielded = true
          if (yielded && ts.isBinaryExpression(n) && n.operatorToken.kind === ts.SyntaxKind.EqualsToken && /^set\.headers/.test(n.left.getText(sf)))
            add('route', 'ELYSIA-CORE-06', 'high', sf, n, `${where}: set.headers after the first yield is silently ignored`)
        })
      }
      // schema-side checks on the same route
      if (only.has('schema') || only.has('eden') || only.has('openapi')) routeSchemaChecks(sf, where, call, handler, opts, rm, su)
    }
  }
  // cookies: a value assigned with no httpOnly in the same handler, or no signing in the constructor
  for (const sf of sources) walk(sf, (n) => {
    if (ts.isBinaryExpression(n) && n.operatorToken.kind === ts.SyntaxKind.EqualsToken && ts.isPropertyAccessExpression(n.left) && n.left.name.text === 'value') {
      const obj = n.left.expression.getText(sf)
      if (!/session|sess|auth|token|sid/i.test(obj)) return
      let fn = n.parent; while (fn && !isFn(fn)) fn = fn.parent
      if (fn && !/httpOnly\s*[:=]\s*true/.test(fn.getText(sf)) && !/httpOnly/.test(sf.text))
        add('route', 'ELYSIA-CORE-05', 'high', sf, n, `session cookie \`${obj}\` is written without httpOnly (and check it is signed: cookie.secrets + sign)`)
      if (!/sign\s*:/.test(sf.text) && !/t\.Cookie\([^)]*sign/.test(sf.text))
        add('route', 'ELYSIA-CORE-05', 'candidate', sf, n, `session cookie \`${obj}\` — no cookie.sign in this file; an unsigned cookie can be forged`)
    }
  })
  // tests
  const asyncFiles = new Set(chains.filter((c) => c.calls.some((x) => x.name === 'use' && x.args[0] && (/import\(/.test(x.args[0].getText(c.sf)) || (isFn(x.args[0]) && x.args[0].modifiers?.some((m) => m.kind === ts.SyntaxKind.AsyncKeyword))))).map((c) => c.sf.fileName))
  const reachesAsync = (sf) => asyncFiles.has(sf.fileName) || importsOf(sf).some((i) => i.from.startsWith('.') && [...asyncFiles].some((f) => f.replace(/\.(ts|tsx)$/, '') === resolve(sf.fileName, '..', i.from).replace(/\.(ts|tsx|js)$/, '')))
  for (const sf of sources.filter(isTest)) {
    const asyncPlugins = reachesAsync(sf)
    if (/\.listen\(/.test(sf.text) && /\bfetch\(\s*['"`]http/.test(sf.text))
      add('route', 'ELYSIA-CORE-09', 'high', sf, sf.statements[0] ?? sf, 'the test starts a server and requests over the network — use app.handle(new Request(…)) or treaty(app)')
    if (asyncPlugins && /\.handle\(|treaty\(/.test(sf.text) && !/await\s+[\w.]+\.modules/.test(sf.text))
      add('route', 'ELYSIA-CORE-10', 'high', sf, sf.statements[0] ?? sf, 'the app uses an async or lazy plugin and this test never awaits app.modules — the route may not exist yet')
  }
}

// ================= GROUP: schema / openapi / eden — per route =================
function routeSchemaChecks(sf, where, call, handler, opts, rm, su) {
  const errCodes = [...su.returned].filter((c) => typeof c === 'number' && c >= 300)
  const allCodes = [...su.returned].filter((c) => typeof c === 'number')
  const thrownCodes = [...su.thrown].filter((c) => typeof c === 'number')
  if (rm.kind !== 'map' && thrownCodes.length && !errCodes.length)
    add('schema', 'ELYSIA-TYPE-06', 'high', sf, call.node, `${where} throws status ${thrownCodes.join(', ')} with ${rm.kind === 'none' ? 'no response schema' : 'a single response schema'} — the client never sees that status typed; declare it in a response map (and return it, ELYSIA-CORE-03)`)
  if (rm.kind === 'map') { const missing = thrownCodes.filter((c) => !rm.codes.has(c)); if (missing.length) add('schema', 'ELYSIA-TYPE-06', 'high', sf, rm.node, `${where} throws status ${missing.join(', ')}, which the response map does not declare — invisible to the client type`) }
  if (only.has('schema') || only.has('eden') || only.has('openapi')) {
    if (rm.kind !== 'map' && (errCodes.length || new Set(allCodes).size > 1 || (allCodes.length && su.rawReturn)))
      add('schema', 'ELYSIA-TYPE-06', 'high', sf, call.node, `${where} returns status ${[...new Set(allCodes)].join(', ')}${su.rawReturn ? ' and a raw value (200)' : ''} with ${rm.kind === 'none' ? 'no response schema' : 'a single response schema'} — declare response as a map by status, or the client sees the error as unknown`)
    if (rm.kind === 'map') {
      const undeclared = allCodes.filter((c) => !rm.codes.has(c))
      if (undeclared.length) add('schema', 'ELYSIA-TYPE-06', 'high', sf, rm.node, `${where} returns status ${undeclared.join(', ')}, which the response map does not declare`)
      if (su.rawReturn && !rm.codes.has(200)) add('schema', 'ELYSIA-CORE-04', 'high', sf, rm.node, `${where} returns a raw value (sent as 200) but the response map has no 200 — return status(${[...rm.codes].find((c) => c < 300) ?? 201}, value)`)
      const dead = [...rm.codes].filter((c) => c !== 200 && c !== 422 && !allCodes.includes(c) && !su.thrown.has(c))
      if (dead.length && handler) add('openapi', 'ELYSIA-CORE-04', 'candidate', sf, rm.node, `${where} declares ${dead.join(', ')} but no status(${dead[0]}, …) in the handler — documented, never emitted (or emitted by a hook: check)`)
    }
  }
  if (!opts || !ts.isObjectLiteralExpression(opts)) return
  const headers = propValue(objProp(opts, 'headers'))
  if (headers) walk(headers, (n) => {
    if (ts.isPropertyAssignment(n) && /[A-Z]/.test(n.name.getText(sf).replace(/['"]/g, '')) && n.parent?.parent && ts.isCallExpression(n.parent.parent) && /t\.Object|z\.object/.test(n.parent.parent.expression.getText(sf)))
      add('schema', 'ELYSIA-TYPE-03', 'high', sf, n, `${where}: header \`${n.name.getText(sf)}\` has capitals — Elysia lowercases header names, so it never matches`)
  })
  const body = propValue(objProp(opts, 'body'))
  if (body) walk(body, (n) => {
    if (ts.isCallExpression(n) && /^(z|v)\.file$/.test(n.expression.getText(sf)) && !/fileType\(/.test(body.getText(sf)))
      add('schema', 'ELYSIA-TYPE-02', /fileType\(/.test(sf.text) || /\.(refine|check)\(\s*[A-Za-z_$][\w$]*\s*[,)]/.test(body.getText(sf)) ? 'candidate' : 'high', sf, n, `${where}: ${n.expression.getText(sf)}() checks the client-declared content-type — refine with fileType() from elysia (t.File checks the content)`)
  })
  const usesStd = ['body', 'query', 'params', 'headers', 'cookie', 'response'].some((k) => { const v = propValue(objProp(opts, k)); return v && isStandardSchema(v) })
  if (usesStd) stdRoutes.push({ sf, where, node: call.node })
  if (call.name === 'get' && rm.kind !== 'none') {
    const q = propValue(objProp(opts, 'query'))
    const pag = q && /\b(page|limit|offset|cursor|pageSize|perPage)\b/.test(q.getText(sf))
    const r200 = rm.kind === 'map' ? rm.node.properties.find((p) => p.name.getText() === '200') : null
    const shape = rm.kind === 'single' ? rm.node : r200 && propValue(r200)
    if (pag && shape && /^t\.Array\(/.test(shape.getText(sf)))
      add('schema', 'ELYSIA-TYPE-13', 'high', sf, shape, `${where} paginates but answers a bare array — return an envelope { items, total, hasMore }`)
  }
}
if (only.has('schema') || only.has('openapi')) {
  // routes are visited in the route group; make sure they are when route is not selected
  if (!only.has('route') && !only.has('lifecycle')) for (const c of chains) for (const call of c.calls) if (ROUTES.has(call.name)) {
    const { path, handler, opts } = routeParts(call)
    routeSchemaChecks(c.sf, `${call.name.toUpperCase()} ${pathText(c.sf, path)}`, call, isFn(handler) ? handler : null, opts, responseMap(opts), statusUse(isFn(handler) ? handler : null))
  }
}
if (only.has('schema')) {
  // TYPE-03 — any `headers:` schema (route, guard, group, ws) with a capitalised key
  for (const sf of sources) walk(sf, (n) => {
    if (!ts.isPropertyAssignment(n) || n.name.getText(sf) !== 'headers') return
    const v = strip(n.initializer)
    if (!v || !ts.isCallExpression(v) || !/^(t\.Object|z\.object|v\.object)$/.test(v.expression.getText(sf))) return
    const obj = v.arguments[0]
    if (obj && ts.isObjectLiteralExpression(obj)) for (const p of obj.properties)
      if (p.name && /[A-Z]/.test(p.name.getText(sf).replace(/['"]/g, '')))
        add('schema', 'ELYSIA-TYPE-03', 'high', sf, p, `header \`${p.name.getText(sf)}\` has capitals — Elysia lowercases header names, so it never matches`)
  })
  // TYPE-05: guard with a schema key that a later route also declares, without standalone
  for (const c of chains) c.calls.forEach((call, i) => {
    if (call.name !== 'guard') return
    const g = call.args[0]
    if (!g || !ts.isObjectLiteralExpression(g)) return
    const sch = propValue(objProp(g, 'schema'))
    if (sch && ts.isStringLiteralLike(sch) && sch.text === 'standalone') return
    const keys = ['body', 'query', 'params', 'headers', 'cookie', 'response'].filter((k) => objProp(g, k))
    const later = c.calls.slice(i + 1).filter((x) => ROUTES.has(x.name))
    const cb = call.args.find(isFn)
    const inner = cb ? chains.filter((x) => x.top.pos >= cb.pos && x.top.end <= cb.end).flatMap((x) => x.calls.filter((y) => ROUTES.has(y.name))) : []
    for (const r of [...later, ...inner]) {
      const o = routeParts(r).opts
      const clash = keys.filter((k) => objProp(o, k))
      if (clash.length) add('schema', 'ELYSIA-TYPE-05', 'high', c.sf, r.node, `${r.name.toUpperCase()} ${pathText(c.sf, routeParts(r).path)} declares ${clash.join(', ')}, replacing the guard's — add schema: 'standalone' to the guard if both must hold`)
    }
  })
  for (const sf of sources) walk(sf, (n) => {
    if (ts.isPropertyAssignment(n) && n.name.getText(sf) === 'allowUnsafeValidationDetails' && n.initializer.kind === ts.SyntaxKind.TrueKeyword)
      add('schema', 'ELYSIA-TYPE-12', 'high', sf, n, 'allowUnsafeValidationDetails: true is global and publishes the schema shape in every 422 — gate it on the environment')
  })
  // TYPE-01: an interface/type literal with exactly the keys of a t.Object
  const shapes = []
  for (const sf of sources) walk(sf, (n) => {
    if (ts.isCallExpression(n) && n.expression.getText(sf) === 't.Object' && n.arguments[0] && ts.isObjectLiteralExpression(n.arguments[0])) {
      const keys = n.arguments[0].properties.map((p) => p.name?.getText(sf)).filter(Boolean).sort()
      if (keys.length >= 3) shapes.push(keys.join(','))
    }
  })
  const shapeSet = new Set(shapes)
  for (const sf of sources) walk(sf, (n) => {
    const members = ts.isInterfaceDeclaration(n) ? n.members : ts.isTypeAliasDeclaration(n) && ts.isTypeLiteralNode(n.type) ? n.type.members : null
    if (!members) return
    const keys = members.map((m) => m.name?.getText(sf)).filter(Boolean).sort().join(',')
    if (shapeSet.has(keys)) add('schema', 'ELYSIA-TYPE-01', 'candidate', sf, n, `\`${n.name.getText(sf)}\` re-declares by hand the keys of a t.Object schema (${keys}) — derive it: typeof Schema.static`)
  })
}

// ================= GROUP: openapi =================
if (only.has('openapi')) {
  const oapiCalls = []
  for (const sf of sources) walk(sf, (n) => { if (ts.isCallExpression(n) && ts.isIdentifier(n.expression) && n.expression.text === 'openapi') oapiCalls.push({ sf, n }) })
  for (const { sf, n } of oapiCalls) {
    const cfg = n.arguments[0]
    const mjs = propValue(objProp(cfg, 'mapJsonSchema'))
    const missing = vendorsWithoutJsonSchema()
    if (stdRoutes.length && missing.length && !mjs)
      add('openapi', 'ELYSIA-TYPE-07', 'high', sf, n, `openapi() has no mapJsonSchema, and ${stdRoutes.length} route(s) use ${missing.join('/')} (no Standard JSON Schema): ${stdRoutes.slice(0, 3).map((r) => r.where).join(', ')} — their schemas are missing from the spec`)
    const zodMap = mjs && propValue(objProp(mjs, 'zod'))
    if (zodMap && (zodMajor === null || zodMajor >= 4) && !/io\s*:\s*['"]input['"]/.test(zodMap.getText(sf)))
      add('openapi', 'ELYSIA-TYPE-07', 'high', sf, zodMap, 'mapJsonSchema.zod with Zod 4 — it is called without an input/output hint, so request bodies get the output view (defaults required, additionalProperties false); remove it (Zod 4 is read natively) or pass io: "input"')
    const exclude = objProp(cfg, 'exclude')
    let cond = n.parent; let guarded = false
    while (cond && !ts.isSourceFile(cond)) { if (ts.isConditionalExpression(cond) || ts.isIfStatement(cond) || (ts.isBinaryExpression(cond) && cond.operatorToken.kind === ts.SyntaxKind.AmpersandAmpersandToken)) guarded = true; cond = cond.parent }
    if (!guarded && !objProp(cfg, 'enabled')) add('openapi', 'ELYSIA-TYPE-19', 'candidate', sf, n, 'the spec and UI are served in every environment, with no auth — gate it with enabled per environment, or an onRequest guard on the prefix')
    void exclude
  }
  if (!oapiCalls.length && chains.some((c) => c.calls.some((x) => ROUTES.has(x.name))) && (projectImports.has('@elysia/openapi') || pkgDeps['@elysia/openapi']))
    add('openapi', 'no ID — OpenAPI doc', 'candidate', sources[0], sources[0], '@elysia/openapi is a dependency but openapi() is never mounted')
  // routes with no detail when the spec exists
  if (oapiCalls.length) {
    const bare = []
    for (const c of chains) {
      const instDetail = !!objProp(ctorCfg(c), 'detail') || !!objProp(ctorCfg(c), 'tags')
      for (const call of c.calls) if (ROUTES.has(call.name) && call.name !== 'ws' && !instDetail && !objProp(routeParts(call).opts, 'detail')) bare.push({ c, call })
    }
    const noId = []
    for (const c of chains) for (const call of c.calls) if (ROUTES.has(call.name) && call.name !== 'ws') {
      const d = propValue(objProp(routeParts(call).opts, 'detail'))
      if (!(d && objProp(d, 'operationId')) && !(d && objProp(d, 'hide'))) noId.push({ c, call })
    }
    if (noId.length) add('openapi', 'ELYSIA-TYPE-18', 'candidate', noId[0].c.sf, noId[0].call.node, `${noId.length} route(s) rely on generated operationIds, which can collide — set detail.operationId if a code generator reads the spec (e.g. ${noId.slice(0, 3).map(({ c, call }) => call.name.toUpperCase() + ' ' + pathText(c.sf, routeParts(call).path)).join(', ')})`)
    const authPlugins = chains.filter((c) => isPlugin(c) && c.calls.some((x) => /^(resolve|onBeforeHandle|derive|macro)$/.test(x.name) && /authoriz|bearer|token|session|jwt|status\(\s*401/i.test(x.node.getText(c.sf))))
    const anySecurity = sources.some((s) => /\bsecurity\s*:/.test(s.text))
    if (authPlugins.length && !anySecurity) add('openapi', 'ELYSIA-TYPE-20', 'high', authPlugins[0].sf, authPlugins[0].top, `routes are protected by \`${authPlugins[0].varName}\` but no detail declares security — the spec describes them as public; add a securityScheme and security on the protected module`)
    if (bare.length) add('openapi', 'no ID — OpenAPI doc, detail', 'candidate', bare[0].c.sf, bare[0].call.node, `${bare.length} route(s) have no detail (summary, tags) and their instance sets none — e.g. ${bare.slice(0, 3).map(({ c, call }) => call.name.toUpperCase() + ' ' + pathText(c.sf, routeParts(call).path)).join(', ')}`)
  }
}

// ================= GROUP: eden =================
if (only.has('eden')) {
  const clients = new Map() // name -> { throws: bool, parseDate: bool|undefined, sf, node }
  for (const sf of sources) {
    walk(sf, (n) => {
      if (ts.isCallExpression(n) && ts.isIdentifier(n.expression) && n.expression.text === 'edenTreaty')
        add('eden', 'no ID — Eden doc, Treaty 1', 'high', sf, n, 'edenTreaty is Eden Treaty 1 (legacy) — use treaty from @elysia/eden')
      if (!(ts.isVariableDeclaration(n) && n.initializer && ts.isIdentifier(n.name))) return
      const init = strip(n.initializer)
      if (!(ts.isCallExpression(init) && ts.isIdentifier(init.expression) && init.expression.text === 'treaty')) return
      const cfg = init.arguments[1]
      const pd = propValue(objProp(cfg, 'parseDate'))
      const th = propValue(objProp(cfg, 'throwHttpError'))
      clients.set(n.name.text, { sf, node: init, throws: !!th && th.kind !== ts.SyntaxKind.FalseKeyword })
      const onResp = propValue(objProp(cfg, 'onResponse'))
      if (onResp) {
        const fns = ts.isArrayLiteralExpression(onResp) ? onResp.elements : [onResp]
        for (const f of fns) if (isFn(f)) {
          let returnsValue = f.body && !ts.isBlock(f.body) && f.body.kind !== ts.SyntaxKind.UndefinedKeyword && !(ts.isIdentifier(f.body) && f.body.text === 'undefined') && !ts.isVoidExpression(f.body) && !(ts.isCallExpression(f.body) && /console\.|log/.test(f.body.expression.getText(sf)))
          if (f.body && ts.isBlock(f.body)) walk(f.body, (x) => { if (ts.isReturnStatement(x) && x.expression && !(ts.isIdentifier(x.expression) && x.expression.text === 'undefined')) returnsValue = true })
          if (returnsValue) add('eden', 'ELYSIA-TYPE-17', 'high', sf, f, 'onResponse returns a value — any non-null return replaces data and skips error detection; an observer returns undefined')
        }
      }
      const isLocal = init.arguments[0] && ts.isIdentifier(init.arguments[0]) && elysiaVars.has(init.arguments[0].text)
      if (usesQuery && !isTest(sf) && !isLocal && !(pd && pd.kind === ts.SyntaxKind.FalseKeyword))
        add('eden', 'ELYSIA-TYPE-10', 'high', sf, init, `treaty client \`${n.name.text}\` keeps parseDate on (the default) in a TanStack Query app — Date objects defeat structural sharing; pass parseDate: false`)
    })
    for (const i of importsOf(sf)) {
      const cl = i.decl.importClause
      if (!cl || cl.isTypeOnly) continue
      const named = cl.namedBindings && ts.isNamedImports(cl.namedBindings) ? cl.namedBindings.elements : []
      for (const e of named) if (/^App$|Server$|^Api$/.test(e.name.text) && !e.isTypeOnly && /treaty\(|treaty</.test(sf.text) && !/^(elysia|@elysia)/.test(i.from))
        add('eden', 'ELYSIA-TYPE-14', 'high', sf, e, `\`${e.name.text}\` is imported as a value next to treaty — import type, or the server code lands in the client bundle`)
    }
  }
  const isEdenCall = (e) => {
    e = strip(e)
    if (!e || !ts.isCallExpression(e)) return false
    let cur = e
    while (cur && (ts.isCallExpression(cur) || ts.isPropertyAccessExpression(cur) || ts.isElementAccessExpression(cur))) cur = strip(cur.expression)
    return cur && ts.isIdentifier(cur) && clients.has(cur.text) ? clients.get(cur.text) : false
  }
  for (const sf of sources) walk(sf, (n) => {
    // TYPE-15: an Eden error read through instanceof or .message
    if (ts.isBinaryExpression(n) && n.operatorToken.kind === ts.SyntaxKind.InstanceOfKeyword && /^(error|err|e)$/.test(n.left.getText(sf)) && n.right.getText(sf) === 'Error' && clients.size && /treaty|unwrap|api\./.test(sf.text))
      add('eden', 'ELYSIA-TYPE-15', 'candidate', sf, n, 'an Eden error is always instanceof Error (EdenFetchError) — narrow on error.status instead')
    if (ts.isPropertyAccessExpression(n) && n.name.text === 'message' && /^(error|err|e|\w+\.error)$/.test(n.expression.getText(sf)) && clients.size && /\{\s*data\s*,\s*error\s*\}|\.error\b/.test(sf.text) && /api\.|treaty|unwrap/.test(sf.text) && !/onError|catch\s*\(/.test(n.parent?.getText(sf) ?? ''))
      add('eden', 'ELYSIA-TYPE-15', 'candidate', sf, n, `${n.getText(sf)} on an Eden error is String(value) — usually "[object Object]"; read error.value after narrowing error.status`)
    // TYPE-08: { data } destructured from an Eden call without error
    if (ts.isVariableDeclaration(n) && n.initializer && ts.isObjectBindingPattern(n.name)) {
      const cl = isEdenCall(n.initializer)
      if (cl && !cl.throws) {
        const keys = n.name.elements.map((el) => (el.propertyName ?? el.name).getText(sf))
        if (keys.includes('data') && !keys.includes('error') && !keys.includes('status'))
          add('eden', 'ELYSIA-TYPE-08', 'high', sf, n, 'Eden result: `data` taken without `error` — data is null on any status >= 300')
      }
    }
    // TYPE-09: queryFn / mutationFn that never throws
    if ((ts.isPropertyAssignment(n) || ts.isMethodDeclaration(n)) && /^(queryFn|mutationFn)$/.test(n.name.getText(sf))) {
      const fn = ts.isMethodDeclaration(n) ? n : strip(n.initializer)
      if (!isFn(fn)) return
      let edenClient = null; let throws = false
      walk(fn, (x) => { const c = ts.isCallExpression(x) && isEdenCall(x); if (c) edenClient ??= c; if (ts.isThrowStatement(x)) throws = true })
      if (!edenClient && fn.body && !ts.isBlock(fn.body) && ts.isCallExpression(strip(fn.body))) {
        // queryFn: () => getOrders()  — a helper; check the helper if it is local
        const callee = strip(fn.body).expression
        if (ts.isIdentifier(callee)) for (const s2 of sources) walk(s2, (d) => {
          if ((ts.isFunctionDeclaration(d) && d.name?.text === callee.text) || (ts.isVariableDeclaration(d) && d.name.getText(s2) === callee.text && isFn(strip(d.initializer ?? d)))) {
            const body = ts.isFunctionDeclaration(d) ? d : strip(d.initializer)
            walk(body, (x) => { const c = ts.isCallExpression(x) && isEdenCall(x); if (c) edenClient ??= c; if (ts.isThrowStatement(x)) throws = true })
          }
        })
      }
      if (edenClient && !edenClient.throws && !throws)
        add('eden', 'ELYSIA-TYPE-09', 'high', sf, n, `${n.name.getText(sf)} calls Eden and never throws — the query ends in success with the error inside data: no isError, no retry, no error boundary`)
      if (n.name.getText(sf) === 'queryFn' && ts.isObjectLiteralExpression(n.parent) && !objProp(n.parent, 'retry') && (edenClient || /unwrap\(/.test(fn.getText(sf))) && (throws || edenClient?.throws || /unwrap\(/.test(fn.getText(sf)))) {
        const globalRetry = sources.some((s) => /defaultOptions[\s\S]{0,200}retry\s*:/.test(s.text))
        if (!globalRetry) add('eden', 'ELYSIA-TYPE-16', 'candidate', sf, n, 'this query throws Eden errors with the default retry — 4xx (404, 401, 422) are retried three times; retry: (n, e) => e.status >= 500 && n < 3')
      }
    }
  })
  if (!clients.size && projectImports.has('@elysia/eden') === false && sources.some((sf) => /treaty/.test(sf.text)))
    add('eden', 'no ID', 'candidate', sources[0], sources[0], 'treaty is used but no client variable was found — the scan could not follow it')
}

// ================= GROUP: lifecycle (elysia-diagnose) =================
if (only.has('lifecycle')) {
  for (const c of chains) {
    const { sf } = c
    const plugin = isPlugin(c)
    const endsScoped = c.calls.some((x) => x.name === 'as')
    const cfg = ctorCfg(c)
    if (plugin) {
      for (const call of c.calls) {
        if (!SCOPABLE.has(call.name)) continue
        const first = call.args[0]
        const asP = first && ts.isObjectLiteralExpression(first) && objProp(first, 'as')
        if (asP || endsScoped) continue
        const auth = /authoriz|bearer|token|session|cookie|jwt|status\(\s*40[13]/i.test(call.node.getText(sf))
        add('lifecycle', 'ELYSIA-LIFE-01', auth || /^(onBeforeHandle|resolve)$/.test(call.name) ? 'high' : 'candidate', sf, call.node,
          `plugin \`${c.varName}\`: .${call.name}() has no scope — local by default, it does not reach the routes of the instance that .use()s it${auth ? ' (this looks like auth: the consumer\'s routes are open)' : ''}`)
      }
      for (const call of c.calls) if (call.name === 'guard' && call.args[0] && ts.isObjectLiteralExpression(call.args[0]) && !objProp(call.args[0], 'as') && !endsScoped && (objProp(call.args[0], 'beforeHandle') || objProp(call.args[0], 'resolve')))
        add('lifecycle', 'ELYSIA-LIFE-01', 'candidate', sf, call.node, `plugin \`${c.varName}\`: guard with hooks and no as — local by default`)
      const users = usesOf(c)
      if (users.length >= 2 && !objProp(cfg, 'name') && c.calls.some((x) => SCOPABLE.has(x.name) || x.name === 'onRequest'))
        add('lifecycle', 'ELYSIA-LIFE-03', 'high', sf, c.top, `plugin \`${c.varName}\` is .use()d by ${users.length} instances and has no name — its hooks run once per use; give it new Elysia({ name })`)
    }
    for (const call of c.calls) {
      const fn = call.args.find(isFn)
      if (call.name === 'derive' && fn && /authoriz|bearer|token|session|jwt|cookie|role|permission/i.test(fn.getText(sf)))
        add('lifecycle', 'ELYSIA-LIFE-02', 'high', sf, call.node, '.derive() reads credentials — derive runs before validation; an access decision belongs in resolve or macro.resolve')
      if (call.name === 'onRequest' && fn) {
        const p0 = fn.parameters[0]
        const bad = p0 && ts.isObjectBindingPattern(p0.name) ? p0.name.elements.map((e) => (e.propertyName ?? e.name).getText(sf)).filter((k) => /^(body|query|params|cookie|headers|path|route)$/.test(k)) : []
        if (bad.length) add('lifecycle', 'ELYSIA-LIFE-04', 'high', sf, p0, `onRequest reads ${bad.join(', ')} — its PreContext has only request, set, store, status, redirect, server and decorators`)
      }
      if (call.name === 'macro') walk(call.node, (n) => { if (ts.isThrowStatement(n)) add('lifecycle', 'ELYSIA-LIFE-10', 'high', sf, n, 'a macro throws to deny access — it becomes 500 and leaves the type; return status(401|403, …)') })
      if (usesOtel && (SCOPABLE.has(call.name) || call.name === 'onRequest') && call.args.some((a) => ts.isArrowFunction(a) || (ts.isFunctionExpression(a) && !a.name)))
        add('lifecycle', 'ELYSIA-LIFE-11', 'high', sf, call.node, `.${call.name}() with an anonymous function in an app traced by OpenTelemetry — the span is named "anonymous"; use a named function`)
      if (call.name === 'decorate') {
        const key = call.args[0] && ts.isStringLiteralLike(call.args[0]) ? call.args[0].text : null
        if (key) for (const s2 of sources) walk(s2, (x) => {
          if (ts.isBinaryExpression(x) && x.operatorToken.kind === ts.SyntaxKind.EqualsToken && new RegExp(`(^|\\.)${key}(\\.|\\[)`).test(x.left.getText(s2)) && !/store\./.test(x.left.getText(s2)))
            add('lifecycle', 'ELYSIA-LIFE-05', 'candidate', s2, x, `\`${key}\` comes from decorate (shared, immutable by contract) and is assigned here — mutable state is .state()`)
        })
      }
    }
  }
  for (const sf of sources) walk(sf, (n) => {
    if (ts.isCallExpression(n) && ts.isIdentifier(n.expression) && n.expression.text === 'cors') {
      const cfg = n.arguments[0]
      if (!objProp(cfg, 'origin'))
        add('lifecycle', 'ELYSIA-LIFE-12', 'high', sf, n, 'cors() with the default origin — it reflects any origin, with credentials; restrict origin to a list or regex')
    }
    if (ts.isArrowFunction(n) && n.parameters.length === 1 && /^app\b/.test(n.parameters[0].name.getText(sf)) && /^app\s*\.\s*\w+\(/.test(n.body.getText(sf).trim()) && n.parent && ts.isCallExpression(n.parent) && /\.use$/.test(n.parent.expression.getText(sf)))
      add('lifecycle', 'ELYSIA-LIFE-07', 'candidate', sf, n, 'a plugin written as an (app) => app callback — make it a new Elysia() instance (scope and dedup work on instances)')
  })
}

// ---------- report ----------
for (let i = findings.length - 1; i >= 0; i--) if (!only.has(findings[i].group)) findings.splice(i, 1)
const order = ['route', 'lifecycle', 'schema', 'openapi', 'eden']
findings.sort((a, b) => order.indexOf(a.group) - order.indexOf(b.group) || (a.confidence === b.confidence ? 0 : a.confidence === 'high' ? -1 : 1) || a.file.localeCompare(b.file) || a.line - b.line)
if (asJson) { console.log(JSON.stringify({ root, scanned: files.length, chains: chains.length, findings }, null, 1)); process.exit(0) }
console.log(`scanned ${files.length} TypeScript files · ${chains.length} Elysia chains · groups: ${[...only].join(', ')}`)
if (!files.length) { console.log('   (no TypeScript files under ' + root + ')'); process.exit(0) }
for (const g of order) {
  if (!only.has(g)) continue
  const fs_ = findings.filter((f) => f.group === g)
  console.log(`\n== ${g}: ${fs_.length} finding(s)`)
  for (const f of fs_) console.log(`   [${f.confidence}] ${f.id} — ${f.file}:${f.line}\n      ${f.message}`)
  if (!fs_.length) console.log('   (nothing this scan can see — not the same as "no defect")')
}
