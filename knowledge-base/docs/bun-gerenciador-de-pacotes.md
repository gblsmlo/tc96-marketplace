---
titulo: Bun - Gerenciador de Pacotes
Link: https://bun.com/docs/pm/cli/install
tags:
  - bun
  - package-manager
  - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Gerenciador de Pacotes

> `bun install` e o que ele faz diferente de npm/pnpm · `bun.lock` e a decisão de commitá-lo · `bun ci`, `--frozen-lockfile` e o que ele **não** protege · lifecycle scripts e `trustedDependencies` · `configVersion` e o linker hoisted × isolated · o isolamento que a migração de pnpm perde em silêncio · workspaces, catalogs e `--filter` · `overrides`/`resolutions` · `bun patch` · `bun outdated`/`why`/`audit`/`pm` · `bun x` × `bunx`.
>
> **Não cobre:** execução de scripts e flags de runtime ([Bun - Runtime e APIs](bun-runtime-e-apis.md)) · `bun build` e bundling ([Bun - Bundler e Build](bun-bundler-e-build.md)) · `bun test` ([Bun - Testes](bun-testes.md)) · publicação de imagem e deploy ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)).

Entrada: [Bun](bun.md) · Base normativa: [Bun](bun.md) § 6

---

## 1. Conceito: o lockfile é um artefato de reprodutibilidade, e confiar em script de instalação é decisão de segurança

Um package manager toma duas decisões que o time herda sem discutir, e as duas viram incidente quando ficam implícitas.

**A primeira é reprodutibilidade.** Se o lockfile não está versionado, ou se o comando de CI é `bun install` em vez de `bun ci`, então "a versão que passou no CI" e "a versão que foi para produção" são duas coisas que ninguém garantiu serem iguais. Bun não força isso: a fonte diz explicitamente que *"Bun does not enable `--frozen-lockfile` automatically in CI"*. Quem vem de `npm ci` assume o contrário e passa meses sem perceber.

**A segunda é execução de código de terceiros na sua máquina.** `postinstall` é um shell script arbitrário que um pacote transitivo pode declarar, e é o vetor de boa parte dos ataques de supply chain recentes. Aqui Bun tem uma posição distinta dos concorrentes, e é o ponto mais importante desta nota:

> "Because running arbitrary code is a security risk, Bun does not execute arbitrary lifecycle scripts by default, unlike other `npm` clients."

O default é seguro. O que não é seguro é o gesto reflexo de contornar o bloqueio quando um pacote "não funciona depois de instalar" — porque contornar significa autorizar execução de código, e a autorização tem uma pegadinha de escopo que a § 4 detalha.

O resto da nota é operacional. Estes dois parágrafos são o que precisa sobreviver a uma revisão de PR.

---

## 2. `bun install`: o que ele faz, e o que não faz

```bash
bun install                      # instala tudo
bun add zod                      # dependência
bun add -d @types/bun            # devDependency  (--dev)
bun add --peer react             # peerDependency
bun add --exact zod              # sem ^ no range
bun remove lodash
bun update                       # respeitando os ranges do package.json
bun update --latest              # cruzando major
```

O que `bun install` faz, verificado na fonte:

- Instala `dependencies`, `devDependencies` e `optionalDependencies`. **Instala `peerDependencies` por padrão** — comportamento igual ao do Yarn, diferente de npm em versões antigas.
- Roda os scripts `{pre|post}install` e `{pre|post}prepare` **do seu próprio projeto**.
- **Não** executa lifecycle scripts das dependências instaladas (§ 4).
- Escreve `bun.lock` na raiz.

Dois flags de escopo que são confundidos:

| Flag | O que faz | O que **não** faz |
| --- | --- | --- |
| `--production` | não instala `devDependencies`; **implica `--frozen-lockfile`** | não remove devDependencies que já estão em `node_modules` — para isso, `bun prune --production` |
| `--omit dev\|peer\|optional` | exclui o tipo indicado, incluindo em dependências transitivas | idem |

**Sobre a implicação, porque ela aparece escrita duas vezes num Dockerfile deste vault.** A fonte descreve o modo `production` (a flag e a chave `[install] production` do `bunfig.toml`) como pular `devDependencies` **e** congelar o lockfile. Então `bun install --production --frozen-lockfile` é **redundante, não contraditório**: o segundo flag não muda nada. A redundância no Dockerfile de [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) é deliberada e vale a pena manter — ela documenta a intenção de reprodutibilidade no ponto onde ela é lida, e sobrevive a alguém trocar `--production` por `--omit dev` (que **não** congela o lockfile). Se preferir a forma curta, `--production` sozinho basta.

Dependências não-npm são declaradas no `package.json` como qualquer outra: `git+https://…`, `git+ssh://…#tag`, `github:owner/repo`, URL de tarball, e alias com `npm:@types/bun`.

`bun install --filter` restringe o alvo em monorepo (§ 6), e `--cpu`/`--os` forçam a plataforma-alvo — o lockfile guarda `cpu` e `os` normalizados, então **ele não muda entre plataformas** mesmo quando os pacotes instalados mudam.

| ID | Regra |
| --- | --- |
| `BUN-PKG-05` | `--production` **NEVER** é tratado como limpeza — ele não remove `devDependencies` já presentes em `node_modules`; use `bun prune --production`. |

---

## 3. Lockfile: `bun.lock` é texto, e o comando de CI não é `bun install`

**O estado atual, verificado:** o lockfile se chama **`bun.lock`** e é **textual**. Ele é o default **desde Bun 1.2**. O formato binário anterior, `bun.lockb`, ainda é lido, e a migração é um comando único:

```bash
bun install --save-text-lockfile --frozen-lockfile --lockfile-only
rm bun.lockb
```

Documentação de terceiros e respostas antigas ainda falam em `bun.lockb` e no ritual de configurar um differ de git para ele. Isso é legado — com `bun.lock`, o diff é legível por padrão.

**Deve ser commitado?** A fonte responde em uma palavra: *"Yes"*.

**Migração automática.** Rodando `bun install` num projeto sem `bun.lock`, Bun converte `yarn.lock` (v1), `package-lock.json` (`lockfileVersion` 2, 3 ou 4) e `pnpm-lock.yaml`. Ele **não** migra `package-lock.json` do npm 6 ou anterior (`lockfileVersion` 1) — nesse caso emite aviso e resolve a partir do `package.json`, o que significa versões potencialmente diferentes das que estavam travadas. O lockfile original é preservado.

**CI.** Duas formas equivalentes, e nenhuma é o default:

```bash
bun ci                              # atalho
bun install --frozen-lockfile       # idêntico
```

Com `--frozen-lockfile`, Bun instala as versões exatas do lockfile e falha se o `package.json` divergir.

**A ponte entre as duas afirmações que parecem se contradizer.** `--frozen-lockfile` verifica uma coisa só: **a concordância entre `package.json` e `bun.lock`**. Não verifica que o lockfile existe. As duas frases abaixo são as duas metades da mesma regra, e nenhuma retrata a outra:

| Situação no checkout | O que `--frozen-lockfile` faz |
| --- | --- |
| `bun.lock` presente e concordando com o `package.json` | instala as versões exatas do lockfile — o caso desejado |
| `bun.lock` presente e **divergindo** do `package.json` | **falha** — é para isso que a flag existe |
| **Nenhum `bun.lock`** | resolve a partir do `package.json` e instala, **sem falhar e sem escrever lockfile** |

Ou seja: a flag protege contra divergência, não contra ausência. Um repositório que nunca commitou `bun.lock` passa no `bun ci` verde, com versões resolvidas na hora, e ninguém é avisado. É exatamente por isso que `BUN-PKG-01` (commitar o lockfile) é uma regra separada de `BUN-PKG-02` (usar `bun ci`): **uma não implica a outra, e o CI só é reprodutível com as duas.** O exemplo de CI abaixo fecha o buraco com uma guarda explícita.

Outros detalhes verificados que importam:

- Funciona em checkout podado de monorepo (saída de `turbo prune`, contexto Docker parcial): workspace listado no lockfile sem `package.json` em disco é pulado com um `note:`. Se um workspace remanescente depender de um pulado, a instalação falha.
- Para validar sem instalar: `bun install --frozen-lockfile --dry-run`.
- **Em monorepo completo, `bun ci` instala todos os workspaces.** É o comportamento de `bun install` na raiz — *"installs dependencies for all workspaces in the monorepo, de-duplicating packages if possible"* — e `bun ci` é equivalente a `bun install --frozen-lockfile`. Para restringir, `--filter`.

```yaml
# .github/workflows/ci.yml
steps:
  - uses: actions/checkout@v4

  # Versão do Bun fixada: uma doc cujo argumento é reprodutibilidade não pode
  # instalar o próprio package manager em versão flutuante. `bun-version` aceita
  # uma versão exata, "latest" ou "canary"; sem o input, a action resolve por
  # packageManager/engines.bun do package.json e cai em "latest" se não achar.
  - uses: oven-sh/setup-bun@v2
    with:
      bun-version: 1.3.14        # ou: bun-version-file: .bun-version

  # Guarda: --frozen-lockfile NÃO falha quando o lockfile não existe.
  - name: lockfile presente
    run: test -f bun.lock || (echo "bun.lock ausente — build não é reprodutível" && exit 1)

  - run: bun ci
  - run: bun run build
```

A alternativa a fixar a versão no YAML é declarar `"packageManager"` (ou `"engines": { "bun": … }`) no `package.json` e usar `bun-version-file`: a versão passa a viver junto do código, versionada, e o YAML deixa de ser um segundo lugar a atualizar.

| ID | Regra |
| --- | --- |
| `BUN-PKG-01` | `bun.lock` **MUST** estar versionado no repositório. |
| `BUN-PKG-02` | Instalação em CI **MUST** ser `bun ci` ou `bun install --frozen-lockfile` — `bun install` puro reescreve o lockfile e não falha em divergência. |

---

## 4. Lifecycle scripts e `trustedDependencies`: o ponto de segurança desta nota

Bun bloqueia lifecycle scripts de dependências por padrão. Só roda os de pacotes numa **allow-list**.

### As três configurações possíveis, e a pegadinha

A fonte é literal: *"Defining `trustedDependencies` in `package.json` **replaces** the default list rather than extending it."*

| `package.json` | Quem pode rodar lifecycle script |
| --- | --- |
| `trustedDependencies` ausente | os pacotes da lista embutida do Bun — **somente se instalados a partir do npm** |
| `trustedDependencies: ["pkg-a"]` | **apenas** `pkg-a`. A lista embutida é ignorada por inteiro. |
| `trustedDependencies: []` | **nenhum** pacote — opt-out total sem precisar de `--ignore-scripts` em todo install |

A pegadinha é a segunda linha. Um time que adiciona um único pacote à lista desliga silenciosamente os scripts de `sharp`, `esbuild` e de tudo o mais que **está** na lista embutida — a lista embutida continua existindo e continua sendo o default; declarar `trustedDependencies` é que a descarta para aquele projeto. O sintoma aparece longe da causa: um binário nativo que não foi baixado, uma falha de build sem relação óbvia com o `package.json`. Ao declarar a lista, reinclua o que ainda for necessário (`bun pm default-trusted` imprime a lista embutida em vigor).

O segundo detalhe verificado: **a lista padrão só vale para pacotes vindos do npm**. Dependências `file:`, `link:`, `git:` ou `github:` precisam de entrada explícita em `trustedDependencies` mesmo que o nome case com um item da lista embutida — precisamente para impedir que um pacote malicioso se passe por um confiável através de um caminho local ou repositório git.

### O fluxo correto quando um pacote precisa de `postinstall`

```bash
bun pm untrusted        # lista o que foi bloqueado, com o comando exato de cada script
```

```txt
./node_modules/@biomejs/biome @1.8.3
 » [postinstall]: node scripts/postinstall.js

These dependencies had their lifecycle scripts blocked during install.
```

Leia o script. Depois, uma das duas:

```bash
bun pm trust @biomejs/biome     # roda agora e adiciona a trustedDependencies
bun pm trust --all              # ← só com a lista acima inteira revisada
```

`bun pm untrusted` é a única superfície que mostra **o comando concreto** que você está autorizando. Aprovar sem passar por ele é aprovar às cegas.

**Por que a regra pede a saída colada no PR, e não "revisão cuidadosa".** Um revisor não consegue distinguir um `trustedDependencies` que passou por leitura de script de um que passou por `bun pm trust --all`: as duas coisas produzem o mesmo diff de `package.json`. Colar a saída de `bun pm untrusted` no corpo do PR transforma o ato mental num artefato que o revisor vê e que fica no histórico. É o que `BUN-PKG-03` exige, e é verificável: ou a saída está lá, ou não está.

**Exit code de `bun pm untrusted`: não verificado.** A doc descreve o comando como "imprimir as dependências não confiáveis com scripts" e não declara exit code. Portanto **não assuma** que `bun pm untrusted` falha o pipeline quando algo foi bloqueado — nem que sai zero. Se você precisa de um portão de CI que reprove instalação com script bloqueado, o caminho verificável é comparar a saída com um baseline commitado:

```bash
# Falha se apareceu um lifecycle script bloqueado que não estava no baseline.
bun pm untrusted > untrusted.atual.txt
diff -u untrusted.esperado.txt untrusted.atual.txt
```

O `diff` é que dá o exit code, e o baseline vira um arquivo revisado no PR — mesmo mecanismo do snapshot em [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 9. Confirme o comportamento real do exit code com `bun pm untrusted; echo $?` na sua versão antes de depender disso.

### Desligar tudo

```bash
bun install --ignore-scripts
```

```toml
# bunfig.toml
[install]
ignoreScripts = true
```

Também aceito via `.npmrc` (`ignore-scripts=true`).

### O outro controle de supply chain: `minimumReleaseAge`

Bun filtra versões publicadas há menos de N segundos, o que neutraliza a janela em que um pacote comprometido é publicado e retirado.

```toml
[install]
minimumReleaseAge = 259200                       # 3 dias, em segundos
minimumReleaseAgeExcludes = ["@types/node", "typescript"]
```

Comportamento verificado: afeta apenas resolução nova (o que já está em `bun.lock` não muda), aplica-se a dependências diretas e transitivas, e traz uma checagem de estabilidade — se várias versões saíram em sequência rápida logo depois do corte, Bun pula essas e escolhe uma mais madura, procurando até 7 dias além do limite. Pedido de versão exata (`pkg@1.1.1`) respeita a idade mas ignora a checagem de estabilidade.

Para integração com serviço de scanning, existe a [Security Scanner API](https://bun.com/docs/pm/security-scanner-api).

| ID | Regra |
| --- | --- |
| `BUN-PKG-03` | PR que adiciona entrada em `trustedDependencies` **MUST** conter, no corpo, a saída de `bun pm untrusted` que mostra o comando autorizado — sem esse artefato, o PR é reprovado. |
| `BUN-PKG-04` | Declarar `trustedDependencies` **MUST** reincluir os pacotes da lista padrão ainda necessários — a lista declarada **substitui** a padrão. |

---

## 5. Layout de `node_modules`: hoisted × isolated

Bun tem duas estratégias de linker, e **o default varia** — é o ponto que mais surpreende ao criar projeto novo.

### `configVersion`: o campo que decide o default sem você saber

Antes da tabela, o termo. `configVersion` é um campo do **`bun.lock`**, escrito pelo **próprio Bun** na primeira instalação (ou na migração de outro package manager). Não é uma configuração que você declara: você o **consulta**, e para isso basta abrir o lockfile — ele é texto desde a 1.2:

```bash
grep configVersion bun.lock      # ausente ⇒ trate como configVersion 0
```

Ele não descreve o formato do arquivo (isso é `lockfileVersion`, outro campo, § 7). Ele marca **em que geração de defaults o projeto nasceu**, e hoje seu efeito principal é um só: decidir o linker quando você não declarou nenhum.

| `configVersion` no lockfile | Tem workspaces? | Linker default |
| --- | --- | --- |
| `1` (projeto novo) | sim | **`isolated`** |
| `1` | não | `hoisted` |
| `0` (projeto anterior à v1.3.2, ou migrado de npm/yarn) | qualquer | `hoisted` |

Migração vinda de pnpm entra como `configVersion = 1`; vinda de npm ou yarn, `configVersion = 0`.

### Vindo do pnpm num projeto de pacote único, você perde o isolamento e ninguém avisa

Junte as duas linhas anteriores e sai um caso que morde exatamente o perfil mais comum — app React de um pacote só, migrado de pnpm:

1. A migração de pnpm grava `configVersion = 1`.
2. `configVersion = 1` **sem workspaces** nasce `hoisted`.
3. Um app de pacote único não tem workspaces.
4. Logo: **o projeto sai de um layout isolado (pnpm) para um layout hoisted, silenciosamente.**

O que isso devolve ao projeto é a *phantom dependency*: um `import` de pacote que o `package.json` nunca declarou passa a resolver, porque o pacote foi hoisteado como dependência de outra coisa. Sob pnpm esse import falhava na hora; agora ele funciona — até o dia em que a dependência intermediária sobe de versão, troca de transitiva, e o import quebra num lugar sem relação com a mudança. É o pior formato de erro: quem introduz não sente, e quem sente não tem pista.

A correção é uma linha, e é a razão de `BUN-PKG-10` existir:

```toml
# bunfig.toml — declare o linker; não herde o default
[install]
linker = "isolated"
hoist = false          # isolamento estrito, ver o final desta seção
```

Depois de declarar, `rm -rf node_modules && bun install` para relayoutar. Um `bun install` sobre o `node_modules` antigo não reorganiza o que já está no disco.

```bash
bun install --linker isolated
bun install --linker hoisted
```

**O que muda.** O modo `isolated` é o modelo do pnpm: um store central em `node_modules/.bun/<pkg>@<versão>/` e symlinks no `node_modules` de topo. Um pacote só enxerga o que declarou. O modo `hoisted` achata tudo num diretório compartilhado, e com isso permite *phantom dependencies* — importar um pacote que você nunca declarou, porque ele foi hoisteado como dependência de outra coisa.

| | Hoisted (npm/Yarn) | Isolated (modelo pnpm) |
| --- | --- | --- |
| Acesso a dependências | qualquer coisa hoisteada | só as declaradas |
| Phantom dependencies | possíveis | prevenidas |
| Determinismo | menor | maior |
| Compatibilidade com ferramentas que varrem `node_modules` | padrão | pode quebrar |
| Melhor para | projeto único, código legado | monorepo, biblioteca |

**Comparação honesta com pnpm**, dentro do que a fonte permite afirmar: o `isolated` é *"conceptually similar to pnpm"*, e a diferença declarada é que Bun usa symlinks dentro do `node_modules` do projeto, enquanto pnpm usa um store global com symlinks. Bun tem um store global virtual (`install.globalStore`), mas ele está **desligado por padrão**; com ele ligado, a doc reporta instalação a quente cerca de **7× mais rápida** depois de `rm -rf node_modules` num projeto de porte médio. Sobre velocidade de instalação em geral, o número que a fonte publica é o monorepo do Remix instalado em cerca de 500 ms no Linux, *"8x faster than pnpm install"* — benchmark do próprio fornecedor, útil como ordem de grandeza e não como medida do seu projeto.

**Um detalhe de isolamento que passa despercebido.** Por padrão, mesmo no modo `isolated`, Bun cria `node_modules/.bun/node_modules` com um symlink para cada pacote instalado. Como esse diretório é ancestral de todas as entradas do store, um pacote **ainda consegue** resolver algo que não declarou. Para isolamento estrito:

```toml
[install]
linker = "isolated"
hoist = false          # equivalente ao hoist=false do pnpm
```

A ressalva, compartilhada com o pnpm e declarada na fonte: o `node_modules` raiz também é ancestral do store, então suas dependências diretas e os pacotes de workspace continuam resolvíveis de qualquer lugar.

| ID | Regra |
| --- | --- |
| `BUN-PKG-10` | Projeto cujo build depende do layout de `node_modules` **MUST** declarar `linker` explicitamente em `bunfig.toml` — o default varia com `configVersion` e com a presença de workspaces. |

---

## 6. Monorepo: workspaces, catalogs e `--filter`

### Workspaces

```json
{
  "name": "loja",
  "private": true,
  "workspaces": ["packages/**", "!packages/**/template/**"]
}
```

**Duas prescrições da fonte sobre a raiz, e a razão de cada uma.** O guia de monorepo é explícito: a raiz *"should not contain `dependencies`, `devDependencies`, or other dependency fields"*, e é convenção declarar `"private": true`. Não são estilo:

- **Cada pacote se declara sozinho** porque é isso que o torna movível e publicável. Dependência que mora só na raiz funciona no monorepo — via hoisting, ou via o `node_modules` de topo que o modo `isolated` mantém visível (§ 5) — e quebra no dia em que o pacote é extraído ou publicado. É *phantom dependency* pela porta da frente.
- **`private: true` na raiz** impede publicar o monorepo inteiro por acidente. A falha é silenciosa até o `bun publish`, e aí é pública.

> **Tensão registrada.** A prescrição é literal e não tem ressalva na fonte, mas ferramenta de repositório (`typescript`, `@types/bun`, linter) na raiz é prática difundida, e os exemplos de CI desta nota a usam. O critério que reconcilia os dois: **dependência que o código de algum pacote importa** vai no `package.json` daquele pacote, sempre; **ferramenta que o repositório executa** e nenhum pacote importa pode ficar na raiz. Se está num `import`, não é ferramenta de repositório.

Glob completo é suportado, inclusive padrões negativos. A referência entre pacotes usa o protocolo `workspace:`:

```json
{ "name": "@loja/api", "dependencies": { "@loja/dominio": "workspace:*" } }
```

Na publicação, Bun substitui: `workspace:*` → `1.0.1`, `workspace:^` → `^1.0.1`, `workspace:~` → `~1.0.1`; uma versão explícita (`workspace:1.0.2`) vence a do `package.json`.

**`bun add` dentro de um workspace escreve nos dois lugares certos.** Rodado de dentro do diretório do pacote, Bun detecta o workspace, acrescenta a dependência ao `package.json` **daquele pacote**, e atualiza o **lockfile da raiz** — que é o único lockfile do monorepo (§ 3). Não é preciso `--filter` nem editar o `package.json` à mão:

```bash
cd packages/api
bun add zod                      # entra em packages/api/package.json
```

Onde o pacote é fisicamente instalado depende do linker (§ 5): em `isolated`, que é o default de monorepo novo, ele vai para o store `node_modules/.bun/` da raiz e é *symlinkado* no `node_modules` do próprio workspace; com `--linker hoisted`, é hoisteado para o `node_modules` da raiz.

### Catalogs: a versão declarada uma vez

O problema que resolvem: dez `package.json` repetindo `"react": "^19.0.0"`, e um deles ficando para trás numa atualização.

```json
{
  "name": "loja",
  "workspaces": {
    "packages": ["packages/*"],
    "catalog":  { "react": "^19.0.0", "react-dom": "^19.0.0" },
    "catalogs": { "testing": { "@testing-library/react": "16.3.0" } }
  }
}
```

```json
{
  "name": "@loja/web",
  "dependencies":    { "react": "catalog:", "react-dom": "catalog:" },
  "devDependencies": { "@testing-library/react": "catalog:testing" }
}
```

Pontos verificados:

- `catalog:` vale em `dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies` e como valor de uma regra de `overrides` na raiz. Comporta-se exatamente como se o range estivesse escrito ali.
- `catalog` e `catalogs` também funcionam no **topo** do `package.json`, não só dentro de `workspaces` — mas a fonte diz isso logo depois de instruir a declará-los *"in your root-level `package.json`"*, e **não declara se o topo vale em `package.json` de pacote membro**. Trate como: topo do `package.json` **da raiz**, verificado; membro, **não verificado** — declare na raiz e não conte com o contrário. O que a fonte é explícita em restringir é a **referência**: `catalog:` só funciona nos `package.json` da raiz e dos workspaces.
- `catalog:default` é o mesmo que `catalog:`; declarar o mesmo pacote em `catalog` e em `catalogs.default` é erro.
- `bun add react --catalog` adiciona ao catálogo raiz e escreve `"catalog:"` no pacote atual. Sem o flag, `bun add react` (sem versão) já escreve `"catalog:"` quando o catálogo padrão lista `react`.
- **`catalog:` não resolve dentro de um pacote publicado.** `bun publish` e `bun pm pack` substituem pelo range real; publicar por outro caminho entrega um `package.json` quebrado ao consumidor.

### `--filter`

```bash
bun install --filter './packages/api'       # instala só as deps de um workspace
bun install --filter 'pkg-*' --filter '!pkg-c'
bun run --filter 'ba*' build                # roda o script em vários pacotes
bun run --workspaces test                   # em todos
```

O padrão aceita glob de nome de pacote, caminho `./…`, diretório `{dir}` e relação de dependência (`foo...`).

### O que é raiz-apenas, o que é por-workspace, e o que não foi verificado

Metade das perguntas de monorepo é sobre **onde o campo mora**. A fonte responde algumas com clareza e silencia sobre outras — e o silêncio é informação, porque um leitor que responde por analogia acerta em algumas e erra em outras.

| Campo / comando | Escopo | Estado |
| --- | --- | --- |
| `overrides` / `resolutions` | **só a raiz**; declarado em workspace é ignorado sem erro | verificado — `BUN-PKG-08` |
| `catalog` / `catalogs` (declaração) | raiz, dentro de `workspaces` ou no topo | verificado para a raiz |
| `catalog:` (referência) | `package.json` da raiz e dos workspaces | verificado |
| `workspace:` | `dependencies` de qualquer membro | verificado |
| `bun install` / `bun ci` sem `--filter`, na raiz | instala **todos** os workspaces, deduplicando | verificado |
| `bun.lock` | um só, na raiz | verificado |
| `trustedDependencies` | — | **não verificado** |
| `bunfig.toml` em monorepo | — | **não verificado** ([Bun - Runtime e APIs](bun-runtime-e-apis.md) § 9) |

**`trustedDependencies` em monorepo — não verificado, e não deduza de `overrides`.** A doc de lifecycle scripts descreve o campo como "uma allow-list no `package.json`" e não diz se, num monorepo, ela é lida da raiz, do workspace, ou dos dois. A analogia com `overrides` (raiz-apenas) é tentadora e **não está confirmada**. O que fazer enquanto isso: declare na raiz, rode `bun pm untrusted` depois do install e confira que a lista está vazia — o comando é o oráculo, e ele responde para a instalação inteira. Se um script continuar bloqueado com a entrada na raiz, é sinal de que o campo é lido do workspace; registre o achado.

**`tsc --noEmit` em monorepo — não documentado pelo Bun.** `BUN-CORE-02` exige o passo de type check porque o runtime não valida um único tipo, mas a fonte do Bun documenta um `tsconfig.json` de projeto único e nada sobre layout de workspaces. O que **está** verificado é onde vai a peça do Bun:

```jsonc
// tsconfig.json — a chave é do compilerOptions, não de um campo de topo
{
  "compilerOptions": {
    "types": ["bun"],          // necessário a partir do TypeScript 6.0
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "noEmit": true
  }
}
```

`bun add -d @types/bun` instala os tipos. Em monorepo, **onde** esse `compilerOptions` mora (um tsconfig por pacote? um base na raiz com `extends`? project references?) é decisão de configuração de TypeScript, fora do escopo da doc do Bun `TypeScript`. O que a doc do Bun **não** oferece é um comando de type check que atravesse workspaces: `bun run --filter '*' typecheck`, com um script `typecheck` em cada pacote, é composição de peças verificadas (`--filter` + script), não uma feature documentada com esse nome.

| ID | Regra |
| --- | --- |
| `BUN-PKG-06` | Versão de dependência compartilhada por mais de um pacote do monorepo **MUST** vir de um catalog, não ser repetida em cada `package.json`. |
| `BUN-PKG-12` | `package.json` da raiz de um monorepo **MUST** declarar `"private": true`, e **NEVER** listar dependência que algum pacote importa — só ferramenta que o repositório executa. |
| `BUN-PKG-07` | `catalog:` **NEVER** chega a um pacote publicado — a publicação **MUST** passar por `bun publish` ou `bun pm pack`. |

---

## 7. Controlar o que você não declarou: `overrides` e `bun patch`

### `overrides` / `resolutions`

Fixam a versão de uma **metadependência** — dependência de uma dependência. Os dois campos existem; `resolutions` é a forma do Yarn, mantida para migração.

```json
{
  "overrides": {
    "semver@<7.5.2": "7.5.2",
    "micromatch>picomatch": "^2.3.2",
    "quux": "npm:@meuorg/quux@^1.0.0",
    "foo": "catalog:"
  }
}
```

Verificado, e não óbvio:

- **Bun só lê `overrides` do `package.json` raiz.** Overrides declarados num workspace são ignorados. Aplicam-se também a `peerDependencies`.
- O valor pode ser qualquer especificador: `npm:` para trocar por um fork, `catalog:` para manter em sincronia, e `"$nome"` para reusar o range que você já declarou para `nome`.
- Formas com escopo de pai: objeto npm com `"."`, forma pnpm `pai>filho`, e pai com range (`micromatch@^4>picomatch`). **Um nível só** — `a>b>c` é ignorado com aviso.
- Seletor de versão (`"semver@<7.5.2"`) compara com o range que o dependente **declara**, não com a versão resolvida. Dependente que usa dist-tag, `catalog:`, `workspace:`, git ou URL nunca casa com um seletor.
- Regras aninhadas ou com seletor fazem o lockfile ser escrito como `lockfileVersion` 3, que versões antigas do Bun não leem.

### `bun patch`

Alterar um pacote em `node_modules` sem vendorizá-lo.

```bash
bun patch react                     # 1. prepara: clone real, sem symlink/hardlink
# edite node_modules/react/…        # 2. teste localmente
bun patch --commit react            # 3. gera patches/react@19.x.patch + package.json + lockfile
```

O passo 1 não é opcional e o aviso da fonte é explícito: sem ele, *"you might end up editing the package globally in the cache"* — a edição vaza para todos os projetos da máquina. `bun patch` existe justamente para preservar a integridade do cache global; o patch resultante vive em `patches/`, é rastreado em `"patchedDependencies"` e deve ser commitado.

| ID | Regra |
| --- | --- |
| `BUN-PKG-08` | `overrides`/`resolutions` **MUST** estar no `package.json` raiz — Bun ignora os declarados em workspace. |
| `BUN-PKG-09` | Editar um pacote em `node_modules/` **MUST** ser precedido de `bun patch <pkg>`; edição direta corrompe o cache global. |

---

## 8. Inspecionar: `outdated`, `why`, `audit`, `pm`

```bash
bun outdated                 # tabela Current | Update | Latest
bun outdated 'eslint*'       # aceita glob
bun why react                # cadeia que trouxe o pacote
bun audit                    # vulnerabilidades conhecidas
bun pm ls                    # dependências resolvidas
bun pm untrusted             # lifecycle scripts bloqueados  ← § 4
bun pm cache rm              # limpa o cache global
bun pm migrate               # converte lockfile de outro PM sem instalar
```

Duas leituras que economizam tempo:

- Em `bun outdated`, **`Update` ≠ `Latest`**. `Update` é o maior que satisfaz o range do `package.json`; `Latest` é o publicado no registry. Linha em que os dois diferem é a que exige mudar o range (major), e é a única que merece discussão.
- `bun audit` lê a lista de pacotes **do `bun.lock`**, sem precisar de `node_modules`, e não modifica nada. Filtros: `--audit-level=<low|moderate|high|critical>`, `--prod`, `--omit=<dev|optional|peer>`, `--ignore <GHSA-…>`. Com `--json`, a saída é a resposta crua do registry — `--audit-level` e `--ignore` afetam só o exit code, não o JSON. `bun audit fix` aplica correções dentro dos ranges; `bun audit fix --latest` cruza major.

---

## 9. `bun x` / `bunx`: executar sem instalar

`bunx` é alias de `bun x`, e é instalado junto com o `bun`. Procura primeiro o pacote instalado localmente e, se não achar, instala no cache global.

```bash
bunx prettier --write .
bunx uglify-js@3.14.0 app.js       # versão fixa
bunx -p @angular/cli ng new app    # binário com nome diferente do pacote
bunx --bun vite                    # força o runtime do Bun no CLI
```

Duas coisas em que se erra:

- **`--bun` vem antes do nome do executável.** Depois do nome, tudo é repassado ao pacote: `bunx my-cli --bun` passa `--bun` para `my-cli`.
- **Sem versão fixada, `bunx <pkg>` resolve a mais recente compatível.** Numa pipeline de CI isso é uma dependência não travada executando com as permissões do runner. Fixe (`bunx pkg@1.2.3`) ou declare como devDependency e chame pelo `bun run`.

| ID | Regra |
| --- | --- |
| `BUN-PKG-11` | Invocação de `bunx` em CI ou script versionado **MUST** fixar a versão do pacote, ou o pacote **MUST** ser uma devDependency chamada por `bun run`. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `bun install` como comando de CI | não trava nada: reescreve `bun.lock` e passa mesmo com `package.json` divergente | `bun ci` — `BUN-PKG-02` |
| `bun.lock` no `.gitignore` | sem lockfile, `--frozen-lockfile` instala do `package.json` **sem falhar**; a build deixa de ser reprodutível em silêncio | commitar — `BUN-PKG-01` |
| `bun pm trust --all` para "destravar o install" | autoriza execução de shell script arbitrário de todo pacote bloqueado, sem ler nenhum | `bun pm untrusted`, ler, e confiar um por um — `BUN-PKG-03` |
| `trustedDependencies: ["meu-pacote"]` e mais nada | substitui a lista padrão; `sharp`, `esbuild` e afins param de rodar seus scripts, com sintoma distante da causa | reincluir o necessário (`bun pm default-trusted`) — `BUN-PKG-04` |
| `bun install --production` esperando `node_modules` enxuto | não remove o que já estava lá; a imagem continua carregando devDependencies | `bun prune --production`, ou instalar em camada limpa — `BUN-PKG-05` |
| Mesma versão de React repetida em oito `package.json` | uma atualização esquece um pacote e o monorepo passa a ter duas cópias de React | catalog na raiz — `BUN-PKG-06` |
| Publicar pacote de workspace com `"react": "catalog:"` | `catalog:` não resolve fora do monorepo; o consumidor recebe um `package.json` inválido | `bun publish` / `bun pm pack` — `BUN-PKG-07` |
| `overrides` no `package.json` de um workspace | Bun só lê os da raiz; a regra é ignorada sem erro e o pacote vulnerável continua instalado | mover para a raiz — `BUN-PKG-08` |
| Editar `node_modules/<pkg>` e depois rodar `bun patch --commit` | sem o `bun patch <pkg>` inicial, a edição pode acontecer no cache global e contaminar outros projetos | `bun patch <pkg>` primeiro — `BUN-PKG-09` |
| `bunx <ferramenta>` sem versão numa pipeline | executa código não travado com as permissões do runner; a build de hoje não é a de ontem | fixar versão ou declarar como devDependency — `BUN-PKG-11` |
| Assumir `bun.lockb` porque a documentação de terceiros diz isso | o formato textual é o default desde 1.2; instruções antigas levam a configurar differ de git para um arquivo que não existe mais | `bun.lock`; migrar com `--save-text-lockfile` |
| Migrar de npm 6 e confiar que as versões foram preservadas | `lockfileVersion` 1 **não** é migrado — Bun avisa e resolve do `package.json` | atualizar o npm e regerar o lockfile antes, ou revisar `bun outdated` após a migração |
| `bun ci` no CI como única garantia de reprodutibilidade | sem `bun.lock` no repositório, `--frozen-lockfile` resolve do `package.json` e passa verde | `test -f bun.lock` antes do install — § 3, `BUN-PKG-01` + `BUN-PKG-02` |
| `oven-sh/setup-bun@v2` sem `bun-version` numa doc sobre reprodutibilidade | a action cai em `latest`; o package manager que trava tudo é ele mesmo não travado | `bun-version: <exata>` ou `bun-version-file` — § 3 |
| Migrar de pnpm um app de pacote único e não declarar `linker` | `configVersion = 1` **sem workspaces** nasce `hoisted`; o isolamento do pnpm some e phantom dependency volta | `[install] linker = "isolated"` + `rm -rf node_modules` — § 5, `BUN-PKG-10` |
| Assumir que `trustedDependencies` na raiz cobre os workspaces | não é declarado pela fonte; a analogia com `overrides` não está confirmada | declarar na raiz e **conferir com `bun pm untrusted`** — § 6 |
| Usar `bun pm untrusted` como portão de CI contando com exit code | a fonte não declara exit code para o comando | comparar a saída com um baseline commitado (`diff`) — § 4 |

---

## Checklist de revisão

- [ ] `bun.lock` está versionado? → `BUN-PKG-01`
- [ ] O comando de CI é `bun ci` (ou `--frozen-lockfile`)? → `BUN-PKG-02`
- [ ] Toda entrada nova em `trustedDependencies` tem justificativa no PR? → `BUN-PKG-03`
- [ ] A lista declarada reinclui os pacotes da lista padrão ainda necessários? → `BUN-PKG-04`
- [ ] `bun pm untrusted` está limpo, ou o que sobrou é decisão consciente?
- [ ] O uso de `--production` está acompanhado de `bun prune`, quando o objetivo é reduzir a imagem? → `BUN-PKG-05`
- [ ] Versões compartilhadas do monorepo estão em catalog? → `BUN-PKG-06`
- [ ] Nenhum `catalog:` escapa para pacote publicado? → `BUN-PKG-07`
- [ ] `overrides` estão na raiz? → `BUN-PKG-08`
- [ ] `patches/` está commitado e `"patchedDependencies"` bate com ele? → `BUN-PKG-09`
- [ ] O `linker` está declarado quando o build depende do layout? → `BUN-PKG-10`
- [ ] `bunx` em CI está com versão fixa? → `BUN-PKG-11`
- [ ] `minimumReleaseAge` foi considerado como defesa de supply chain?
- [ ] O CI tem guarda de **existência** do lockfile, e não só `bun ci`? → § 3
- [ ] A versão do Bun no CI está fixada (`bun-version` ou `bun-version-file`)? → § 3
- [ ] Projeto migrado de pnpm declarou `linker` explicitamente? → § 5, `BUN-PKG-10`
- [ ] `bun pm untrusted` foi rodado **depois** do install em monorepo, para confirmar onde `trustedDependencies` foi lido? → § 6

---

## Relacionados

- [Bun](bun.md) — hub, mapa da API, árvores de decisão
- [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Testes](bun-testes.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)
- `Node.js` · `TypeScript`
- — a fronteira vizinha de segredo em build

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Configuring a monorepo using workspaces](https://bun.com/guides/install/workspaces) — guia, com [projeto de exemplo](https://github.com/colinhacks/bun-workspaces)
- [bun install](https://bun.com/docs/pm/cli/install) · [bun add](https://bun.com/docs/pm/cli/add) · [bun update](https://bun.com/docs/pm/cli/update)
- [Lockfile](https://bun.com/docs/pm/lockfile) · [Lifecycle scripts](https://bun.com/docs/pm/lifecycle)
- [Isolated installs](https://bun.com/docs/pm/isolated-installs) · [Global virtual store](https://bun.com/docs/pm/global-store)
- [Workspaces](https://bun.com/docs/pm/workspaces) · [Catalogs](https://bun.com/docs/pm/catalogs) · [bun --filter](https://bun.com/docs/pm/filter)
- [Overrides and resolutions](https://bun.com/docs/pm/overrides) · [bun patch](https://bun.com/docs/pm/cli/patch)
- [bun outdated](https://bun.com/docs/pm/cli/outdated) · [bun why](https://bun.com/docs/pm/cli/why) · [bun audit](https://bun.com/docs/pm/cli/audit) · [bun pm](https://bun.com/docs/pm/cli/pm)
- [bunx](https://bun.com/docs/pm/bunx) · [Security Scanner API](https://bun.com/docs/pm/security-scanner-api)
- [bunfig.toml — `[install]`](https://bun.com/docs/runtime/bunfig) · [TypeScript](https://bun.com/docs/typescript)
- Fora da doc do Bun, para o input de versão da action de CI: [oven-sh/setup-bun](https://github.com/oven-sh/setup-bun)

**O que a verificação contrariou:**

- **`bun.lock` textual é o default desde Bun 1.2.** O binário `bun.lockb` é legado, e boa parte do material de terceiros ainda ensina a configurar um differ de git para ele.
- **`bun install` não vira `--frozen-lockfile` em CI automaticamente.** A fonte diz isso de forma explícita e oferece `bun ci`. O hábito vindo de `npm ci` produz a suposição oposta.
- **`--frozen-lockfile` sem lockfile nenhum não falha** — instala a partir do `package.json`. Ou seja, ele não protege contra a ausência do lockfile, só contra a divergência.
- **`trustedDependencies` substitui a lista padrão.** Declarar um pacote desliga o allow-list embutido inteiro.
- **A lista padrão de pacotes confiáveis só vale para origem npm.** `file:`, `link:`, `git:` e `github:` exigem entrada explícita, para impedir spoofing de nome.
- **O linker default depende de `configVersion` e da presença de workspaces**, não de uma configuração única: monorepo novo nasce `isolated`, projeto de pacote único nasce `hoisted`.
- **Mesmo em `isolated`, `node_modules/.bun/node_modules` permite resolução não declarada** até que se ligue `hoist = false` — e mesmo então o `node_modules` raiz continua visível, ressalva que a fonte diz ser compartilhada com o pnpm.
- **`overrides` só é lido da raiz**, e ignora silenciosamente os declarados em workspaces.
- **`lockfileVersion` 1 do npm não é migrado**: Bun avisa e resolve do `package.json`, o que pode trocar versões sem que ninguém peça.
- **Overrides aninhados ou com seletor de versão elevam o lockfile a `lockfileVersion` 3**, ilegível por versões antigas do Bun.
- **`bun install` instala `peerDependencies` por padrão** — comportamento de Yarn, não o de npm antigo.
- **`bun install` na raiz instala todos os workspaces**, deduplicando — e `bun ci`, sendo equivalente a `bun install --frozen-lockfile`, herda isso. Restringir exige `--filter`.
- **`--production` já congela o lockfile.** A fonte descreve o modo `production` como pular `devDependencies` **e** congelar o lockfile, então `--production --frozen-lockfile` é redundante, não contraditório.
- **`configVersion` é escrito pelo Bun no `bun.lock`**, não declarado por você, e é diferente de `lockfileVersion`. A combinação `configVersion = 1` + ausência de workspaces é o que faz um projeto migrado de pnpm cair em `hoisted`.
- **`"types": ["bun"]` vai dentro de `compilerOptions`**, e passa a ser necessário a partir do TypeScript 6.0.

**O que não foi verificado (declarado, não inventado):**

- **`trustedDependencies` em monorepo**: raiz, workspace ou ambos. A fonte não declara. Não deduzir de `overrides`.
- **Exit code de `bun pm untrusted`**: não documentado. Não usar como portão de CI sem confirmar na sua versão.
- **`catalog`/`catalogs` no topo do `package.json` de um pacote membro**: a fonte afirma o topo no contexto do `package.json` da raiz e não estende a afirmação a membros.
- **`bunfig.toml` em monorepo**: se há herança ou merge entre raiz e workspace. Só o par global × projeto é documentado.
- **Layout de `tsconfig.json` em monorepo**: fora do escopo da doc do Bun. `bun run --filter '*' typecheck` é composição de peças verificadas, não uma feature nomeada.
