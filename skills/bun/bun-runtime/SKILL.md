---
nome: bun-runtime
descricao: Escrever código que usa as APIs do runtime Bun — arquivo, `.env`, processo, shell, hashing, watch — citando IDs `BUN-RT-*` e `BUN-CORE-*`, com autoverificação executável — use quando a tarefa for ler ou escrever arquivo, carregar e validar variável de ambiente, rodar subprocesso ou comando externo, hashear senha, escolher entre `--watch` e `--hot`, ou decidir entre API do Bun e módulo `node:*`. Não use para instalar pacote e mexer em workspace, que é bun-workspace, para migrar código de Node que não roda, que é bun-migrate, nem para escrever teste, que é bun-test-build.
tipo: skill
familia: bun
fonte: "[Bun - Runtime e APIs](../../../knowledge-base/docs/bun-runtime-e-apis.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - backend
---

# bun-runtime

> **Fonte desta skill:** [Bun - Runtime e APIs](../../../knowledge-base/docs/bun-runtime-e-apis.md), com o hub [Bun](../../../knowledge-base/docs/bun.md) como roteador.
> Esta skill **não contém** o texto das regras nem a superfície de API — ela diz o que decidir e o que conferir.
> **Superfície de API:** resolva pelo Context7 — `/oven-sh/bun`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

---

## Quando usar

Escrever código de aplicação que usa o runtime.

| Situação | Vá para |
| --- | --- |
| dependência, lockfile, workspace, `trustedDependencies` | `bun-workspace` |
| código que veio do Node e não roda | `bun-migrate` |
| escrever teste | `bun-test-build` · revisar suíte | `bun-test-review` |
| rota HTTP | `elysia-build` · persistência | `drizzle-review` |

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | [Bun](../../../knowledge-base/docs/bun.md) § 2 (o binário é runtime, gerenciador, bundler e runner) |
| 2 | [Bun](../../../knowledge-base/docs/bun.md) § 6 — `BUN-CORE-*` |
| 3 | [Bun - Runtime e APIs](../../../knowledge-base/docs/bun-runtime-e-apis.md) |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/invariantes-do-binario.md` | as cinco invariantes que valem em qualquer tarefa |
| `references/arquivo-ambiente-processo.md` | arquivo, `.env`, processo e shell |
| `references/hash-e-watch.md` | hash e senha, e `--watch` × `--hot` |
| `references/autoverificacao.md` | a checklist |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 43 `BUN-CORE/RT/PKG/SYS-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/autoverificar.sh` | roda os itens mecânicos |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas três skills de runtime/pacote/migração |

---

## Passo 1 — As invariantes do binário

**`BUN-CORE-02` é a que mais custa:** Bun transpila TypeScript e **não checa tipos**. Sem `tsc --noEmit` no CI, o projeto tem **tipos decorativos** — o erro só aparece quando o valor errado chega em runtime.

E `BUN-CORE-03`: adicionar `jest`, `ts-node`, `nodemon` ou `dotenv` exige **justificar** por que o equivalente embutido não serve.

---

## Passo 2 — Arquivo, ambiente, processo e shell

`references/arquivo-ambiente-processo.md`. A decisão recorrente é **API do Bun × módulo `node:*`** — e ela muda quando o código precisa rodar fora do processo `bun` (`BUN-CORE-01`).

---

## Passo 3 — Hash e senha

**Senha é `Bun.password`** (argon2id por default), nunca `createHash` — usar hash genérico para senha é achado de **segurança**, não de estilo.

---

## Passo 4 — `--watch` × `--hot`

`--hot` **mantém o estado do processo**; `--watch` reinicia. Servidor com estado global muda de comportamento entre os dois, e o sintoma aparece como "só reproduz em dev".

---

## Passo 5 — Autoverificar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-runtime/scripts/autoverificar.sh src
tsc --noEmit
```

---

## Passo 6 — Fechar

1. **`tsc --noEmit` roda no CI?** Se não, esse é o primeiro achado.
2. **Se o código usa o global `Bun`**, ele só roda sob o processo `bun` — declare isso se a lib for publicada.
3. **Se veio de Node e não roda**, é `bun-migrate` — e "funciona no Node" não é evidência (`BUN-CORE-05`).
4. **Declare o que não verificou.**

---

## Exemplo

Serviço que lê `.env`, escreve arquivo e hasheia senha: `Bun.file`/`Bun.write` no lugar de `fs`, validação de env na inicialização, `Bun.password` para a senha, e `--watch` em vez de `--hot` porque o servidor tem estado global.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [Bun - Runtime e APIs](../../../knowledge-base/docs/bun-runtime-e-apis.md) — fonte desta skill
- [Bun](../../../knowledge-base/docs/bun.md) § 2, § 6
- `bun-workspace` · `bun-migrate` · `bun-test-build` · `bun-test-review` — a família
