# Exemplo trabalhado — o pedido criado aparece na lista

Tarefa: *"teste que o pedido criado aparece na lista"*.

---

## Passo 1 — as três perguntas

| Pergunta | Resposta |
| --- | --- |
| o que pode dar errado? | a listagem não reflete o pedido recém-criado |
| é jornada ou regra? | **jornada** — se fosse regra, iria para [[bun-test-build]] |
| o estado existe ou preciso criá-lo? | criar — e **por API** (`PW-NET-06`) |

A terceira é a que mais economiza tempo: doze cliques para chegar ao assunto do teste viram
um `POST`, e o teste passa a falhar por **um** motivo em vez de por qualquer defeito no
caminho.

## O teste

```ts
import { test, expect } from './fixtures';   // PW-FIX-05: nunca de '@playwright/test'

test('pedido criado aparece na lista imediatamente', async ({ page, request }) => {
  const r = await request.post('/pedidos', { data: { item: 'Café' } });
  await expect(r).toBeOK();
  const { id } = await r.json();

  await page.goto('/pedidos');                                   // relativo — PW-CFG-05

  await expect(
    page.getByRole('row').filter({ hasText: String(id) })        // PW-LOC-01 + filter, não .first()
  ).toBeVisible();                                               // web-first — PW-EXP-01
});
```

## O que as decisões evitaram

| Decisão | Alternativa ruim | Regra |
| --- | --- | --- |
| criar o pedido por `request` | 12 cliques no formulário de criação | `PW-NET-06` |
| `getByRole('row').filter(…)` | `page.locator('tr').nth(1)` | `PW-LOC-01`, `PW-LOC-02` |
| `await expect(...).toBeVisible()` | `expect(await ....isVisible()).toBe(true)` | `PW-EXP-01` |
| `page.goto('/pedidos')` | `page.goto('http://localhost:3000/pedidos')` | `PW-CFG-05` |
| título com o comportamento | `test('pedidos')` | `PW-STR-04` |
| `test`/`expect` de `./fixtures` | de `@playwright/test` | `PW-FIX-05` |

Nenhum `waitForTimeout`: a asserção web-first reespera por conta própria.

## Autoverificação

```
$ bash scripts/autoverificar.sh e2e/pedidos.spec.ts
 1. ✓ nenhum waitForTimeout
 ...
12. ✓ test/expect vêm do módulo do projeto
```

Depois, as três que valem mais: quebrar o código de propósito (a asserção **fica** vermelha),
`--repeat-each=5`, e a suíte inteira.
