# O caminho do framework — o Passo 0 que não se pula

**Antes de qualquer outra coisa**, leia o campo `framework` de `.storybook/main.ts` (`SB-CFG-01`):

| `framework` | Caminho | Nota a carregar |
| --- | --- | --- |
| `@storybook/tanstack-react` | **A** | [[Storybook - TanStack React]] · família `SB-TS-*` |
| `@storybook/react-vite` | **B** | [[Storybook - React Vite]] · família `SB-RV-*` |

Isto não é formalidade. É a única estrutura deste vault em que **prescrever o caminho errado falha em silêncio**:

- sob `react-vite`, `parameters.tanstack.*` **não tem efeito nenhum** — sem erro, sem aviso (`SB-RV-04`);
- sob `tanstack-react`, um decorator com `RouterProvider` cria um **segundo** router, e o sintoma aparece longe da causa (`SB-TS-03`).

**As duas famílias são mutuamente exclusivas.** Citar `SB-TS-*` contra um projeto `react-vite` é achado inválido, e vice-versa — e `SB-TS-03`/`SB-RV-05` e `SB-TS-08`/`SB-RV-06` são **pares por caminho**, não canônico e apelido ([[Storybook]] § 6.2).

Se o componente sob teste não toca rota nem router, o caminho não muda nada — mas confirme antes de assumir isso, porque sob `tanstack-react` o redirecionamento de `@tanstack/react-router` para a camada de mock é **global**, não opt-in por story.

---


---

## Por que este passo é diferente de todos os outros do vault

É a **única estrutura em que prescrever o caminho errado falha em silêncio**. Não há erro,
não há aviso, não há tipo reclamando:

| Sob… | O erro | O sintoma |
| --- | --- | --- |
| `react-vite` | `parameters.tanstack.*` | **nenhum efeito** — a story renderiza, e o que você configurou é ignorado (`SB-RV-04`) |
| `tanstack-react` | decorator com `RouterProvider` | um **segundo** router; o sintoma aparece longe da causa (`SB-TS-03`) |

O script `descobrir-caminho.sh` de [[storybook-setup]] lê o campo e **já procura a
contradição correspondente** no código.

```bash
bash ~/.claude/skills/storybook-setup/scripts/descobrir-caminho.sh
```
