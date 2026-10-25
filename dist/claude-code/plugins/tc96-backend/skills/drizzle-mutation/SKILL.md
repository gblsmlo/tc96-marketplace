---
name: drizzle-mutation
description: Write and fix Drizzle ORM writes on PostgreSQL — insert with `returning`, upsert with `onConflictDoNothing`/`onConflictDoUpdate`, guarded updates, PATCH semantics (`null` clears, `undefined` is ignored), scoped deletes, batch inserts, transactions, `tx.rollback()` and savepoints, and mapping constraint violations — citing `DRZ-QUERY-04`–`07` and `DRZ-TX-*` IDs, with an AST self-check. Use when the task is creating, changing or deleting rows, a double-submit or duplicate row, a negative balance or lost update, "No values to set", a write that must be atomic, idempotency keys, or a transaction that does not roll back as expected. Do not use for reads, listings or relations (drizzle-query), for validating the body with Zod (drizzle-zod), nor to audit existing persistence (drizzle-review).
source: "[Drizzle - Writes and Transactions](../../docs/drizzle/drizzle-writes-and-transactions.md)"
docs:
  - /drizzle-team/drizzle-orm-docs
tags:
  - skill
  - drizzle
  - database
---

# drizzle-mutation

> **Source of this skill:** [Drizzle - Writes and Transactions](../../docs/drizzle/drizzle-writes-and-transactions.md) — its § 0 holds the three decision trees, and every rule this skill cites has its body there.
> **API surface:** resolve it through Context7 — `/drizzle-team/drizzle-orm-docs`, topics `insert`, `update`, `delete`, `transactions`. Signatures come from there; the rule and the ID come from the family docs.

A write in Drizzle touches exactly the rows its `where` names — and every row when there is no `where`, with no compiler warning. The other expensive failures are quieter: a check done in JavaScript between a read and a write, which two concurrent requests both pass; an `undefined` that silently leaves a column unchanged; a rollback the caller did not expect to be a rejection. This skill is the checklist that catches them while the code is being written.

---

## When to use

| Situation | Go to |
| --- | --- |
| reading, listing, relations, pagination | `drizzle-query` |
| validating the request body before the write | `drizzle-zod` |
| reviewing persistence that already exists | `drizzle-review` |
| a unique constraint or column the write needs | [Drizzle - Schema and Migrations](../../docs/drizzle/drizzle-schema-and-migrations.md) |
| the route's status codes and idempotency contract | `http-contract` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Drizzle - Writes and Transactions](../../docs/drizzle/drizzle-writes-and-transactions.md) | the trees (§ 0), the rules and the verified behaviour — the one doc this skill needs |
| 2 | [Drizzle - Schema and Migrations](../../docs/drizzle/drizzle-schema-and-migrations.md) § 1.3–1.4 | only when the write needs a new unique constraint, default or `$onUpdate` |
| 3 | [Drizzle ORM](../../docs/drizzle/drizzle-orm.md) § 0 | only when `package.json` shows `drizzle-orm` 1.x |

**Never load the reads or Zod satellites for a write.**

| File | What for |
| --- | --- |
| `references/patterns.md` | eight write shapes worth copying, each executed with a test: create, create-or-get, batch upsert, guarded update, transfer, PATCH, scoped delete, expected rollback |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | the `DRZ-QUERY-04`–`07` and `DRZ-TX-*` IDs and where their bodies live |
| `scripts/self-check.sh` | the version line and the mutation-group AST scan |

---

## Step 0 — Which line is the project on

```bash
grep -E '"drizzle-(orm|kit)"' package.json
```

The write API barely differs between `0.x` and `1.0.0-rc`, but the behaviour marked *verified* in the doc was executed on 0.45.4 — say so if the project is elsewhere.

---

## Step 1 — Four questions before the first line

1. **Which rows, exactly?** Every `update` and `delete` gets a `where` that names them — the owner and the id, not the id alone, when a user acts on their own data (`DRZ-QUERY-04`). If the filter is built from optional inputs, check that it cannot collapse to `undefined`: `and()` of all-`undefined` is `undefined`, and `where(undefined)` is no filter.
2. **Can the key already exist?** Then it is an upsert on a **unique** column — `onConflictDoNothing` or `onConflictDoUpdate` — never a `select` followed by a conditional `insert` (`DRZ-QUERY-06`). Tree § 0.1.
3. **Does the write depend on a value read before it?** A balance, a stock count, a status. Put the condition in the write's own `where` and read `returning()` — an empty array means the condition failed — or lock the row with `.for('update')` inside a transaction (`DRZ-TX-05`). A transaction alone does not stop two requests from passing the same check.
4. **Is it more than one statement?** Then one `db.transaction`, with `tx` in every call inside it (`DRZ-TX-01`, `DRZ-TX-03`). One statement is already atomic — do not wrap it.

---

## Step 2 — Write it

Start from the closest shape in `references/patterns.md`. The details that turn into bugs:

- **The function's shape:** `db: Database` first, then one typed input object whenever there are two or more inputs, an optional one, or two of the same type — `transfer(db, { idempotencyKey, fromAccountId, toAccountId, amount })`, never four positional values where two account ids can swap (`DRZ-CORE-03`, [Drizzle ORM](../../docs/drizzle/drizzle-orm.md) § 10).
- **`undefined` means "leave it"; `null` means "clear it"** (`DRZ-QUERY-05`). A `set()` whose fields are all `undefined` throws `No values to set` — reject the empty PATCH before the query.
- **`values([])` throws** — guard a list that can be empty (`DRZ-QUERY-07`); chunk a very large one (65,535 bind parameters per statement).
- **`.returning()` can be empty** — after `onConflictDoNothing` on a collision, or an update whose `where` matched nothing. `const [row] = …` is then `undefined`; decide what that means.
- **`tx.rollback()` rejects** the awaited `db.transaction()` with `TransactionRollbackError` (`DRZ-TX-04`). Catch it when the rollback is an expected outcome, or throw a domain error instead when the caller needs the reason. A nested transaction spares the outer one only inside a `try`.
- **Constraint violations arrive wrapped** — a `DrizzleQueryError` whose `.cause.code` is the PostgreSQL code (`23505` unique, `23503` foreign key). Map them to 409/422, not 500 (doc § 4.4).

---

## Step 3 — Prove it

Write the test that would have failed: the second identical request (idempotency), the debit larger than the balance (guard), the empty PATCH, the delete that must not touch another owner's rows. A fresh PGlite database per test runs real PostgreSQL in-process — the harness is in `references/patterns.md`. Then:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-mutation/scripts/self-check.sh .
bunx tsc --noEmit
```

The self-check flags writes without `where`, filters that can collapse, `undefined` in `set`, unguarded `values(list)`, the outer `db` inside a transaction, nested transactions outside `try`, `rollback()` with no `TransactionRollbackError` handling, read-then-write sequences and multi-write functions without a transaction. `candidate` findings need reading.

---

## Step 4 — Report

Say what each write now guarantees — which rows, atomic or not, idempotent or not — the tests that prove it with their output, the IDs behind each change, and what you did not verify. A race between two connections cannot be reproduced on single-connection PGlite: say so rather than claiming it was tested.

---

## Example

A credit transfer debits with `update … set balance = balance - x` after reading the balance in JavaScript, credits with the outer `db` inside the transaction, and deduplicates retries with a `select` on the idempotency key. Rewritten: the ledger insert with `onConflictDoNothing` on the unique key comes first (a replay returns the earlier entry), the debit carries `balance >= amount` in its `where` and an empty `returning()` throws `InsufficientFunds`, and every call uses `tx`. Tests cover the replay, the overdraft and an unknown account — rejected by the ledger's foreign key with `cause.code === '23503'`. Cites `DRZ-QUERY-06`, `DRZ-TX-03`, `DRZ-TX-05`.
