---
titulo: Playwright - Estrutura de Testes
Link: https://playwright.dev/docs/pom
tags:
  - playwright
  - testing
  - architecture
  - page-object
  - agent-context
source: "Documentação oficial do Playwright — Page object models, Best Practices, Annotations, Parameterize tests"
verificado-em: 2026-08-20
---

# Playwright — Estrutura de Testes

> Satélite de [Playwright](playwright.md). Cobre a organização da suíte: o que é um teste, o que é um page object, onde a asserção mora, como parametrizar, e o que um bom título comunica. É o satélite menos "API" e o mais decisivo depois do trigésimo teste.
>
> **A fronteira desta nota.** Ela não decide *o que* testar — isso é [Teste de Software](teste-de-software.md) e. Ela decide, dado que um teste vai existir, como escrevê-lo para que ele continue legível e barato de manter.

---

## 1. O que um teste é

Um teste E2E é **uma jornada de usuário com uma afirmação**. Três consequências:

**1. Um teste, um motivo de falha.** Um teste que cria cliente, cria pedido, aplica desconto e emite nota falha por quatro motivos, e a mensagem não diz qual. Cada um desses passos que não é o assunto do teste deveria ser preparado por API ([Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 5.1).

**2. O teste é independente.** Nada de ordem, nada de estado herdado. É o que o isolamento por contexto entrega de graça e o que `mode: 'serial'` abre mão de propósito (`PW-CORE-06`).

**3. O teste observa o usuário.** É o princípio de e no Playwright ele se manifesta em duas escolhas concretas: locator por papel (`PW-LOC-01`) e asserção sobre o que a tela mostra (`PW-EXP-01`).

E o corolário econômico, da página de boas práticas: **E2E é a camada mais cara**. Cada regra de negócio verificada aqui é uma regra verificada devagar, num lugar frágil. A suíte E2E cobre *jornada crítica*; a regra vai para teste unitário ou de integração —.

---

## 2. Page object

A fonte apresenta o padrão com duas justificativas: *"simplificar a autoria criando uma API de nível mais alto"* e *"simplificar a manutenção capturando os seletores em um lugar"*.

```ts
// e2e/pages/pedidos.ts
import type { Locator, Page } from '@playwright/test';

export class PaginaPedidos {
  readonly page: Page;
  readonly lista: Locator;
  readonly botaoNovo: Locator;
  readonly campoBusca: Locator;

  constructor(page: Page) {
    this.page = page;
    this.lista = page.getByRole('list', { name: 'Pedidos' });
    this.botaoNovo = page.getByRole('button', { name: 'Novo pedido' });
    this.campoBusca = page.getByRole('searchbox', { name: 'Buscar pedidos' });
  }

  async abrir() {
    await this.page.goto('/pedidos');
  }

  async buscar(termo: string) {
    await this.campoBusca.fill(termo);
    await this.campoBusca.press('Enter');
  }

  linha(referencia: string): Locator {
    return this.lista.getByRole('listitem').filter({ hasText: referencia });
  }
}
```

Quatro decisões nesse código:

- **Locators no construtor, como `readonly`.** É correto porque locator é consulta preguiçosa e não envelhece ([Playwright - Locators](playwright-locators.md) § 1). Um método `get botaoNovo()` que reconstrói a cada chamada funciona, mas espalha a definição do seletor por várias linhas de uso (`PW-STR-01`).
- **`linha(ref)` é método porque é paramétrico.** Locator que depende de argumento não pode ser propriedade — e devolver `Locator` (não `Promise<void>`) mantém o poder de composição no teste.
- **`abrir()` é ação, não asserção.**
- **Nenhum `expect` na classe.**

### 2.1 A asserção é do teste

```ts
// ✓
test('busca filtra a lista', async ({ page }) => {
  const pedidos = new PaginaPedidos(page);
  await pedidos.abrir();
  await pedidos.buscar('Café');

  await expect(pedidos.lista.getByRole('listitem')).toHaveCount(1);
  await expect(pedidos.linha('Café especial')).toBeVisible();
});
```

```ts
// ✗ o page object decide o que é sucesso
async buscar(termo: string) {
  await this.campoBusca.fill(termo);
  await this.campoBusca.press('Enter');
  await expect(this.lista.getByRole('listitem')).toHaveCount(1);   // ← quem disse 1?
}
```

O segundo caso quebra dois testes com expectativas diferentes sobre a mesma ação, e esconde a afirmação de quem lê o teste. Um page object **pode** conter asserção de *invariante estrutural* — "depois de `abrir()`, o cabeçalho existe", que é sanidade de navegação — mas não de regra de negócio (`PW-STR-02`).

### 2.2 Entregar por fixture

Page object com setup próprio vira fixture, e o teste deixa de instanciar nada:

```ts
// e2e/fixtures.ts
export const test = base.extend<{ pedidos: PaginaPedidos }>({
  pedidos: async ({ page }, use) => {
    const p = new PaginaPedidos(page);
    await p.abrir();
    await use(p);
  },
});
export { expect } from '@playwright/test';
```

```ts
test('busca filtra a lista', async ({ pedidos }) => {
  await pedidos.buscar('Café');
  await expect(pedidos.lista.getByRole('listitem')).toHaveCount(1);
});
```

Ver [Playwright - Fixtures](playwright-fixtures.md) § 2 (`PW-STR-03`).

### 2.3 Quando page object é excesso

Suíte de 8 testes numa tela não precisa de classe. O sinal para extrair é **o terceiro arquivo** que repete o mesmo locator. Antes disso, page object é indireção que custa mais do que economiza — o mesmo critério de extração de [React - Patterns](react-patterns.md).

---

## 3. Título de teste

O título é lido em três lugares onde ninguém tem o código à mão: saída do CI, relatório HTML e notificação de falha. Ele deve dizer **o que deixou de funcionar**.

| ✗ | ✓ |
| --- | --- |
| `test('test')` | `test('visitante é redirecionado ao login')` |
| `test('login')` | `test('senha errada mostra mensagem e mantém o e-mail preenchido')` |
| `test('funciona')` | `test('pedido criado aparece na lista imediatamente')` |
| `test('caso 3')` | `test('desconto acima de 50% exige aprovação')` |

Regra prática: o título completa a frase *"quando isto falha, significa que…"* (`PW-STR-04`).

`describe` agrupa por capacidade, não por arquivo:

```ts
test.describe('Pedidos — criação', () => { … });
test.describe('Pedidos — aprovação de desconto', () => { … });
```

---

## 4. Parametrizar

### 4.1 Por dado, no arquivo

```ts
const casos = [
  { papel: 'operador', podeAprovar: false },
  { papel: 'gerente',  podeAprovar: true },
] as const;

for (const { papel, podeAprovar } of casos) {
  test(`${papel} ${podeAprovar ? 'pode' : 'não pode'} aprovar desconto`, async ({ page }) => {
    // …
  });
}
```

**Duas armadilhas:**

- **Título duplicado.** Se dois casos produzem o mesmo título, o relatório os confunde e `--grep` seleciona os dois. O título tem de conter o que varia.
- **Hooks dentro do laço.** A fonte é explícita: `beforeEach`/`beforeAll`/`afterEach`/`afterAll` ficam **fora** do laço, senão rodam uma vez por iteração (`PW-STR-06`).

### 4.2 Por project, na suíte

Quando o parâmetro vale para a suíte inteira, é option fixture — não laço, não `process.env`:

```ts
// fixtures.ts
papel: ['operador', { option: true }],
```

```ts
// playwright.config.ts
projects: [
  { name: 'operador', use: { papel: 'operador' } },
  { name: 'gerente',  use: { papel: 'gerente' } },
],
```

Ver [Playwright - Fixtures](playwright-fixtures.md) § 4 (`PW-FIX-04`).

---

## 5. Layout de arquivos

```
e2e/
  fixtures.ts                  ← o único test/expect que os testes importam
  pages/
    pedidos.ts
    login.ts
  auth.setup.ts                ← setup project
  global.teardown.ts
  pedidos/
    criacao.spec.ts
    aprovacao.spec.ts
  login.spec.ts
playwright/
  .auth/                       ← no .gitignore
playwright.config.ts
```

Duas convenções que carregam peso:

- **`fixtures.ts` é o ponto de entrada único.** Todo `*.spec.ts` importa `test` e `expect` de lá, nunca de `@playwright/test`. Elimina `PW-FIX-05` por construção.
- **`e2e/` fora de `src/`.** A suíte E2E é consumidora da aplicação, não parte dela — a direção de dependência é só num sentido. Num monorepo, é um pacote folha ([Monorepo com Bun - estrutura e tooling](../pages/monorepo-com-bun-estrutura-e-tooling.md)).

---

## 6. Helpers × fixtures × page objects

| Precisa de… | Use |
| --- | --- |
| função pura sobre dado (gerar CPF, formatar) | função exportada, sem `page` |
| sequência de ações numa tela | método de page object |
| setup/teardown com ciclo de vida | fixture |
| parâmetro da suíte | option fixture |
| estado externo criado uma vez | setup project |

O erro comum é o **helper que recebe `page`**:

```ts
// ✗ nem page object nem fixture — cresce sem dono
export async function fazerLogin(page: Page, email: string, senha: string) { … }
```

Login é setup project ([Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 2); uma sequência de tela é page object. Um arquivo `helpers.ts` que recebe `page` é onde vai tudo que ninguém decidiu onde colocar, e ele nunca encolhe (`PW-STR-07`).

---

## 7. Regras — `PW-STR-01` a `PW-STR-07`

| ID | Regra |
| --- | --- |
| `PW-STR-01` | Locator de page object **MUST** ser declarado no construtor como propriedade `readonly`. Locator paramétrico **MUST** ser método que devolve `Locator`. † |
| `PW-STR-02` | Page object **NEVER** contém asserção de regra de negócio. A asserção é do teste. † |
| `PW-STR-03` | Page object com setup próprio **MUST** ser entregue ao teste por fixture. † |
| `PW-STR-04` | Título de teste **MUST** descrever o comportamento observável que deixa de funcionar quando ele falha. † |
| `PW-STR-05` | `test.skip` e `test.fixme` **MUST** carregar motivo textual. † |
| `PW-STR-06` | Hooks **MUST** ficar fora do laço de parametrização. Dentro, rodam uma vez por iteração. |
| `PW-STR-07` | Função que recebe `page` **NEVER** vive em `helpers.ts`: ou é page object, ou é fixture. † |

---

## 8. Antipadrões

### 8.1 Teste que faz tudo

```ts
// ✗ falha por seis motivos, e a mensagem não diz qual
test('fluxo completo', async ({ page }) => {
  // cadastra cliente, cria pedido, aplica desconto, aprova, emite nota, confere e-mail
});
```

Ver § 1 e [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 5.1.

### 8.2 Asserção dentro do page object

```ts
// ✗
async aprovar() {
  await this.botaoAprovar.click();
  await expect(this.page.getByText('Aprovado')).toBeVisible();
}
```

O teste de "operador não pode aprovar" agora não consegue usar `aprovar()` (`PW-STR-02`).

### 8.3 Page object que devolve dado em vez de locator

```ts
// ✗ perde o retry
async textoDoTotal(): Promise<string> {
  return (await this.total.textContent()) ?? '';
}
// ✓
readonly total: Locator;
```

O primeiro força o teste a `expect(await p.textoDoTotal()).toBe(…)`, que é exatamente `PW-EXP-01`. Um page object que devolve `Promise<string>` empurra o antipadrão para todos os testes que o usam.

### 8.4 `helpers.ts` com `page`

Ver § 6 (`PW-STR-07`).

### 8.5 Título que não informa

```ts
// ✗ o CI diz "1 failed: test > test 3"
test('test 3', async ({ page }) => { … });
```

(`PW-STR-04`)

### 8.6 Hook dentro do laço

```ts
// ✗ o beforeEach roda três vezes por teste
for (const caso of casos) {
  test.beforeEach(async ({ page }) => { await page.goto('/'); });
  test(`caso ${caso.nome}`, async ({ page }) => { … });
}
```

(`PW-STR-06`)

### 8.7 Suíte E2E como suíte de regra de negócio

```ts
// ✗ 40 testes E2E sobre arredondamento de desconto
```

Cada um custa segundos e um browser. A regra pertence a teste unitário; o E2E cobre que a tela mostra o valor calculado. [Teste de Software](teste-de-software.md).

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 7 é o contrato de skill
- [Playwright - Fixtures](playwright-fixtures.md) — o mecanismo que sustenta a § 2.2 e a § 4.2
- [Playwright - Locators](playwright-locators.md) — por que locator no construtor funciona
- [Playwright - Assertions](playwright-assertions.md) — por que page object não devolve `string`
- [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) — onde o login realmente mora
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — `test.step` e por que codegen não é teste
- [Teste de Software](teste-de-software.md) — que nível de teste para que risco
- ·
- [React - Patterns](react-patterns.md) — o mesmo critério de "quando extrair"
- [Feature-Based Architecture](../pages/feature-based-architecture.md) · [Monorepo com Bun - estrutura e tooling](../pages/monorepo-com-bun-estrutura-e-tooling.md) — onde `e2e/` vive
- ·

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Page object models](https://playwright.dev/docs/pom) — locators no construtor, métodos, uso no teste
- [Best Practices](https://playwright.dev/docs/best-practices) — comportamento visível ao usuário, isolamento, custo do E2E
- [Parameterize tests](https://playwright.dev/docs/test-parameterize) — laço, hooks fora do laço, projects
- [Annotations](https://playwright.dev/docs/test-annotations) — motivo em `skip`/`fixme`, tags
- [Fixtures](https://playwright.dev/docs/test-fixtures) — page object entregue por fixture
