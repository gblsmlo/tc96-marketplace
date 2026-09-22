# Locator e asserção — o par inseparável

> Passos 2 e 3. As árvores completas são a § 5.1 do hub [[Playwright]],
> [[Playwright - Locators]] e [[Playwright - Assertions]].

---

## Locator, na ordem de prioridade

1. `getByRole('papel', { name })` — o default, e o caminho certo na maioria dos casos (`PW-LOC-01`).
2. `getByLabel` / `getByPlaceholder` / `getByAltText` / `getByText` — por caso.
3. `getByTestId` — escape hatch, e **registre a dívida** (`PW-LOC-04`).
4. `locator('css=…')` — último recurso, com justificativa na linha acima.

**Resolveu para mais de um elemento?** A resposta **não** é `.first()` (`PW-LOC-02`). É, nesta
ordem: `filter({ hasText })`, encadear dentro de um container, `filter({ has: … })`.

**`getByRole` não alcança o elemento?** Na maioria dos casos o achado é sobre o
**componente**, não sobre o teste — falta papel ou nome acessível. Siga a ponte da § 8 do
hub em vez de descer para CSS.

**Gere o locator, não escreva de cabeça.** `npx playwright codegen <url>` ou o pick locator
do UI mode já prioriza papel, texto e test id — resolve `PW-LOC-01` sem exigir disciplina.
Mas **a saída do codegen não é o teste** (`PW-DBG-06`): extraia os locators e reescreva.

---

## Asserção

Uma regra domina todas: **afirme sobre a condição, nunca sobre um valor lido** (`PW-EXP-01`).

```ts
// ✗ congela um instante
expect(await page.getByText('Salvo').isVisible()).toBe(true);
// ✓ reespera
await expect(page.getByText('Salvo')).toBeVisible();
```

E o defeito gêmeo, que passa **sempre**: asserção web-first sem `await` (`PW-CORE-04`). A
única defesa automática é `@typescript-eslint/no-floating-promises` — confirme que está
ligada. Os dois **não** são o mesmo defeito e exigem correções diferentes (§ 6.2 do hub).

| Situação | Use |
| --- | --- |
| estado da UI | `expect(locator).…` |
| lista inteira | `toHaveText([...])` — verifica ordem e conteúdo com retry |
| resposta HTTP | `await expect(resposta).toBeOK()` |
| valor fora da UI que demora | `expect.poll(...)` |
| bloco com várias asserções que demora | `expect(fn).toPass({ timeout })` — **timeout obrigatório** (`PW-EXP-03`) |
| estrutura de UI | `toMatchAriaSnapshot` **antes** de `toHaveScreenshot` (`PW-SNAP-01`) |

**Nunca** afirme ausência sozinha: `not.toBeVisible()` passa também com locator errado.
Afirme o estado positivo esperado (`PW-EXP-06`).

---

## Relacionados

- [[Playwright - Locators]] · [[Playwright - Assertions]] — as duas fontes desta skill
- `ambiente-e-estrutura.md` — o que substituir, e como organizar
- `mapa-de-ids.md` — onde cada `PW-*` está declarado
