#!/usr/bin/env node
// Drizzle static scan over a project's TypeScript, on the TypeScript compiler API (AST, not regex).
//
//   node drizzle-scan.mjs <dir> [--only schema,query,mutation,zod] [--json]
//
// Each finding names the DRZ-* rule, file:line and a confidence:
//   high      — the shape is the defect (an update chain with no .where()).
//   candidate — the shape is suspicious; confirm by reading (a select followed by a guarded insert).
// The scan never claims a defect is absent: it reports what it could see.
// `typescript` is resolved from the scanned project's node_modules, then from next to this script.
import { createRequire } from 'node:module'
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs'
import { join, relative, resolve, dirname } from 'node:path'

const args = process.argv.slice(2)
const root = resolve(args.find((a) => !a.startsWith('--')) ?? '.')
const onlyArg = args.includes('--only') ? args[args.indexOf('--only') + 1] : 'schema,query,mutation,zod'
const only = new Set(onlyArg.split(','))
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
;(function walk(dir) {
  let entries = []
  try { entries = readdirSync(dir) } catch { return }
  for (const e of entries) {
    if (SKIP.has(e) || e.startsWith('.')) continue
    const p = join(dir, e)
    let s; try { s = statSync(p) } catch { continue }
    if (s.isDirectory()) walk(p)
    else if (/\.(ts|tsx|mts|cts)$/.test(e) && !/\.d\.ts$/.test(e)) files.push(p)
  }
})(root)

const sources = files.map((f) => ts.createSourceFile(f, readFileSync(f, 'utf8'), ts.ScriptTarget.Latest, true,
  f.endsWith('x') ? ts.ScriptKind.TSX : ts.ScriptKind.TS))

const findings = []
const add = (group, id, conf, sf, node, msg) => {
  const { line } = sf.getLineAndCharacterOfPosition(node.getStart(sf))
  findings.push({ group, id, confidence: conf, file: relative(root, sf.fileName), line: line + 1, message: msg })
}
const text = (sf, n) => n.getText(sf).replace(/\s+/g, ' ').slice(0, 110)
const isTest = (sf) => /\.(test|spec)\.[cm]?tsx?$/.test(sf.fileName)

// ---------- AST helpers ----------
const walk = (node, fn, parents = []) => {
  fn(node, parents)
  ts.forEachChild(node, (c) => walk(c, fn, [...parents, node]))
}
// a call chain: db.update(t).set({}).where(x) -> { root: 'db', calls: [{name:'update',args},{name:'set'},...] }
function chainOf(call) {
  const calls = []
  let cur = call
  while (cur) {
    if (ts.isCallExpression(cur)) {
      const e = cur.expression
      if (ts.isPropertyAccessExpression(e)) { calls.unshift({ name: e.name.text, args: cur.arguments, node: cur }); cur = e.expression; continue }
      if (ts.isIdentifier(e)) { calls.unshift({ name: e.text, args: cur.arguments, node: cur }); return { root: null, calls } }
      return { root: null, calls }
    }
    if (ts.isPropertyAccessExpression(cur)) {
      // db.query.users.findMany — fold property names into the call list as markers
      calls.unshift({ name: '.' + cur.name.text, args: [], node: cur }); cur = cur.expression; continue
    }
    if (ts.isIdentifier(cur)) return { root: cur.text, calls }
    if (cur.kind === ts.SyntaxKind.ThisKeyword) return { root: 'this', calls }
    if (ts.isParenthesizedExpression(cur) || ts.isAwaitExpression(cur) || ts.isNonNullExpression(cur)) { cur = cur.expression; continue }
    return { root: null, calls }
  }
  return { root: null, calls }
}
const isChainTop = (call) => !(call.parent && ts.isPropertyAccessExpression(call.parent) && call.parent.expression === call)
const names = (ch) => ch.calls.map((c) => c.name)
const DB_ROOTS = new Set(['db', 'tx', 'trx', 'database', 'client', 'conn'])
const isDbRoot = (ch, extra = new Set()) => ch.root && (DB_ROOTS.has(ch.root) || extra.has(ch.root) ||
  (ch.root === 'this' && ch.calls[0]?.name === '.db'))
const READ = new Set(['select', 'selectDistinct', 'findMany', 'findFirst', 'execute', '$count'])
const WRITE = new Set(['insert', 'update', 'delete'])
const isQueryChain = (ch) => names(ch).some((n) => READ.has(n) || WRITE.has(n))
const enclosingFn = (parents) => [...parents].reverse().find((p) => ts.isFunctionLike(p))
const objProp = (obj, key) => obj && ts.isObjectLiteralExpression(obj)
  ? obj.properties.find((p) => (ts.isPropertyAssignment(p) || ts.isShorthandPropertyAssignment(p)) && p.name && p.name.getText() === key)
  : undefined
const firstArgTable = (ch, method) => {
  const c = ch.calls.find((x) => x.name === method)
  const a = c?.args?.[0]
  return a && ts.isIdentifier(a) ? a.text : null
}
const readTable = (ch) => firstArgTable(ch, 'from') ??
  (ch.calls.find((c, i) => c.name === '.query' && ch.calls[i + 1])?.name ? ch.calls[ch.calls.findIndex((c) => c.name === '.query') + 1]?.name.slice(1) : null)

// ---------- schema model: tables, columns, relations ----------
const tables = new Map() // name -> { file, line, exported, columns: Map(col -> { nullable, notNull, type, jsonType, hasDefault, identity }), indexes: [] }
const relationExports = new Set()
const enumExports = new Set()
for (const sf of sources) {
  walk(sf, (node, parents) => {
    if (!ts.isVariableDeclaration(node) || !node.initializer || !ts.isCallExpression(node.initializer)) return
    const callee = node.initializer.expression
    const calleeName = ts.isIdentifier(callee) ? callee.text : ts.isPropertyAccessExpression(callee) ? callee.name.text : ''
    const stmt = parents.find((p) => ts.isVariableStatement(p))
    const exported = !!stmt?.modifiers?.some((m) => m.kind === ts.SyntaxKind.ExportKeyword)
    const name = node.name.getText(sf)
    if (calleeName === 'relations' && exported) relationExports.add(name)
    if (calleeName === 'pgEnum' && exported) enumExports.add(name)
    if (!/^(pgTable|table|mysqlTable|sqliteTable)$/.test(calleeName)) return
    const [, colsArg, extraArg] = node.initializer.arguments
    const cols = new Map()
    let colObj = colsArg
    if (colObj && (ts.isArrowFunction(colObj))) colObj = ts.isParenthesizedExpression(colObj.body) ? colObj.body.expression : colObj.body
    if (colObj && ts.isObjectLiteralExpression(colObj)) {
      for (const p of colObj.properties) {
        if (ts.isSpreadAssignment(p)) {
          // ...timestamps: resolve a same-file or imported object of columns by name
          const spreadName = p.expression.getText(sf)
          for (const s2 of sources) walk(s2, (n2) => {
            if (ts.isVariableDeclaration(n2) && n2.name.getText(s2) === spreadName && n2.initializer && ts.isObjectLiteralExpression(n2.initializer))
              for (const q of n2.initializer.properties) if (ts.isPropertyAssignment(q)) cols.set(q.name.getText(s2), describeColumn(q.initializer.getText(s2)))
          })
          continue
        }
        if (!ts.isPropertyAssignment(p)) continue
        cols.set(p.name.getText(sf), describeColumn(p.initializer.getText(sf)))
      }
    }
    const indexes = []
    if (extraArg) walk(extraArg, (n) => {
      if (ts.isCallExpression(n) && ts.isPropertyAccessExpression(n.expression) && n.expression.name.text === 'on') {
        const head = n.expression.expression
        const kind = ts.isCallExpression(head) ? head.expression.getText(sf) : ''
        if (/^(index|uniqueIndex)$/.test(kind))
          indexes.push({ unique: kind === 'uniqueIndex', cols: n.arguments.map((a) => a.getText(sf).split('.').pop()), node: n })
      }
    })
    tables.set(name, { sf, node, exported, columns: cols, indexes })
  })
}
function describeColumn(src) {
  const type = (src.match(/^(?:\w+\.)?(\w+)\(/) || [])[1] || ''
  return {
    type,
    notNull: /\.notNull\(\)|\.primaryKey\(\)/.test(src),
    hasDefault: /\.(default|\$default|\$defaultFn|defaultNow|\$onUpdate|generatedAlwaysAsIdentity|generatedByDefaultAsIdentity)\(/.test(src),
    identity: /generated(Always|ByDefault)AsIdentity|serial\(/.test(src) || type === 'serial',
    jsonType: /^(json|jsonb)$/.test(type) && /\.\$type</.test(src),
    temporal: /^(timestamp|date|time)$/.test(type) && !/mode:\s*['"]string['"]/.test(src),
    secret: false,
  }
}
for (const [, t] of tables) for (const [c, d] of t.columns) d.secret = /password|hash|secret|token|apikey|api_key/i.test(c)
const tableColumnSet = (n) => new Set(tables.get(n)?.columns.keys() ?? [])

// ---------- GROUP: schema ----------
if (only.has('schema') || only.has('query')) {
  // S1 — client registration: drizzle({ schema }) must carry the relations
  const drizzleCalls = []
  for (const sf of sources) walk(sf, (n) => {
    if (ts.isCallExpression(n) && ts.isIdentifier(n.expression) && n.expression.text === 'drizzle') drizzleCalls.push({ sf, n })
  })
  if (relationExports.size && drizzleCalls.length) {
    for (const { sf, n } of drizzleCalls) {
      const opts = n.arguments.find((a) => ts.isObjectLiteralExpression(a) && objProp(a, 'schema')) ?? n.arguments.find((a) => ts.isObjectLiteralExpression(a))
      const sp = objProp(opts, 'schema')
      if (!sp) { if (!isTest(sf)) add('query', 'DRZ-REL-05', 'high', sf, n, `drizzle(...) has no { schema } — db.query.* is undefined, yet ${relationExports.size} relations() are exported`); continue }
      const val = ts.isShorthandPropertyAssignment(sp) ? sp.name : sp.initializer
      if (ts.isObjectLiteralExpression(val)) {
        const keys = val.properties.map((p) => ts.isSpreadAssignment(p) ? '...' + p.expression.getText(sf) : p.name?.getText(sf))
        if (keys.some((k) => k.startsWith('...'))) continue
        const missing = [...relationExports].filter((r) => !keys.includes(r))
        if (missing.length) add('query', 'DRZ-REL-05', 'high', sf, val, `the schema object handed to drizzle() lacks ${missing.length} exported relations (${missing.slice(0, 4).join(', ')}${missing.length > 4 ? ', …' : ''}) — \`with\` on them throws at runtime`)
      }
    }
  }
}
if (only.has('schema')) {
  for (const [name, t] of tables) {
    if (!t.exported) add('schema', 'DRZ-CORE-02', 'high', t.sf, t.node, `table \`${name}\` is not exported — drizzle-kit does not see it`)
    for (const a of t.indexes) for (const b of t.indexes) {
      if (a === b || a.unique || a.cols.length >= b.cols.length) continue
      if (a.cols.every((c, i) => b.cols[i] === c)) add('schema', 'no ID — schema satellite § 1.4', 'candidate', t.sf, a.node, `index (${a.cols}) on \`${name}\` is a strict prefix of (${b.cols}) — write cost, no reader it alone serves`)
    }
  }
  for (const sf of sources) walk(sf, (n, parents) => {
    if (!ts.isCallExpression(n) || !ts.isPropertyAccessExpression(n.expression)) return
    const m = n.expression.name.text
    if (m === 'default' && n.arguments[0] && /^(new Date|Date\.now|crypto\.|randomUUID|uuid|nanoid|cuid)/.test(n.arguments[0].getText(sf)))
      add('schema', 'DRZ-SCHEMA-04', 'high', sf, n, `.default(${text(sf, n.arguments[0])}) freezes one value into the migration SQL — use $defaultFn/$default, or defaultNow()/defaultRandom()`)
    if (m === 'references' && n.arguments[0] && ts.isArrowFunction(n.arguments[0]) && !n.arguments[0].type) {
      const target = n.arguments[0].body.getText(sf).split('.')[0]
      const decl = parents.find((p) => ts.isVariableDeclaration(p))
      if (decl && decl.name.getText(sf) === target) add('schema', 'DRZ-SCHEMA-02', 'high', sf, n, `self-reference to \`${target}\` without an AnyPgColumn return type`)
    }
  })
}

// ---------- GROUP: query ----------
const LOOP_METHODS = new Set(['map', 'forEach', 'flatMap', 'reduce', 'filter', 'some', 'every'])
if (only.has('query')) {
  for (const sf of sources) {
    walk(sf, (n, parents) => {
      if (!ts.isCallExpression(n) || !isChainTop(n)) return
      const ch = chainOf(n)
      const ns = names(ch)
      // N+1: a query chain inside a loop body or a .map/.forEach callback
      if (isDbRoot(ch) && isQueryChain(ch) && !isTest(sf)) {
        const fnIdx = [...parents].reverse().findIndex((p) => ts.isFunctionLike(p))
        const scope = fnIdx < 0 ? parents : parents.slice(parents.length - 1 - fnIdx)
        const loop = parents.slice().reverse().find((p, i, arr) => {
          if (ts.isForStatement(p) || ts.isForOfStatement(p) || ts.isForInStatement(p) || ts.isWhileStatement(p) || ts.isDoStatement(p)) return true
          if (ts.isFunctionLike(p) && p.parent && ts.isCallExpression(p.parent) && ts.isPropertyAccessExpression(p.parent.expression) && LOOP_METHODS.has(p.parent.expression.name.text)) return true
          return false
        })
        if (loop && (ns.some((x) => READ.has(x))))
          add('query', 'DRZ-RQB-01', 'high', sf, n, `a read runs once per item of a loop (${text(sf, n).slice(0, 70)}) — fold it into \`with\`, or one inArray query grouped in a Map`)
      }
      // RQB where must be a callback
      const fm = ch.calls.find((c) => c.name === 'findMany' || c.name === 'findFirst')
      if (fm && fm.args[0] && ts.isObjectLiteralExpression(fm.args[0])) {
        walk(fm.args[0], (m, mp) => {
          if (!ts.isPropertyAssignment(m)) return
          const key = m.name.getText(sf)
          if (key === 'where' && ts.isCallExpression(m.initializer))
            add('query', 'DRZ-RQB-03', 'high', sf, m, `RQB \`where\` is a call (${text(sf, m.initializer).slice(0, 50)}), not the (table, { eq }) => … callback`)
          if (key === 'offset' && mp.some((p) => ts.isPropertyAssignment(p) && p.name.getText(sf) === 'with'))
            add('query', 'DRZ-RQB-02', 'high', sf, m, '`offset` inside a nested `with` — a type error, and ignored at runtime if cast')
          if (key === 'extras') {
            let obj = m.initializer
            const own = new Set([readTable(ch)].filter(Boolean))
            if (ts.isArrowFunction(obj)) { if (obj.parameters[0]) own.add(obj.parameters[0].name.getText(sf)); obj = ts.isParenthesizedExpression(obj.body) ? obj.body.expression : obj.body }
            if (ts.isObjectLiteralExpression(obj)) for (const e of obj.properties) {
              if (!ts.isPropertyAssignment(e)) continue
              if (ts.isArrowFunction(e.initializer) || ts.isFunctionExpression(e.initializer))
                add('query', 'no ID — reads satellite § 3.5', 'high', sf, e, `extras field \`${e.name.getText(sf)}\` is a per-field callback — v1 syntax; on 0.x use an aliased sql value or one function returning the object`)
              else if (!/\.as\(/.test(e.initializer.getText(sf)))
                add('query', 'DRZ-RQB-04', 'high', sf, e, `extras field \`${e.name.getText(sf)}\` has no .as(name)`)
              else if (/select/i.test(e.initializer.getText(sf)) && [...e.initializer.getText(sf).matchAll(/\$\{\s*([A-Za-z_]\w*)(?:\.\w+)?\s*\}/g)].some((x) => !own.has(x[1])))
                add('query', 'no ID — reads satellite § 3.5', 'candidate', sf, e, `extras field \`${e.name.getText(sf)}\` interpolates Drizzle columns in a subquery — inside extras they are re-aliased to the root table`)
            }
          }
        })
        if (fm.name === 'findMany' && !objProp(fm.args[0], 'limit') && !isTest(sf))
          add('query', 'no ID — reads satellite § 0.3', 'candidate', sf, n, `findMany with no limit on \`${readTable(ch) ?? '?'}\` — bounded by design, or a listing that grows with the data?`)
      } else if (fm && fm.name === 'findMany' && !fm.args[0] && !isTest(sf)) {
        add('query', 'no ID — reads satellite § 0.3', 'candidate', sf, n, `findMany() with no options on \`${readTable(ch) ?? '?'}\` — reads the whole table`)
      }
      // raw SQL
      if (ns.includes('raw') && ch.root === 'sql') {
        const a = ch.calls.find((c) => c.name === 'raw')?.args[0]
        if (a && !ts.isStringLiteral(a) && !ts.isNoSubstitutionTemplateLiteral(a))
          add('query', 'DRZ-QUERY-02', 'high', sf, n, `sql.raw(${text(sf, a).slice(0, 50)}) inserts text as SQL — a user value here is SQL injection`)
      }
      // offset pagination without a unique tiebreaker
      if (ns.includes('offset') && ns.includes('orderBy') && isDbRoot(ch)) {
        const ob = ch.calls.find((c) => c.name === 'orderBy')
        if (!ob.args.some((a) => /\.id\b|\bid\)/.test(a.getText(sf))))
          add('query', 'no ID — reads satellite § 5.1', 'candidate', sf, ob.node, 'offset pagination ordered without the primary key as a tiebreaker — rows with equal sort keys can swap between pages')
      }
    })
    // sql`` with an interpolation inside where(): candidates for DRZ-QUERY-03
    walk(sf, (n, parents) => {
      if (ts.isTaggedTemplateExpression(n) && n.tag.getText(sf) === 'sql' && ts.isTemplateExpression(n.template)) {
        const inWhere = parents.some((p) => ts.isCallExpression(p) && ts.isPropertyAccessExpression(p.expression) && p.expression.name.text === 'where' &&
          p.arguments.some((a) => n.getStart(sf) >= a.getStart(sf) && n.getEnd() <= a.getEnd()))
        if (inWhere) add('query', 'DRZ-QUERY-03', 'candidate', sf, n, `sql\`\` as a filter (${text(sf, n).slice(0, 60)}) — does the query builder express it?`)
      }
    })
  }
}

// ---------- GROUP: mutation ----------
if (only.has('mutation')) {
  for (const sf of sources) {
    const fileText = sf.getFullText()
    const usesRollback = /\.rollback\(\)/.test(fileText)
    if (usesRollback && !/TransactionRollbackError/.test(fileText))
      add('mutation', 'DRZ-TX-04', 'high', sf, sf.statements[0] ?? sf, 'tx.rollback() is called but TransactionRollbackError is never handled — the awaited db.transaction() rejects with it')
    walk(sf, (n, parents) => {
      if (!ts.isCallExpression(n) || !isChainTop(n)) return
      const ch = chainOf(n)
      const ns = names(ch)
      const txParams = new Set(parents.filter((p) => ts.isFunctionLike(p) && p.parent && ts.isCallExpression(p.parent) &&
        ts.isPropertyAccessExpression(p.parent.expression) && p.parent.expression.name.text === 'transaction')
        .map((p) => p.parameters?.[0]?.name.getText(sf)).filter(Boolean))
      if (!isDbRoot(ch, txParams)) return
      const first = ns.find((x) => WRITE.has(x) || READ.has(x) || x === 'transaction')
      // write without where
      if ((first === 'update' || first === 'delete') && !ns.includes('where'))
        add('mutation', 'DRZ-QUERY-04', 'high', sf, n, `${first} with no .where() — it touches every row of \`${firstArgTable(ch, first) ?? '?'}\``)
      if ((first === 'update' || first === 'delete') && ns.includes('where')) {
        const w = ch.calls.find((c) => c.name === 'where').args[0]
        if (w && ts.isCallExpression(w) && /^(and|or)$/.test(w.expression.getText(sf)) && w.arguments.length && w.arguments.every((a) => ts.isConditionalExpression(a) && /undefined/.test(a.getText(sf))))
          add('mutation', 'DRZ-QUERY-04', 'high', sf, w, 'every condition of this filter can be undefined — and() then returns undefined and the write has no filter')
        if (w && w.kind === ts.SyntaxKind.Identifier && w.getText(sf) === 'undefined')
          add('mutation', 'DRZ-QUERY-04', 'high', sf, w, '.where(undefined) — no filter')
      }
      // undefined in set
      const set = ch.calls.find((c) => c.name === 'set')
      if (set && set.args[0] && ts.isObjectLiteralExpression(set.args[0]))
        for (const p of set.args[0].properties) {
          if (!ts.isPropertyAssignment(p)) continue
          const v = p.initializer.getText(sf)
          if (v === 'undefined')
            add('mutation', 'DRZ-QUERY-05', 'high', sf, p, `set({ ${p.name.getText(sf)}: undefined }) leaves the column unchanged — use null to clear it`)
          else if (/\|\|\s*undefined\s*$/.test(v))
            add('mutation', 'DRZ-QUERY-05', 'high', sf, p, `set({ ${p.name.getText(sf)}: ${v.slice(0, 40)} }) turns null (and '' and 0) into undefined — the column is not cleared`)
        }
      // values(list) without an empty guard
      const vals = ch.calls.find((c) => c.name === 'values')
      if (vals && vals.args[0] && !ts.isObjectLiteralExpression(vals.args[0]) && !ts.isArrayLiteralExpression(vals.args[0])) {
        const v = vals.args[0]
        const fn = enclosingFn(parents)
        const name = ts.isIdentifier(v) ? v.text : null
        const looksList = /\.map\(|\.filter\(|\.flatMap\(|rows|items|list|batch|\w+s$/.test(v.getText(sf))
        const guarded = fn && name && new RegExp(`${name}\\.length|${name}\\?\\.length`).test(fn.getText(sf))
        if (looksList && !guarded && !/\.length/.test(fn?.getText(sf) ?? ''))
          add('mutation', 'DRZ-QUERY-07', 'candidate', sf, v, `values(${text(sf, v).slice(0, 40)}) — if this list can be empty, values([]) throws`)
      }
    })
    // transactions: outer db inside, nested uncaught, throw-only
    walk(sf, (n, parents) => {
      if (!ts.isCallExpression(n) || !ts.isPropertyAccessExpression(n.expression) || n.expression.name.text !== 'transaction') return
      const cb = n.arguments[0]
      if (!cb || !ts.isFunctionLike(cb)) return
      const p = cb.parameters[0]?.name.getText(sf)
      const outer = chainOf(n).root
      const insideTx = parents.some((q) => ts.isFunctionLike(q) && q.parent && ts.isCallExpression(q.parent) && ts.isPropertyAccessExpression(q.parent.expression) && q.parent.expression.name.text === 'transaction')
      if (insideTx && !parents.some((q) => ts.isTryStatement(q)))
        add('mutation', 'DRZ-TX-04', 'high', sf, n, 'a nested transaction (savepoint) outside try/catch — its failure rolls back the outer one too')
      walk(cb.body, (m, mp) => {
        if (ts.isCallExpression(m) && isChainTop(m)) {
          const ch = chainOf(m)
          if (ch.root && ch.root !== p && (ch.root === outer || ch.root === 'db') && isQueryChain(ch))
            add('mutation', 'DRZ-TX-03', 'high', sf, m, `\`${ch.root}\` used inside the transaction callback — this statement runs outside the transaction (use \`${p}\`)`)
        }
      })
      const writes = []
      walk(cb.body, (m) => { if (ts.isCallExpression(m) && isChainTop(m) && names(chainOf(m)).some((x) => WRITE.has(x))) writes.push(m) })
    })
    // two writes on db in one function with no transaction; read-then-write
    walk(sf, (fn) => {
      if (!ts.isFunctionLike(fn) || !fn.body || isTest(sf)) return
      const inTx = (node) => { for (let q = node.parent; q && q !== fn; q = q.parent) if (ts.isCallExpression(q) && ts.isPropertyAccessExpression(q.expression) && q.expression.name.text === 'transaction') return true; return false }
      const own = []
      const isTxCallback = (q) => ts.isFunctionLike(q) && q.parent && ts.isCallExpression(q.parent) &&
        ts.isPropertyAccessExpression(q.parent.expression) && q.parent.expression.name.text === 'transaction'
      walk(fn.body, (m, mp) => {
        if (mp.some((q) => ts.isFunctionLike(q) && !isTxCallback(q))) return // other nested functions are judged on their own
        if (ts.isCallExpression(m) && isChainTop(m)) own.push({ m, ch: chainOf(m), mp })
      })
      const returned = (m) => m.parent && (ts.isReturnStatement(m.parent) || (ts.isAwaitExpression(m.parent) && m.parent.parent && ts.isReturnStatement(m.parent.parent)))
      const dbWrites = own.filter(({ ch, m }) => (ch.root === 'db' || (ch.root === 'this' && ch.calls[0]?.name === '.db')) && names(ch).some((x) => WRITE.has(x)) && !inTx(m))
        .filter(({ m }, _i, all) => !(returned(m) && all.filter((w) => returned(w.m)).length === all.length))
      if (dbWrites.length >= 2 && !own.some(({ ch }) => names(ch).includes('transaction')))
        add('mutation', 'DRZ-TX-01', 'candidate', sf, dbWrites[1].m, `${dbWrites.length} writes on \`db\` in one function, no transaction — must they succeed or fail together?`)
      const txNames = new Set(['tx', ...own.filter(({ mp }) => mp.some(isTxCallback)).flatMap(({ mp }) => mp.filter(isTxCallback).map((q) => q.parameters?.[0]?.name.getText(sf)))].filter(Boolean))
      const reads = own.filter(({ ch }) => isDbRoot(ch, txNames) && names(ch).some((x) => READ.has(x)))
      for (const { m, ch, mp } of own) {
        const ns = names(ch)
        const w = ns.find((x) => x === 'insert' || x === 'update')
        if (!w || !isDbRoot(ch, txNames)) continue
        const t = firstArgTable(ch, w)
        const guardedByIf = mp.some((q) => ts.isIfStatement(q))
        // a read inside an `if` whose branch returns is a different path from a write outside that `if`
        const exclusive = (r) => r.mp.some((q) => ts.isIfStatement(q) && q.parent && !(m.getStart(sf) >= q.getStart(sf) && m.getEnd() <= q.getEnd()) &&
          (() => { let ret = false; walk(q.thenStatement, (z) => { if (ts.isReturnStatement(z) || ts.isThrowStatement(z)) ret = true }); return ret })())
        const prior = reads.find((r) => r.m.getStart(sf) < m.getStart(sf) && readTable(r.ch) === t && !exclusive(r))
        if (!prior) continue
        if (w === 'insert' && guardedByIf && !ns.some((x) => x.startsWith('onConflict')))
          add('mutation', 'DRZ-QUERY-06', 'candidate', sf, m, `read of \`${t}\` then a conditional insert — two requests can both see "absent"; use onConflictDoNothing/DoUpdate on a unique key`)
        if (w === 'update' && !ns.includes('for')) {
          const priorLocked = names(prior.ch).includes('for')
          if (!priorLocked) add('mutation', 'DRZ-TX-05', 'candidate', sf, m, `\`${t}\` is read, then updated — if the update depends on the read value, put the condition in .where() and check returning(), or read with .for('update')`)
        }
      }
    })
  }
}

// ---------- GROUP: zod ----------
if (only.has('zod')) {
  const pkgPath = join(root, 'package.json')
  const zodVersion = existsSync(pkgPath) ? (JSON.parse(readFileSync(pkgPath, 'utf8')).dependencies?.zod ?? '') : ''
  for (const sf of sources) {
    const ft = sf.getFullText()
    const importsDrizzleZod = /from ['"](drizzle-zod|drizzle-orm\/zod)['"]/.test(ft)
    if (importsDrizzleZod && /^[\^~]?3\./.test(zodVersion) && /from ['"]zod['"]/.test(ft))
      add('zod', 'no ID — zod satellite § 1.2', 'high', sf, sf.statements[0], `zod ${zodVersion} with \`from 'zod'\` next to drizzle-zod — on 3.25 that is the v3 API; import from 'zod/v4'`)
    const factoryCoerce = /createSchemaFactory\(\s*\{[^}]*coerce/.test(ft)
    walk(sf, (n, parents) => {
      // hand-written object duplicating a table
      if (ts.isCallExpression(n) && n.expression.getText(sf) === 'z.object' && n.arguments[0] && ts.isObjectLiteralExpression(n.arguments[0])) {
        const keys = n.arguments[0].properties.map((p) => p.name?.getText(sf)).filter(Boolean)
        for (const [tn, t] of tables) {
          const cols = tableColumnSet(tn)
          const hit = keys.filter((k) => cols.has(k))
          if (keys.length >= 3 && hit.length / keys.length >= 0.8)
            add('zod', 'DRZ-ZOD-01', 'high', sf, n, `z.object with ${hit.length}/${keys.length} keys that are columns of \`${tn}\` — derive it with create*Schema(${tn}) and narrow`)
        }
      }
      if (!ts.isCallExpression(n) || !isChainTop(n)) return
      // find a create*Schema call at the chain's head
      let head = n
      while (ts.isCallExpression(head) && ts.isPropertyAccessExpression(head.expression) && ts.isCallExpression(head.expression.expression)) head = head.expression.expression
      if (!ts.isCallExpression(head) || !ts.isIdentifier(head.expression)) return
      const fnName = head.expression.text
      const kind = (fnName.match(/^create(Insert|Update|Select)Schema/) || [])[1]
      if (!kind || !head.arguments[0] || !ts.isIdentifier(head.arguments[0])) return
      const tn = head.arguments[0].text
      const t = tables.get(tn)
      if (!t) return
      const chainText = n.getText(sf)
      const methods = names(chainOf(n))
      const narrowed = methods.includes('pick') || methods.includes('omit')
      const refine = head.arguments[1] && ts.isObjectLiteralExpression(head.arguments[1]) ? head.arguments[1] : null
      const refined = new Set(refine?.properties.map((p) => p.name?.getText(sf)) ?? [])
      const pickedOut = (col) => {
        const pk = chainOf(n).calls.find((c) => c.name === 'pick')?.args[0]
        const om = chainOf(n).calls.find((c) => c.name === 'omit')?.args[0]
        if (pk && ts.isObjectLiteralExpression(pk)) return !pk.properties.some((p) => p.name?.getText(sf) === col)
        if (om && ts.isObjectLiteralExpression(om)) return om.properties.some((p) => p.name?.getText(sf) === col)
        return false
      }
      if ((kind === 'Insert' || kind === 'Update') && !narrowed) {
        const serverOwned = [...t.columns.keys()].filter((c) => /^(role|ownerId|authorId|userId|tenantId|orgId|isAdmin|published|status|passwordHash|createdAt|updatedAt|deletedAt)$/.test(c))
        add('zod', 'DRZ-ZOD-03', serverOwned.length ? 'high' : 'candidate', sf, n, `${fnName}(${tn}) not narrowed with .pick()/.omit()` + (serverOwned.length ? ` — a caller can set ${serverOwned.join(', ')}` : ''))
      }
      if (kind === 'Select') {
        const secrets = [...t.columns].filter(([c, d]) => d.secret && !pickedOut(c)).map(([c]) => c)
        if (secrets.length) add('zod', 'DRZ-ZOD-03', 'high', sf, n, `${fnName}(${tn}) keeps ${secrets.join(', ')} — a response schema must omit it`)
      }
      if (methods.includes('extend') || methods.includes('merge')) {
        const ext = chainOf(n).calls.find((c) => c.name === 'extend' || c.name === 'merge')?.args[0]
        const clash = ext && ts.isObjectLiteralExpression(ext) ? ext.properties.map((p) => p.name?.getText(sf)).filter((k) => t.columns.has(k)) : []
        if (clash.length) add('zod', 'DRZ-ZOD-02', 'high', sf, n, `.extend() re-declares generated column(s) ${clash.join(', ')} — refine through the second argument of ${fnName}`)
      }
      if (kind === 'Insert' || kind === 'Update') {
        const temporal = [...t.columns].filter(([c, d]) => d.temporal && !pickedOut(c) && !refined.has(c) && !(d.hasDefault && /createdAt|updatedAt/.test(c))).map(([c]) => c)
        if (temporal.length && !factoryCoerce)
          add('zod', 'DRZ-ZOD-04', 'candidate', sf, n, `${fnName}(${tn}) accepts ${temporal.join(', ')} as Date — a JSON body sends a string; coerce with createSchemaFactory({ coerce: { date: true } })`)
        const json = [...t.columns].filter(([c, d]) => d.jsonType && !pickedOut(c) && !refined.has(c)).map(([c]) => c)
        if (json.length) add('zod', 'DRZ-ZOD-07', 'high', sf, n, `${json.join(', ')} is typed with $type<T>() but the generated schema accepts any JSON — give it a Zod schema in the refinement`)
      }
      if (refine) for (const p of refine.properties) {
        if (!ts.isPropertyAssignment(p) || ts.isArrowFunction(p.initializer) || ts.isFunctionExpression(p.initializer)) continue
        const col = p.name.getText(sf)
        const d = t.columns.get(col)
        if (d && !d.notNull && !/\.(nullable|nullish|optional)\(/.test(p.initializer.getText(sf)))
          add('zod', 'DRZ-ZOD-05', 'high', sf, p, `\`${col}\` is nullable, and this replacement drops null/optional — add .nullish(), or refine with (s) => …`)
      }
      if (kind === 'Update' && !methods.includes('refine') && !methods.includes('superRefine') && !/Object\.keys\(/.test(ft))
        add('zod', 'DRZ-ZOD-06', 'candidate', sf, n, `${fnName}(${tn}) accepts {} — and set({}) throws "No values to set"; reject the empty body`)
    })
  }
}

// ---------- GROUP: shape (DRZ-CORE-03) — runs with any group ----------
for (const sf of sources) {
  if (isTest(sf)) continue
  walk(sf, (fn) => {
    if (!(ts.isFunctionDeclaration(fn) || ts.isArrowFunction(fn) || ts.isFunctionExpression(fn) || ts.isMethodDeclaration(fn))) return
    const ps = fn.parameters
    if (ps.length < 3 || !ts.isIdentifier(ps[0].name)) return
    const first = ps[0].name.text
    const firstType = ps[0].type?.getText(sf) ?? ''
    if (!/^(db|tx|database)$/.test(first) && !/^(Db|Database|Tx|Transaction)\b/.test(firstType)) return
    const rest = ps.slice(1).filter((q) => ts.isIdentifier(q.name))
    if (rest.length < 2) return
    const types = rest.map((q) => q.type?.getText(sf) ?? '?')
    const dup = types.find((t, i) => t !== '?' && types.indexOf(t) !== i)
    const optional = rest.some((q) => q.questionToken || q.initializer)
    const name = fn.name?.getText(sf) ?? (ts.isVariableDeclaration(fn.parent) ? fn.parent.name.getText(sf) : 'function')
    const sig = rest.map((q) => q.name.getText(sf)).join(', ')
    add('shape', 'DRZ-CORE-03', dup || optional ? 'high' : 'candidate', sf, fn,
      `${name}(${first}, ${sig}) — ${dup ? `two ${dup} inputs can swap places; ` : optional ? 'an optional positional input; ' : ''}take one typed input object after ${first}`)
  })
}

// ---------- report ----------
findings.sort((a, b) => (a.confidence === b.confidence ? 0 : a.confidence === 'high' ? -1 : 1) || a.file.localeCompare(b.file) || a.line - b.line)
if (asJson) { console.log(JSON.stringify({ root, scanned: files.length, tables: tables.size, relations: relationExports.size, findings }, null, 1)); process.exit(0) }
console.log(`scanned ${files.length} TypeScript files · ${tables.size} tables · ${relationExports.size} exported relations() · groups: ${[...only].join(', ')}`)
if (!files.length) { console.log('   (no TypeScript files under ' + root + ')'); process.exit(0) }
for (const g of ['shape', 'schema', 'query', 'mutation', 'zod']) {
  if (g !== 'shape' && !only.has(g)) continue
  const fs_ = findings.filter((f) => f.group === g)
  console.log(`\n== ${g}: ${fs_.length} finding(s)`)
  for (const f of fs_) console.log(`   [${f.confidence}] ${f.id} — ${f.file}:${f.line}\n      ${f.message}`)
  if (!fs_.length) console.log('   (nothing this scan can see — not the same as "no defect")')
}
