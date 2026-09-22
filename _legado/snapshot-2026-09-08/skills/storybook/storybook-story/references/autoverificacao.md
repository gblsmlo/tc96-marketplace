# Autoverificação antes de entregar

```bash
bash ~/.claude/skills/storybook-story/scripts/autoverificar.sh src
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | cada story é um **estado nomeado**, não uma demo | `SB-CSF-04` |
| 2 | o que distingue as stories é `args` | `SB-CSF-04` |
| 3 | `satisfies Meta<…>` + `StoryObj<typeof meta>` | `SB-CSF-02` |
| 4 | import de `Meta`/`StoryObj` do pacote do framework | `SB-CORE-02` |
| 5 | `title` literal, e explícito em `packages/ui` | `SB-CSF-03`, `SB-CSF-10` |
| 6 | nenhum `argTypes` que o docgen já inferiria | `SB-CSF-08` |
| 7 | descrição de prop só no JSDoc | `SB-DOC-02` |
| 8 | variação reusada por spread, sem mutar `Story.args` | `SB-CSF-05` |
| 9 | ambiente por decorator/loader, não por `args` | `SB-CTX-03`, `SB-CTX-05` |
| 10 | valor não serializável passa por `mapping` | `SB-CSF-06` |
| 11 | export que não é story saiu ou está em `excludeStories` | `SB-CSF-09` |
| 12 | corpo do módulo sem efeito colateral | `SB-CORE-06` |
| 13 | nenhuma story depende de outra ter rodado | `SB-CORE-05` |
| 14 | estados vazio e de erro existem, ou a ausência foi decidida | `TS-TIPO-02` |

**Depois, suba e olhe a sidebar.** Glob que não casa **não dá erro** — dá sidebar vazia (`SB-CFG-02`). E abra a página de docs: controles vazios são o sintoma de `SB-CSF-04` violada.

---

