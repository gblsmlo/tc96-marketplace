# Skills de Playwright — a tríade E2E

Três skills, um diretório cada. A divisão é **escrever · auditar · diagnosticar**, e em
Playwright ela é deliberada: o diagnóstico começa **fora do código**, no trace.

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| `playwright-build` | como escrevo este teste E2E? | [Playwright - Locators](../../knowledge-base/docs/playwright-locators.md) | 5 referências + 1 exemplo + 1 script |
| `playwright-review` | esta suíte tem defeito? | [Playwright](../../knowledge-base/docs/playwright.md) | 5 referências + 1 auditoria + 2 scripts |
| `playwright-diagnose` | por que **este** teste falha? | [Playwright - Debug e Trace](../../knowledge-base/docs/playwright-debug-e-trace.md) | 5 referências + 1 diagnóstico + 1 script |

**Antes das três vem `teste-design`:** se o que pode dar errado é regra de negócio, o
teste **não é E2E** (`TS-CORE-02`).

## O que cada pacote acrescentou

| Skill | Ganhou | Lacuna que fechou |
| --- | --- | --- |
| `playwright-build` | **`scripts/autoverificar.sh`** — os 12 itens do Passo 6 executáveis | a checklist existia; rodá-la era manual |
| `playwright-review` | **`scripts/sondas.sh`** — S1 a S8 executáveis | as oito sondas eram comandos soltos numa tabela |
| `playwright-diagnose` | **`scripts/isolar.sh`** — a bissecção inteira, com a leitura de cada resultado | a bateria estava descrita, mas montá-la era do leitor |

`isolar.sh` imprime, para cada execução, **a hipótese que ela elimina** — e repete a
advertência que a skill faz duas vezes: `--workers=1` **diagnostica, não conserta**.

## O mapa de IDs

`mapa-de-ids.md` é **gerado** e igual nas três, por
`playwright-review/scripts/gerar-mapa-de-ids.sh`. Indexa os **85** `PW-*` por satélite e
seção — o número que a própria skill declara — mais a § 6.2 completa: os dois apelidos
(`PW-ACT-07`, `PW-LOC-07`) **e** as quatro regras que *parecem* apelido e continuam citáveis.

```bash
bash plugins/hermes-e2e/skills/playwright-review/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `playwright-build` | 1.767 | `mapa-de-ids.md` (4.032) | 9.531 | 6 |
| `playwright-diagnose` | 1.676 | `mapa-de-ids.md` (4.032) | 9.059 | 6 |
| `playwright-review` | 1.412 | `mapa-de-ids.md` (4.032) | 12.033 | 6 |

Carregar as 3 skills deste grupo de uma vez custaria **4.855 tokens** só de `SKILL.md`,
e **30.623** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Relacionados

- [Skill — Índice](../README.md) · [Playwright](../../knowledge-base/docs/playwright.md) § 7 — o contrato
- `hermes-core: família teste` — a camada de conceito, que vem antes
- `hermes-backend: família bun` — unidade e integração
