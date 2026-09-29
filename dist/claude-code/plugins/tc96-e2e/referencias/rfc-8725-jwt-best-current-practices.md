---
titulo: RFC 8725 - JWT Best Current Practices
title: RFC 8725 — JSON Web Token Best Current Practices
aliases: [RFC 8725, JWT BCP, BCP 225]
tags: [jwt, security, rfc, ietf, authn, bondingai]
status: verificado
verificado-em: 2026-08-12
fonte: https://www.rfc-editor.org/rfc/rfc8725.html
---

> [!info] Identificação
> **RFC 8725**, fevereiro de 2020 · **BCP 225** · Sheffer, Hardt, Jones.
> Curta e quase inteiramente acionável: §2 lista as vulnerabilidades, §3 lista as regras.

## Quando esta nota se aplica

Sempre que **a aplicação valida um JWT por conta própria** — verificação offline de access token via JWKS, tokens internos entre serviços, qualquer coisa em que o código chame `verify()`. Se o SDK do provedor de identidade faz a validação inteira e você só lê o resultado, o risco está no SDK; ainda assim vale conhecer as regras para saber **o que perguntar** à documentação dele.

O tema central: JWT é um formato, não um protocolo de segurança. Ele não diz para que serve nem para quem — quem decide é o validador. Quase todo ataque da §2 explora essa ambiguidade.

---

## §2 — as ameaças, em uma linha cada

| § | Ameaça |
|---|---|
| 2.1 | Assinatura fraca ou validação insuficiente (o clássico `alg: none` e a confusão RS256 → HS256) |
| 2.2 | Chave simétrica fraca (senha como chave de HMAC) |
| 2.3 | Composição incorreta de cifra e assinatura |
| 2.4 | Vazamento de plaintext pela análise do tamanho do ciphertext (compressão) |
| 2.5 | Uso inseguro de curva elíptica (pontos inválidos) |
| 2.6 | Multiplicidade de codificações JSON |
| 2.7 | **Ataques de substituição** — token válido usado onde não devia |
| 2.8 | **Cross-JWT confusion** — token de um tipo aceito como outro |
| 2.9 | Ataques indiretos ao servidor via conteúdo do token (`kid` → SQLi, LFI, SSRF) |

## §3 — as regras

| §    | Regra                                                                                                                     |
| ---- | ------------------------------------------------------------------------------------------------------------------------- |
| 3.1  | Bibliotecas **devem restringir os algoritmos a um allowlist** e conferir que o header `alg` bate com a operação realizada |
| 3.2  | Usar algoritmos criptograficamente atuais, adequados ao requisito                                                         |
| 3.3  | **Toda** operação criptográfica é validada; qualquer falha → rejeitar o JWT                                               |
| 3.4  | Validar entradas criptográficas antes do uso, em especial pontos de curva elíptica                                        |
| 3.5  | Chaves com entropia suficiente; senha **não** serve como chave de MAC                                                     |
| 3.6  | Evitar compressão antes de cifrar                                                                                         |
| 3.7  | UTF-8 exclusivamente para o JSON de header e claims                                                                       |
| 3.8  | **Verificar a identidade do issuer**; validar o `sub` contra os registros da aplicação                                    |
| 3.9  | **Incluir e validar `aud`** quando o JWT serve a mais de um relying party                                                 |
| 3.10 | **Sanitizar claims não confiáveis** como `kid` — é entrada de usuário até prova em contrário                              |
| 3.11 | Usar `typ` para tipagem explícita do JWT                                                                                  |
| 3.12 | Regras de validação mutuamente exclusivas para tipos distintos de JWT do mesmo issuer                                     |

---

## As três que mais falham na prática

**Allowlist de algoritmo (3.1).** Passar o `alg` do próprio token para a função de verificação é a vulnerabilidade original do JWT e continua aparecendo. A configuração correta é fixar o algoritmo esperado no código do validador, não lê-lo do token.

```ts
// ❌ o token escolhe como é verificado
jwt.verify(token, key);

// ✅ o validador escolhe
jwt.verify(token, key, { algorithms: ['RS256'], issuer: ISS, audience: AUD });
```

**`aud` (3.9) e `iss` (3.8).** Sem audience restriction, um token emitido para o serviço A é aceito pelo serviço B — o ataque de substituição da §2.7. Com um único issuer emitindo tokens para vários públicos, `aud` é o que separa. Nota complementar da [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) §2.3: audience restriction também é recomendação da BCP de OAuth, pelo mesmo motivo.

**`kid` (3.10).** É um valor controlado por quem monta o token e frequentemente vira índice de busca de chave — em arquivo, banco ou URL. Concatenar `kid` num path ou numa query é como concatenar qualquer input de usuário. Preferir: resolver `kid` contra um conjunto fechado de chaves conhecidas (JWKS cacheado), nunca contra o sistema de arquivos ou uma URL derivada do token.

---

## Checklist de validação

- [ ] Algoritmo fixado no validador, não lido do token
- [ ] `iss` conferido contra valor esperado
- [ ] `aud` presente e conferido
- [ ] `exp` (e `nbf`, se houver) conferidos; tolerância de clock skew definida e pequena
- [ ] `typ` verificado quando o issuer emite mais de um tipo de token
- [ ] `kid` resolvido contra JWKS conhecido, jamais interpolado em path/URL/SQL
- [ ] JWKS cacheado com rotação — e o cache não é fonte de DoS nem de aceitação de chave revogada
- [ ] Falha de validação → `401`, sem detalhar o motivo na resposta

> [!check] Aberto
> - [x] Claims do access token do WorkOS levantadas em [WorkOS - AuthKit](workos-authkit.md) §5 — **não há `aud` documentada**; a separação de público depende de `iss` + `client_id`
> - [ ] Confirmar com o suporte da WorkOS se `aud` existe e não está documentada
> - [ ] Se a validação for offline por JWKS (`https://api.workos.com/sso/jwks/{clientId}`): onde fica o cache, qual o TTL, o que acontece quando o JWKS muda

## Relacionados

- [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) — audience/scope restriction pelo lado do OAuth
- [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) — ASVS V9, "Self-contained Tokens", é a versão auditável destas regras
- [WorkOS - AuthKit](workos-authkit.md) · [WorkOS - RBAC](workos-rbac.md)
