# The sentence, the level and the proportion

> Steps 1 to 3 of the skill. The full tree is § 4.1 of [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md); here is the
> path and what it eliminates.

---

## The sentence, before anything else

> **What exactly can go wrong here?**

Write it down. If you cannot, **the test should not be written yet** (`TS-CORE-01`): there is
no way to judge whether it is worth the cost, nor which level it belongs to.

A good sentence **names a subject and a wrong behavior** — and it is the sentence that decides
the level, not intuition:

| ✗ vague | ✓ actionable | Level the sentence reveals |
| --- | --- | --- |
| "checkout might break" | "a discount above 50% might be applied without manager approval" | unit |
| "the listing might fail" | "a just-created order might not appear in the list" | E2E |
| "the form might error" | "the tax-ID field might accept 10 digits" | unit |
| "the screen might look odd" | "an empty list might render without the empty state" | component |
| "the API might change" | "the server might rename `quantity` and the client not notice" | contract |

---

## The level

| What can go wrong | Level | Tool |
| --- | --- | --- |
| calculation, parsing, validation, domain invariant | **unit** | `bun-test-build` |
| two of my pieces talking (use case + repository) | **integration**, with a controlled real dependency | `bun-test-build` |
| the format crossing the boundary with a system that is not mine | **contract** — and much of it is the compiler | [Hono - Validação e RPC](../../../../knowledge-base/docs/hono-validacao-e-rpc.md) · [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| visual/interactive state of a component | **component** | `storybook-story` · `storybook-test` |
| the critical journey works with routing, session and network | **E2E** | `playwright-build` |
| incompatible type, incorrect API use | **static** | TypeScript via Context7, `/microsoft/typescript` |

Three cuts decide most cases:

- **A business rule is never E2E** (`TS-NIV-02`). E2E verifies that the screen displays the calculated value; the calculation is a unit test.
- **If it needs routing, login or more than one screen** → E2E. If it varies **props** → component.
- **If the defect is in the joint between pieces**, a unit test of each piece passes and the system breaks — that is integration.

And the cut that separates this skill from intuition: **E2E is the smallest slice of the suite**, and writing E2E by default is the most expensive mistake an agent makes (`TS-CORE-02`).

---

## The proportion — per module, not per repository

`TS-NIV-08`. It is not a global policy:

```
Is this module's complexity INSIDE functions?
 (calculation, rich domain, dense rules, parsing)
 → pyramid: the mass goes to unit

Is the complexity BETWEEN the pieces?
 (BFF, data adaptation, orchestration, contract mapping)
 → trophy: the mass goes to integration
```

The package that computes tax is a pyramid. The route that orchestrates three calls is a trophy.
**The same repository has both**, and treating the proportion as a global policy is what
produces an unbalanced suite.

The two models agree on one thing, and it holds as a rule: **E2E is the smallest slice**, and
the inverted shape — mass in E2E — is the antipattern (`TS-NIV-04`).

**Count the static layer.** TypeScript and lint catch a whole class of defect before any test
runs, and they are the cheapest layer there is (`TS-TIPO-08`).

---

## Related

- [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 4.1 — the full tree
- [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) — the source
- `tecnicas-de-caso.md` — the next step, when there is input to exercise
