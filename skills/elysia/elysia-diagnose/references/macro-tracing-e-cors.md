# Macro, tracing e CORS

| Regra | O que exige |
| --- | --- |
| `ELYSIA-LIFE-10` | macro sinaliza falha com `return status(...)` — **`throw` vira 500** e perde a inferência para Eden e OpenAPI |
| `ELYSIA-LIFE-11` | hook em app instrumentada com OpenTelemetry é **função nomeada** — arrow anônima produz span `anonymous` |
| `ELYSIA-LIFE-12` | `cors()` em API autenticada **nunca** fica com `origin` default (`*`) |

**`ELYSIA-LIFE-11` inutiliza o tracing sem quebrar nada:** todos os spans se chamam `anonymous`, e a instrumentação existe sem informar.

**`ELYSIA-LIFE-12` é o mesmo achado que `HTTP-CORS-02`** por outro caminho: `origin: '*'` com `credentials: true` é inválido, e o browser recusa. Ver [[http-diagnose]] § 2.2 — o default permissivo do plugin é a causa concreta mais comum no stack.

---


---

## As três falham sem quebrar nada

| Regra | O que se perde | Como o sintoma aparece |
| --- | --- | --- |
| `ELYSIA-LIFE-10` | inferência para Eden e OpenAPI | o `throw` dentro do macro vira **500**, e o status esperado some do tipo |
| `ELYSIA-LIFE-11` | o tracing inteiro | todos os spans se chamam `anonymous`; a instrumentação existe sem informar |
| `ELYSIA-LIFE-12` | a proteção de origem | `origin: '*'` com `credentials: true` é **inválido**, e o browser recusa |

`ELYSIA-LIFE-12` é o mesmo achado que `HTTP-CORS-02` por outro caminho — o default permissivo
do plugin é a causa concreta mais comum no stack. Ver [[http-diagnose]].

## Relacionados

- [[Elysia - Lifecycle e Plugins]] — a fonte
- [[http-diagnose]] — quando o sintoma é o browser bloqueando
