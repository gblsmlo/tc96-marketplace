---
titulo: RFC 9700 - OAuth 2.0 Security BCP
title: RFC 9700 — OAuth 2.0 Security Best Current Practice
aliases: [RFC 9700, OAuth Security BCP, BCP 240]
tags: [oauth, security, rfc, ietf, authn, bondingai]
status: verificado
verificado-em: 2026-08-12
fonte: https://www.rfc-editor.org/rfc/rfc9700.html
---

> [!info] Identificação
> **RFC 9700**, janeiro de 2025 · **BCP 240** · Lodderstedt, Bradley, Labunets, Fett.
> **Atualiza** RFC 6749 (OAuth 2.0), RFC 6750 (Bearer) e RFC 6819 (Threat Model).
> **Não obsoleta** nenhuma delas — as RFCs originais continuam válidas, mas a leitura
> normativa de qualquer decisão de segurança passa por aqui.

## Por que este documento primeiro

É o único texto que consolida, num só lugar, o que mudou no OAuth entre 2012 e hoje. Cada seção 4.x descreve um ataque concreto e a mitigação correspondente; a seção 2 é a versão condensada em regras. Densidade prática alta: a §2 sozinha resolve a maioria das dúvidas de configuração de um Authorization Server.

Ordem de leitura recomendada: **§2 inteira** → **§3** (modelo de atacante) → seções 4.x conforme a dúvida aparecer. A §4 é referência, não leitura linear.

---

## Estrutura

| Seção | Conteúdo |
|---|---|
| 1 | Introdução, estrutura, terminologia |
| **2** | **Best Practices** — o núcleo normativo |
| 3 | Modelo de atacante atualizado |
| 4 | 17 ataques, cada um com mitigação (4.1 a 4.17) |
| 5–7 | IANA, considerações de segurança, referências |

---

## §2 — o que passou a valer

**Fluxos baseados em redirect (§2.1)**

- Validação de `redirect_uri` por **comparação exata de string** no Authorization Server. Matching por prefixo ou wildcard está fora. Exceção: portas de loopback em aplicações nativas.
- **Open redirectors proibidos** — tanto no cliente quanto no AS. É o vetor que transforma um redirect mal validado em exfiltração de credencial.
- **Defesa de CSRF obrigatória** no cliente: `state`, PKCE ou `nonce` do OIDC. Uma das três, explicitamente.
- **Mix-up defense** quando o cliente fala com mais de um AS: identificação do issuer na resposta ou `redirect_uri` distinta por AS.

**Authorization Code (§2.1.1)**

- Clientes públicos **MUST** usar PKCE. Clientes confidenciais **SHOULD**.
- Método de challenge `S256`. O `plain` expõe o verifier.

**Implicit (§2.1.2)**

- Depreciado. Response types que emitem access token no authorization endpoint carregam risco de vazamento e replay sem mitigação disponível. Use Authorization Code.

**Replay de token (§2.2)**

- Access tokens **sender-constrained** — mTLS ou DPoP — como direção recomendada.
- Refresh tokens de clientes públicos: **rotação** ou sender-constraining. Uma das duas.

**Privilégio (§2.3)**

- Escopo mínimo e **audience restriction** por resource server. Token que serve para tudo é token que vale roubar.

**Outros (§2.4–2.6)**

- **ROPC (password grant) proibido.** Conflita com autenticação moderna e expõe credencial ao cliente.
- Autenticação de cliente: métodos assimétricos preferidos (mTLS, Private Key JWT) sobre `client_secret`.
- Publicar **AS Metadata** — reduz configuração manual, que é onde o erro mora.
- HTTPS nas respostas de autorização; `http` só em loopback de app nativo.
- Comunicação in-browser (`postMessage`): verificar origin do **iniciador e do receptor**.

---

## Seções 4.x que valem leitura dirigida

| Se a dúvida é… | Leia |
|---|---|
| "posso aceitar `redirect_uri` com wildcard?" | 4.1 |
| "o `code` vaza pelo `Referer`/histórico?" | 4.2, 4.3 |
| "por que preciso identificar o issuer?" | 4.4 (mix-up) |
| "PKCE me protege de quê exatamente?" | 4.5 (code injection), 4.8 (downgrade) |
| "o `state` ainda é necessário se uso PKCE?" | 4.7 |
| "estamos atrás de um proxy TLS-terminating" | 4.13 |
| "rotação de refresh token: como detectar reuso?" | 4.14 |
| "podemos abrir o app em iframe?" | 4.16 |

---

## Aplicação ao projeto

- O AS é o WorkOS ([WorkOS - AuthKit](workos-authkit.md)) — a maior parte da §2 é responsabilidade dele, não nossa. **O que sobra para o cliente**: `redirect_uri` exata cadastrada por ambiente, defesa de CSRF, tratamento de reuso de refresh token e não expor open redirect no `returnTo`.
- O `returnTo` carregado dentro do `state` é exatamente o ponto onde um open redirector nasce por descuido. Validar contra allowlist de rotas internas, nunca ecoar URL absoluta recebida do cliente.
- Rotação de refresh token com detecção de reuso já é o comportamento do WorkOS; a §4.14 explica **por que** o reuso deve derrubar a família inteira de tokens, e não só falhar a request.

> [!check] Aberto
> - [ ] Confirmar se o WorkOS suporta DPoP / sender-constrained tokens (§2.2) — define se o hardening extra está disponível ou fora de alcance.
> - [ ] Verificar se o AS publica metadata e se consumimos dela em vez de hardcode de endpoints.

## Relacionados

- [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) — aplica esta BCP ao caso específico de SPA
- [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) — quando o access token é JWT verificado por nós
- [WorkOS - AuthKit](workos-authkit.md) · [WorkOS - RBAC](workos-rbac.md)
