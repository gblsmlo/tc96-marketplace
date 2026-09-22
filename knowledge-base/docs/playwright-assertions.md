---
titulo: Playwright - Assertions
Link: https://playwright.dev/docs/test-assertions
tags:
 - playwright
 - testing
 - assertions
 - agent-context
source: "Documentação oficial do Playwright — Assertions, TestConfig.expect"
verificado-em: 2026-08-20
---

# Playwright — Assertions

> Satélite de [Playwright](playwright.md). Cobre como um teste **afirma**. A distinção entre asserção que reespera e asserção que congela o tempo é a única que importa aqui, e ela decide se a suíte é confiável.

---

## 1. As duas famílias

| Família | Sobre o quê | Reespera? | Precisa de `await`? |
| --- | --- | --- | --- |
| **web-first** | `Locator`, `Page`, `APIResponse` | **sim** | **sim** |
| **genérica** | valores comuns (número, string, objeto) | não | não |

```ts
// web-first: afirma sobre a CONDIÇÃO, e reespera até 5 s
await expect(page.getByText('Bem-vindo')).toBeVisible;

// genérica: afirma sobre o VALOR agora
expect(total).toBe(3);
```

**A confusão que causa mais flake** é aplicar a segunda forma a um alvo da primeira:

```ts
// ✗ lê um booleano de um instante e afirma sobre esse instante
expect(await page.getByText('Bem-vindo').isVisible).toBe(true);

// ✓ afirma sobre a condição
await expect(page.getByText('Bem-vindo')).toBeVisible;
```

As duas linhas parecem equivalentes. A primeira falha se o elemento aparecer 40 ms depois; a segunda espera. Nenhum linter pega isso, porque as duas são código válido (`PW-EXP-01`).

**O caso oposto, igualmente silencioso:** asserção web-first **sem** `await`.

```ts
// ✗ cria uma Promise e a joga fora — não afirma nada, passa sempre
expect(page.getByText('Erro')).toBeVisible;
```

Isso não é o mesmo defeito. Aqui o teste não verifica coisa alguma, e passa mesmo com o produto quebrado (`PW-CORE-04`). É a razão de a fonte recomendar a regra `@typescript-eslint/no-floating-promises` — é o único mecanismo automático que pega este caso.

---

## 2. Asserções web-first

### 2.1 Sobre `Locator`

```ts
await expect(locator).toBeVisible;
await expect(locator).toBeHidden;
await expect(locator).toBeAttached;
await expect(locator).toBeEnabled;
await expect(locator).toBeDisabled;
await expect(locator).toBeEditable;
await expect(locator).toBeChecked;
await expect(locator).toBeFocused;
await expect(locator).toBeEmpty;
await expect(locator).toBeInViewport;

await expect(locator).toHaveText('exato');
await expect(locator).toContainText('parte');
await expect(locator).toHaveValue('abc');
await expect(locator).toHaveValues(['a', 'b']);
await expect(locator).toHaveCount(3);
await expect(locator).toHaveAttribute('href', '/docs');
await expect(locator).toHaveClass(/ativo/);
await expect(locator).toContainClass('ativo');
await expect(locator).toHaveCSS('display', 'flex');
await expect(locator).toHaveId('total');
await expect(locator).toHaveJSProperty('checked', true);
await expect(locator).toHaveRole('button');
await expect(locator).toHaveAccessibleName('Fechar');
await expect(locator).toHaveAccessibleDescription('Fecha sem salvar');

await expect(locator).toHaveScreenshot;
await expect(locator).toMatchAriaSnapshot(`- button "Salvar"`);
```

### 2.2 Sobre `Page` e `APIResponse`

```ts
await expect(page).toHaveTitle(/Painel/);
await expect(page).toHaveURL('/dashboard');
await expect(page).toHaveScreenshot;
await expect(page).toMatchAriaSnapshot(`- heading "Painel" [level=1]`);

await expect(resposta).toBeOK;
```

`toHaveURL` respeita `baseURL`, então caminho relativo funciona — ver [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) § 2.

### 2.3 `toHaveText` × `toContainText`

`toHaveText` é **exato** (com espaço normalizado); `toContainText` é substring. Sobre uma lista, os dois aceitam array e verificam **ordem**:

```ts
await expect(page.getByRole('listitem')).toHaveText(['maçã', 'banana', 'laranja']);
```

Isso substitui a maior parte dos laços sobre locators — com retry, o que o laço não tem ([Playwright - Locators](playwright-locators.md) § 4).

---

## 3. Negação

```ts
await expect(locator).not.toBeVisible;
expect(valor).not.toEqual(0);
```

**Semântica que importa:** `not.toBeVisible` reespera até o elemento **deixar** de estar visível (ou o timeout estourar). Não é "verifique agora que não está visível" — é a asserção certa para "o spinner desaparece".

Mas cuidado com o falso positivo: `not.toBeVisible` passa também quando o elemento nunca existiu, inclusive por locator errado. Para "o erro não aparece", o teste ganha muito mais afirmando o **estado positivo** esperado (`toBeVisible` no conteúdo de sucesso) do que a ausência do negativo.

---

## 4. Timeout

| Onde | Como | Efeito |
| --- | --- | --- |
| default | — | **5 000 ms** |
| global | `expect: { timeout }` no config | toda asserção da suíte |
| por asserção | `toBeVisible({ timeout: 30_000 })` | só ali |
| instância | `expect.configure({ timeout })` | um `expect` alternativo |

```ts
const expectLento = expect.configure({ timeout: 15_000 });
await expectLento(page.getByText('Relatório pronto')).toBeVisible;
```

**O critério:** afrouxar `expect.timeout` global é a medida de menor precisão possível — ela deixa **toda** a suíte mais lenta para falhar e esconde regressão de performance. Um alvo que legitimamente demora recebe `timeout` na própria asserção (`PW-EXP-04`). E antes de qualquer um dos dois, vale a § 5.5 do hub: quase sempre o problema não é o timeout.

---

## 5. Soft assertions

Uma soft assertion falha o teste, mas **não interrompe** a execução:

```ts
await expect.soft(page.getByTestId('status')).toHaveText('Sucesso');
await page.getByRole('link', { name: 'próxima página' }).click;
```

Serve para colher várias falhas de uma vez numa página de resultado. Não serve quando a falha invalida o passo seguinte — aí o teste segue interagindo com uma tela que não está no estado esperado e produz uma cascata de erros que esconde a causa (`PW-EXP-02`).

Para abortar depois de um bloco de soft:

```ts
expect(test.info.errors).toHaveLength(0);
```

Mensagem customizada funciona nas duas formas:

```ts
await expect(page.getByText('Nome'), 'deveria estar logado').toBeVisible;
expect.soft(valor, 'total do carrinho').toBe(56);
```

---

## 6. `expect.poll` e `toPass`

Para o que **não** é locator mas ainda precisa de retry.

### 6.1 `expect.poll`

Transforma uma leitura assíncrona em asserção com retry:

```ts
await expect.poll(async => {
 const r = await page.request.get('/api/pedidos/42');
 return r.status;
}, {
 message: 'o pedido deve ficar disponível',
 timeout: 10_000,
 intervals: [1_000, 2_000, 10_000],
}).toBe(200);
```

### 6.2 `toPass`

Reexecuta um bloco inteiro até ele passar:

```ts
await expect(async => {
 const r = await page.request.get('/api/pedidos/42');
 expect(r.status).toBe(200);
}).toPass({ intervals: [1_000, 2_000, 10_000], timeout: 60_000 });
```

> **A pegadinha, e é séria:** o timeout default de `toPass` é **`0`**, e ele **não** respeita o `expect.timeout` configurado. Sem `timeout` explícito, um bloco que nunca passa fica retentando até o teste estourar em 30 s — e a mensagem de erro é o timeout do teste, não a asserção interna. Passar `timeout` é obrigatório (`PW-EXP-03`).

**Qual usar:** `poll` quando há um valor a ler e uma condição sobre ele; `toPass` quando o próprio bloco tem várias asserções ou efeitos. Nenhum dos dois para UI — para UI a asserção web-first já reespera, e usar `poll` ali é reimplementar o que a ferramenta faz melhor.

---

## 7. Matchers customizados

```ts
// fixtures.ts
import { expect as baseExpect } from '@playwright/test';
import type { Locator } from '@playwright/test';

export const expect = baseExpect.extend({
 async toHaveTotal(locator: Locator, esperado: number, options?: { timeout?: number }) {
 const nome = 'toHaveTotal';
 let recebido: number | undefined;
 try {
 await baseExpect(locator)
.toHaveAttribute('data-total', String(esperado), options);
 return { name: nome, pass: true, message: => '' };
 } catch {
 recebido = Number(await locator.getAttribute('data-total'));
 return {
 name: nome,
 pass: false,
 expected: esperado,
 actual: recebido,
 message: => `esperava total ${esperado}, recebeu ${recebido}`,
 };
 }
 },
});
```

Um matcher customizado **deve delegar a uma asserção web-first** por dentro — é o que lhe dá retry. Um matcher que faz `await locator.getAttribute` e compara não reespera, e reintroduz o defeito de `PW-EXP-01` num lugar onde ninguém vai olhar.

Combinar de módulos diferentes:

```ts
import { mergeExpects } from '@playwright/test';
export const expect = mergeExpects(dbExpect, a11yExpect);
```

Este `expect` estendido **substitui** o import base no arquivo, pelo mesmo motivo de `PW-FIX-05` ([Playwright - Fixtures](playwright-fixtures.md) § 6).

---

## 8. Matchers assimétricos

Para casar parcialmente dentro de outra asserção — úteis sobre payload de API:

```ts
expect(corpo).toEqual(expect.objectContaining({
 id: expect.any(Number),
 titulo: expect.stringContaining('Bug'),
 tags: expect.arrayContaining(['aberto']),
}));
```

Disponíveis: `expect.any`, `expect.anything`, `expect.arrayContaining`, `expect.arrayOf`, `expect.closeTo`, `expect.objectContaining`, `expect.stringContaining`, `expect.stringMatching`.

Isso é o que evita que um teste de API quebre por causa de um `id` ou `createdAt` que muda a cada execução — sem recorrer a snapshot, que seria diff ruidoso ([Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 4).

---

## 9. Regras — `PW-EXP-01` a `PW-EXP-06`

| ID | Regra |
| --- | --- |
| `PW-EXP-01` | Afirmação sobre a UI **MUST** usar asserção web-first (`expect(locator).…`). `expect(await locator.isVisible)` e formas equivalentes **NEVER**. |
| `PW-EXP-02` | `expect.soft` **MUST** ser usado só quando a falha não invalida os passos seguintes. † |
| `PW-EXP-03` | `expect(fn).toPass` **MUST** receber `timeout` explícito — o default é `0` e ele **não** herda `expect.timeout`. |
| `PW-EXP-04` | Alvo que legitimamente demora **MUST** receber `timeout` na própria asserção. Afrouxar `expect.timeout` global **NEVER** como resposta a uma asserção lenta. † |
| `PW-EXP-05` | Matcher customizado **MUST** delegar internamente a uma asserção web-first, para preservar o retry. † |
| `PW-EXP-06` | Ausência **MUST** ser afirmada junto do estado positivo esperado. `not.toBeVisible` sozinho **NEVER** é evidência suficiente — ele passa também com locator errado. † |

---

## 10. Antipadrões

### 10.1 Ler para afirmar

```ts
// ✗
const texto = await page.getByTestId('total').textContent;
expect(texto).toBe('R$ 42,00');
// ✓
await expect(page.getByTestId('total')).toHaveText('R$ 42,00');
```

O caso mais comum de todos, e o mais fácil de gerar por hábito de outros frameworks (`PW-EXP-01`).

### 10.2 Asserção web-first sem `await`

```ts
// ✗ passa sempre
expect(page.getByText('Erro')).toBeVisible;
```

Não afirma nada (`PW-CORE-04`). Um teste inteiro assim fica verde com a aplicação fora do ar.

### 10.3 `waitForTimeout` antes da asserção

```ts
// ✗
await page.waitForTimeout(2000);
await expect(page.getByText('Salvo')).toBeVisible;
```

A asserção já reespera 5 s. A linha de cima só torna o teste 2 s mais lento — em toda execução, incluindo as que passariam em 80 ms (`PW-CORE-05`).

### 10.4 `toPass` sem timeout

```ts
// ✗ trava até o teste estourar, e a mensagem culpa o teste
await expect(async => { /* … */ }).toPass;
```

Ver § 6.2 (`PW-EXP-03`).

### 10.5 Soft assertion em pré-condição

```ts
// ✗
await expect.soft(page.getByRole('dialog')).toBeVisible;
await page.getByRole('dialog').getByRole('button', { name: 'Confirmar' }).click;
```

Se o diálogo não abriu, o clique falha de qualquer forma — e agora com dois erros no relatório em vez de um, sendo que o segundo é consequência do primeiro (`PW-EXP-02`).

### 10.6 Snapshot para verificar uma condição

```ts
// ✗
await expect(page).toMatchAriaSnapshot(/* 80 linhas */); // só para checar um botão
// ✓
await expect(page.getByRole('button', { name: 'Salvar' })).toBeEnabled;
```

Snapshot para condição única produz diff enorme com informação de menos, e passa a falhar por mudanças que não têm relação com o que o teste queria verificar.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.5 decide qual timeout mexer
- [Playwright - Locators](playwright-locators.md) — o par inseparável
- [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) — `toHaveScreenshot` e `toMatchAriaSnapshot` em detalhe
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — `toBeOK` e asserção sobre payload
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — como a asserção falhada aparece no trace
- `TypeScript` — `no-floating-promises` é o que pega a asserção sem `await`
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o mesmo princípio de `await` em `play`

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Assertions](https://playwright.dev/docs/test-assertions) — as listas completas, soft, poll, toPass, extend
- [Timeouts](https://playwright.dev/docs/test-timeouts) — o default de 5 s do `expect`
- [TestConfig (API)](https://playwright.dev/docs/api/class-testconfig) — `expect` no config
- [Best Practices](https://playwright.dev/docs/best-practices) — web-first assertions e `no-floating-promises`
