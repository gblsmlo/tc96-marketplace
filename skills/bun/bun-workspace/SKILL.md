---
nome: bun-workspace
descricao: Gerenciar dependências e workspace com o package manager do Bun — `bun install`, lockfile, `trustedDependencies`, linker, catalogs, `overrides`, `bun patch` — citando IDs `BUN-PKG-*`, com oito sondas executáveis e uma checagem JSON de `trustedDependencies` — use quando a tarefa for adicionar dependência, configurar instalação de CI, liberar script de instalação de um pacote, alinhar versão compartilhada num monorepo, declarar workspace, aplicar patch em pacote, ou montar imagem de produção. Não use para escrever código de aplicação, que é bun-runtime, para migrar código de Node, que é bun-migrate, nem para bundle e build, que é o satélite Bundler e Build.
tipo: skill
familia: bun
fonte: "[Bun - Gerenciador de Pacotes](../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - backend
---

# bun-workspace

> **Fonte desta skill:** [Bun - Gerenciador de Pacotes](../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md), com o hub [Bun](../../../knowledge-base/docs/bun.md) como roteador.
> **Superfície de API:** resolva pelo Context7 — `/oven-sh/bun`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

---

## Quando usar

Dependência, lockfile, workspace, instalação.

| Situação | Vá para |
| --- | --- |
| escrever código de aplicação | `bun-runtime` |
| código de Node que não roda | `bun-migrate` |
| suíte de teste e portões de CI | `bun-test-review` |
| bundle e build | [Bun - Bundler e Build](../../../knowledge-base/docs/bun-bundler-e-build.md) |

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | [Bun](../../../knowledge-base/docs/bun.md) § 6 — `BUN-PKG-*` |
| 2 | [Bun - Gerenciador de Pacotes](../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/trusted-dependencies.md` | a regra que quebra o build inteiro |
| `references/lockfile-monorepo-linker.md` | lockfile e CI, monorepo, linker, patch e `bunx` |
| `references/autoverificacao.md` | a checklist |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 43 `BUN-CORE/RT/PKG/SYS-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/sondas.sh` | oito sondas, com checagem **JSON** de `trustedDependencies` |

---

## Passo 1 — A regra que quebra o build inteiro

> **`trustedDependencies` SUBSTITUI a lista padrão. Não estende.**

Declarar um pacote ali **desliga os scripts de instalação de todo o resto** — `sharp`, `esbuild`, `better-sqlite3`. O sintoma **não é erro de instalação**: é um binário que não foi compilado, e a falha aparece em **runtime**, longe da causa (`BUN-PKG-04`).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-workspace/scripts/sondas.sh.
```

A sonda S1 lê o `package.json` **como JSON** e diz quais pacotes conhecidos da lista padrão ficaram de fora — é a checagem que um `grep` não faz direito.

E `BUN-PKG-03`: um PR que adiciona entrada ali **precisa** trazer no corpo a saída de `bun pm untrusted`. Liberar script de instalação é **decisão de segurança** — o script roda com as permissões de quem instala.

---

## Passo 2 — Lockfile e CI

`bun ci`, não `bun install` (`BUN-PKG-02`): `install` pode atualizar o lockfile no CI; `ci` falha se ele divergir. E a versão do Bun **pinada**, para que local e CI resolvam igual.

---

## Passo 3 — Monorepo, linker, patch

`references/lockfile-monorepo-linker.md`: workspaces, catalogs para versão compartilhada, `overrides` (a chave do Bun — `resolutions` é do Yarn), linker `isolated` × `hoisted`, e `bun patch` versionado.

---

## Passo 4 — Autoverificar

`references/autoverificacao.md`, e as sondas acima.

---

## Passo 5 — Fechar

1. **Se `trustedDependencies` existe**, confirme que nada da lista padrão ficou de fora.
2. **Se o CI usa `bun install`**, troque por `bun ci`.
3. **Se `bunx` roda sem `@versão`**, o que executa é o que estiver publicado no momento.
4. **Declare o que não verificou.**

---

## Exemplo

Monorepo que adicionou um pacote interno a `trustedDependencies` e passou a ver `sharp` falhando em runtime: a lista padrão foi substituída, e o script de instalação do `sharp` nunca rodou. A correção é **reincluir na mesma lista**, com a saída de `bun pm untrusted` no corpo do PR.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [Bun - Gerenciador de Pacotes](../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) — fonte desta skill
- `bun-runtime` · `bun-migrate` · `bun-test-build` · `bun-test-review` — a família
- [Bun - Bundler e Build](../../../knowledge-base/docs/bun-bundler-e-build.md) — bundle, que fica fora desta skill
