# Deriving the cases

> Step 4. The tree is § 4.3 of [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md). When there is input to exercise,
> this is the highest-return stage of the skill.

---

## The technique, by the shape of the input

| The input has… | Technique | Rule |
| --- | --- | --- |
| a range or a size limit | **boundary value analysis** | `TS-TEC-01` |
| classes of values | equivalence partitioning, **including the invalid ones** | `TS-TEC-02` |
| a combination of conditions | decision table | — |
| dependence on previous state | state transition, **including the invalid ones** | `TS-TEC-04` |
| many independent parameters | pairwise, or reduction by risk | `TS-TEC-09` |

**If you are going to apply one technique, make it boundary value.** It turns "I tested with 5" into four
cases that catch off-by-one, `>` × `>=` and the forgotten zero.

---

## The non-numeric boundaries — the most forgotten ones

| Boundary | Cases |
| --- | --- |
| collection | **empty**, one element, many, the maximum (`TS-TEC-03`) |
| string | empty, one character, the maximum, above it |
| text | whitespace at the edges, accents, emoji, RTL |
| optional | absent, `null`, present and empty |
| date | end of month, leap year, timezone rollover, daylight saving |
| number | zero, negative, floating-point precision |

**An empty collection is the boundary that breaks UI most** — and it is the "empty" state that
`TS-TIPO-02` requires.

---

## The five states of a flow

Loading · empty · success · error · recovery (`TS-TIPO-02`).

Covering only the happy path is the most common omission. The unhappy states are **cheap at the
component level** — that is where they cost least and are worth most (`storybook-story`).

Deciding "not to cover" is a valid answer; **not deciding** is the gap.

---

## Related

- [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) — the source
- [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) — the five states and the attributes
- `substituicao.md` — the next step, when there is a dependency
