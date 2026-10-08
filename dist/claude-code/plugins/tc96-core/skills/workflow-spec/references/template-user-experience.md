# Spec template: User experience

Tool-neutral, saved as `.specs/<feature>/user-experience.md`. It is the **experience contract**
of one feature: how the person moves through it (UX), what each screen shows in every state
(UI), what keeps them from getting stuck (usability), and what every person can reach and
operate (accessibility). `product-designer` writes it from `requirements.md`; every frontend
Task in `tasks.md` cites it as input.

It never decides what to build, which is `requirements.md` and `product-manager`, nor how the
React code is structured, which `frontend-developer` decides while executing the Task.

---

## Fields

| Field | Meaning |
| --- | --- |
| `feature` | the slug of `.specs/<feature>/` |
| `stories` | the stories from `requirements.md` this file covers, by ID |
| `owner` | `product-designer` |
| `status` | `draft` · `reviewed` · `accepted`; a frontend Task does not start on `draft` (`WF-SPEC-04`), and only the owner moves it (`WF-SPEC-06`) |

## Body (copy from here down)

---

### 1. UX: journey and flow

**Persona and context:** [who uses this, where, with what pain point, and the source of each
claim: data, interview, ticket. A claim with no source is listed under §3 as an assumption
(`WF-RES-04`).]

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
**Components and catalog level:** <component> → <UI | Patterns | Features | Layout> (SB-LAYER-03)
```

**New or changed components:** [for each one: variants and states as named stories, what is a
prop and what is composition, and how it behaves with overflow, long text, and no data.]

### 3. Usability

| Check | Answer |
| --- | --- |
| recovery path for every expected failure | [failure → what the screen offers] |
| destructive actions | [confirm or undo, per action] |
| optimistic actions | [what is shown, and how it reverts on failure] |
| perceived speed | [the requirement, e.g. "feedback within 1 s"; the means is `frontend-developer`'s] |
| state preserved on reload and on a shared link | [what lives in the URL] |

**Not validated with a user:** [each assumption, and how it will be tested. An empty list
means every claim above has a source.]

### 4. Accessibility

| Control | Role | Accessible name |
| --- | --- | --- |
| [control] | [button, link, textbox...] | [the exact name] |

The role and name in this table are the contract with the tests: they are what `qa-engineer`
locates (`PW-LOC-01`).

**Forms:** [each field's label, where its error appears and how it is announced
(`RHF-A11Y-01`, `RHF-A11Y-02`, `RHF-A11Y-03`).]

**Focus and keyboard:** [the focus order on each screen, checked against the visual order
(`RHF-A11Y-04`), and the keyboard path through the main flow.]

### Done when

- Every screen in §2 has all four states.
- Every expected failure has a recovery path in §3.
- Every control in the flow is in the §4 table, with role and name.
- Every component's catalog level is decided by vocabulary, not by consumer count (`SB-LAYER-03`).
- Every claim about the user has a source, or is listed under "Not validated with a user".

### Out of this file

| Belongs in | What |
| --- | --- |
| `requirements.md` | whether to build it, priority, acceptance scenarios |
| `design.md` | boundaries (BFF × backend, feature), contracts, schemas |
| the frontend Task, decided by `frontend-developer` | where the code lives, who owns each piece of state, which React API |
| `test-design` | the level of each test |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `product-designer`: the agent that writes this file; its "Output format" is the §2 block
- `template-story.md`: the stories this file covers come from that shape
- `template-tasks.md`: a frontend Task cites this file under **Inputs**
- `template-design.md`: the boundaries and contracts this file does not hold
- [Storybook estruturado por Atomic Design](../../../referencias/storybook-estruturado-por-atomic-design.md): the `SB-LAYER-*` rules
- [React Hook Form - Registro e Controle](../../../referencias/react-hook-form-registro-e-controle.md): the `RHF-A11Y-*` rules
- [Playwright - Locators](../../../referencias/playwright-locators.md): `PW-LOC-01`
