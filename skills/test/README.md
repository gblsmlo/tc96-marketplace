# Skills de teste — a camada de conceito

Três skills, um diretório cada. Elas decidem **o quê**, **em que nível** e **se a suíte
protege** — e nunca escrevem teste: isso é da camada de ferramenta
(`hermes-e2e: família playwright`, `hermes-backend: família bun`, `storybook-test`).

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| `teste-design` | que teste eu escrevo, e em que nível? | [Teste de Software - Níveis e Escopo](../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) | 4 referências + 1 exemplo + 1 script |
| `teste-review` | esta suíte protege alguma coisa? | [Teste de Software](../../knowledge-base/docs/teste-de-software.md) | 4 referências + 1 auditoria + 1 script |
| `teste-diagnose` | por que ninguém confia nesta suíte? | [Teste de Software - Confiabilidade da Suíte](../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) | 4 referências + 1 diagnóstico + 1 script |

**A ordem é conceito → ferramenta.** Pular esta camada produz **E2E por default**, que é o
antipadrão de maior custo do stack (`TS-CORE-02`).

## O que cada pacote acrescentou

| Skill | Ganhou | Lacuna que fechou |
| --- | --- | --- |
| `teste-design` | `references/` por passo, e a grade de 24 antipadrões separada | o SKILL.md tinha 291 linhas e afogava o procedimento em tabela |
| `teste-review` | **`scripts/sondas-suite.sh`** — S1 a S9 executáveis | as nove sondas existiam só como descrição em tabela |
| `teste-diagnose` | **`scripts/medir-flakiness.sh`** — inventário de anestésicos + taxa medida | "sem a taxa não há diagnóstico" era regra sem instrumento |

`medir-flakiness.sh` faz as duas coisas que a skill exige antes de opinar: **inventaria os
anestésicos já instalados** (retry, `workers: 1`, `skip`, espera por tempo fixo, relógio
real, prefixo numérico, `try/catch` no corpo) e **mede a taxa** repetindo o comando N vezes,
comparando com o limiar de ~1%.

## O mapa de IDs

`mapa-de-ids.md` é **gerado** e igual nas três, por
`teste-design/scripts/gerar-mapa-de-ids.sh`. Ele indexa os **64** `TS-*` por satélite e
seção — o mesmo número que a § 6.2 do hub declara, o que serve de conferência — e carrega a
tabela de apelidos: `TS-NIV-01`, `TS-DUB-02` e `TS-SUI-02` **não** se citam.

```bash
bash plugins/hermes-core/skills/teste-design/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `teste-design` | 2.032 | `mapa-de-ids.md` (3.085) | 8.482 | 6 |
| `teste-diagnose` | 1.994 | `mapa-de-ids.md` (3.085) | 9.365 | 6 |
| `teste-review` | 1.631 | `mapa-de-ids.md` (3.085) | 9.941 | 6 |

Carregar as 3 skills deste grupo de uma vez custaria **5.657 tokens** só de `SKILL.md`,
e **27.788** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Relacionados

- [Skill — Índice](../README.md) · [Teste de Software](../../knowledge-base/docs/teste-de-software.md) § 7 — o contrato que as três implementam
- `hermes-e2e: família playwright` · `hermes-backend: família bun` — a camada de ferramenta
