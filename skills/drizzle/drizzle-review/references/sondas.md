# The probes — before reading the code

> In persistence, the worst defects are **invisible to reading**: the schema looks complete,
> the query looks right, the test passes — and even so the relational API is switched off or the
> migration generator is blind.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-review/scripts/sondas.sh src
```

| Probe | How | What it reveals |
| --- | --- | --- |
| **S1. Client registration** | Compare the exported `pgTable` and `relations` with the keys of the object passed to `drizzle({ schema })` | `DRZ-REL-05` — a schema without the `relations` makes `with` throw at runtime; a missing table makes `db.query.x` `undefined` |
| **S2. Snapshot chain** | Count entries in `meta/_journal.json` × `*_snapshot.json` files; run `generate` on a clean tree | a hand-written migration that did not update the snapshot makes the generator diff from an old state and propose destructive SQL |
| **S3. Redundant indexes** | For each table, find an index that is a strict prefix of another | write and cache cost with no reader at all |
| **S4. Live integration tests** | Run the suite with the flags that unlock the database tests | a test that never runs is not coverage; a wrong file path goes unnoticed for years |

S1 and S3 are code reading — neither needs a connection. **S2** needs a `generate` on a clean
tree. **S4** (live integration tests) needs the database up and the migrations applied — if it
did not run, declare it.

**If S1 fails, stop and report before continuing.** With the relational API switched off, every
hand-built read is a **consequence, not a cause**, and criticizing each one is noise.

## What the script adds to the four probes from the docs

| Extra probe | Rule | Why it belongs here |
| --- | --- | --- |
| S4 — a query inside `map`/`for` | `DRZ-RQB-01` | the most common finding and the most expensive |
| S5 — `update`/`delete` without `where` | `DRZ-QUERY-04` | blocking, and one line produces it |
| S6 — `sql\`\`` with interpolation | `DRZ-QUERY-03` | becomes a **security** finding when the value comes from the user |
| S7 — external `db` inside a `transaction` | `DRZ-TX-03` | the write leaves the transaction with no error |
| S8 — `push` outside local | `DRZ-MIG-02`, `DRZ-MIG-04` | a grep over `package.json` and the workflow settles it |
| S9 — `.default` with a computed value | `DRZ-SCHEMA-04` | the value freezes in the migration's SQL |
| S10 — hand-written Zod | `DRZ-ZOD-01` | it points at the candidates; confirmation is reading |

## Related

- `varredura-e-severidade.md` — what to do with what the probe pointed at
- `mapa-de-ids.md` — where each `DRZ-*` has its body
