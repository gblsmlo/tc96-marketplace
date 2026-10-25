# When the client turns `any`, or loses a route

The build passes in every case below. That is why they last.

| Symptom | Cause | Check | Fix |
| --- | --- | --- | --- |
| every route is `any` | `strict` off, or TypeScript < 5.0, in the server **or** the client | `self-check.sh` lists every tsconfig | `strict: true` both sides (`ELYSIA-APP-04`) |
| `any` right after upgrading one package | two `elysia` copies resolved | `bun pm ls --all \| grep elysia@`; `self-check.sh` lists installed copies | one version: a workspace `catalog`, or `overrides` (`ELYSIA-TYPE-11`) |
| one route missing, the rest typed | the server registered it in a separate statement | `keyof typeof api` | one chain (`ELYSIA-APP-01`) |
| works in the server package, `any` in the app | a path alias or `exports` entry that resolves the type to a different file on each side | `tsc --traceResolution` in the client, look for the server path | point the client at the package's `exports` entry the server builds from |
| an error status missing from the union | not in the route's `response` map, and thrown rather than returned | the route's map and handler | declare it; return `status()` (`ELYSIA-TYPE-06`, `ELYSIA-CORE-03`) |
| `error.value` is `unknown` | no `response` map and no returned `status()` | the route | add the map |
| a date field is a `Date` though typed `string` | `parseDate` left on | the treaty config | `parseDate: false` (`ELYSIA-TYPE-10`) |

In a monorepo, publish the type from the server package:

```json
{ "name": "@acme/server", "exports": { ".": { "types": "./src/app.ts", "default": "./src/app.ts" } } }
```

and import it with `import type { App } from '@acme/server'`. A bundler then drops the import entirely.
