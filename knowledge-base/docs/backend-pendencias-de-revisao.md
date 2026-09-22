---
titulo: Backend - Pendências de revisão
tags:
  - bun
  - hono
  - elysia
  - manutencao
source: "Teste de leitura com agentes sem contexto + auditoria adversarial, 2026-08-15"
verificado-em: 2026-08-15
---

# Backend — registro de revisão

> O que a revisão de [Bun](bun.md) · [Hono](hono.md) · [Elysia](elysia.md) · [Backend no runtime Bun](backend-no-runtime-bun.md) encontrou, o que foi corrigido, e o que **continua aberto**.
>
> **Por que esta nota existe.** A estrutura passou por cinco leitores sem contexto e duas auditorias adversariais em 2026-08-15. Guardar o que foi achado — e o que sobrou — é o que impede o mesmo defeito de ser redescoberto do zero na próxima edição.

**Estado: 49 achados aplicados.** Bun (5 do hub + os satélites), Hono (H1–H24), Elysia (E1–E20). Restam os itens abertos da seção final, todos declarados dentro das próprias notas.

---

## O que a revisão encontrou

Cinco classes de defeito, todas encontradas por leitura e nenhuma por releitura do autor:

**1. Exemplo que viola a regra da própria nota** — a classe mais grave, sete ocorrências. O único exemplo de 409 de Hono usava `throw new HTTPException`, que por `HONO-RPC-09` **não chega tipado ao cliente RPC**; as duas únicas construções de cliente Eden do vault omitiam o `parseDate: false` que `ELYSIA-TYPE-10` declara `MUST`; o exemplo marcado ✅ da § 8 de Lifecycle usava `derive` para resolver sessão, que `ELYSIA-LIFE-02` declara `NEVER`; o exemplo canônico de WebSocket de Bun roteava por `URL(req.url).pathname` dentro de `fetch`, que `BUN-HTTP-01` proíbe; e o Dockerfile "que vale reproduzir" referenciava um stage inexistente.

**2. Duas fontes de verdade divergindo** — o texto de regra existia no hub **e** no satélite, e as cópias derivaram. A pior perdeu o `process.exit()` de `BUN-SYS-11` e prescrevia um shutdown que deixa o container pendurado até o `SIGKILL`. Corrigido por construção: a § 6.1 dos três hubs agora reproduz o satélite **verbatim**, com o satélite declarado canônico.

**3. Rota que não entrega** — a § 4 prometia rotear API → satélite e metade dela estava em granularidade de área, não de assinatura. Um leitor procurando o diagnóstico de um SSE que caía não achava nada e chegou à resposta por leitura linear da tabela de 34 regras.

**4. Regra inverificável** — `MUST verificar`, `MUST conferir`, `escritas relacionadas`. Predicado que é ato mental não reprova PR nenhum, e ruído numa tabela de regras faz o agente ignorar a tabela inteira.

**5. Contagem em prosa** — errada em 11 na primeira medição, e errada de novo depois. Numeral escrito à mão é dívida de manutenção; hoje as três estruturas declaram o total com detalhamento por família, e há um checador.

## O achado que mais mudou a estrutura

A nota de decisão roteava o perfil React → **Hono**, e a documentação de Hono era a mais fraca das duas exatamente em "erro tipado chegando ao React" — o requisito que decidia a escolha. Hono tinha **zero** IDs citáveis para o bug que [Backend no runtime Bun](backend-no-runtime-bun.md) elege como o mais acionável do corpus (a `queryFn` que nunca lança), contra três de Elysia; e o contrato de skill nunca mandava carregar a § 8, embora a invariante 5 da mesma seção mandasse "preferir a ponte".

Hoje Hono tem `HONO-CORE-13`, `HONO-RPC-13` e `HONO-RPC-14`, a § 6.1 os carrega, e a § 7 tem bloco `EM CONSUMO PELO REACT`.

## Invariantes que agora são verificáveis por script

| Invariante | Estado |
| --- | --- |
| § 6.1 do hub reproduz o satélite verbatim | ok nas três |
| Nenhum ID citado no corpo sem existir em tabela | ok nas três |
| Nenhuma lacuna de numeração dentro de família | ok nas três |
| Nenhuma regra com predicado inverificável | ok em Hono e Elysia |
| Contagem declarada bate com a real | Bun 89 · Hono 50 · Elysia 44 |
| Todo ``wikilink`` resolve | ok |

---

## O que continua aberto

**1. WebSocket em Hono.** Só a origem do import está verificada (`HONO-APP-08` e a matriz da § 3.2). Assinatura de `upgradeWebSocket`, formato de `ConnInfo` e opções **não** foram conferidos, e o hub declara isso nominalmente. Elysia tem `.ws()` com schema e cliente `EdenWS` documentados. Se WebSocket virar requisito, este eixo pesa e falta metade.

**2. `@hono/zod-openapi` não verificado.** É a lacuna que mais pode mudar uma decisão: o nó de OpenAPI é o que inverte a árvore do § 3 de [Backend no runtime Bun](backend-no-runtime-bun.md). A fonte indica que o pacote muda a forma de escrever as rotas, o que não é detalhe.

**3. O envelope paginado é convenção deste vault, não das ferramentas.** `hasMore` foi adotado nas três estruturas porque `TSQ-PATTERN-05` em [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) lê `data?.hasMore`, e o consumidor veio primeiro. Nem Hono nem Elysia têm opinião sobre formato de resposta de lista. Está declarado como decisão local em `ELYSIA-TYPE-13` e na § 8.6 de [Hono](hono.md).

**4. `BUN-SYS-07` ainda contém a palavra "conferir".** Hoje tem método concreto e artefato (a enumeração de módulos `node:*`, incluindo transitivos), então é falso positivo do checador — mas a redação pode ser apertada.

**5. Nada foi confirmado executando código.** As verificações vêm de doc oficial, `.d.ts` e JS publicado. Três afirmações de Elysia vieram do pacote e **contradizem a documentação**: o default de `aot` é `true` (a página diz `false`), o status de erro de validação é `422` (nenhuma página declara), e o export `env` devolve `{}` no Cloudflare Worker.

## Fora do escopo desta estrutura

Notas preexistentes que o caminho mínimo referencia e que estão vazias ou quase — apontadas por dois leitores independentes:

| Nota | Estado | Por que importa |
| --- | --- | --- |
| `Guia de configuração para projetos TypeScript` | **0 bytes** | `HONO-RPC-11` exige `"strict": true` nos dois `tsconfig.json` como requisito documentado, e nada mostra o layout de projeto (monorepo? workspaces? project references?) |
| `TypeScript` | ~1 KB | a ponte tipada usa `ReturnType<typeof hc<...>>`, module augmentation e união discriminada por status, sem explicação em lugar nenhum |
| `Node.js` | 67 bytes | é linkada repetidamente como a fronteira que Bun substitui |

---

## Relacionados

- [Bun](bun.md) · [Hono](hono.md) · [Elysia](elysia.md) · [Backend no runtime Bun](backend-no-runtime-bun.md)
- `README` — índice de `docs/`
