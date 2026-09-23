# Where this file lives

> The tree and the five questions come from [Feature-Based Architecture](../../../../knowledge-base/feature-based-architecture.md) § 3, § 4 and § 10.
> Here is the path and what usually goes wrong along it — the normative text lives in the note.

---

## The five questions before creating a feature

A normative order. Answer them **in writing**, one sentence each, before the first `mkdir`.

| # | Question | If the answer stalls |
| --- | --- | --- |
| 1 | Is this a **domain**? | with no product vocabulary of its own, it is not a feature — stop, the problem is one of definition |
| 2 | Does the domain **already exist**? | a new feature requires a new capability, not a new screen |
| 3 | Is the data **remote**? | if so, `api/` with `queryOptions` — never `stores/` |
| 4 | Is this **public**? | only what another layer actually consumes goes into the barrel |
| 5 | **Who** is going to import this? | another feature → confirm `REACT-ARCH-05` and record the `REACT-ARCH-08` counter |

**The exception to question 5:** when the specification itself already names **three**
consumers, the third is not a prediction — create it straight in `features/core/` (§ 4, "Capacidade
que nasce compartilhada").

Do not open all seven subfolders at once. Criterion in § 3.

---

## The tree

Walk it in order; the first "yes" decides.

```
Does it know the vocabulary of some product capability?
├─ NO → it is generic. Which kind?
│ ├─ a visual component......... components/ui/ or components/layout/
│ ├─ a hook..................... hooks/
│ ├─ infrastructure, formatter.. libs/
│ └─ a type/contract............ types/
│ ⚠ REACT-ARCH-06: if it has to import from @features/ to
│ work, it is NOT generic. Go back and treat it as a domain.
│ If it only has to DISPLAY a domain (a header with a currency
│ selector), it stays generic: receive it through a slot and compose in
│ the shell. See § 4, "Camada genérica que precisa exibir domínio".
│
└─ YES → it is a domain. How many capabilities consume it?
 ├─ 1......... features/<capability>/, private
 ├─ 2......... it stays where it is; the second imports the barrel
 │ (REACT-ARCH-05). Do not duplicate, do not extract.
 └─ 3 or +.... features/core/<capability>/ and cut the direct
 edges (REACT-ARCH-08)
```

Inside the feature, the subdirectory follows the file's **type** — `api/`, `components/`,
`hooks/`, `stores/`, `types/`, `utils/`, per § 3. A test is co-located next to the file it
tests, never in the barrel.

---

## The most common mistake: confusing three moves

`REACT-ARCH-08` answers *when to create a shared module* — **not** *whether I may import*.
The table in § 4 ("Importar, duplicar e extrair são três movimentos diferentes") breaks the tie:

| Move | When | Cost of getting it wrong |
| --- | --- | --- |
| **import** the other feature's barrel | 2 consumers | none; it is the normal path (`REACT-ARCH-05`) |
| **duplicate** | almost never — only when the two copies are meant to diverge | two truths nobody keeps in sync |
| **extract** into `features/core/` | 3 real, counted consumers | premature extraction becomes a `libs/` that knows a domain (`REACT-ARCH-06`) |

---

## When **not** to use this structure

§ 9 of the source note. A single-domain app does not need a vertical slice, and imposing the structure
on it is this skill's antipattern. Check § 9 **before** deciding something is overkill — and
before proposing a whole repository's migration.

---

## Related

- [Feature-Based Architecture](../../../../knowledge-base/feature-based-architecture.md) § 3, § 4, § 9, § 10 — the source
- `varredura-de-imports.md` — auditing what is already placed
- `mapa-de-ids.md` — ID → severity → who enforces it
