# Lockfile, CI, monorepo, linker e patch

| Regra | O que exige |
| --- | --- |
| `BUN-PKG-01` | `bun.lock` **versionado** |
| `BUN-PKG-02` | CI instala com `bun ci` ou `bun install --frozen-lockfile` |

**`bun install` puro em CI reescreve o lockfile e não falha** — então um `package.json` divergente do lock passa silenciosamente, e a build usa versões que ninguém revisou. É a violação com maior distância entre causa e sintoma desta família.

```bash
bun ci # CI
bun install --frozen-lockfile # equivalente explícito
```

E `BUN-PKG-05`, que engana pelo nome: **`--production` não é limpeza.** Ele não remove `devDependencies` já presentes em `node_modules` — para isso é `bun pm`. Numa imagem em camadas, `--production` depois de um install completo não reduz nada.

---

## Passo 3 — Monorepo

| Regra | O que exige |
| --- | --- |
| `BUN-PKG-12` | `package.json` da raiz declara `"private": true`, e **nunca** lista dependência que algum pacote importa |
| `BUN-PKG-06` | versão compartilhada por mais de um pacote vem de **catalog**, não repetida em cada `package.json` |
| `BUN-PKG-08` | `overrides`/`resolutions` no `package.json` **raiz** — Bun **ignora** os declarados em workspace |
| `BUN-PKG-07` | `catalog:` **nunca** chega a pacote publicado — publique por `bun publish` ou `bun pm pack` |

**`BUN-PKG-08` falha em silêncio:** um `overrides` num pacote de workspace é simplesmente ignorado, e a versão que o autor queria fixar continua flutuando.

**`BUN-PKG-12` é sobre direção de dependência:** dependência na raiz que um pacote importa faz o pacote funcionar por acidente — ele resolve pelo hoisting e quebra quando alguém o move ou publica. Ver `Monorepo com Bun - estrutura e tooling`.

**`BUN-PKG-07`** é o par de `BUN-PKG-06`: catalog resolve a versão na instalação do workspace, e o protocolo `catalog:` não é entendido por quem instala do registry. `bun publish` reescreve; `npm publish` cru publica o protocolo literal.

---

## Passo 4 — Linker

| Modo | Layout |
| --- | --- |
| `hoisted` | `node_modules` plano, como npm/yarn clássico |
| `isolated` | por pacote, sem hoisting |

`BUN-PKG-10`: projeto cujo **build depende do layout de `node_modules`** declara `linker` explicitamente em `bunfig.toml`. O default pode mudar, e ferramenta que resolve por caminho — bundler com `resolve.alias`, plugin que faz `require.resolve` — quebra quando ele muda.

Se o build não depende do layout, não declare: é configuração que envelhece sem benefício.

---

## Passo 5 — Patch e `bunx`

| Regra | O que exige |
| --- | --- |
| `BUN-PKG-09` | editar pacote em `node_modules/` **precisa** de `bun patch <pkg>` antes — edição direta **corrompe o cache global** |
| `BUN-PKG-11` | `bunx` em CI ou script versionado fixa a versão, ou o pacote é devDependency |

**`BUN-PKG-09` tem consequência fora do projeto:** o cache é global, então uma edição direta contamina outros projetos da máquina. E o sintoma aparece neles, não neste.

**`BUN-PKG-11`** é reprodutibilidade: `bunx <pkg>` sem versão resolve o `latest` do dia, e o CI de amanhã roda outra coisa.

---

