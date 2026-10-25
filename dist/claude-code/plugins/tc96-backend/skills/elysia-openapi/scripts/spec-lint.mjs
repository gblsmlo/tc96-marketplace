#!/usr/bin/env node
// Lints an OpenAPI JSON produced by @elysia/openapi for what consumers and code generators rely on.
//   node spec-lint.mjs <openapi.json> [--generator]
// Without --generator, a missing operationId is reported as a note; with it, as a problem.
import { readFileSync } from 'node:fs'

const file = process.argv[2]
const generator = process.argv.includes('--generator')
if (!file) { console.log('usage: node spec-lint.mjs <openapi.json> [--generator]'); process.exit(2) }
let spec
try { spec = JSON.parse(readFileSync(file, 'utf8')) } catch (e) { console.log(`cannot read ${file}: ${e.message}`); process.exit(2) }

const METHODS = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace']
const ops = []
for (const [path, item] of Object.entries(spec.paths ?? {}))
  for (const m of METHODS) if (item[m]) ops.push({ where: `${m.toUpperCase()} ${path}`, path, method: m, op: item[m] })

const schemes = Object.keys(spec.components?.securitySchemes ?? {})
const docSecurity = Array.isArray(spec.security) && spec.security.length > 0
const problems = []
const notes = []
const ids = new Map()
for (const { where, path, op } of ops) {
  if (op.operationId) ids.set(op.operationId, [...(ids.get(op.operationId) ?? []), where])
  else (generator ? problems : notes).push(`${where}: no operationId (ELYSIA-TYPE-18)`)
  if (!op.summary) problems.push(`${where}: no summary`)
  if (!op.tags?.length) problems.push(`${where}: no tags`)
  const codes = Object.keys(op.responses ?? {})
  if (!codes.length) problems.push(`${where}: no responses — the route declares no response schema (ELYSIA-TYPE-06)`)
  const hasInput = op.requestBody || (op.parameters ?? []).length
  if (codes.length && hasInput && !codes.includes('422')) notes.push(`${where}: has input but documents no 422 — Elysia answers 422 on invalid input`)
  if (path.endsWith('/') && path !== '/') problems.push(`${where}: trailing slash — in a prefixed module register the route as '' not '/'`)
  if (schemes.length && op.security === undefined && !docSecurity) notes.push(`${where}: no security declared while the document defines ${schemes.join(', ')} — public on purpose? say security: [] (ELYSIA-TYPE-20)`)
  for (const s of op.security ?? []) for (const k of Object.keys(s)) if (!schemes.includes(k)) problems.push(`${where}: security names \`${k}\`, which components.securitySchemes does not define`)
  const body = op.requestBody?.content?.['application/json']?.schema
  if (body && typeof body === 'object' && !body.$ref && !body.type && !body.properties && !body.anyOf && !body.oneOf)
    problems.push(`${where}: request body documented with an empty schema — a validator without Standard JSON Schema needs mapJsonSchema (ELYSIA-TYPE-07)`)
}
// every $ref must resolve inside the document
const refs = new Set()
;(function collect(node) {
  if (Array.isArray(node)) return node.forEach(collect)
  if (node && typeof node === 'object') for (const [k, v] of Object.entries(node)) k === '$ref' && typeof v === 'string' ? refs.add(v) : collect(v)
})(spec.paths)
for (const ref of refs) {
  const target = ref.startsWith('#/') ? ref.slice(2).split('/').reduce((n, k) => n?.[decodeURIComponent(k)], spec) : undefined
  if (!target) problems.push(`$ref \`${ref}\` does not resolve — for arrays of a model use t.Array(t.Ref('#/components/schemas/Name'))`)
}
for (const [id, wheres] of ids) if (wheres.length > 1) problems.push(`operationId \`${id}\` is shared by ${wheres.join(', ')} (ELYSIA-TYPE-18)`)

console.log(`${file}: OpenAPI ${spec.openapi ?? '?'} · ${ops.length} operations · ${Object.keys(spec.components?.schemas ?? {}).length} component schemas · security schemes: ${schemes.join(', ') || 'none'}`)
console.log(`\n== problems: ${problems.length}`)
for (const p of problems) console.log(`   ${p}`)
console.log(`\n== notes: ${notes.length}`)
for (const n of notes.slice(0, 40)) console.log(`   ${n}`)
if (notes.length > 40) console.log(`   … ${notes.length - 40} more`)
process.exit(problems.length ? 1 : 0)
