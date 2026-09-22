---
gerado-por: skills/http/http-review/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-22
---

# ID map `HTTP-*`

> An index, not a copy: it says **where** the rule is declared, never what it says.
> Regenerate with `bash skills/http/http-review/scripts/gerar-mapa-de-ids.sh` —
> the same file is written into all four HTTP skills.

## Canonical IDs and aliases


Dois princípios aparecem em mais de um arquivo, com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use o ID canônico.**

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| O status carrega o resultado; corpo de erro dentro de `2xx` não existe | `HTTP-CORE-06` | `HTTP-STATUS-01` |
| Resposta que varia por header de request declara `Vary` | `HTTP-CORE-04` | — ver abaixo |

**`Vary` é o caso que não é apelido, e a distinção importa.** Três regras exigem `Vary` e **nenhuma delas é redundante**: cada uma acrescenta uma obrigação concreta que as outras não cobrem. Cite a específica quando o contexto for específico.

| O que acrescenta ao princípio geral | Cite |
| --- | --- |
| O enunciado geral — e o único que viaja no caminho mínimo | `HTTP-CORE-04` |
| A consequência de cache: sem `Vary`, o cache serve a representação errada a outro cliente | `HTTP-CACHE-10` |
| Resposta comprimida traz no mínimo `Vary: Accept-Encoding` | `HTTP-NEG-01` |
| Com origem dinâmica, `Vary: Origin` vale inclusive quando a origem é **recusada** | `HTTP-CORS-03` |

O mesmo vale para `ETag` forte: `HTTP-CACHE-09` é o canônico, e `HTTP-NEG-12` é a aplicação dele em retomada de download.


## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `HTTP-CACHE-01` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 3. `Cache-Control`, diretiva a diretiva, no que decide código |
| `HTTP-CACHE-02` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 3. `Cache-Control`, diretiva a diretiva, no que decide código |
| `HTTP-CACHE-03` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 3. `Cache-Control`, diretiva a diretiva, no que decide código |
| `HTTP-CACHE-04` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 3. `Cache-Control`, diretiva a diretiva, no que decide código |
| `HTTP-CACHE-05` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 4. Revalidação: `ETag` e `Last-Modified` |
| `HTTP-CACHE-06` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 4. Revalidação: `ETag` e `Last-Modified` |
| `HTTP-CACHE-07` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 4. Revalidação: `ETag` e `Last-Modified` |
| `HTTP-CACHE-08` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 5. `If-Match` e `If-Unmodified-Since`: o uso mais valioso e menos conhecido |
| `HTTP-CACHE-09` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 5. `If-Match` e `If-Unmodified-Since`: o uso mais valioso e menos conhecido |
| `HTTP-CACHE-10` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 6. `Vary` e o cache envenenado |
| `HTTP-CACHE-11` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 6. `Vary` e o cache envenenado |
| `HTTP-CACHE-12` | [HTTP - Cache e Requisições Condicionais](../../../../knowledge-base/docs/http-cache-e-requisicoes-condicionais.md) | 7. Invalidação: por que não existe "purge" no protocolo |
| `HTTP-CORE-01` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-02` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-03` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-04` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-05` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-06` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-07` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORE-08` | [HTTP](../../../../knowledge-base/docs/http.md) | 6. Regras normativas |
| `HTTP-CORS-01` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 4. `Access-Control-Allow-Origin` e o veto do `*` com credenciais |
| `HTTP-CORS-02` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 4. `Access-Control-Allow-Origin` e o veto do `*` com credenciais |
| `HTTP-CORS-03` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 4. `Access-Control-Allow-Origin` e o veto do `*` com credenciais |
| `HTTP-CORS-04` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 5. `Access-Control-Expose-Headers`: o sintoma clássico |
| `HTTP-CORS-05` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 3. Simples × preflighted: o que exatamente dispara o preflight |
| `HTTP-CORS-06` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 3. Simples × preflighted: o que exatamente dispara o preflight |
| `HTTP-CORS-07` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 3. Simples × preflighted: o que exatamente dispara o preflight |
| `HTTP-CORS-08` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 6. O modelo de falha, e o que CORS não protege |
| `HTTP-CORS-09` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 4. `Access-Control-Allow-Origin` e o veto do `*` com credenciais |
| `HTTP-CORS-10` | [HTTP - CORS](../../../../knowledge-base/docs/http-cors.md) | 5. `Access-Control-Expose-Headers`: o sintoma clássico |
| `HTTP-METH-01` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 1. Conceito: a semântica do método é um contrato com intermediários que você não controla |
| `HTTP-METH-02` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 6. Corpo em `GET`, `HEAD` e `DELETE`: o que a spec realmente diz |
| `HTTP-METH-03` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 3. `PUT` × `PATCH` × `POST`: decidido por semântica, não por hábito |
| `HTTP-METH-04` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 3. `PUT` × `PATCH` × `POST`: decidido por semântica, não por hábito |
| `HTTP-METH-05` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 3. `PUT` × `PATCH` × `POST`: decidido por semântica, não por hábito |
| `HTTP-METH-06` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 5. `HEAD`, `OPTIONS`, `Allow` e o `405` |
| `HTTP-METH-07` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 5. `HEAD`, `OPTIONS`, `Allow` e o `405` |
| `HTTP-METH-08` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 7. Idempotência é decisão de desenho, não do cliente |
| `HTTP-METH-09` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 7. Idempotência é decisão de desenho, não do cliente |
| `HTTP-METH-10` | [HTTP - Métodos e Semântica](../../../../knowledge-base/docs/http-metodos-e-semantica.md) | 7. Idempotência é decisão de desenho, não do cliente |
| `HTTP-NEG-01` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 5. `Vary`: a contrapartida obrigatória |
| `HTTP-NEG-02` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 3. `Content-Type`, `charset` e a fronteira do request |
| `HTTP-NEG-03` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 4. Compressão: `Content-Encoding` × `Transfer-Encoding` |
| `HTTP-NEG-04` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 4. Compressão: `Content-Encoding` × `Transfer-Encoding` |
| `HTTP-NEG-05` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 4. Compressão: `Content-Encoding` × `Transfer-Encoding` |
| `HTTP-NEG-06` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 2. `Accept*` e a sintaxe de qualidade |
| `HTTP-NEG-07` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 3. `Content-Type`, `charset` e a fronteira do request |
| `HTTP-NEG-08` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 7. `Content-Disposition` |
| `HTTP-NEG-09` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 6. `Range` e `206`: requisição parcial |
| `HTTP-NEG-10` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 6. `Range` e `206`: requisição parcial |
| `HTTP-NEG-11` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 6. `Range` e `206`: requisição parcial |
| `HTTP-NEG-12` | [HTTP - Negociação de Conteúdo e Range](../../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | 6. `Range` e `206`: requisição parcial |
| `HTTP-SPEC-01` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-02` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-03` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-04` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-05` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-06` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-07` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-08` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-09` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-SPEC-10` | [HTTP - Specs e RFCs](../../../../knowledge-base/docs/http-specs-e-rfcs.md) | 6. Regras — `HTTP-SPEC-*` |
| `HTTP-STATUS-01` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 1. Conceito: o status é a parte da resposta que intermediários leem sem abrir o corpo |
| `HTTP-STATUS-02` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 1. Conceito: o status é a parte da resposta que intermediários leem sem abrir o corpo |
| `HTTP-STATUS-03` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 2. Sucesso: qual dos quatro |
| `HTTP-STATUS-04` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 2. Sucesso: qual dos quatro |
| `HTTP-STATUS-05` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 2. Sucesso: qual dos quatro |
| `HTTP-STATUS-06` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 3. Redirecionamento: a árvore que decide `301` · `302` · `303` · `307` · `308` |
| `HTTP-STATUS-07` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 3. Redirecionamento: a árvore que decide `301` · `302` · `303` · `307` · `308` |
| `HTTP-STATUS-08` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 3. Redirecionamento: a árvore que decide `301` · `302` · `303` · `307` · `308` |
| `HTTP-STATUS-09` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 3. Redirecionamento: a árvore que decide `301` · `302` · `303` · `307` · `308` |
| `HTTP-STATUS-10` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 4. Erro de cliente: os pares que se confundem |
| `HTTP-STATUS-11` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 4. Erro de cliente: os pares que se confundem |
| `HTTP-STATUS-12` | [HTTP - Status e Redirecionamento](../../../../knowledge-base/docs/http-status-e-redirecionamento.md) | 5. Erro de servidor: `500` × `502` × `503` × `504` |
