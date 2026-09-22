# Autoverificação antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-workspace/scripts/sondas.sh.
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | `bun.lock` está versionado | `BUN-PKG-01` |
| 2 | CI usa `bun ci` ou `--frozen-lockfile` | `BUN-PKG-02` |
| 3 | se tocou `trustedDependencies`, a lista padrão necessária foi reincluída | `BUN-PKG-04` |
| 4 | o PR traz a saída de `bun pm untrusted` | `BUN-PKG-03` |
| 5 | `--production` não está sendo usado como limpeza | `BUN-PKG-05` |
| 6 | versão compartilhada vem de catalog | `BUN-PKG-06` |
| 7 | nenhum `catalog:` num pacote a publicar | `BUN-PKG-07` |
| 8 | `overrides` está na raiz | `BUN-PKG-08` |
| 9 | edição em `node_modules` passou por `bun patch` | `BUN-PKG-09` |
| 10 | `linker` declarado se o build depende do layout | `BUN-PKG-10` |
| 11 | `bunx` em CI tem versão fixa | `BUN-PKG-11` |
| 12 | raiz é `"private": true` e não lista dependência de pacote | `BUN-PKG-12` |

**As sondas:**

```bash
bun pm untrusted # o que está bloqueado, e por qual comando
bun install --frozen-lockfile # o lock corresponde ao package.json?
bun pm ls # a árvore resolvida é a esperada?
git status --short bun.lock # o install reescreveu o lock?
```

A última é a mais reveladora depois de qualquer mexida: se o `bun.lock` mudou e você não esperava, algum `package.json` estava divergente.

---

