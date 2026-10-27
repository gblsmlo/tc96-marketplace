# Template: one layer of a delivery

Saved as `.specs/delivery/<YYYY-MM-DD>-<slug>/plans/<layer-id>-<slug>.md`, one file per row of the
index in `plan.md`. Answers one question: **what does this layer give the next one, and how is it
proved?** Rule: `SDD-PLAN-04`. It is everything the layer's run needs besides the index's vocabulary and the
**Provides** of the layers it consumes. Under about 60 lines.

Each fact lives in one file (`SDD-PLAN-02`): a shape lives in the **Provides** of the layer that
provides it; a consumer links to it and never copies it. A check's text lives here, in the layer
that proves it; `contract.md` only maps each `AC-*` to check IDs.

Once the layer is merged the file is frozen (`SDD-PLAN-09`): a later change is a new file
(`plans/<layer-id>.<n>-<slug>.md`) and a new row in the index.

## Fields

| Field | Meaning |
| --- | --- |
| `layer` | the layer ID, as in the index (`L2a`) |
| `delivery` | the delivery ID |
| `owner` | `backend-developer` · `frontend-developer` · `qa-engineer` |
| `depends` | the layer IDs it consumes from |
| `status` | `Draft` · `Approved` (progress lives in the index, not here) |

## Body (copy from here down)

---

**Goal.** <one sentence: what the next layer can do once this one is merged>

**Skills.** <exact skill names from the caller's list, e.g. `tc96-backend:drizzle-mutation`>

**Consumes.** One line per seam, each a link to where it is defined:
- <seam name> — `plans/<layer-id>-<slug>.md#provides` (or `path:line` when it already exists)

### Provides

<the seams the next layers code against, by name, each with a type-level shape — a signature, a
schema's fields, a route with method, statuses and body. No bodies, no file contents.>

### Must hold

- <rule> — <source: AC-NN, ADR-NNNN §n>

### Free to decide

<what the implementer and its skill choose>

### Checks

One per line: ID, the `AC-*` it proves (`—` for an ADR invariant), what is observed with the edge
values, and the level. What is observed, never how the test is written.

- **C<NN>** (AC-NN) <given> → <then> · `unit`

### Surface, size, done

- **Surface:** <folders or globs>
- **Size:** <estimated changed lines with tests; review family>
- **Done when:** the checks above green, and G1 and G2 pass on this layer's pull request
