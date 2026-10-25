# Template: User experience

Tool-neutral, saved as `.specs/<capability>/user-experience.md`. The **experience contract** of
one capability: how the person moves through it (UX), what each screen shows in every state
(UI), what keeps them from getting stuck (usability), and what every person can reach and
operate (accessibility). Written by `product-designer`. Rules: `rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/` |
| `stories` | the stories from the PRD this file covers, by ID |
| `owner` | `product-designer` |
| `status` | `draft` · `reviewed` · `accepted`; frontend work does not start on `draft`, and only the owner moves it |

## Body (copy from here down)

---

### 1. UX: journey and flow

**Persona and context:** [who uses this, where, with what pain point, and the source of each
claim. A claim with no source is listed under §3 as an assumption.]

**Journey:** [from trigger to value, one line per step: what the person sees, does, and what
can go wrong.]

1. [step]
2. [...]

**Flow:** [screens and transitions, one flow per journey. A diagram is optional; the
transitions are not.]

### 2. UI: screens and components

One block per screen or journey step:

```
## <Screen / journey step>
**Who lands here and why:** ...
**States:** loading → ... | empty → ... | success → ... | failure → ... (what to do next)
**Lives in the URL:** <filter, tab, page, or "nothing">
**Components and catalog level:** <component> → <UI | Patterns | Features | Layout>
```

**New or changed components:** [for each one: variants and states as named stories, what is a
prop and what is composition, and how it behaves with overflow, long text, and no data.]

### 3. Usability

| Check | Answer |
| --- | --- |
| recovery path for every expected failure | [failure → what the screen offers] |
| destructive actions | [confirm or undo, per action] |
| optimistic actions | [what is shown, and how it reverts on failure] |
| perceived speed | [the requirement, e.g. "feedback within 1 s"; the means is the implementer's] |
| state preserved on reload and on a shared link | [what lives in the URL] |

**Not validated with a user:** [each assumption, and how it will be tested. An empty list
means every claim above has a source.]

### 4. Accessibility

| Control | Role | Accessible name |
| --- | --- | --- |
| [control] | [button, link, textbox...] | [the exact name] |

**Forms:** [each field's label, where its error appears and how it is announced.]

**Focus and keyboard:** [the focus order on each screen, checked against the visual order, and
the keyboard path through the main flow.]

### Done when

- Every screen in §2 has all four states.
- Every expected failure has a recovery path in §3.
- Every control in the flow is in the §4 table, with role and name.
- Every component's catalog level is decided by vocabulary, not by consumer count.
- Every claim about the user has a source, or is listed under "Not validated with a user".

### Out of this file

| Belongs in | What |
| --- | --- |
| the PRD | whether to build it, priority, acceptance scenarios |
| a design doc or RFC | boundaries (BFF versus backend, feature), contracts, schemas |
| the frontend Task, decided by the implementer | where the code lives, who owns each piece of state, which React API |
| test design | the level of each test |
