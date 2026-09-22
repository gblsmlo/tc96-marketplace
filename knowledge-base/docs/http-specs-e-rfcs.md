---
titulo: HTTP - Specs e RFCs
Link: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Resources_and_specifications
tags:
  - http
  - rfc
  - specs
  - agent-context
source: "MDN Web Docs — https://developer.mozilla.org/en-US/docs/Web/HTTP"
verificado-em: 2026-08-15
---

# HTTP - Specs e RFCs

> Diferença entre MDN e documento normativo · a reorganização de 2022 (7230–7235 → 9110–9114) · mapa spec → o que rege → nota do vault · onde confirmar cada assunto · registros do IANA · o que o vault já cobre e o que é lacuna.
>
> **Não cobre:** semântica de método ([HTTP - Métodos e Semântica](http-metodos-e-semantica.md)) · significado de cada status ([HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md)) · diretivas de cache ([HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md)) · mecânica de preflight ([HTTP - CORS](http-cors.md)) · `Accept-*` e `Range` ([HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)) · atributos de cookie ([RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md)) · política de OAuth/JWT ([RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md), [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md)).

Entrada: [HTTP](http.md) · Base normativa: [HTTP](http.md) § 6

---

## 1. Conceito: o MDN ensina, o RFC decide

MDN é a melhor porta de entrada de HTTP que existe e **não é normativa**. Ele descreve o que os browsers fazem, com a granularidade certa para aprender; não é o texto que define o protocolo, e não é o texto que um implementador de servidor, proxy ou cache é obrigado a obedecer. Quando o MDN e o RFC divergem, o RFC vence — e a divergência acontece, porque MDN simplifica de propósito e porque browsers implementam subconjuntos.

A consequência prática é uma só, e é onde esta nota paga o custo de existir: **em discussão de code review, o link do MDN não encerra o assunto e o RFC encerra.** "O MDN diz que PUT é idempotente" convida a réplica; "RFC 9110 § 9.2.2 lista PUT como idempotent" não convida. A diferença entre as duas frases é ter, na mão, o número e a seção. Achar isso do zero custa dez minutos por vez; esta tabela custa zero.

**Quando escalar de MDN para RFC:**

| Situação | Fonte suficiente |
| --- | --- |
| Aprender o que um header faz, ver exemplo, checar suporte de browser | MDN |
| Decidir o comportamento de um servidor, cache ou proxy que você escreve | RFC |
| Uma afirmação com `MUST`/`SHOULD`/`MUST NOT` entrando em doc, ADR ou revisão | RFC, com seção |
| Duas pessoas discordam sobre o que o protocolo exige | RFC, com seção |
| Um header ou status que você não sabe se existe oficialmente | Registro do IANA (§ 4) |
| Comportamento de `fetch()`, CORS ou preflight no browser | **Fetch Standard (WHATWG)**, não IETF |

E o inverso também vale: o RFC **não** documenta suporte de browser, não traz exemplo pedagógico e não avisa quando a prática de mercado diverge do texto. Ler RFC para aprender HTTP é caro e desnecessário. Ler RFC para fechar uma decisão é barato e obrigatório.

---

## 2. A reorganização de 2022 — a seção que mais importa

Em **junho de 2022** o IETF republicou o núcleo do HTTP. A família 7230–7235, de 2014, foi dividida por **eixo** em vez de por versão: semântica de um lado, cache de outro, e a sintaxe de fio de cada versão em seu próprio documento. Os números antigos continuam acessíveis e continuam aparecendo em Stack Overflow, em blog post e em comentário de código — **e estão obsoletos**.

| Documento de 2014 | Título | Substituído por |
| --- | --- | --- |
| RFC 7230 | HTTP/1.1: Message Syntax and Routing | **RFC 9110 e RFC 9112** (dividido entre os dois) |
| RFC 7231 | HTTP/1.1: Semantics and Content | **RFC 9110** |
| RFC 7232 | HTTP/1.1: Conditional Requests | **RFC 9110** (§ 13) |
| RFC 7233 | HTTP/1.1: Range Requests | **RFC 9110** (§ 14) |
| RFC 7234 | HTTP/1.1: Caching | **RFC 9111** |
| RFC 7235 | HTTP/1.1: Authentication | **RFC 9110** (§ 11) |
| RFC 7538 | Status Code 308 (Permanent Redirect) | **RFC 9110** (§ 15.4.9) |
| RFC 7540 | HTTP/2 | **RFC 9113** |
| RFC 7807 | Problem Details for HTTP APIs | **RFC 9457** |

E o que ficou no lugar, com status confirmado no rfc-editor.org em **2026-08-15**:

| RFC | Título | Status | Data |
| --- | --- | --- | --- |
| **9110** | HTTP Semantics | **Internet Standard — STD 97** | jun/2022 |
| **9111** | HTTP Caching | **Internet Standard — STD 98** | jun/2022 |
| **9112** | HTTP/1.1 | **Internet Standard — STD 99** | jun/2022 |
| **9113** | HTTP/2 | Proposed Standard | jun/2022 |
| **9114** | HTTP/3 | Proposed Standard | jun/2022 |
| **9204** | QPACK: Field Compression for HTTP/3 | Proposed Standard | jun/2022 |

Três pontos que mudam como se cita:

**A semântica não pertence mais a nenhuma versão.** RFC 9110 define método, status, header e negociação para HTTP/1.1, /2 e /3 ao mesmo tempo. Citar "RFC 9112 § ..." para falar de `POST` é erro de endereço: 9112 só cobre a sintaxe de fio do 1.1 (linha de request, `Transfer-Encoding`, gestão de conexão). Se a afirmação vale em HTTP/2, ela mora em 9110.

**9110, 9111 e 9112 são Internet Standard; 9113 e 9114 não.** A distinção não é cosmética: `Internet Standard` (com número STD) é o topo do processo do IETF e sinaliza estabilidade e implantação comprovadas. HTTP/2 e HTTP/3 seguem em `Proposed Standard` — plenamente implantados, mas em degrau formal mais baixo. Em documento que classifica maturidade de dependências, isso é a informação correta.

**RFC 9110 obsoletou também a RFC 2818 (HTTP Over TLS).** As regras de verificação de identidade em `https` passaram para 9110 § 4.3.4. Citar 2818 para justificar validação de certificado é citar documento obsoletado.

> **Regra de bolso:** número de RFC de HTTP começando com **72xx** ou **75xx** no meio de uma discussão de protocolo é, quase sempre, o documento errado. Confira a linha "Obsoleted by" no `rfc-editor.org/info/rfcNNNN` — ela é o campo mais barato de checar e o mais caro de ignorar.

---

## 3. Mapa spec → o que rege → nota do vault

Status e data confirmados individualmente em `rfc-editor.org` em **2026-08-15**, salvo onde indicado.

### 3.1 Núcleo

| Spec | O que governa | Seção mais citada | Nota do vault |
| --- | --- | --- | --- |
| **RFC 9110** · Internet Standard (STD 97) | métodos, status, campos, negociação, condicionais, range, framework de auth | § 9 métodos · § 15 status · § 12 negociação · § 13 condicionais · § 14 range · § 11 auth · § 5 campos | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| **RFC 9111** · Internet Standard (STD 98) | cache compartilhado e privado, frescor, revalidação, invalidação | § 5.2 `Cache-Control` · § 4.1 `Vary` · § 4.2 frescor · § 4.3 validação · § 4.4 invalidação | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| **RFC 9112** · Internet Standard (STD 99) | sintaxe de fio do HTTP/1.1: request line, framing, `Transfer-Encoding`, conexão | § 6 framing · § 9 conexões persistentes | — |
| **RFC 9113** · Proposed Standard | HTTP/2: frames, streams, HPACK, multiplexação | § 5 streams · § 8 mapeamento de semântica | — |
| **RFC 9114** · Proposed Standard | HTTP/3 sobre QUIC | § 4 expressão de semântica · § 6 streams | — |
| **RFC 9204** · Proposed Standard | QPACK, compressão de campos do HTTP/3 | — | — |
| **RFC 9218** · Proposed Standard, jun/2022 | esquema de prioridade extensível: header `Priority`, `u` e `i`, `PRIORITY_UPDATE` | § 4 parâmetros | — |
| **RFC 9651** · Proposed Standard, set/2024 (obsoleta 8941) | Structured Field Values: tipos e parsing de valores de header | § 3 tipos | — |
| **RFC 9205** · **Best Current Practice — BCP 56**, jun/2022 | como construir protocolos de aplicação **em cima** de HTTP sem quebrar a semântica genérica | inteiro; é curto | — |

RFC 9205 é a menos conhecida e a mais útil em revisão de design de API: ela é o documento que proíbe redefinir método, status ou campo genérico com significado próprio da sua aplicação. Quando alguém propõe "`404` aqui significa que o pagamento falhou", o argumento que encerra está nela.

### 3.2 Erros, extensões e campos

| Spec | O que governa | Nota do vault |
| --- | --- | --- |
| **RFC 9457** · Proposed Standard, jul/2023 (obsoleta **7807**) | `application/problem+json`: `type`, `title`, `status`, `detail`, `instance` | — (lacuna; conceito em) |
| **RFC 5789** · Proposed Standard, mar/2010 | método `PATCH` e header `Accept-Patch` — **não** está na 9110 | [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) |
| **RFC 6585** · Proposed Standard, abr/2012 | status `428`, `429`, `431`, `511` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| **RFC 8246** · Proposed Standard, set/2017 | diretiva `Cache-Control: immutable` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| **RFC 5861** · **Informational**, mai/2010 | `stale-while-revalidate` e `stale-if-error` | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| **RFC 8288** · Proposed Standard, out/2017 (obsoleta 5988) | header `Link` e tipos de relação | |
| **RFC 6266** · Proposed Standard, jun/2011 | `Content-Disposition` em HTTP: `attachment`, `inline`, `filename*` | |
| **RFC 7578** · Proposed Standard, jul/2015 (obsoleta 2388) | `multipart/form-data` | |
| **RFC 7239** · Proposed Standard, jun/2014 | header `Forwarded` (`for`, `by`, `host`, `proto`) | — |
| **RFC 9530** · Proposed Standard, 2024 (obsoleta 3230) | `Content-Digest`, `Repr-Digest`, `Want-*` | — |
| **RFC 3986** · **Internet Standard (STD 66)**, jan/2005 | sintaxe genérica de URI, resolução de referência relativa | — |

Duas armadilhas nessa lista. **`PATCH` não está na RFC 9110** — quem procura o método na spec de semântica não acha, porque ele vive na 5789 desde 2010; e a 5789 exige atomicidade ("ou aplica inteiro, ou não aplica nada"), o que muitas implementações ignoram. E **`stale-while-revalidate` é `Informational`** — categoria mais fraca da lista inteira. A diretiva é largamente implementada por CDNs, mas apoiar um SLA nela é apoiar em algo que o IETF não colocou no standards track.

### 3.3 Cookies, autenticação e sessão — território já coberto pelo vault

| Spec | O que governa | Nota do vault |
| --- | --- | --- |
| **RFC 6265** · Proposed Standard, abr/2011 | `Set-Cookie`, `Cookie`, `Domain`, `Path`, `Secure`, `HttpOnly` | [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) |
| **draft-ietf-httpbis-rfc6265bis** · rev. **-22** de 2025-12-01, **RFC Ed Queue** (ainda sem número de RFC) | `SameSite`, prefixos `__Host-`/`__Secure-`, limite de 400 dias | [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) |
| **RFC 9110 § 11** | framework de auth: `Authorization`, `WWW-Authenticate`, `Proxy-Authenticate`, `401`, `407`, `realm` | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) |
| **RFC 7617** · Proposed Standard, set/2015 | esquema `Basic` e o parâmetro `charset` | — |
| **RFC 6750** · Proposed Standard, out/2012 · atualizada por 8996 e **9700** | esquema `Bearer`, três formas de transmissão, erros `invalid_token`/`insufficient_scope` | [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) |
| **RFC 9700** · BCP 240 | política de segurança de OAuth 2.0 | [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) |
| **RFC 8725** · BCP 225 | validação de JWT | [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) |
| **RFC 6797** · Proposed Standard, nov/2012 | HSTS: `Strict-Transport-Security`, `max-age`, `includeSubDomains` | [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) |
| **RFC 6454** · Proposed Standard, dez/2011 | conceito de origin (scheme + host + port) e o header `Origin` | |

O ponto que o vault já registra e que esta tabela só reforça: **`SameSite` não existe na RFC 6265.** Citar 6265 para justificar `SameSite=Lax` é citar um documento de 2011 que não menciona o atributo. O documento certo é o 6265bis, e ele ainda é draft — a nota [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) tem a revisão e o estado.

### 3.4 O que é WHATWG, não IETF

| Spec | Organização | O que governa | Nota do vault |
| --- | --- | --- | --- |
| **Fetch Standard** — [fetch.spec.whatwg.org](https://fetch.spec.whatwg.org/) | WHATWG, **Living Standard** | protocolo CORS (§ 3.3), preflight (§ 3.3.8), forbidden request-headers (§ 2.2.2), `Cross-Origin-Resource-Policy`, API `fetch()`/`Headers`/`Request`/`Response` (§ 5) | [HTTP - CORS](http-cors.md) · · |
| **URL Standard** — [url.spec.whatwg.org](https://url.spec.whatwg.org/) | WHATWG, Living Standard | o que browsers realmente fazem com URL; convive com a RFC 3986 sem substituí-la | — |
| **HTML Standard** | WHATWG, Living Standard | Server-Sent Events e o comportamento de formulário sobre HTTP | — |

**Não existe RFC de CORS.** É o erro de atribuição mais comum da área, e ele tem consequência operacional: quem procura CORS no IETF não acha nada, e quem cita um número de RFC para uma regra de CORS está citando algo que não diz aquilo. `Access-Control-Allow-Origin`, a lista de headers permitidos sem preflight e a distinção entre requisição simples e preflighted moram no Fetch Standard.

E a diferença entre os dois processos importa em revisão:

| | IETF (RFC) | WHATWG (Living Standard) |
| --- | --- | --- |
| Versionamento | número imutável; mudança gera novo RFC | não há versão; o documento é editado no lugar |
| Como citar | número + seção — estável para sempre | URL + **data de consulta** + âncora de seção |
| O que "obsoleto" significa | campo explícito `Obsoleted by` | não existe; o texto antigo simplesmente sumiu |
| Estabilidade da citação | permanente | numeração de seção pode mudar entre consultas |

Por isso `HTTP-SPEC-10` exige data em citação de WHATWG: sem ela, ninguém consegue reconstruir o que o texto dizia quando a decisão foi tomada.

---

## 4. Onde a especificação mora, por assunto

O inverso da § 3: você tem uma dúvida, quer o endereço.

| Assunto | Onde confirmar |
| --- | --- |
| Um método é safe? idempotente? cacheável? | RFC 9110 § 9.2 (propriedades) e § 9.3 (cada método) |
| O que este status significa exatamente | RFC 9110 § 15; `428`/`429`/`431`/`511` em RFC 6585 |
| `301` × `302` × `303` × `307` × `308` | RFC 9110 § 15.4 |
| Semântica de `PATCH` | RFC 5789 (**não** está na 9110) |
| Uma diretiva de `Cache-Control` | RFC 9111 § 5.2 — request em 5.2.1, response em 5.2.2 |
| Como o cache monta a chave, e o papel de `Vary` | RFC 9111 § 4.1 |
| Cálculo de frescor e de `Age`; frescor heurístico | RFC 9111 § 4.2 |
| `ETag`, `If-None-Match`, `If-Match`, precedência de precondições | RFC 9110 § 13 |
| `Accept`, `Accept-Language`, `Accept-Encoding`, q-values | RFC 9110 § 12 |
| `Range`, `Accept-Ranges`, `Content-Range`, `206` | RFC 9110 § 14 |
| `Authorization` / `WWW-Authenticate` / `401` / `407` | RFC 9110 § 11 |
| Qualquer coisa de CORS ou preflight | **Fetch Standard § 3.3** (WHATWG) |
| Comportamento de `fetch()`, `Headers`, `Request`, `Response` | **Fetch Standard § 5** (WHATWG) |
| `SameSite`, `__Host-`, prefixos de cookie | **draft-ietf-httpbis-rfc6265bis** |
| Formato de corpo de erro de API | RFC 9457 |
| **Este header existe oficialmente?** | **IANA HTTP Field Name Registry** |
| **Este status code existe oficialmente?** | **IANA HTTP Status Code Registry** |
| Este RFC ainda vale? | `https://www.rfc-editor.org/info/rfcNNNN` — campo `Obsoleted by` |

### Os dois registros do IANA

São a resposta canônica para "isto existe?", e a maioria das pessoas nunca abriu nenhum dos dois.

- **[Hypertext Transfer Protocol (HTTP) Field Name Registry](https://www.iana.org/assignments/http-fields/http-fields.xhtml)** — lista todo nome de campo registrado com um `Status`: `permanent`, `provisional`, `deprecated`, `obsoleted`. É onde se descobre que `Accept-Charset` está **deprecated** e que `Content-MD5` foi **obsoleted**. Desde a RFC 9651 o registro ganhou também a coluna `Structured Type`.
- **[Hypertext Transfer Protocol (HTTP) Status Code Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)** — governado pela RFC 9110 § 16.2.1. Lista os códigos atribuídos **e as faixas não atribuídas** (`105-199`, `209-225`, `309-399`, `419-420`, `512-599`). É o argumento de uma linha contra `419`, `420` e `499`, que aparecem em frameworks e em CDN e **não existem** no registro.

Um header que não está no registro não é ilegal — o registro tem processo de extensão. Mas um header não registrado é campo privado da sua aplicação, e nomeá-lo como se fosse padrão (`Request-Id` em vez de `Acme-Request-Id`) é criar uma colisão futura com um nome que o IETF pode registrar.

---

## 5. O que o vault já cobre e o que não

Declaração explícita, para que ninguém reescreva o que já existe nem assuma cobertura que não há.

### Coberto em profundidade — **roteie, não reescreva**

| Território | Nota | Profundidade |
| --- | --- | --- |
| Cookies: `Domain`, `Path`, `Secure`, `HttpOnly`, `SameSite`, prefixos, limites, estado do 6265bis | [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) | completa, verificada, com a tabela de decisão app-em-host-distinto |
| Segurança de OAuth 2.0: PKCE, `redirect_uri`, mix-up, rotação de refresh token, ROPC | [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) | completa, com roteiro de leitura das seções 4.x |
| Validação de JWT: allowlist de `alg`, `iss`, `aud`, `kid`, `typ` | [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) | completa, com checklist |
| OAuth em SPA e padrão BFF | [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) | completa |
| Sessão e autorização como checklist auditável (ASVS) | [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) | completa |
| Cache **de cliente** em app React | [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) | completa — camada diferente do cache HTTP da RFC 9111 |

Nas notas de HTTP, `Authorization` e `WWW-Authenticate` entram como **mecanismo de protocolo** (RFC 9110 § 11: o servidor desafia, o cliente responde, `401` × `403`). Tudo que é **política** — qual grant, onde guardar o token, como rotacionar — pertence ao cluster acima e é referência, não conteúdo.

### Lacunas — ausência aqui significa "não coberto no vault", não "não importa"

| Lacuna | Onde estaria a fonte |
| --- | --- |
| **RFC 9457 / Problem Details** — nenhuma nota cobre o formato de erro padronizado | RFC 9457 |
| **RFC 9205 / BCP 56** — nenhuma nota cobre design de protocolo sobre HTTP | RFC 9205 |
| **HTTP/2 e HTTP/3** — nenhuma nota trata frames, streams, priorização ou QUIC | RFC 9113, 9114, 9204, 9218 |
| **HSTS** — citado de passagem, sem nota própria | RFC 6797 |
| **`Forwarded` e a cadeia de proxies** — sem nota | RFC 7239 |
| **WebSocket** — sem nota; o upgrade a partir de HTTP não está documentado | RFC 6455, Proposed Standard, dez/2011 |
| **Structured Field Values** — sem nota; muda como headers novos são parseados | RFC 9651 |
| **URL Standard (WHATWG)** × RFC 3986 — a divergência entre os dois não está registrada | url.spec.whatwg.org |

---

## 6. Regras — `HTTP-SPEC-*`

| ID | Regra |
| --- | --- |
| `HTTP-SPEC-01` | Afirmação normativa sobre o protocolo em ADR, comentário de PR ou doc **MUST** trazer número de RFC **e** número de seção (`RFC 9110 § 9.2.2`), não só o número do RFC. |
| `HTTP-SPEC-02` | Texto do projeto **NEVER** cita RFC 7230, 7231, 7232, 7233, 7234, 7235, 7538, 7540, 7807 ou 2818 como fonte vigente — os substitutos estão na § 2. |
| `HTTP-SPEC-03` | Afirmação com `MUST`/`MUST NOT`/`SHOULD` sobre HTTP **NEVER** tem link do MDN como única fonte; o RFC com seção **MUST** aparecer ao lado. |
| `HTTP-SPEC-04` | Regra de CORS, preflight, `fetch()` ou `Cross-Origin-Resource-Policy` **NEVER** é atribuída a um número de RFC — a fonte é o Fetch Standard (WHATWG). |
| `HTTP-SPEC-05` | Afirmação sobre `SameSite`, `__Host-` ou `__Secure-` **NEVER** cita RFC 6265; **MUST** citar `draft-ietf-httpbis-rfc6265bis` com a revisão. |
| `HTTP-SPEC-06` | Serviço nosso **NEVER** emite status code ausente do IANA HTTP Status Code Registry — `419`, `420` e `499` estão fora. |
| `HTTP-SPEC-07` | Header definido pelo projeto e ausente do IANA HTTP Field Name Registry **MUST** ter nome prefixado pelo produto (`Acme-Request-Id`) e constar do contrato da API. |
| `HTTP-SPEC-08` | Uma API **MUST** ter um único formato de corpo de erro declarado no contrato — `application/problem+json` (RFC 9457) ou formato próprio, nunca os dois. |
| `HTTP-SPEC-09` | Afirmação sobre semântica de método, status, header ou negociação que valha em HTTP/2 ou /3 **NEVER** é citada a partir da RFC 9112 — essa afirmação mora na RFC 9110. |
| `HTTP-SPEC-10` | Citação de spec WHATWG (Fetch, URL, HTML) **MUST** incluir a data de consulta — Living Standard não tem versão nem numeração de seção estável. |

**Total: 10 regras**, todas da família `HTTP-SPEC-*`.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Citar "RFC 7231" para semântica de método | documento de 2014, obsoletado pela RFC 9110 em junho de 2022; quem abrir o link vê o banner de obsoleto e desconta o argumento inteiro | RFC 9110 § 9 — `HTTP-SPEC-02` |
| Citar "o RFC de CORS" | não existe; CORS é o Fetch Standard da WHATWG, e nenhum número de RFC contém a regra que se quis citar | Fetch Standard § 3.3 — `HTTP-SPEC-04` |
| Justificar `SameSite=Lax` com a RFC 6265 | a 6265 é de abril de 2011 e não menciona `SameSite` em lugar nenhum | 6265bis, e [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) — `HTTP-SPEC-05` |
| Fechar decisão de protocolo com link do MDN | MDN descreve browsers, não define o protocolo; um implementador de proxy ou cache não está vinculado a ele | RFC com seção ao lado — `HTTP-SPEC-03` |
| Devolver `419` ou `499` | não estão no registro do IANA; ficam na faixa `419-420` (unassigned) e no `4xx` genérico; cliente e intermediário tratam como `400` opaco | status do registro — `HTTP-SPEC-06` |
| Inventar `X-Request-Id` sem namespace | o prefixo `X-` foi depreciado e o nome sem namespace colide com futuro registro do IANA | nome prefixado pelo produto — `HTTP-SPEC-07` |
| Misturar `problem+json` e formato próprio na mesma API | o cliente precisa de dois parsers de erro e adivinhar qual usar pelo endpoint | um formato declarado no contrato — `HTTP-SPEC-08` |
| Citar Fetch ou URL Standard sem data | Living Standard é editado no lugar; seis meses depois a seção mudou de número e a citação não reconstrói a decisão | URL + data de consulta — `HTTP-SPEC-10` |
| Tratar `stale-while-revalidate` como garantia de padrão | RFC 5861 é `Informational`, a categoria mais fraca; a diretiva é convenção implantada por CDNs, não requisito de standards track | usar, e documentar como dependência de CDN |

---

## Relacionados

- [HTTP](http.md) — hub
- [HTTP - Métodos e Semântica](http-metodos-e-semantica.md) · [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md) · [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) · [HTTP - CORS](http-cors.md) · [HTTP - Negociação de Conteúdo e Range](http-negociacao-de-conteudo-e-range.md)
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) · [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) · [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) · [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) · [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md)
- · · ·
- · ·
- · · ·
- · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [MDN — HTTP resources and specifications](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Resources_and_specifications)
- [RFC Editor](https://www.rfc-editor.org/) — páginas `info/` de: 9110, 9111, 9112, 9113, 9114, 9204, 9205, 9218, 9457, 9530, 9651, 8288, 8246, 7617, 7578, 7540, 7538, 7239, 7234, 7235, 7230, 7231, 6797, 6750, 6585, 6455, 6454, 6266, 6265, 5861, 5789, 3986
- [draft-ietf-httpbis-rfc6265bis (datatracker)](https://datatracker.ietf.org/doc/draft-ietf-httpbis-rfc6265bis/)
- [Fetch Standard — WHATWG](https://fetch.spec.whatwg.org/)
- [IANA — HTTP Field Name Registry](https://www.iana.org/assignments/http-fields/http-fields.xhtml)
- [IANA — HTTP Status Code Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)

### Notas de verificação

- **A RFC 9110 obsoletou a RFC 2818 (HTTP Over TLS)**, além da família 723x. Não estava no radar: a regra de verificação de identidade de servidor em `https` migrou para 9110 § 4.3.4, e 2818 é rotineiramente citada como se estivesse viva.
- **9110, 9111 e 9112 são `Internet Standard` com número STD (97, 98, 99); 9113 e 9114 são apenas `Proposed Standard`.** O hábito de tratar as cinco como "o novo HTTP" apaga uma diferença formal real de maturidade.
- **RFC 9112 obsoleta apenas *porções* da RFC 7230** — o resto da 7230 foi absorvido pela 9110. A 7230 é o único documento da família antiga com dois sucessores.
- **`PATCH` nunca esteve na spec de semântica.** Continua na RFC 5789 (mar/2010), fora do núcleo de 2022, e ela exige aplicação atômica do patch.
- **`stale-while-revalidate` e `stale-if-error` são `Informational` (RFC 5861), não standards track.** São convenção de mercado implantada por CDNs, não requisito do protocolo.
- **RFC 9651 (set/2024) obsoletou a RFC 8941** para Structured Field Values, acrescentando os tipos `Date` e `Display String`. Muita referência ainda aponta para 8941.
- **RFC 9457 (jul/2023) obsoletou a RFC 7807.** O `problem+json` que a maioria dos times conhece foi citado por número errado por seis anos de inércia.
- **O registro do IANA marca `Accept-Charset` como `deprecated`** e lista faixas inteiras de status como *unassigned* — `419-420` entre elas, o que derruba de uma vez os códigos que frameworks inventam.
- **A RFC 6265bis continua sem número de RFC em 2026-08-15**: revisão -22, de 2025-12-01, em `RFC Ed Queue`. Ou seja, `SameSite` e `__Host-`, implantados em todos os browsers há anos, ainda não têm RFC publicado. Consistente com [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md), verificada em 2026-08-12.
- **Não verificado:** o mês exato de publicação da RFC 9530 (confirmado apenas o ano, 2024). Status e escopo confirmados.
- **Não verificado:** status atual de RFC 7541 (HPACK) e RFC 7725 (status `451`) — listados pelo MDN, mas não confirmados individualmente no rfc-editor nesta sessão; ficaram fora da § 3.
- **Não verificado:** a página do MDN classifica "Content Security Policy Level 3" como obsoleta e cita "RFC 5689" para WebDAV. Nenhuma das duas afirmações foi confirmável nas fontes primárias nesta sessão, e por isso nenhuma entrou nas tabelas.
