# Exemplo trabalhado

Tarefa: *"adicionar `sharp` ao serviço de imagens, num monorepo onde `@escopo/core` também usa `zod`"*.

**Passo 1 — o script de instalação.** `sharp` compila binário no install. Ele **está** na lista padrão de confiança, então nada a declarar:

```bash
bun add sharp --cwd apps/imagens
bun pm untrusted # confirma que sharp NÃO ficou bloqueado
```

**Se houvesse `trustedDependencies` no projeto**, aí sim: `sharp` teria de ser reincluído, porque a lista declarada substitui a padrão (`BUN-PKG-04`).

**Passo 3 — a versão compartilhada.** `zod` é usado por `apps/imagens` e por `@escopo/core` → catalog:

```jsonc
// package.json da raiz
{
 "private": true, // BUN-PKG-12
 "workspaces": {
 "packages": ["apps/*", "packages/*"],
 "catalog": { "zod": "^3.24.1" } // BUN-PKG-06
 }
}
```

```jsonc
// apps/imagens/package.json
{ "dependencies": { "sharp": "^0.34.1", "zod": "catalog:" } }
```

E `sharp` **não** vai no catalog: só um pacote o usa.

**Passo 2 — CI:**

```yaml
- run: bun ci # não `bun install` — BUN-PKG-02
- run: tsc --noEmit # o runtime não checa tipo — BUN-CORE-02
```

**O que as decisões evitaram:**

| Decisão | Alternativa que dói | Regra |
| --- | --- | --- |
| conferir `bun pm untrusted` | supor que `sharp` compilou, e descobrir em runtime | `BUN-PKG-03` |
| não declarar `trustedDependencies` sem necessidade | declarar e desligar os scripts de todo o resto | `BUN-PKG-04` |
| `zod` em catalog | duas versões divergindo entre pacotes | `BUN-PKG-06` |
| raiz `"private": true` sem `zod` | pacote funcionando por hoisting, quebrando ao ser movido | `BUN-PKG-12` |
| `bun ci` no CI | `bun install`, que reescreve o lock e não falha | `BUN-PKG-02` |
| `sharp` fora do catalog | catalog com entrada de um consumidor só, que envelhece | `BUN-PKG-06` |

---

