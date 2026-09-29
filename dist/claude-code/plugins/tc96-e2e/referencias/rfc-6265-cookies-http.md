---
titulo: RFC 6265 - Cookies HTTP
title: RFC 6265 — Cookies HTTP (e o 6265bis, onde mora o SameSite)
aliases: [RFC 6265, RFC 6265bis, Cookies HTTP, SameSite]
tags: [http, cookies, security, rfc, ietf, frontend, bondingai]
status: verificado
verificado-em: 2026-08-12
fonte: https://www.rfc-editor.org/rfc/rfc6265.html
---

> [!warning] O documento que você quer não é o 6265
> **RFC 6265** (abril/2011, Adam Barth, obsoleta a RFC 2965) define `Domain`, `Path`,
> `Secure` e `HttpOnly` — e **não menciona `SameSite` em lugar nenhum**. É anterior ao
> atributo por vários anos.
>
> `SameSite`, os prefixos `__Host-`/`__Secure-` e o limite de 400 dias estão em
> **draft-ietf-httpbis-rfc6265bis**, que **obsoleta a 6265**. Em **2026-08-12**: revisão
> **-22**, de **2025-12-01**, estado **RFC Ed Queue / In Progress**.
>
> Prática: leia o **6265bis** e trate a 6265 como histórico. Ele consolida os documentos
> separados de same-site cookies, cookie prefixes e secure cookies.

## Por que ler antes de tentar acertar por tentativa

Cookie não obedece à same-origin policy. Quase todo bug de sessão em ambiente multi-host vem de assumir que obedece. Os três fatos que mudam o modelo mental:

1. **Cookies não são isolados por porta.** Cookies de um host são compartilhados entre todas as portas dele, mesmo que a same-origin policy separe o conteúdo servido em portas diferentes.
2. **Cookies têm integridade fraca.** Não há verificação de integridade embutida; o servidor não consegue saber se um cookie foi modificado. `Secure` protege confidencialidade, **não** integridade diante de um atacante de rede ativo — que pode *escrever* cookies mesmo sem ler os existentes.
3. **`Path` não é fronteira de segurança.** A própria 6265 diz isso: limita o envio em HTTP normal, mas não protege contra acesso via APIs não-HTTP (XSS lê `document.cookie` inteiro).

---

## `Domain` — a fonte do mal-entendido

| Situação | Efeito |
|---|---|
| `Domain` **omitido** | **host-only**: o cookie volta só para o host que o emitiu. É o default e é o mais restritivo. |
| `Domain=site.example` | vale para `site.example`, `www.site.example` **e** `www.corp.site.example` — sufixo, não igualdade |
| `Domain=.site.example` | o ponto inicial é **ignorado** (removido no processamento); idêntico ao caso acima |

Consequências:

- **`Domain` só alarga, nunca restringe.** Não existe forma de dizer "só este subdomínio, e não os outros" além de omitir o atributo.
- Definir `Domain` num cookie de sessão significa entregá-lo a **todo subdomínio**, presente e futuro — incluindo aquele host de staging ou de landing page que alguém sobe depois. Por isso o `SHOULD NOT set Domain` do [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md).
- Um host pode setar cookie para **si mesmo ou para qualquer domínio ancestral** que não seja public suffix. Não pode setar para domínio irmão. Logo, `evil.site.example` consegue gravar cookie em `Domain=site.example` e afetar `app.site.example` — subdomínio hostil é ameaça real, e é contra isso que serve o `__Host-`.

---

## `SameSite` (6265bis)

| Valor | Comportamento |
|---|---|
| `Strict` | nunca vai em request cross-site — inclusive em navegação de topo vinda de outro site |
| `Lax` | vai em navegação de topo com método seguro (link, `GET`); não vai em `POST` cross-site nem em sub-recursos |
| `None` | vai sempre — e **exige `Secure`**: sem ele o cookie é ignorado por completo |

Detalhes que importam:

- **Ausente ≠ `Lax` pela especificação.** Quando o atributo não está presente, a flag interna fica em `"Default"` e o user agent **pode** aplicar a política `Lax-allowing-unsafe`. Valor desconhecido, por outro lado, cai em enforcement equivalente a `Lax`. Ou seja: o comportamento sem atributo é decisão do browser, varia entre eles e muda com o tempo — **sempre defina explicitamente**.
- `Strict` num cookie de sessão quebra o retorno de fluxos de redirect (voltar do Authorization Server é navegação cross-site). Padrão usual: `Lax` para o cookie de sessão, ou `Strict` com um cookie de transição no callback.
- `SameSite` é defesa **em profundidade** contra CSRF, não substituto de token/header anti-CSRF. É política de browser, não do seu servidor.

## Prefixos de nome (6265bis)

| Prefixo | Exige |
|---|---|
| `__Secure-` | atributo `Secure` |
| `__Host-` | `Secure` + `Path=/` + **sem `Domain`** (host-only) |

O `__Host-` é a coisa mais próxima que um cookie chega de tratar a origem como fronteira de segurança. O ganho real: um subdomínio comprometido não consegue **sobrescrever** o cookie do host principal — mitiga cookie tossing/fixation, que os outros atributos não cobrem.

Servidores devem escrever o prefixo com case exato; user agents comparam sem diferenciar maiúsculas.

## Limites

- **4096 octetos** para nome + valor somados. Sessão selada cifrada ([WorkOS - AuthKit](workos-authkit.md) §3) está perto desse teto — vale medir, não estimar. Cookie que estoura o limite é descartado silenciosamente.
- Suporte mínimo esperado: 50 cookies por domínio, 3000 no total.
- **Expiração máxima de 400 dias**: `Expires`/`Max-Age` maiores **devem** ser reduzidos ao limite.

---

## Decisão prática para app + API em hosts distintos

```
app.exemplo.com  ←→  api.exemplo.com
```

| Opção | Cookie | Custo |
|---|---|---|
| Mesmo host (proxy do BFF sob `/api`) | `__Host-`, `SameSite=Lax`, sem `Domain` | exige o proxy; **é a opção recomendada pelo draft de browser-based apps** |
| Domínio-pai | `Domain=exemplo.com`, `SameSite=Lax` | cookie exposto a todo subdomínio; incompatível com `__Host-` |
| Hosts sem parentesco | `SameSite=None; Secure` + CORS `credentials` | perde a defesa de CSRF do browser; depende de bloqueio de third-party cookies do navegador |

A terceira linha é a que envelhece pior: browsers vêm restringindo cookies de terceiros, e uma arquitetura que depende deles está apostando contra a direção da plataforma.

> [!check] Aberto
> - [ ] Medir o tamanho real do cookie de sessão selada contra os 4096 octetos
> - [ ] Confirmar hosts de app e API por ambiente — decide qual linha da tabela acima se aplica
> - [ ] `__Host-` é compatível com o nome de cookie que o SDK usa? (o SDK controla o nome?)

## Relacionados

- [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) — requisitos de cookie do BFF
- [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) — os mesmos atributos como item de checklist
- [WorkOS - AuthKit](workos-authkit.md)
