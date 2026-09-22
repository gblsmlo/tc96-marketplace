# Ambiente e estrutura

> Passos 4 e 5. As árvores são a § 5.4 do hub [[Playwright]].

---

## O que substituir

A pergunta que decide é uma:

> **Se a dependência real divergisse, este teste deveria quebrar?**
> Sim → não substitua. Não → substitua.

| Substituir | Como | Regra |
| --- | --- | --- |
| terceiro que não possuo | `page.route(…)` + `fulfill` | `PW-NET-01` |
| resposta real com um ajuste | `route.fetch()` + `fulfill({ response, json })` | — |
| API de browser | `page.addInitScript` **antes** do `goto` | `PW-NET-02` |
| relógio e aleatoriedade | `page.clock` | `PW-NET-07` |
| sessão | `storageState` por setup project | `PW-AUTH-01` |
| **nada disso: o estado do servidor** | crie de verdade via `request` | `PW-NET-06` |

Mock que reproduz o shape de uma resposta **deriva do tipo exportado pelo servidor**, nunca
redigitado à mão (`PW-NET-04`) — [[elysia-schema]], [[Hono - Validação e RPC]].

---

## Estrutura

| Precisa de… | Use | Regra |
| --- | --- | --- |
| sequência de ações numa tela | page object, locators `readonly` no construtor | `PW-STR-01` |
| setup com ciclo de vida, reusado entre arquivos | fixture, entregue por `await use(v)` | `PW-FIX-01`, `PW-FIX-03` |
| parâmetro da suíte | option fixture + `projects[].use` | `PW-FIX-04` |
| estado externo criado uma vez | setup project com `dependencies` | `PW-CFG-03` |
| login | setup project + `storageState` | `PW-AUTH-01` |

Três invariantes que geram retrabalho quando ignoradas:

- **Page object não contém asserção de regra de negócio** (`PW-STR-02`) — senão o teste do
  caminho negativo não consegue reusar o método.
- **Page object não devolve `Promise<string>`** — devolve `Locator`, senão empurra
  `PW-EXP-01` para todos os testes que o usam.
- **`test` e `expect` vêm de um módulo único do projeto** (`PW-FIX-05`) — importar o base e
  o derivado no mesmo arquivo faz as fixtures desaparecerem **sem erro de compilação**.
  Reexporte os dois de `fixtures.ts`.

Teste com mais de um passo de negócio recebe `test.step` (`PW-DBG-03`) — é o que transforma
"falhou na ação 19" em "falhou ao finalizar".

---

## Relacionados

- [[Playwright - Rede e Mocking]] · [[Playwright - Autenticação e Isolamento]] · [[Playwright - Fixtures]] · [[Playwright - Estrutura de Testes]]
- `autoverificacao.md` — o que conferir depois de escrever
