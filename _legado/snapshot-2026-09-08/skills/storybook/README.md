# Skills de Storybook — três, um arquivo cada

As três dividem o **arquivo**, não o modo de trabalho — é a única família do vault
organizada assim.

| Skill | Cuida de | Fonte | Apoio interno |
| --- | --- | --- | --- |
| [[storybook-setup]] | `.storybook/`, `vite.config.ts`, versões | [[Storybook - Configuração e Builder]] | 5 referências + 2 scripts |
| [[storybook-story]] | `*.stories.tsx` — o `meta`, os `args`, as tags | [[Storybook - Stories e Args]] | 5 referências + 1 script |
| [[storybook-test]] | a `play` dentro da story, mock, a11y | [[Storybook - Testes e Interações]] | 6 referências + 1 script |

**Escrever e revisar estão juntas em cada uma**, porque no Storybook a story **é** o teste e
a decisão é a mesma nas duas direções.

## O script que define a família

`storybook-setup/scripts/descobrir-caminho.sh` — e as outras duas o chamam antes de
qualquer prescrição.

Ele lê o campo `framework` de `.storybook/main.ts`, confere os pisos de versão, e **procura
a contradição de caminho no código**:

| Sob… | O erro que ele acha | O sintoma |
| --- | --- | --- |
| `react-vite` | `parameters.tanstack.*` | **nenhum efeito** — sem erro, sem aviso (`SB-RV-04`) |
| `tanstack-react` | decorator com `RouterProvider` | um **segundo** router; o sintoma aparece longe da causa (`SB-TS-03`) |

**É a única estrutura do vault em que prescrever o caminho errado falha em silêncio** — e
por isso é a única com um script cujo trabalho é **descobrir antes de decidir**.

`SB-TS-*` e `SB-RV-*` são **mutuamente exclusivas**: citar a família do caminho errado é
achado inválido. O cabeçalho do mapa de IDs repete isso, e o `autoverificar.sh` de
`storybook-test` roda o Passo 0 **antes** dos seus próprios itens.

## O mapa de IDs

Gerado por `storybook-setup/scripts/gerar-mapa-de-ids.sh`, igual nas três: **75 IDs** em
nove famílias, com a § 6.2 completa no cabeçalho — inclusive os **pares por caminho**
(`SB-TS-03`/`SB-RV-05`, `SB-TS-08`/`SB-RV-06`), que **não** são canônico e apelido.

```bash
bash Skills/storybook/storybook-setup/scripts/gerar-mapa-de-ids.sh
bash Skills/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| [[storybook-setup]] | 1.216 | `mapa-de-ids.md` (2.877) | 7.738 | 6 |
| [[storybook-story]] | 1.195 | `mapa-de-ids.md` (2.877) | 7.389 | 6 |
| [[storybook-test]] | 1.430 | `mapa-de-ids.md` (2.877) | 8.687 | 7 |

Carregar as 3 skills deste grupo de uma vez custaria **3.841 tokens** só de `SKILL.md`,
e **23.814** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->

## Relacionados

- [[Skills/README|Skill — Índice]] · [[Storybook]] § 7 — o contrato
- [[Skills/teste/README|Skills/teste/]] — decide o nível, antes destas
- [[Storybook - Cobertura e CI]] — o lado operacional, consultado direto
