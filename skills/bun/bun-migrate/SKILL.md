---
name: bun-migrate
description: Migrar código de Node para Bun e diagnosticar o que não roda — matriz de compatibilidade `node:*`, lacunas de cripto, async hooks que são stub, IPC entre runtimes, encerramento em container, Dockerfile — citando IDs `BUN-SYS-*` e `BUN-CORE-*`, com um script que enumera os módulos usados pelo código **e pelas dependências transitivas** — use quando a tarefa for planejar migração de um serviço Node, investigar módulo que se comporta diferente, decidir se uma dependência transitiva é suportada, montar imagem de produção, ou fazer o container encerrar sem derrubar requisição. Não use para escrever código novo com API do Bun, que é bun-runtime, nem para lockfile e workspace, que é bun-workspace.
tags:
  - skill
  - bun
  - backend
fonte: "[[Bun - Shell, FFI e Compat Node]]"
---
# bun-migrate

> **Fonte desta skill:** [[Bun - Shell, FFI e Compat Node]], com o hub [[Bun]] como roteador.

---

## Quando usar

Código que veio do Node, ou vai vir.

| Situação | Vá para |
| --- | --- |
| escrever código novo com API do Bun | [[bun-runtime]] |
| dependência, lockfile, workspace | [[bun-workspace]] |
| teste que falha só sob Bun | [[bun-test-review]] |

---

## Passo 0 — A regra que governa a skill inteira

> **Afirmação sobre compatibilidade com Node.js MUST ser conferida na página oficial.** "Funciona no Node" **não** é evidência de que funciona no Bun (`BUN-CORE-05`).

A compatibilidade é **parcial e desigual**: alguns módulos são completos, alguns têm lacuna específica, e alguns são **stub que não lança** — o pior caso, porque o código roda e o resultado é **silenciosamente errado**.

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | [[Bun]] § 6 — `BUN-CORE-*` e `BUN-SYS-*` |
| 2 | [[Bun - Shell, FFI e Compat Node]] |
| 3 | a página oficial de compatibilidade, para **cada** módulo enumerado |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/enumerar-e-lacunas.md` | o passo que não se pula, e as quatro lacunas que importam |
| `references/container.md` | imagem, encerramento e Dockerfile |
| `references/diagnostico-e-relatorio.md` | sintoma → causa, formato do achado, e o que **não** é incompatibilidade |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 43 `BUN-CORE/RT/PKG/SYS-*` por satélite e seção |
| `scripts/enumerar.sh` | enumera `node:*` no código **e** nas dependências transitivas |

---

## Passo 1 — Enumerar, antes de migrar

```bash
bash ~/.claude/skills/bun-migrate/scripts/enumerar.sh src
```

`BUN-SYS-07` é o passo que **não se pode pular**. E **a segunda busca é a que muda o plano**: uma dependência que usa `async_hooks` para tracing, ou `crypto` para uma cifra específica, decide a viabilidade da migração — e **não aparece no código do projeto**.

Sem `node_modules` instalado, a enumeração é parcial — o script diz isso em vez de fingir cobertura.

---

## Passo 2 — As quatro lacunas que importam

| Módulo | Estado | Consequência |
| --- | --- | --- |
| `async_hooks` | **stub que não lança** | o código roda e o resultado é silenciosamente errado |
| `crypto` | completo em quase tudo, com lacunas por cifra | confira **a cifra que você usa**, não o módulo |
| `worker_threads` | parcial | |
| `vm` / `cluster` | parcial ou ausente | |

Detalhe: `references/enumerar-e-lacunas.md`.

---

## Passo 3 — Container

`references/container.md`: imagem, `--smol`, e o **encerramento**. Sem tratamento de `SIGTERM`, o container encerra **no meio da requisição** — e o sintoma aparece como erro intermitente de cliente durante o deploy.

---

## Passo 4 — Diagnosticar e reportar

`references/diagnostico-e-relatorio.md`: sintoma → causa, o formato do achado, e **o corte** — o que não é incompatibilidade e sim bug do próprio código.

---

## Passo 5 — Fechar

1. **Cada módulo enumerado foi conferido na página oficial?** Se não, o plano está apoiado em suposição (`BUN-CORE-05`).
2. **Se algum é stub que não lança**, ele é bloqueante — não é "funciona com ressalva".
3. **Se o container não trata `SIGTERM`**, o deploy derruba requisição.
4. **Declare o que não foi verificado** — em especial as transitivas, se `node_modules` não estava instalado.

---

## Relacionados

- [[Bun - Shell, FFI e Compat Node]] — fonte desta skill
- [[Bun]] § 6
- [[bun-runtime]] · [[bun-workspace]] · [[bun-test-build]] · [[bun-test-review]] — a família
- [[Node.js]] — o de onde se está saindo
