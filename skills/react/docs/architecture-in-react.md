---
titulo: Architecture in React
aliases:
  - Arquitetura em React
tags:
  - frontend
  - react
  - architecture
---
# Architecture in React

A map of the architectural decisions in a React application and of the note that answers each one. This page
**routes**; the content lives in the notes it points to.

React is a rendering library. It defines how the UI is described and reconciled, and
deliberately does **not** take a position on folders, routing, data fetching, caching or module boundaries.
"Architecture in React" is, almost entirely, the set of decisions React left open — and
that someone will make anyway, by omission if not by choice.

That is why order matters: decisions made by omission become ownerless coupling.

---

## 1. The five decision axes

| Axis | The question it answers |
| --- | --- |
| **State ownership** | Who owns each piece of data and where it lives |
| **Physical organization and boundaries** | Where the code lives and who may import whom |
| **Data flow and contracts** | How data crosses layers and how that is verified |
| **Failure boundaries** | What happens when something breaks, and where the failure stops |
| **Verification** | What keeps the architecture from eroding without anyone noticing |

The axes are independent. A project can have exemplary feature folders and no caching
policy at all — and it will suffer just the same.

---

## 2. Map: each axis and its entry note

### State ownership

| Decision | Entry note |
| --- | --- |
| Where to put each piece of state | [React - Patterns](react-patterns.md) § 2 |
| Don't store what can be computed | [React - Patterns](react-patterns.md) § 2 — `REACT-PAT-01` |
| Separate local, remote and persisted | [React - Patterns](react-patterns.md) § 2 |
| Server data is not global state | [React.js](react-js.md) § 8 · [React - Patterns](react-patterns.md) § 2 |
| Freshness and invalidation policy | `TanStack Query` |
| Data in the browser needs a version | [React - Patterns](react-patterns.md) § 2 |
| API reference | [React - State and Reactivity](react-state-and-reactivity.md) |

### Physical organization and boundaries

| Decision | Entry note |
| --- | --- |
| Group by domain, not by type | [Feature-Based Architecture](feature-based-architecture.md) § 1 |
| **Full structure, rules and enforcement** | **[Feature-Based Architecture](feature-based-architecture.md)** |
| A module's public surface | [Feature-Based Architecture](feature-based-architecture.md) § 2 — `REACT-ARCH-02` |
| When to extract into the shared layer | [Feature-Based Architecture](feature-based-architecture.md) § 4 — `REACT-ARCH-08` |
| Composition instead of configuration | [React - Patterns](react-patterns.md) § 3 |
| Boundary inside the component | [React - Patterns](react-patterns.md) § 6 |
| Cohesion and coupling, in general | [Feature-Based Architecture](feature-based-architecture.md) § 2 |

### Data flow and contracts

| Decision | Entry note |
| --- | --- |
| Direction of data | [React - Patterns](react-patterns.md) § 7 |
| Verifiable contract between front end and back end | [Feature-Based Architecture](feature-based-architecture.md) § 5.1 |
| **Who owns each decision at the server boundary** | **`Fronteira do BFF - forma, jornada e regra`** |
| When code becomes a package, and what CI needs to verify | `Monorepo com Bun - estrutura e tooling` |
| Where to validate, and how many times | [Feature-Based Architecture](feature-based-architecture.md) § 5.2 |
| Runtime schema | [Feature-Based Architecture](feature-based-architecture.md) § 5.1 |
| Capture separate from validation | [Feature-Based Architecture](feature-based-architecture.md) § 5.5 · [React Hook Form](react-hook-form.md) |
| Extract synchronization | [React - Effects and Synchronization](react-effects-and-synchronization.md) |
| Trust boundary on the server | [React - Server Components and Directives](react-server-components-and-directives.md) § 3 |
| Route, loader and data fetching | `TanStack Router` |

### Failure boundaries

| Decision | Entry note |
| --- | --- |
| Expected × unexpected error | [React - Suspense and Async](react-suspense-and-async.md) § 4 |
| Isolate rendering failure | [React - Patterns](react-patterns.md) § 6 · [React - Suspense and Async](react-suspense-and-async.md) § 4 |
| Revert an optimistic change | [React - Forms and Actions](react-forms-and-actions.md) § 5 · `TanStack Query` |
| Async and loading states | [React - Suspense and Async](react-suspense-and-async.md) |

### Verification

| Decision | Entry note |
| --- | --- |
| Test behavior, not implementation | `Teste de Software` |
| Boundary verified by lint | [Feature-Based Architecture](feature-based-architecture.md) § 7 |
| Normative React rules | [React - Rules of React](react-rules-of-react.md) |
| Purity as a precondition | [React - Rules of React](react-rules-of-react.md) § 2 |

---

## 3. Order of decisions

Not every decision costs the same to undo. Decide early what is expensive to reverse; postpone the rest until
there is evidence.

| Order | Decision | Cost to reverse |
| --- | --- | --- |
| 1 | Direction of dependency between layers | **high** — cuts across all the code |
| 2 | Where remote data lives | **high** — changes every component that consumes it |
| 3 | Contracts and validation at the boundary | **high** — without them, the error shows up far from the cause |
| 4 | Physical organization into features | medium — moving a file is mechanical if the barrel exists |
| 5 | Internal structure of each feature | low — local to the feature |
| 6 | Extraction into the shared layer | low — and it should be postponed on purpose |

Item 6 is the one most commonly done ahead of time and the one that costs the most when done ahead of time: an abstraction created at the
second consumer has an invented contract, and the third case arrives demanding a flag.

A corollary: **folder structure is not the first decision.** It is the fourth. Projects that start
by drawing the directory tend to have pretty boundaries with inverted dependencies running across them.

---

## 4. The decision adopted for physical organization

[Feature-Based Architecture](feature-based-architecture.md) — vertical slice by domain, `index.ts` as the public API, a single dependency
direction `routes → features → generic`, and `REACT-ARCH-*` rules verified with Biome.

That is this note's child note and the **default entry** for writing or reviewing React code structure
in the vault. It also defines the contract a structure skill carries (§ 10).

---

## 5. Use by an agent

This page is a **router**, not a source. An agent must not cite it as a rule — it has no
normative IDs. It answers a single question: *which note to open for this decision*.

```
STRUCTURE / IMPORT / FOLDER DECISION
  → [Feature-Based Architecture](feature-based-architecture.md) § 4 (rules) and § 10 (contract)

DECISION INSIDE THE COMPONENT
  → [React - Patterns](react-patterns.md)

NORMATIVE REACT RULE
  → [React - Rules of React](react-rules-of-react.md) and [React.js](react-js.md) § 6

API LOOKUP
  → [React.js](react-js.md) § 4 (API map) → the indicated satellite
```

The knowledge base's source hierarchy, from strongest to weakest: verified tool
documentation (`verificado-em` in the frontmatter) → router
pages, like this one, that only point and have no ID. A divergence between a router page and a verified doc
is a bug in the page. See [React.js](react-js.md) § 7, and `react-build` as an example of a skill
that implements that contract.

**Three exceptions, explicit.** [Feature-Based Architecture](feature-based-architecture.md),
`Fronteira do BFF - forma, jornada e regra` and `Monorepo com Bun - estrutura e tooling` are
**normative** pages: they have citable IDs (`REACT-ARCH-*`, `BFF-*` and `MONO-*`), invariants and a
skill contract — unlike this page, which only routes. The difference is not where the file
lives: it is that they don't summarize a tool's external documentation, but record a decision
of this house, with conventions that only exist in this project. A page with a skill contract is citable
as a rule; this page, which only routes, is not. When a tool doc contradicts one of these
three on a verifiable fact — Biome behavior, the TanStack API — the doc wins and the normative
page is corrected.

---

## Related

- [Feature-Based Architecture](feature-based-architecture.md) — child note: physical organization of the code
- [React.js](react-js.md) — React hub: mental model, API map, skill contract
- [React - Patterns](react-patterns.md) — structural decision inside the component
- [React - Rules of React](react-rules-of-react.md) — normative base
- `Frontend roadmap` — study track and practical evidence
