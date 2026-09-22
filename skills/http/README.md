# Skills de HTTP — quatro, porque cache é domínio próprio

| Skill | Domínio | Fonte | Apoio interno |
| --- | --- | --- | --- |
| `http-contract` | método, status, idempotência, corpo de erro | [HTTP - Métodos e Semântica](../../knowledge-base/docs/http-metodos-e-semantica.md) | 5 referências + 1 script |
| `http-cache` | frescor, `ETag`, condicional, escrita concorrente, `Vary` | [HTTP - Cache e Requisições Condicionais](../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 6 referências + 1 script |
| `http-diagnose` | requisição bloqueada, formato errado | [HTTP - CORS](../../knowledge-base/docs/http-cors.md) | 5 referências + 1 script |
| `http-review` | auditar o contrato de uma API existente | [HTTP](../../knowledge-base/docs/http.md) | 6 referências + 2 scripts |

## O que os pacotes acrescentaram

As quatro skills descreviam sondas `curl` **em tabela**. Agora elas rodam:

| Script | O que faz |
| --- | --- |
| `http-review/scripts/sondas.sh <base> <rota> [escrita] [origem]` | S1–S8, incluindo `If-Match` obsoleto e origem recusada |
| `http-diagnose/scripts/sondas-cors.sh <url> [origem]` | as cinco, com a **leitura** de cada resultado |
| `http-cache/scripts/sondas-cache.sh <url> [escrita]` | extrai o `ETag` real e **reusa** em `If-None-Match` |
| `http-contract/scripts/conferir.sh <base> <rota> [escrita]` | `GET`/`HEAD`/`PATCH`/`POST`/erro, e lista o que exige leitura |

**Duas sondas foram desenhadas para pegar o que ninguém roda:**

- **origem recusada** (`curl -H 'Origin: https://malicioso.example'`) — se a origem for
 ecoada, é reflexo cego (`HTTP-CORS-01`); se faltar `Vary: Origin`, o cache serve a
 resposta de uma origem para outra (`HTTP-CORS-03`);
- **escrita com `If-Match` obsoleto** — se ela for **aplicada**, há perda silenciosa de dado
 sob concorrência (`HTTP-CACHE-08`). É o achado mais grave da família, e o menos testado.

`curl` **não faz CORS** — e é exatamente por isso que ele serve: mostra o que o servidor
responde, sem o browser no meio.

## O mapa de IDs

Gerado por `http-review/scripts/gerar-mapa-de-ids.sh`, igual nas quatro. **74 IDs** — o
número que o hub declara, com numeração contínua: um ID ausente é bug da estrutura.

**A peculiaridade:** `Vary` tem **três** regras que **não são apelidos** — `HTTP-CACHE-10`
(cache), `HTTP-NEG-01` (compressão) e `HTTP-CORS-03` (origem dinâmica), sobre o enunciado
geral `HTTP-CORE-04`. Cada uma acrescenta uma obrigação concreta, e citar a genérica onde
cabia a específica perde informação. O cabeçalho do mapa carrega a § 6.2 inteira.

```bash
bash plugins/hermes-core/skills/http-review/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `http-cache` | 1.417 | `mapa-de-ids.md` (3.267) | 8.332 | 7 |
| `http-contract` | 1.378 | `mapa-de-ids.md` (3.267) | 8.223 | 6 |
| `http-diagnose` | 1.311 | `mapa-de-ids.md` (3.267) | 7.483 | 6 |
| `http-review` | 1.220 | `mapa-de-ids.md` (3.267) | 8.823 | 6 |

Carregar as 4 skills deste grupo de uma vez custaria **5.326 tokens** só de `SKILL.md`,
e **32.861** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Relacionados

- [Skill — Índice](../README.md) · [HTTP](../../knowledge-base/docs/http.md) § 7 — o contrato
- `hermes-backend: família elysia` — o mecanismo que implementa o contrato
- `tanstack-query` — a camada de cache do cliente, que não é esta
