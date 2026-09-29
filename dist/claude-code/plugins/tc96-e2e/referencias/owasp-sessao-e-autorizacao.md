---
titulo: OWASP - Sessão e Autorização
title: OWASP — Sessão e Autorização (Cheat Sheets + ASVS 5.0)
aliases: [OWASP Session Management, OWASP Authorization Cheat Sheet, ASVS V7]
tags: [owasp, asvs, security, session, authz, checklist, bondingai]
status: verificado
verificado-em: 2026-08-12
fonte: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
---

> [!tip] Como usar esta nota
> Os documentos do OWASP não ensinam o **porquê** — para isso servem as RFCs. Eles dão o
> **critério de revisão**: itens verificáveis, com ID estável, que cabem num comentário de PR.
> Cheat sheets leem-se em ~15 minutos cada; o ASVS não se lê, se consulta.

---

## 1. Session Management Cheat Sheet

Seções: propriedades do session ID · implementação · cookies · Web Storage · Web Workers · ciclo de vida · expiração · reautenticação em eventos de risco · defesas client-side · detecção de ataques · proteções em WAF.

**Session ID**

- Entropia mínima de **64 bits**, gerada por CSPRNG. Com hexadecimal, isso é ≥16 caracteres.
- Nome **não descritivo** — `id` em vez de `JSESSIONID`/`PHPSESSID`, que entregam a stack.
- Sem porção fixa ou previsível no valor.

**Cookies**

- `Secure` e `HttpOnly` sempre.
- `SameSite` explícito — `Strict` preferido, `Lax` aceitável. **Nunca confiar no default do browser.**
- Prefixo `__Host-` recomendado (implica `Secure`, sem `Domain`, `Path=/`).
- `Domain` omitido quando possível; `Path` restrito.
- Cookie de sessão **não persistente**; invalidação também no cliente, com `Expires` no passado.

**Ciclo de vida**

- **Regenerar o session ID em toda mudança de privilégio** — login, elevação, troca de organização. É a defesa contra session fixation.
- **Idle timeout** no servidor: 2–5 min em contexto de alto valor, 15–30 min em baixo risco.
- **Absolute timeout**: 4–8 h conforme o uso.
- Logout invalida **no servidor** pelo método do framework, além de limpar o cookie.

**Armazenamento**

- **Nunca `localStorage`/`sessionStorage`** para token, JWT ou credencial — a razão é XSS, e vale igualmente para access token.
- Preferir cookie `HttpOnly` ou o padrão **BFF**. Web Workers como alternativa quando o segredo precisa de isolamento sem compartilhamento entre abas.

**Detecção**

- Correlacionar sessão com IP, User-Agent ou certificado — com cuidado: IP muda em rede móvel, e a correlação vira falso positivo. Trate como sinal de anomalia, não como regra de bloqueio.
- Logar criação, uso e destruição de sessão, com o ID **hasheado** no log.

---

## 2. Authorization Cheat Sheet

Seções: least privilege · deny by default · validar permissão em toda request · revisar a lógica de autorização das ferramentas · **preferir ABAC/ReBAC a RBAC** · proteger IDs de lookup · autorização em recursos estáticos · checagem no lugar certo · falha segura · logging · testes.

- **Decisão server-side, sempre.** Lógica client-side é fácil de contornar — reflete permissão, não decide.
- **Deny by default**: negar salvo autorização explícita; ser capaz de justificar por que cada permissão foi concedida.
- **Least privilege** horizontal (entre tipos de recurso) e vertical (por nível hierárquico).
- **IDOR**: validar que o usuário pode acessar **aquele objeto**, não apenas que o objeto existe. Permissão sobre o tipo ≠ permissão sobre a instância.
- **Testes unitários e de integração da autorização** — o único mecanismo que detecta regressão silenciosa quando o catálogo de permissões muda.
- Logging consistente das decisões, para resposta a incidente e auditoria.

> [!note] Tensão a registrar
> O cheat sheet **recomenda ABAC/ReBAC sobre RBAC**: lógica booleana complexa, multi-tenancy
> e acesso cross-organizacional cabem mal em roles. É a mesma fronteira descrita em
> [WorkOS - RBAC](workos-rbac.md) §7. Não é razão para trocar de modelo agora — é razão para manter a
> divisão: RBAC para permissão **funcional**, lógica de aplicação para permissão **sobre
> instância**, sem misturar os dois mecanismos.

---

## 3. ASVS 5.0 — os capítulos relevantes

Estrutura: cada requisito tem ID estável (`7.2.3`) e nível (L1/L2/L3). Use o ID no PR — é inequívoco e sobrevive a reescrita de texto.

### V7 — Session Management

| Sub | Requisitos |
|---|---|
| **7.1 Documentação** | 7.1.1 (L2) documentar timeout de inatividade e vida máxima, com justificativa · 7.1.2 (L2) definir limite de sessões concorrentes e o comportamento ao atingi-lo · 7.1.3 (L2) documentar identidade federada e coordenação de sessão |
| **7.2 Fundamentos** | 7.2.1 (L1) validação do token de sessão por serviço backend confiável · 7.2.2 (L1) token gerado dinamicamente, self-contained ou por referência · 7.2.3 (L1) token por referência: único, CSPRNG, **≥128 bits** de entropia · 7.2.4 (L1) **novo token na autenticação**, encerrando o atual |
| **7.3 Timeout** | 7.3.1 (L2) timeout de inatividade conforme documentado · 7.3.2 (L2) vida máxima absoluta conforme a análise de risco |
| **7.4 Término** | 7.4.1 (L1) após terminar, o token não pode mais ser usado · 7.4.2 (L1) encerrar **todas** as sessões quando a conta é desabilitada/excluída · 7.4.3 (L2) permitir encerrar as demais sessões após mudança de autenticação · 7.4.4 (L2) logout visível nas páginas protegidas · 7.4.5 (L2) administrador pode encerrar sessões |
| **7.5 Abuso** | 7.5.1 (L2) reautenticação completa antes de alterar atributos sensíveis · 7.5.2 (L2) usuário vê e encerra sessões ativas · 7.5.3 (L3) autenticação adicional em transações de alto valor |
| **7.6 Federação** | 7.6.1 (L2) comportamento de sessão entre RP e IdP conforme documentado · 7.6.2 (L2) criação de sessão exige consentimento ou ação explícita do usuário |

Note que **7.1.x exige documentação como pré-requisito** — a análise de risco de sessão é ela própria um requisito, não só a implementação. Boa notícia para quem já vai escrever ADR.

### V3.3 — Cookies (dentro de *Web Frontend Security*)

| ID | Nível | Requisito |
|---|---|---|
| 3.3.1 | L1 | `Secure` setado; se não usar prefixo `__Host-`, usar `__Secure-` no nome |
| 3.3.2 | L2 | `SameSite` configurado adequadamente contra CSRF e UI redress |
| 3.3.3 | L2 | Prefixo `__Host-`, salvo cookie explicitamente projetado para compartilhamento entre hosts |
| 3.3.4 | L2 | Valores sensíveis (token de sessão): `HttpOnly`, e o valor só trafega via `Set-Cookie` |
| 3.3.5 | L3 | Nome + valor ≤ 4096 bytes |

### V9 — Self-contained Tokens (JWT)

| ID | Nível | Requisito |
|---|---|---|
| 9.1.1 | L1 | Validar assinatura/MAC **antes** de aceitar o conteúdo |
| 9.1.2 | L1 | Apenas algoritmos de um allowlist, por contexto |
| 9.1.3 | L1 | Material de chave vindo de fonte confiável pré-configurada |
| 9.2.1 | L1 | Se houver janela de validade, aceitar só dentro dela |
| 9.2.2 | L2 | Validar **tipo** e propósito do token antes de aceitar |
| 9.2.3 | L2 | Aceitar apenas tokens destinados a este serviço (**audience**) |
| 9.2.4 | L2 | Issuer que usa a mesma chave para públicos distintos: `aud` identificando unicamente o destino |

É a [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) em forma auditável.

---

## Uso como critério de PR

Itens que cabem direto num template de revisão de mudanças que tocam sessão ou autorização:

- [ ] Session ID regenerado na autenticação e em toda mudança de privilégio (7.2.4)
- [ ] Cookie com `Secure`, `HttpOnly`, `SameSite` explícito e prefixo (3.3.1–3.3.4)
- [ ] Logout invalida no servidor, não só no browser (7.4.1)
- [ ] Nenhum token em `localStorage`/`sessionStorage`
- [ ] Decisão de autorização no handler do servidor, não em componente ou rota do app
- [ ] Checagem **por instância** onde houver ID no path (IDOR)
- [ ] Deny by default: rota nova nasce protegida
- [ ] Teste automatizado cobrindo a negação, não só o caminho feliz
- [ ] `aud`/`iss`/`alg` validados onde há JWT (9.1.x, 9.2.x)

## Relacionados

- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) — o porquê dos atributos que o checklist exige
- [RFC 8725 - JWT Best Current Practices](rfc-8725-jwt-best-current-practices.md) — o porquê do V9
- [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) — o porquê de "nada em localStorage"
- [WorkOS - RBAC](workos-rbac.md) — as três camadas de enforcement
- [NIST RBAC - ANSI INCITS 359](nist-rbac-ansi-incits-359.md)
