# Template: the triage file

Saved as `.specs/triage/<YYYY-MM-DD>-<slug>.md`, one per request. Answers one question: **what
does this request touch, what already exists, and where does each part go next?** Written by the
main session in `workflow-search`. Rules: `SDD-FLOW-05`, `SDD-FLOW-06`, `SDD-PLAN-01`.

It is a record of facts and routes, not a decision: it has no status to approve, and it is never
edited after `workflow-plan` reads it (`SDD-FLOW-02`). A later request gets its own file.

## Fields

The file opens with these fields as YAML frontmatter, then the body.

| Field | Meaning |
| --- | --- |
| `request` | the person's words, quoted |
| `date` | ISO 8601 |
| `route` | `amendment` · `adr` · `delivery` · `fast-lane` · `owner`: the first stop in plan, as the route section below orders it |

## Body (copy from here down)

---

### Slices

One row per slice, one sentence each. An axis the request does not touch has no row.

| # | Axis | Slice | Entities · capabilities | Answer | Source | Verdict | Next step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | product | [the promised behavior, in one sentence] | [User · authenticate] | [what the record or the code says, one line] | record: [path] · code: [path:line] · none | [verdict] | [next step] |

**Axes:** `product` · `frontend` · `backend` · `tooling` · `stack`.

**Verdicts and their next step:**

| Verdict | Next step |
| --- | --- |
| `exists` | nothing; the Source column cites it |
| `product-decision` | plan · `product-manager`, PRD amendment |
| `technical-decision` | plan · `software-architect`, ADR |
| `build` | plan · `spec-writer`, delivery plan |
| `no-behavior-change` | plan · fast lane |
| `untraced` | a question for the owner |

### Facts

The code facts `repo-explorer` returned, grouped by slice, each with `file:line`. These are the
repo search the delivery plan cites (`SDD-PLAN-01`). A slice the record answered has no entry here.

- S3 — [fact] — [path:line]

### Route

The order plan follows, one line per stop. An amendment comes before the delivery plan that
depends on it, and an ADR before the plan that cites it. Which layer builds each `build` slice is
plan's; an order you infer is `(proposed)`.

1. [amendment: S1 — product-manager]
2. [ADR: S2 — software-architect]
3. [delivery plan: S3 backend, S4 frontend, … — spec-writer]

### Gaps

Each question the record and the code did not answer, with who decides it. One round only: an
unanswered question stays here, it never triggers a second search (`SDD-FLOW-06`).

- [the question, in one sentence] — decides: [owner | product-manager | software-architect]

---

## Example

```markdown
---
request: "a login page that takes the user to the dashboard when already authenticated"
date: 2026-10-26
route: amendment
---

### Slices

| # | Axis | Slice | Entities · capabilities | Answer | Source | Verdict | Next step |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | product | An authenticated user goes to the dashboard; an anonymous one sees the login | User · Session · redirect | no capability promises it | record: .specs/PRD.md | product-decision | plan · product-manager, amendment |
| S2 | stack | Which authentication provider | Session | sessions decided as WorkOS AuthKit | record: .specs/adr/0002-auth-provider.md | exists | nothing |
| S3 | backend | A way to ask "who am I" for the current session | Session · read | session middleware exists, no "me" route | code: src/server/auth.ts:14 | build | plan · spec-writer, delivery plan |
| S4 | frontend | `/login` route, a guard that redirects, the dashboard route | Route · guard | dashboard route exists, no guard | code: src/routes/dashboard.tsx:3 | build | plan · spec-writer, delivery plan |
| S5 | tooling | An E2E check of the flow; the provider's variables in each worktree | E2E · env | E2E runs on `bun run e2e`; no auth variables in `sdd.config.sh` | record: sdd.config.sh | build | plan · spec-writer, as checks and gates of the plan |

### Facts

- S3 — `authMiddleware` reads the session cookie and sets `ctx.user` — src/server/auth.ts:14
- S3 — no route returns the current user — src/server/routes.ts:1-60
- S4 — `/dashboard` renders with no `beforeLoad` — src/routes/dashboard.tsx:3

### Route

1. amendment: S1 — product-manager
2. delivery plan: S3 backend, S4 frontend needing S3's "current user" `(proposed)`, S5 as checks and gates — spec-writer

### Gaps

- After login, does the user return to the page they first tried to open, or always to the
  dashboard? — decides: owner
```
