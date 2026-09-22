# The thirty-second test

> For question 3 of the six, and it is the **highest-return** check in this skill.

---

## The procedure

**Break the code on purpose and see whether anything goes red.** Flip a sign, invert a
condition, remove a call, return `null`. If nothing breaks, **the assertion does not exist**
(`TS-SUI-04`).

Do it in three places, chosen by risk:

| Where | What to break |
| --- | --- |
| the most critical business rule | invert a comparison |
| the most used input validation | remove the check |
| the most important error path | make it succeed where it should fail |

If the suite stays green in **any** of the three, the finding is **blocking** — and it explains
question 6 all by itself ("everything passes and the defect reaches production").

---

## The rigorous version, and when it pays

**Mutation testing**: the mutant that **survives** points at the missing assertion with line
precision (`TS-SUI-04`). It is expensive to run always; the realistic use is **targeted, on the
critical module**. The thirty-second version serves every day and needs no tooling.

---

## The corollary that closes the discussion about coverage

**Coverage does not answer that question.** A test that calls the function and asserts nothing
gives full coverage (`TS-CORE-05`). That is why "96% coverage" and "the defect got through"
coexist without contradiction.

Declaring the suite sufficient **without having broken anything** is `TS-TEC-08`.

---

## Related

- [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) — coverage × mutation
- [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) — `TS-SUI-04`
- `medicao.md` — the other mandatory measurement in this skill
