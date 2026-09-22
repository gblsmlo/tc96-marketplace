---
titulo: Monorepo com Bun - estrutura e tooling
aliases:
 - Monorepo com Bun
 - Bun workspaces
tags:
 - architecture
 - bun
 - monorepo
 - agent-context
verificado-em: 2026-08-16
---
# Monorepo com Bun — estrutura e tooling

> Nota irmã de [Feature-Based Architecture](feature-based-architecture.md) e [Fronteira do BFF - forma, jornada e regra](fronteira-do-bff-forma-jornada-e-regra.md). Aquelas
> decidem, respectivamente, **onde o código de uma app mora** e **quem é dono de cada decisão na
> fronteira do servidor**. Esta decide **o que vira pacote, o que não vira, e o que precisa estar no
> CI para a divisão não apodrecer em silêncio**.

Como as duas irmãs, esta mora em `pages/` mas é **normativa**: tem IDs (`MONO-*`), invariantes e
contrato de skill. Ver a exceção explicada em [Architecture in React](architecture-in-react.md) § 5.

Tudo aqui foi executado, não deduzido. A referência é `elysia-bff-lab`, migrado de pacote
único para workspace em seis passos, com CI verde a cada um. Onde a nota cita comportamento de
ferramenta, ele foi verificado com Bun 1.3.14.

---

## 1. A pergunta que vem antes da estrutura

Monorepo não é decisão única — são **duas perguntas independentes**, e responder as duas com o mesmo
"sim" é o erro mais caro.

**Pergunta 1: separar servidor de cliente em pacotes?** Quando os dois compartilham um contrato de
tipos (Elysia + Eden, tRPC, ou qualquer coisa que atravesse `typeof app`), a resposta padrão é
**não separar em instalações**. Duas resoluções da mesma biblioteca degradam o contrato para `any`
**sem erro de build, sem teste vermelho**. Dentro de um workspace com hoisting o risco é gerenciável,
mas exige guarda explícita (§ 5.3).

**Pergunta 2: extrair UI, config ou qualquer coisa compartilhada em pacotes?** Aqui o critério é
evidência de duplicação, não estética. E a evidência que basta é brutal: se o mesmo componente existe
em dois repositórios e **divergiu**, o custo já está sendo pago.

O caso que motivou esta nota: 53 componentes compartilhados entre dois repositórios, **zero
idênticos**. Não é previsão de problema — é fatura vencida.

### Quando NÃO fazer monorepo

- um app só, sem segundo consumidor de nada;
- a duplicação é hipotética ("um dia vamos ter mobile");
- o time não tem quem mantenha a fronteira. Pacote sem dono é `shared/` com outro nome.

`MONO-01` responde por isso.

---

## 2. A árvore, e por que `apps` × `packages`

```
raiz/
├── package.json workspaces + scripts orquestradores + overrides
├── biome.json lint/format, com os overrides de fronteira
├── tsconfig.json só o que a raiz precisa (scripts/)
├── apps/
│ ├── server/ deployável — BFF
│ ├── web/ deployável — SPA
│ └── storybook/ deployável — folha do grafo
└── packages/
 ├── ui/ consumido, nunca deploya
 └── config/ tsconfig e biome compartilhados
```

O critério que separa as duas pastas não é tamanho nem importância: **`apps/` é o que sobe;
`packages/` é o que é consumido.** Storybook é `apps/` mesmo sendo ferramenta — ele sobe, tem URL, e
ninguém importa dele.

### A direção de dependência, e a exceção real

```
apps/storybook → apps/web → packages/ui → packages/config
 ⋮
 └ ─ ─ ─(só tipo)─ ─ ─→ apps/server
```

Três invariantes:

1. **`apps` dependem de `packages`, nunca o contrário.** Um primitivo de `packages/ui` que precise
 de algo da aplicação recebe por prop ou slot.
2. **`apps/web` depende de `apps/server` apenas por tipo.** App dependendo de app é incomum, mas aqui
 é o desenho: `import type { App } from '@escopo/server'`, apagado no build por
 `verbatimModuleSyntax`. Acoplamento total em compilação, **zero em runtime**.
3. **Ninguém depende do Storybook.** Ele é folha, e é isso que permite tirá-lo do build de produção
 sem tocar em outro pacote.

---

## 3. Nomes de arquivo e camadas

Kebab-case em tudo. O nome do arquivo diz **o que a coisa é**, não quem a usa — é a mesma regra que
condena `shared/`.

### Fatia do servidor

```
apps/server/src/features/<capacidade>/
├── <capacidade>.routes.ts rotas + response por status
├── <capacidade>.schema.ts a declaração canônica (validação, tipo, OpenAPI, contrato)
├── <capacidade>.mapper.ts DTO do upstream → domínio
├── <capacidade>.routes.test.ts colocalizado
└── index.ts barrel = superfície pública da fatia
```

Prefixo repetido no nome (`agentes.routes.ts` e não `routes.ts`) porque o arquivo é encontrado por
busca, não por navegação de pasta.

### Fatia do cliente

```
apps/web/src/features/<capacidade>/
├── routes/ as telas — só montagem, ver abaixo
├── api/ queryOptions, mutations, chaves, e os tipos DERIVADOS do contrato
├── components/
├── hooks/
├── schemas/ o que é schema de verdade: search params, formulários
├── utils/
└── index.ts barrel = contrato da feature
```

**`routes/` não é `http/`.** Ali mora montagem de tela — `createFileRoute`, `loader`, `component`,
`validateSearch`. Quem fala HTTP é `api/`, e o único arquivo que conhece transporte é
`libs/api-client.ts`. Chamar a pasta de `http/` manda quem procura chamada de rede para o lugar
errado.

`features/<x>/routes/` **exige rotas virtuais** quando o router é file-based. Sem
`virtualRouteConfig`, o gerador não olha para a pasta, as telas não entram na árvore, e o sintoma é
uma rota que **some sem erro**.

### `types/` costuma ter dois inquilinos

A pasta `types/` de uma feature tipicamente guarda duas coisas de naturezas diferentes:

| O que é | Onde vai |
| --- | --- |
| schema com comportamento (Zod de search params, de formulário) | `schemas/` |
| derivação de tipo do contrato (`NonNullable<Awaited<ReturnType<...>>>`) | `api/<x>-tipos.ts` |

Renomear `types/` → `schemas/` mecanicamente coloca uma derivação de tipo numa pasta chamada
"schemas" — a mesma desonestidade que se acusa em `shared/`. **Quando um nome único mente sobre parte
do conteúdo, o problema não é o nome: a pasta tem dois inquilinos.**

---

## 4. Tooling: quem faz o quê

| Ferramenta | Papel | Por que não outra |
| --- | --- | --- |
| **Bun** | runtime, package manager, test runner | `bun test`, `bun install`, `bun --watch` cobrem quatro dependências que não precisam existir |
| **Vite** | bundler do frontend | ver § 4.1 — testado, e o Bun ainda não substitui |
| **Biome** | lint + format, e **as regras de fronteira** | um binário, e `noRestrictedImports` por override é o que torna a arquitetura verificável |
| **TypeScript** | `tsc --noEmit` como **passo separado** | o runtime transpila sem checar; "roda" não é evidência |

### 4.1 Bun não substitui o bundler ainda — e o teste é barato

`Bun.serve` aceita importar `.html` como rota e serve SPA + API no mesmo processo. Testado: bundla
TSX, resolve aliases do `tsconfig`, processa CSS, e funciona.

O que trava, verificado: com HMR ligado o app React não monta quando há TanStack Router — conflito
entre o runtime de HMR do Bun e a cola de hot-reload do router. Com `hmr: false` monta, mas hot
reload é boa parte da razão de existir um dev server.

Some-se o ecossistema: plugins de bundler (router codegen, React Compiler via Babel, Tailwind) têm
alvos para vite/rspack/webpack/esbuild e **nenhum para Bun**.

**Conclusão adotada:** Bun como runtime e package manager, Vite como bundler (`bunx --bun vite`).
Refaça o teste antes de aceitar isso como permanente — é uma medição com data.

### 4.2 Orquestração de scripts

```jsonc
{
 "scripts": {
 "typecheck": "tsc --noEmit -p tsconfig.json && bun run --filter '@escopo/*' typecheck",
 "test": "bun run --filter '@escopo/*' test",
 "build": "bun run --filter '@escopo/web' build",
 "ci": "bun run lint:ci && bun run typecheck && bun run test && bun run check:resolucao"
 }
}
```

Três coisas verificadas aqui:

- **`--filter` propaga falha.** Confirmado plantando um teste quebrado: o script sai com código 1.
 Não assuma — plante e confirme;
- **Bun não suporta filtro negado.** `--filter '!@escopo/storybook'` roda o pacote mesmo assim. Para
 excluir, use filtro positivo;
- **`--filter '*'` casa o pacote raiz** e recursiona. Use o escopo (`'@escopo/*'`).

---

## 5. As armadilhas, todas verificadas

São as que custam tempo e não estão em nenhum tutorial.

### 5.1 Declarar o workspace não linka nada

Com `"workspaces": ["apps/*", "packages/*"]`, o `bun pm ls` já mostra o pacote — mas
`node_modules/@escopo/` **não existe** e o `tsc` falha com `File '...' not found`. O symlink só é
criado quando **algum pacote declara dependência** dele.

### 5.2 `paths` do TypeScript resolvem relativo ao arquivo que os declara

Consequência direta: **um `tsconfig` base compartilhado carrega flags, não `paths`.** Declarados na
base, apontariam para dentro de `packages/config/`.

Isso não enfraquece a mitigação — melhora. O alias arriscado é o que atravessa a fronteira
(`@server`), e no monorepo ele deixa de existir: vira especificador de pacote, resolvido por
`exports`.

### 5.3 A resolução dupla é silenciosa, e precisa de guarda no CI

Duas cópias da biblioteca de contrato degradam os tipos para `any`. Duas de React quebram hooks.
Nenhuma das duas aparece em `bun test`.

Duas guardas, e as duas são necessárias:

```jsonc
// package.json da RAIZ — os declarados em pacote de workspace são IGNORADOS pelo Bun
{ "overrides": { "elysia": "1.4.29" } }
```

E um passo de CI que falha se aparecer mais de uma resolução:

```ts
const saida = await new Response(Bun.spawn(['bun', 'pm', 'why', pacote], { stdout: 'pipe' }).stdout).text
const resolucoes = saida.split('\n').filter((l) => new RegExp(`^${pacote}@`).test(l.trim) && !l.startsWith(' '))
if (resolucoes.length > 1) process.exit(1)
```

> **A guarda estava documentada e não implementada.** Foi o achado de uma auditoria adversarial: os
> documentos registravam `overrides` + `bun pm why` como decididos, e nenhum dos dois existia. A
> resolução única era consequência do hoisting — sobreviveria por sorte até o dia em que não.

### 5.4 Caminho relativo em runtime resolve pelo cwd

Um `staticPlugin({ assets: 'dist' })` que funcionava no pacote único passa a apontar para o lugar
errado quando o processo roda de `apps/server/`. O sintoma foi produção servindo **404 na raiz com a
API respondendo normalmente** — e nenhum teste pegou, porque o CI não sobe o servidor em modo
produção.

Correção: ancorar em `import.meta.dir`, com env var para o container sobrescrever.

### 5.5 Mover a rota para dentro da feature cria violação que o lint não pega

Uma tela que morava em `src/routes/` importava `@features/<x>` corretamente. Movida para
`features/<x>/routes/`, o mesmo import passa a ser **import do próprio barrel** — proibido, porque é
frágil a ciclo.

`noImportCycles` **não pega**: o ciclo só fecha se o barrel reexportar a rota, e ele não reexporta.
É o resíduo que [Feature-Based Architecture](feature-based-architecture.md) documenta como cobertura parcial de `REACT-ARCH-04`.
Corrija para import relativo.

### 5.6 Ferramenta reconhece JSONC pelo nome do arquivo

Biome aceita comentários em `tsconfig.json` porque conhece o nome. Um
`packages/config/tsconfig/base.json` com comentários dá erro de parse. Precisa de override
declarando `json.parser.allowComments`.

### 5.7 Augmentation de tipo precisa estar no programa de quem consome

Um `declare module` que mora no arquivo de bootstrap (`main.tsx`) não alcança outros programas — e
`main.tsx` monta o DOM, então não pode entrar no programa do Storybook nem no de testes.

Separe a augmentation num módulo próprio (`router.ts`), exporte-o, e importe **de tipo** onde
precisar. Verificado por sabotagem: tirando o import, o typecheck falha contra o tipo genérico;
recolocando, fica limpo.

---

## 6. Regras normativas (`MONO-*`)

| ID | Regra | Severidade | Verificação |
| --- | --- | --- | --- |
| `MONO-01` | Extração para `packages/` **MUST** ter duplicação real, não prevista. Dois consumidores em repositórios diferentes bastam; um consumidor não. | crítica | revisão |
| `MONO-02` | `apps/` **NEVER** é importado por `packages/`. A dependência vai numa direção só. | crítica | lint (`noRestrictedImports`) |
| `MONO-03` | Import de app para app **MUST** ser type-only, com `verbatimModuleSyntax: true`. | crítica | revisão + build |
| `MONO-04` | O pacote que compartilha contrato de tipos **MUST** ter resolução única, garantida por `overrides` na **raiz** e verificada no CI. | crítica | CI |
| `MONO-05` | `tsconfig` base compartilhado **NEVER** declara `paths` — só flags. | crítica | build |
| `MONO-06` | Todo pacote do workspace **MUST** ser declarado como dependência por quem o usa, senão não existe em `node_modules`. | alta | build |
| `MONO-07` | Todo pacote **MUST** ter script `typecheck` alcançado pelo `--filter` do CI. Pacote sem script é pulado em silêncio. | alta | CI |
| `MONO-08` | Caminho de runtime **NEVER** é relativo ao cwd; **MUST** ancorar em `import.meta.dir` ou variável de ambiente. | alta | revisão |
| `MONO-09` | `declare module` que outros programas precisam **MUST** morar em módulo próprio, nunca no bootstrap. | média | revisão |
| `MONO-10` | Migração **MUST** avançar um passo por vez, com CI verde antes do seguinte, e sob git. | alta | processo |
| `MONO-11` | Guarda declarada em documento **MUST** existir como passo executável. Documento não é verificação. | crítica | auditoria |
| `MONO-12` | Aresta **lateral** — irmão importando irmão na mesma camada, package ou feature — **MUST** passar pela API pública do irmão, e o fan-in lateral **MUST** ser contado: ao terceiro consumidor distinto, extraia para o compartilhado e corte as arestas diretas. | alta | CI (sonda de fan-in, § 7) |

### `MONO-12` — a aresta lateral, e por que ela precisa de contagem

`MONO-02` governa a aresta **vertical**: `packages/` nunca importa `apps/`, a dependência vai numa
direção só. Ela não diz nada sobre a aresta **lateral** — irmão importando irmão dentro da mesma
camada —, que não inverte direção nenhuma e por isso atravessa intacta todo lint de direção.

A decisão da casa, em [Feature-Based Architecture](feature-based-architecture.md) § 4, é **permitir** a aresta lateral pela API
pública, em vez de proibi-la como faz o Feature-Sliced Design. A troca é consciente: o modelo
estrito paga uma camada compartilhada desde o dia um para prevenir um acoplamento que o barrel
mantém visível e barato de desfazer. O preço, declarado lá, é que **um grafo de irmãos pode virar
emaranhado sem ninguém perceber**.

Esse preço só não vence porque existe um número: o **terceiro consumidor distinto**. Até dois, a
aresta é acoplamento visível e reversível; no terceiro, o módulo já é compartilhado de fato, e
continuar importando direto é negar isso. Enquanto o número não era medido, a permissão era prosa e
o alerta era intenção — `MONO-11` contra esta própria família de notas. A sonda da § 7 é o que
transforma a decisão em regra.

O ID cobre as duas escalas porque é o mesmo invariante em granularidades diferentes: `@escopo/ui`
consumido por três packages e `@features/faturas` consumido por três features são o mesmo evento.
Deep import continua proibido em qualquer contagem, e isso **não** é este ID — é `REACT-ARCH-05` no
frontend e o campo `exports` do `package.json` no workspace.

> **Quem é dono de quê.** `MONO-12` decide *quais arestas podem existir*; `REACT-ARCH-05` decide
> *como atravessar* uma que existe; `REACT-ARCH-08` é a mesma contagem aplicada dentro de uma app
> React, e cita este ID. Confundir os três foi o defeito que abriu esta seção.

---

## 7. O que o CI precisa ter

Um CI que só roda lint, typecheck e teste **não verifica um monorepo**. Faltam três:

| Passo | Pega o quê |
| --- | --- |
| `bun pm why <contrato>` e `<react>` | resolução dupla — degradação silenciosa de tipo |
| teste do raio de explosão | contrato morto: renomeie um campo do schema e conte os erros. Zero erro = o contrato não existe mais |
| smoke em modo **produção** | tudo que depende de cwd, `NODE_ENV` ou de artefato de build |
| sonda de fan-in lateral (`MONO-12`) | irmão que já é compartilhado de fato e continua importado direto por três ou mais |

### A sonda de fan-in lateral (`MONO-12`)

**O executável não mora aqui.** Ele é `skills/bun-workspace/scripts/fan-in-lateral.sh`, no Hermes, e
é a skill `bun-workspace` que documenta a invocação — este vault tem o que se **aprende**, o repo tem
o que **executa**, e copiar o código para cá criaria a segunda cópia que a próxima correção esquece.
Quem audita chega pela sonda S14 do `monorepo-auditor`.

O que ela faz, e o que esperar:

- roda as **duas escalas** — packages, identificados pelo `name` do manifesto, e as features de cada
 `apps/*/src/features` que encontrar;
- **lista a aresta antes de contá-la**, porque o número sozinho não diz o que consertar;
- exclui `*boundar*`: o teste de fronteira carrega o import proibido **como string** para afirmá-lo,
 e contá-lo é reportar a guarda como violação;
- **sai com código 1** quando algum alvo chega a três — é isso que a faz passo de CI, e não leitura.

Contagem **3 ou mais** é violação de `MONO-12`; 1 e 2 são inventário, não achado.

**O consumidor é identificado pelo `name` do manifesto, nunca pelo diretório.**
`packages/infra/database` e `packages/infra/env` são irmãos distintos, e recortar o caminho pelo
primeiro componente inventa uma aresta do pacote para ele mesmo — defeito que a primeira versão
desta sonda tinha, encontrado ao rodá-la.

Verificação da própria sonda, nos dois sentidos: contra um workspace real de sete packages e duas
apps, onde o fan-in máximo é 2 e ela sai 0; e contra um fixture com três consumidores plantados em
cada escala, onde acusa os dois alvos e sai 1, **sem** contar o quarto "consumidor", que só carrega o
teste de fronteira. Refaça as duas antes de confiar nela noutro repositório.

### A lição que atravessa a migração inteira

> **CI verde não é evidência de que a migração preservou o comportamento.**

Passaram pelo CI verde, numa única migração: produção servindo 404 na raiz, a guarda de resolução
única inexistente apesar de documentada, e cinco violações de regra de fronteira. Os três só
apareceram porque alguém foi olhar — smoke em produção, auditoria adversarial, e leitura dos imports.

Duas disciplinas que decorrem disso, e valem além do monorepo:

- **guarda que não falha não é guarda.** Sabote a guarda e confirme que o CI fica vermelho;
- **número medido tem data de validade.** Ao citar, remeça. Um número correto quando medido vira
 falso quando o sistema ganha um consumidor a mais.

---

## 8. Contrato de skill

```
SEMPRE: § 1 (as duas perguntas) + § 6 (regras MONO-*)

AO CRIAR O WORKSPACE: § 2 (árvore) + § 5.1, § 5.2, § 5.6
AO EXTRAIR UM PACOTE: § 1 + MONO-01 + § 3 (nomes)
AO CONFIGURAR O CI: § 7 + MONO-04, MONO-07, MONO-11, MONO-12
AO MIGRAR APP EXISTENTE: § 5 inteira + MONO-10
AO AUDITAR: § 7 + MONO-11, MONO-12

TAMBÉM: [Feature-Based Architecture](feature-based-architecture.md) para dentro de cada app
 [Fronteira do BFF - forma, jornada e regra](fronteira-do-bff-forma-jornada-e-regra.md) para o corte servidor/cliente

NUNCA: criar pacote por simetria, sem duplicação que o justifique
```

### Invariantes

1. **Duas perguntas, não uma** (§ 1). Contrato de tipos e UI compartilhada respondem diferente.
2. **Evidência antes de extração.** Duplicação que divergiu é fatura; duplicação prevista é palpite.
3. **A degradação de tipo é silenciosa** e só o CI pega (`MONO-04`).
4. **Documento não é guarda** (`MONO-11`). Se está escrito e não roda, não existe.
5. **Um passo por vez, verde antes do seguinte** (`MONO-10`).
6. **A aresta lateral é permitida e contada** (`MONO-12`). Quem decide que aresta existe é esta
 nota; `REACT-ARCH-05` só decide como atravessá-la. Ao terceiro consumidor a permissão acaba.
7. **Verificar antes de afirmar.** Toda afirmação sobre comportamento de ferramenta nesta nota foi
 executada. Se divergir do real, a nota é o bug.

---

## Relacionados

- [Feature-Based Architecture](feature-based-architecture.md) — onde o código mora **dentro** de cada app
- [Fronteira do BFF - forma, jornada e regra](fronteira-do-bff-forma-jornada-e-regra.md) — quem é dono de cada decisão na fronteira
- ·
- [Bun](../docs/bun.md) · [Bun - Gerenciador de Pacotes](../docs/bun-gerenciador-de-pacotes.md) (`BUN-PKG-08`: overrides só na raiz) · [Bun - Testes](../docs/bun-testes.md)
- [Elysia](../docs/elysia.md) · [Elysia - Schema e Eden](../docs/elysia-schema-e-eden.md) — a degradação para `any` e suas causas
- [TanStack Router](../docs/tanstack-router.md) — rotas virtuais, quando a convenção de arquivo colide com a feature
- [Architecture in React](architecture-in-react.md) — o roteador das decisões arquiteturais
-
- `Monorepo Architecture - The Ultimate Guide for 2025` — fonte externa (blog do FSD): o mesmo
 problema resolvido com pnpm, Turborepo e Nx. Confirma fronteira, direção e API pública; diverge em
 tooling, em `paths` do tsconfig e no critério de extração. Acrescenta `affected`, cache remoto,
 `CODEOWNERS` e prune no deploy — nada disso verificado aqui

## Procedência

Destilada da migração de `elysia-bff-lab` de pacote único para workspace Bun, em 2026-08-16.
Seis passos, cada um com CI verde, seguidos de auditoria adversarial. As armadilhas da § 5 são todas
falhas reais encontradas na execução, não hipóteses — cinco durante os passos, duas na auditoria.
Comportamento de ferramenta verificado com Bun 1.3.14.
