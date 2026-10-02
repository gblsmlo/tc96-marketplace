---
titulo: Feature-Based Architecture
aliases:
  - FBA
  - Feature-based architecture
tags:
  - frontend
  - react
  - architecture
---
# Feature-Based Architecture

> Child note of [Architecture in React](architecture-in-react.md). This is where we decide **where code lives and who may import whom**.
> The conceptual idea in one sentence is in;
> this note turns the idea into structure, citable rules and automated verification.
>
> **A self-contained family.** These notes live inside the `react` skill family, not in the tc96 knowledge base, so the family can move without it. Names in code spans — `TanStack Query`, `TanStack Router`, `Storybook`, `Monorepo com Bun - estrutura e tooling` — and IDs from other families (`TSQ-*`, `TSR-*`, `SB-*`, `PW-*`) belong to the tc96 knowledge base: useful context when it is installed, never required to apply a `REACT-*`, `RHF-*` or `REACT-ARCH-*` rule.

This note is **guidance**, not a summary. It exists for two readers: me, deciding where to put a
file, and an agent, creating or reviewing code. Section 10 is the contract an agent loads.

---

## 1. The problem: grouping by technical role

The default structure of almost every React project organizes by **what the file is**:

```
src/
├── components/
├── hooks/
├── utils/
├── pages/
└── store/
```

It works while the app has one capability. After that, every product change becomes a sweep:
changing "invoices" touches `components/invoice-card.tsx`, `hooks/use-invoices.ts`, `store/invoices-slice.ts`,
`utils/format-due-date.ts` and `pages/invoices.tsx` — five folders, none of them called invoices.

The real cost is not aesthetic. It is that **the domain boundary stops existing in the code**:

- nothing stops `components/invoice-card.tsx` from importing `store/user-slice.ts`;
- the `utils/` folder accumulates business rules from every domain;
- nobody knows what can be deleted when the capability dies;
- onboarding requires understanding the whole app before changing one screen.

The cause is a misalignment: **files are grouped by type, but change by domain.** Things that
change for the same reason should live together — it is cohesion, applied to a directory instead of a class.

---

## 2. The principle and the layers

**Group by domain, not by technical role.** Everything that belongs to a capability — UI, hooks,
API calls, schemas, state, types — lives in a single vertical slice.

The structure adopted in the vault:

```
src/
├── routes/          # route tree (TanStack Router, file-based). Composes, does not implement.
├── features/        # product domains. Each one is a closed vertical slice.
│   ├── auth/
│   └── invoices/
├── components/      # domain-free UI
│   ├── ui/          # primitives: button, input, dialog
│   └── layout/      # header, sidebar, footer
├── hooks/           # generic hooks: use-debounce, use-local-storage
│   └── index.ts
├── libs/            # infrastructure: http-client, formatters, config
│   └── index.ts
└── types/           # generic contracts: ApiResponse, PaginationParams
    └── index.ts
```

Each layer consumed through an alias has its own barrel — that is what the alias addresses. Without
`src/libs/index.ts`, the import `from '@libs'` does not resolve. This holds for `@hooks`, `@libs` and `@app-types`;
`@features/*` and `@components/*` address the subfolder's barrel (`@features/invoices`, `@components/ui`).

Matching aliases in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@features/*": ["./src/features/*"],
      "@components/*": ["./src/components/*"],
      "@routes/*": ["./src/routes/*"],

      "@hooks": ["./src/hooks"],
      "@libs": ["./src/libs"],
      "@app-types": ["./src/types"]
    }
  }
}
```

> **No `baseUrl`.** TypeScript 7 **removed** this option — `error TS5102: Option 'baseUrl' has been
> removed`. It is not a deprecation, it is a configuration error: the project does not compile. This breaks nothing
> here, because a `paths` without `baseUrl` resolves relative to the location of the `tsconfig.json` itself, and
> the entries above are already written that way (`./src/...`). Verified with `tsc` 7.0.2. If you keep
> `baseUrl` in an old project, remove it; if you need the implicit-root behavior it gave,
> the replacement indicated by the message itself is `"paths": { "*": ["./*"] }`.

> **Why `@app-types` and not `@types`.** The `@types/` prefix is the npm scope for declaration
> packages (`@types/node`, `@types/react`). TypeScript `paths` resolves **before**
> `node_modules`, so an `@types/*` alias is on a collision course with the ecosystem. Use a
> prefix that does not exist in the registry.

> **Why some entries have `/*` and others do not.** A `"@libs/*"` mapping only matches
> specifiers that have something after the slash — `import { httpClient } from '@libs'` **does not
> resolve**. Layers consumed only through the barrel (`@hooks`, `@libs`, `@app-types`) get
> the entry without a wildcard; layers in which the subpath is the legitimate address (`@features/invoices`,
> `@components/ui`) get the entry with `/*`. Declaring both forms for the same layer reopens the
> door to deep imports.

The same aliases must exist in `vite.config.ts` and `vitest.config.ts`. Three files that
must agree is a classic source of "works in the build, breaks in the test".

### Dependency direction

Between layers, there is only one legal direction:

```
routes/  →  features/  →  components/ · hooks/ · libs/ · types/
             ╰─ ─ ─ ─╯
        lateral edge: feature → feature,
        allowed only through the barrel (see § 4)
```

Never backwards. `components/ui/button.tsx` does not know invoices exist. `libs/http-client.ts` does not
know authentication exists — it receives an interceptor, it does not import it. And no feature imports
from `routes/`: the route knows the feature, not the other way around.

The lateral edge between features is the only exception, and it is deliberate — see § 4, "Imports between sibling
features". It does not invert the direction; it moves sideways within the same layer.

This is the rule that produces all the others. An inverted arrow is a domain leaking into the
generic, and the generic stops being reusable the moment that happens.

---

## 3. Anatomy of a feature

The full vocabulary of a **mature** feature — not what you create on day one:

```
features/invoices/
├── api/            # queryOptions, mutations, the domain's HTTP client
├── components/     # domain UI, explicit props
│   ├── invoice-card.tsx
│   └── invoice-card.test.tsx   # colocated test, next to what it tests
├── hooks/          # the feature's interaction logic
├── stores/         # client state (when it exists); see note below
├── types/          # Zod schemas and inferred types
├── utils/          # pure domain functions
└── index.ts        # ← the public API. The rest is private.
```

Not every feature needs all seven folders. A feature is born with **`index.ts` and nothing else**; each
subfolder opens in the same commit as the first file that belongs to it — `mkdir` and file together.
`types/invoice-schema.ts` can be born before any component, because a schema is not a component; the
order is not fixed, the trigger is always the file.

Creating all seven at once costs two things: an empty folder announces structure that does not exist, and a
ready-made skeleton pushes whoever arrives later to fill the holes just because they are there. The tc96
scaffold follows this rule — see the tc96 command `scaffold-fba-05-fba`.

Tests are **colocated**, next to the file they test, and never go into the barrel. This keeps the
rule "what changes together lives together" valid for verification too.

### The barrel is the contract

`index.ts` is not an import convenience. It is **the declaration of the feature's public surface**:

```typescript
// src/features/invoices/index.ts
export { InvoicesPanel } from './components/invoices-panel'
export { InvoiceForm } from './components/invoice-form'
export { invoicesQueryOptions } from './api/invoices-queries'
export { useMarkAsPaid } from './api/invoices-mutations'
export type { Invoice, InvoiceFilters } from './types/invoice-schema'
```

Notice what is **not** exported: `InvoiceCard`, `invoices-client.ts`, the utilities. `InvoiceCard`
is a detail of how `InvoicesPanel` draws the list — if it leaks, the consumer starts depending on the
feature's internal decoration and the list can no longer change on its own.

What is not here does not exist for the rest of the app. This gives three things the folder alone does not:

1. **Cheap refactoring** — moving `invoice-card.tsx` to another subdirectory does not break any consumer.
2. **Focused review** — a change in the barrel is a contract change, and shows up in the diff as such.
3. **Safe deletion** — the surface is finite and auditable.

The barrel contains **only re-exports**. No logic, no side effect, no constant. A
`console.log` or an initialization in the barrel runs for everyone who touches the feature.

### `stores/` and the question of state

Most of what projects call "global state" is misnamed server cache. Before
creating `stores/`, check whether the data is not remote — if it is, it belongs in `api/` as
`queryOptions`.

When `stores/` is actually needed — client state shared across screens, such as the filters
of a journey or a wizard step — the choice of tool is not decided here. See [React - Patterns](react-patterns.md) § 2. This note decides **where the file lives**, not what it is
written with.

---

## 4. Normative rules (`REACT-ARCH-*`)

Citable IDs, in the same format as [React - Rules of React](react-rules-of-react.md). A review finding cites the ID, the
file and the line — it does not paraphrase.

| ID | Rule | Severity | Verification |
| --- | --- | --- | --- |
| `REACT-ARCH-01` | Group by domain, not by technical role. | critical | review |
| `REACT-ARCH-02` | Every feature exposes `index.ts`. Nothing outside it is public. | critical | review |
| `REACT-ARCH-03` | The barrel contains only re-exports — no logic, no side effect. | critical | review |
| `REACT-ARCH-04` | Inside the feature, **relative** imports. Never its own alias, never its own barrel. | critical | `noImportCycles` |
| `REACT-ARCH-05` | Between modules with a barrel — another feature, `@components/ui`, `@components/layout` — import through the **barrel**. Deep imports are forbidden. | critical | `noRestrictedImports` |
| `REACT-ARCH-06` | `components/`, `hooks/`, `libs/`, `types/` know no domain. | critical | `noRestrictedImports` |
| `REACT-ARCH-07` | Dependency flows `routes → features → generic`. Never backwards. | critical | `noRestrictedImports` partial |
| `REACT-ARCH-08` | Extraction into the generic layer requires the **third consumer**. | high | review |
| `REACT-ARCH-09` | The route composes and loads. The journey belongs to the feature. | high | review (see bench test) |
| `REACT-ARCH-10` | An import cycle is an error, not a warning. | high | `noImportCycles` |
| `REACT-ARCH-11` | Types leave the barrel with `export type`. | medium | review |
| `REACT-ARCH-12` | kebab-case in every file and directory. | medium | review |

### `REACT-ARCH-04` — why the cycle detects it

Importing the feature's own barrel from inside it looks harmless, but it creates a real cycle:

```
features/invoices/index.ts
  → features/invoices/components/invoice-card.tsx
    → @features/invoices   (= features/invoices/index.ts)
```

That is why the rule does not depend on convention: Biome's `noImportCycles` fails the build. The runtime
symptom depends on the module system — in native ESM (what Vite serves in dev), using a `const` or
`class` before initialization gives a `ReferenceError` from the temporal dead zone; in CJS or transpiled
output, it gives a silent `undefined` export. Both are sensitive to evaluation order and expensive
to diagnose. Relative imports inside the feature eliminate the entire class of bug.

**Partial coverage.** The cycle only closes when the file that imports its own alias is itself
reachable from the barrel. An internal file that nobody re-exports can import
`@features/invoices` without forming a cycle — it violates `REACT-ARCH-04` and passes lint. That residue stays in
review; in practice it is rare, because an internal file nobody reaches is usually dead code.

### `REACT-ARCH-08` — the third-consumer rule

Two consumers are a coincidence; three are a pattern. Extracting at the second produces an abstraction with an
invented contract, which then needs flags to serve both cases. Let the duplication live
until the third case reveals the real shape. It is the rule of three applied to extraction.

### Imports between sibling features — the adopted decision

> **The owner of this rule is `MONO-12`**, in `Monorepo com Bun - estrutura e tooling` § 6: the lateral
> edge is the same invariant for a package and for a feature, and that is where it has an ID, severity and an
> executable probe. This section **applies** the invariant to the React case. `REACT-ARCH-05` is the *how to
> cross* an edge that exists, and `REACT-ARCH-08` is the *when to extract* — neither of them is the
> permission itself, and citing them as if they were was the defect that motivated `MONO-12`.

The reference article **forbids** sibling ↔ sibling imports and routes all reuse through `features/core/`.
The vault adopts the **progressive** variant:

- a sibling may import a sibling (`MONO-12`), **as long as it is through the barrel** (`REACT-ARCH-05`);
- deep imports remain forbidden;
- when a third consumer appears (`REACT-ARCH-08`), extract into `features/core/<capability>/`
  and cut the direct edges.

**Importing, duplicating and extracting are three different moves.** Confusing them is the most common mistake when
reading these rules together:

| Consumers | Move | Rule |
| --- | --- | --- |
| 1 | stays where it is, private | `REACT-ARCH-02` |
| 2 | the second one **imports the barrel** of the first — does not duplicate, does not extract | `REACT-ARCH-05` |
| 3 | extracts into `features/core/<capability>/` and cuts the edges | `REACT-ARCH-08` |

`REACT-ARCH-08` answers *"when to create a shared module"*, not *"may I import"*. It never
recommends copying code between features — the duplication it tolerates is the one that already exists by accident,
not one you create on purpose to avoid an import.

**A capability born shared.** The rule speaks of *extracting*, and therefore presupposes duplication
that already exists. When the specification names three consumers before the first line of code —
"the chosen currency applies to invoices, contracts and the profile" —, the third consumer is not a
forecast, it is a requirement. Create it directly in `features/core/<capability>/`. What `REACT-ARCH-08` forbids
is **presuming** the third consumer, not **reading** three in the specification.

**Before that, ask whether it is domain.** A component that knows no capability's vocabulary
— it only receives `variant` and `children` — never enters this table: it is `@components/ui`
from the first consumer. `features/core/` is for a shared capability (permissions, subscription
status), not for generic UI. The test: if the component needs to know what an invoice is to
render correctly, it is domain.

The reason: `features/core/` without real consumers becomes a dumping ground. The strict model pays the cost of an
extra layer from day one to prevent a coupling that the barrel already keeps visible and cheap to
undo. The trade-off is conscious and has a price: **a graph of sibling features can become a tangle without
anyone noticing.** The warning sign is a feature appearing in three or more foreign barrels — at that
point `features/core/` has stopped being optional.

That sign has stopped being an intention: the lateral fan-in probe of
`Monorepo com Bun - estrutura e tooling` § 7 counts it, and three or more is a `MONO-12` finding. Until
it existed, this section's permission was prose without a gate — `MONO-11` against this note.

### `REACT-ARCH-09` — bench test

"Compose" and "implement" are vague enough for two reviewers to disagree with no way to arbitrate.
The objective criterion for a file in `src/routes/`:

- it does not declare `useState`, `useReducer` or `useEffect`;
- it imports nothing from `@components/` — the feature is what assembles UI;
- it only imports from `@features/*` and the router itself;
- its body fits on one screen without scrolling.

A route file that fails any of these points has absorbed a journey that belongs to the feature.

**Exception: the shell.** The root route (`__root.tsx`) and persistent layouts are not journey routes —
they are the skeleton that survives between navigations. The test above does not apply to them: the shell **must**
import `@components/layout`, and it is the only place in `routes/` that may. What still holds is the
rest: the shell assembles, it does not implement; no domain state or capability logic in it.

### Generic layer that needs to display domain

The concrete case: the header is generic (`@components/layout`), but it needs to show a currency
selector, which is domain. `REACT-ARCH-06` forbids the header from importing the feature — and the prohibition is
right, because a `Header` that knows about currencies stops serving any other app.

The way out is **inversion through a slot**, and it is always the same:

```tsx
// src/components/layout/header.tsx — generic, does not know what it will receive
export function Header({ actions }: { actions?: ReactNode }) {
  return <header><Logo />{actions}</header>
}

// src/routes/__root.tsx — the shell composes both layers
import { Header } from '@components/layout'
import { CurrencySelector } from '@features/core/currencies'

export const Route = createRootRoute({
  component: () => <><Header actions={<CurrencySelector />} /><Outlet /></>,
})
```

The generic **receives** domain, it never fetches it. And who has license to import both layers at the
same time is the shell — through the exception above..

---

## 5. Examples in the real stack

Stack: Vite/TanStack Start · TanStack Router · TanStack Query · Zod · React Hook Form · Biome · pnpm.

### 5.1 The contract is born from the schema

```typescript
// src/features/invoices/types/invoice-schema.ts
import { z } from 'zod'

export const invoiceSchema = z.object({
  id: z.string().uuid(),
  description: z.string().min(1),
  amountCents: z.number().int().positive(),
  dueDate: z.coerce.date(),
  status: z.enum(['open', 'paid', 'overdue']),
})

export const invoiceListSchema = z.array(invoiceSchema)

export const invoiceFiltersSchema = z.object({
  status: invoiceSchema.shape.status.optional(),
  search: z.string().optional(),
})

export type Invoice = z.infer<typeof invoiceSchema>
export type InvoiceFilters = z.infer<typeof invoiceFiltersSchema>
```

Every type is **derived** from a schema, not declared next to it — including `InvoiceFilters`, which is
input and not response. A single place defines shape and validation, so there is no state in which the
type says one thing and the runtime accepts another. `invoiceSchema.shape.status` reuses the enum instead of
retyping it: if a new status appears, the filter follows on its own.

### 5.2 The HTTP boundary validates

```typescript
// src/features/invoices/api/invoices-client.ts
import { httpClient } from '@libs'
import {
  invoiceSchema,
  invoiceListSchema,
  invoiceFiltersSchema,
  type InvoiceFilters,
} from '../types/invoice-schema'

export async function listInvoices(filters: InvoiceFilters) {
  const response = await httpClient.get('/invoices', {
    params: invoiceFiltersSchema.parse(filters),
  })
  return invoiceListSchema.parse(response.data)
}

export async function markInvoiceAsPaid(id: string) {
  const response = await httpClient.post(`/invoices/${id}/pay`)
  return invoiceSchema.parse(response.data)
}
```

`httpClient` comes from `@libs` — generic infrastructure, domain-free (`REACT-ARCH-06`). The schema is
imported by relative path, because it belongs to the feature itself (`REACT-ARCH-04`).

### 5.3 Remote data is `queryOptions`, not state

```typescript
// src/features/invoices/api/invoices-queries.ts
import { queryOptions } from '@tanstack/react-query'
import { listInvoices } from './invoices-client'
import type { InvoiceFilters } from '../types/invoice-schema'

export function invoicesQueryOptions(filters: InvoiceFilters = {}) {
  return queryOptions({
    queryKey: ['invoices', 'list', filters],
    queryFn: () => listInvoices(filters),
    staleTime: 30_000,
  })
}
```

`queryOptions` is the format that serves route and component with the same definition — the loader preloads and
the component consumes the same key, without duplicating the freshness policy.

The mutation lives next to it, and **invalidation is part of it**:

```typescript
// src/features/invoices/api/invoices-mutations.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { markInvoiceAsPaid } from './invoices-client'

export function useMarkAsPaid() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: markInvoiceAsPaid,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] })
    },
  })
}
```

Writing the mutation without `onSuccess` is the most common bug in this layer: the server accepts the change and the
screen keeps showing the old value until a manual refresh. That is why the key is hierarchical —
`['invoices', 'list', filters]` in the query, `['invoices']` in the invalidation — and one prefix brings down all
the lists at once, with any filter. When waiting for the response becomes noticeable, the next
step is an optimistic update: [React - Forms and Actions](react-forms-and-actions.md) § 5.

The structural rule: **the feature that owns the key is the one that invalidates.** A feature never invalidates
another one's `queryKey` — if it needs that, the operation belongs to the other feature and must be exported
by it.

### 5.4 The route composes, it does not implement

```tsx
// src/routes/invoices/index.tsx
import { createFileRoute } from '@tanstack/react-router'
import { InvoicesPanel, invoicesQueryOptions } from '@features/invoices'

export const Route = createFileRoute('/invoices/')({
  loader: ({ context }) => context.queryClient.ensureQueryData(invoicesQueryOptions()),
  component: InvoicesPanel,
})
```

Four lines. The route decides **which** capability appears at that path and what to preload; it does not
know how an invoice is rendered (`REACT-ARCH-09`). Every import comes from the barrel (`REACT-ARCH-05`).

When the router's file convention collides with the organization by feature, the way out is virtual
routes instead of dismantling the features — see `TanStack Router - Virtual File Routes`.

### 5.5 Form: capture and validation kept separate

```tsx
// src/features/invoices/components/invoice-form.tsx
import { z } from 'zod'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Button, Input } from '@components/ui'
import { invoiceSchema } from '../types/invoice-schema'

const newInvoiceSchema = invoiceSchema.omit({ id: true, status: true })
type NewInvoice = z.infer<typeof newInvoiceSchema>

export function InvoiceForm({ onSave }: { onSave: (data: NewInvoice) => void }) {
  const { register, handleSubmit, formState } = useForm<NewInvoice>({
    resolver: zodResolver(newInvoiceSchema),
  })

  return (
    <form onSubmit={handleSubmit(onSave)}>
      <Input {...register('description')} aria-invalid={!!formState.errors.description} />
      <Button type="submit" disabled={formState.isSubmitting}>Save</Button>
    </form>
  )
}
```

The creation schema is **derived** from the domain schema with `.omit()`, not rewritten. The component
receives `onSave` as a prop instead of calling the mutation directly: that way it is testable without a server and the
orchestration stays with whoever composes it.

### 5.6 Note on the Next.js App Router

In Next, `app/` **is the route layer**, not bootstrap — the original article's naming collides.
The mapping is direct: `app/` takes the place of `routes/`, and `src/features/` stays the same.

Two precautions that only exist in Next and that change the barrel's design:

- **`'use client'` contaminates the barrel.** An `index.ts` that re-exports a client component together with
  server utilities drags the whole module into the client bundle. In mixed features,
  separate the surfaces: `index.ts` (server) and `client.ts` (client), and import from each one
  according to the context.
- **Large barrels cost build time.** An `index.ts` that re-exports a lot makes the bundler walk
  the whole graph even when the consumer uses a single symbol. The structural mitigation is keeping the
  barrel small — there is no flag that solves this for local code. Next's
  `experimental.optimizePackageImports` is for `node_modules` **packages** that export
  hundreds of modules (the default list is entirely third-party libraries), it is experimental and the
  docs themselves do not recommend it for production. Do not count on it for a feature barrel.

None of this invalidates the structure — it only means the server/client boundary is a second
dimension that cuts across the vertical slice.

---

## 6. Antipatterns

| Antipattern | Why it hurts | Fix |
| --- | --- | --- |
| `import { X } from '@features/invoices/components/invoice-card'` | Ties the consumer to the internal structure; moving the file breaks the app. | Export it in the barrel and import `@features/invoices`. |
| `import { useInvoices } from '@features/invoices'` inside `features/invoices/` | Cycle through `index.ts`; `undefined` export at runtime. | Relative path: `../api/invoices-queries`. |
| Logic in `index.ts` | Runs for every consumer; becomes an import with a side effect. | The barrel only re-exports. |
| `libs/format-invoice.ts` | Domain inside the generic; `libs/` stops being reusable. | Move it to `features/invoices/utils/`. |
| Generic `features/common/` folder | Becomes an ownerless dumping ground; nobody knows what can be deleted. | Name it by capability: `features/core/permissions/`. |
| Feature created for one screen | A feature is a product capability, not a route. | Keep it in an existing feature until it has its own domain. |
| Seven empty subfolders in a new feature | Noise; suggests structure that does not exist. | Create the folder at the second file of that type. |
| `stores/` holding an API response | Reimplements cache, invalidation and revalidation by hand. | `queryOptions` in `api/`. |

React antipatterns (not architecture ones) are in [React - Patterns](react-patterns.md) § 8.

---

## 7. Enforcement with Biome

> **A boundary nobody verifies is only a convention.** Folder structure does not solve architecture;
> what solves it is dependency discipline, and discipline that depends on human memory fails at
> scale. The rules below move part of `REACT-ARCH-*` from review to build.

`biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/latest/schema.json",
  "linter": {
    "rules": {
      "correctness": { "noUnusedImports": "error" },
      "suspicious": { "noImportCycles": "error" },
      "style": {
        "noRestrictedImports": {
          "level": "error",
          "options": {
            "patterns": [
              {
                "group": ["@features/*/*", "@features/*/*/**"],
                "message": "REACT-ARCH-05: deep import into a feature. Import through the barrel: @features/<feature>."
              },
              {
                "group": ["@components/*/*", "@components/*/*/**"],
                "message": "REACT-ARCH-05: deep import into a shared component. Import @components/ui or @components/layout."
              }
            ]
          }
        }
      }
    }
  },
  "overrides": [
    {
      "includes": ["src/features/**"],
      "linter": {
        "rules": {
          "style": {
            "noRestrictedImports": {
              "level": "error",
              "options": {
                "patterns": [
                  {
                    "group": ["@routes/**"],
                    "message": "REACT-ARCH-07: a feature does not import a route. The route knows the feature, never the other way around."
                  },
                  {
                    "group": ["@features/*/*", "@features/*/*/**"],
                    "message": "REACT-ARCH-05: deep import into a feature. Import through the barrel: @features/<feature>."
                  }
                ]
              }
            }
          }
        }
      }
    },
    {
      "includes": ["src/components/**", "src/hooks/**", "src/libs/**", "src/types/**"],
      "linter": {
        "rules": {
          "style": {
            "noRestrictedImports": {
              "level": "error",
              "options": {
                "patterns": [
                  {
                    "group": ["@features/**", "@routes/**"],
                    "message": "REACT-ARCH-06: the generic layer knows no domain and no route. Invert the dependency through a prop or parameter."
                  }
                ]
              }
            }
          }
        }
      }
    }
  ],
  "assist": {
    "actions": { "source": { "organizeImports": "on" } }
  }
}
```

### What each rule covers

| Rule | Group | Available since | Covers |
| --- | --- | --- | --- |
| `noImportCycles` | `suspicious` | Biome v2.0.0 | `REACT-ARCH-04`, `REACT-ARCH-10` |
| `noRestrictedImports` | `style` | `patterns` since v2.2.0 | `REACT-ARCH-05`, `REACT-ARCH-06` |
| `noUnusedImports` | `correctness` | — | barrel with a dead export |

None of the three is recommended by default — `noImportCycles` and `noRestrictedImports` must be
enabled explicitly. `noImportCycles` ignores type-only imports by default (`ignoreTypes`), which
is the correct behavior: the compiler erases them and they do not form a cycle at runtime.

Per-folder scope uses `overrides[].includes` with gitignore-style globs (`**` as a whole component,
`!` for an exception). **Only the first matching override is applied** — the Biome docs are explicit:
*"If a file can match three patterns, only the first one is used."* The order of the array matters, and the
two overrides above do not overlap on purpose. Rules declared at the top level apply to
files no override captured; that is why the global deep-import pattern is repeated inside the
`src/features/**` override, which would otherwise overwrite the whole rule.

### What Biome does not express

Three rules stay fully or partially in review:

- **`REACT-ARCH-06` in the full reverse sense.** You can forbid the generic layer from importing
  features. You cannot detect a business rule *written* inside `libs/`.
- **`REACT-ARCH-08`, the third consumer.** It is a judgment about duplication, not about the graph.
- **`REACT-ARCH-04` in the non-re-exported case.** `noImportCycles` only catches the import of the feature's own alias
  when it closes a cycle — see the caveat in § 4. Expressing the remaining case would require one override per
  feature, which does not pay off.

Also, `REACT-ARCH-09` has no lint rule, but it has the bench test from § 4, which is objective
enough for a review to arbitrate.

Also, `noPrivateImports` (`correctness` group, v2.0.0) **does not work** as a feature boundary,
even though it seems to. Biome's `@package` visibility is relative to the folder that declares the symbol:
modules that only share an ancestor folder cannot import. That means
`features/invoices/index.ts` **cannot** re-export an `@package` symbol from
`features/invoices/components/` — the barrel pattern breaks. The rule is useful at fine granularity
(making helpers inside `api/` private, for example), not as a domain boundary.

**Verified.** This configuration was run against Biome **2.5.8** in a real project: the schema is
accepted without complaint, and the two cases that matter fire as described —
`@features/invoices/api/invoices-client` from another feature emits `REACT-ARCH-05`, while
`@features/invoices` (the barrel) passes; and a file in `src/libs/` importing `@features/invoices`
emits `REACT-ARCH-06`. The `@features/*/*` globs do what the text claims.

Still, run it against your own project when adopting — the shape of your aliases may differ:

```bash
pnpm biome check src
```

Use `biome check` **without** `--write` to verify. With `--write` it fixes and rewrites files,
which is useful during development and useless as an acceptance criterion: a command that fixes the problem
before reporting it proves nothing.

---

## 8. Gradual migration

Do not reorganize the whole repository in one PR. The order below keeps the app green at every step.

1. **Aliases first.** Add `paths` to `tsconfig.json` and the equivalent `resolve.alias` in
   `vite.config.ts` and `vitest.config.ts`. All three must agree, or the tests break on their own.
2. **Extract what is genuinely generic.** Move into `components/ui/`, `hooks/` and `libs/` only what already
   has no domain today. Do not "generalize" anything at this stage.
3. **Migrate one small, isolated feature, whole.** A capability with few dependencies, from the
   component to the schema. The goal is to have a living example in the repository, not coverage.
4. **Add the barrel and fix the consumers.** This is where the public surface becomes explicit.
5. **Turn on `noImportCycles`.** It reveals couplings nobody had seen. Treat it as an error
   from the start — in warning mode it gets ignored.
6. **Turn on `noRestrictedImports` per layer.** Start with the generic layer (`overrides` above) —
   it tends to flag fewer violations because it has fewer files, but confirm first with
   `pnpm biome check src` instead of assuming.
7. **Only then consider `features/core/`.** When `REACT-ARCH-08` actually fires.

One PR per step. Structural migration mixed with behavior change is unreviewable.

---

## 9. When not to use it

This structure charges discipline before it returns value. The return shows up when there are **multiple
domains and more than one person working on it**. It is not worth it when:

- the app has a single domain (a landing page, a calculator, a form);
- the product is still discovering its shape — a boundary defined early is a boundary defined wrong;
- the project is mostly a design system, where the natural organization is by component;
- it is a prototype with an expiration date.

In those cases, a flat `components/` + `hooks/` is the right answer. `REACT-ARCH-01` applies from the
moment a second domain exists — not before.

The cost, when you adopt it: more files, more indirection, barrels that need maintenance, and the
real need to enforce the rules. Without enforcement, the layers become suggestions and the result is
worse than the flat structure — because now there is the **illusion** of a boundary.

---

## 10. Skill contract

Implements the contract of [React.js](react-js.md) § 7. A structure skill derives **from this note**, not from the whole React
doc, and records `fonte: "[Feature-Based Architecture](feature-based-architecture.md)"` in its frontmatter.

The skill that implements this contract is `react-structure`. It routes by task and repeats nothing
of what is here — if the two diverge, the skill is the one that is wrong.

### Minimum loading

```
ALWAYS:              § 2 (layers and direction) + § 4 (REACT-ARCH-* rules)

WHEN CREATING A FEATURE:  § 3 (anatomy) + § 5 (examples in the stack)
WHEN MOVING CODE:         § 8 (migration) + REACT-ARCH-08
WHEN REVIEWING IMPORTS:   § 6 (antipatterns) + § 7 (what lint covers)
WHEN CONFIGURING A REPO:  § 7 (biome.json and aliases)

ALSO:                [React - Patterns](react-patterns.md) for component decisions
                     (this note decides where the file lives; that one decides what goes inside)

NEVER:               invent a new layer without recording it here
```

### Order of decisions when creating new code

1. **Is this a domain?** If it has no product vocabulary of its own, it is not a feature — it is `components/`
   or `libs/`.
2. **Does the domain already exist?** Prefer growing an existing feature to creating the ninth. A new feature requires
   a new capability, not a new screen.
3. **Is the data remote?** If so, `api/` with `queryOptions` — not `stores/`.
4. **Is this public?** Only what another layer actually consumes goes into the barrel.
5. **Who will import this?** If the answer is another feature, confirm `REACT-ARCH-05` and record the
   `REACT-ARCH-08` counter.

### How to cite a finding

Cite the ID, the file and the line. Do not paraphrase the rule:

> `REACT-ARCH-05` — `src/features/reports/components/chart.tsx:8`
> Deep import: `@features/invoices/api/invoices-queries`.
> Fix: export `invoicesQueryOptions` in the `invoices` barrel and import `@features/invoices`.

### Invariants

1. **Structure does not replace the rule.** Moving a file does not fix an inverted dependency.
2. **Direction before aesthetics.** A `REACT-ARCH-06` or `-07` violation takes precedence over
   any organizational preference.
3. **Do not extract without the third consumer** (`REACT-ARCH-08`). Duplication is cheaper than the
   wrong abstraction.
4. **Verify before asserting.** If a Biome rule is not in the table in § 7, it was not
   verified in this note — check `biomejs.dev` and update it here.
5. **The source wins.** A divergence between this note and the real behavior of Biome or TanStack is a
   bug in this note.

### Self-check before delivering

- [ ] Every import from another feature goes through the barrel (`REACT-ARCH-05`)
- [ ] No import inside the feature uses `@features/` (`REACT-ARCH-04`)
- [ ] The barrel only has re-exports (`REACT-ARCH-03`)
- [ ] Nothing in `components/`, `hooks/`, `libs/` imports domain (`REACT-ARCH-06`)
- [ ] No feature imports from `@routes/` (`REACT-ARCH-07`)
- [ ] Every new mutation invalidates the `queryKey` it affects, and only keys of its own feature
- [ ] Test colocated next to the tested file, outside the barrel
- [ ] Types exported with `export type` (`REACT-ARCH-11`)
- [ ] Files and folders in kebab-case (`REACT-ARCH-12`)
- [ ] `pnpm biome check src` passes

---

## Divergences from the source

The `Feature-Based Architecture in React` article (dev.to) is the origin of the argument; this note is the
source of truth for decisions in the vault. Where they diverge, and why:

| Axis | Article | Here | Reason |
| --- | --- | --- | --- |
| Layers | `app/` `pages/` `features/` `shared/` | `routes/` `features/` + `components/` `hooks/` `libs/` `types/` | `app/` collides with Next; the generic layer is already flat in the vault's scaffold |
| Reuse core | `features/core/` from the start | only when `REACT-ARCH-08` fires | a layer without consumers becomes a dumping ground |
| Feature ↔ sibling | forbidden | allowed through the barrel | see § 4, adopted decision |
| Orchestration subfolder | `containers/` | `api/` + composition in the route | `containers/` is pre-hooks vocabulary; TanStack Query fills the role |
| Naming | `UserAvatar/` PascalCase | strict kebab-case | consistency with the scaffold and with case-insensitive file systems |
| Alias | `@/features/*` | `@features/*` | the vault's scaffold convention |
| Enforcement | `eslint-plugin-boundaries` | Biome | Biome is the single lint tool here |

The article also positions itself as a simplification of Feature-Sliced Design. This note does not adopt FSD:
no `entities/`/`widgets/`, no layer numbering.

---

## Related

- `Fronteira do BFF - forma, jornada e regra` — sibling note: this one decides where frontend code
  lives; that one decides what crosses the server boundary and who owns each decision
- `Monorepo com Bun - estrutura e tooling` — when a layer of this note becomes its own package
- [Architecture in React](architecture-in-react.md) — parent note: the axes of architectural decision
- `react-structure` — the skill that implements the contract in § 10
- [React - Patterns](react-patterns.md) — decisions inside the component
- [React.js](react-js.md) — the React hub and § 7, the skill contract
- `TanStack Router - Virtual File Routes` — when the route collides with the feature
- `Frontend roadmap` — study track

## Sources consulted

- `Feature-Based Architecture in React` — source article (dev.to)
- [Biome — `noImportCycles`](https://biomejs.dev/linter/rules/no-import-cycles/)
- [Biome — `noRestrictedImports`](https://biomejs.dev/linter/rules/no-restricted-imports/)
- [Biome — `noPrivateImports`](https://biomejs.dev/linter/rules/no-private-imports/)
- [Biome — configuration and `overrides`](https://biomejs.dev/reference/configuration/)
- the tc96 commands `scaffold-fba-02-biome` and `scaffold-fba-05-fba` — the scaffold's conventions
