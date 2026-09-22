---
Link: https://playwright.dev/docs/test-fixtures
tags:
 - playwright
 - testing
 - fixtures
 - architecture
 - agent-context
source: "Documentação oficial do Playwright — Fixtures, Global setup and teardown, Parameterize tests"
verificado-em: 2026-08-20
---

# Playwright — Fixtures

> Satélite de [Playwright](playwright.md). Cobre a unidade de arquitetura da suíte. A árvore "onde colocar setup" está na § 5.3 do hub.
>
> **Por que isto é arquitetura e não utilitário.** Uma suíte que cresce sem fixtures acumula `beforeEach` copiado entre arquivos, e cada cópia divergindo devagar. Uma suíte com fixtures tem um lugar só para cada preparação, tipado, e que só roda quando alguém pede. A diferença aparece por volta do trigésimo teste.

---

## 1. Fixtures embutidas

| Fixture | Tipo | Escopo | O que é |
| --- | --- | --- | --- |
| `page` | `Page` | teste | página isolada, dentro de um contexto novo |
| `context` | `BrowserContext` | teste | o contexto daquele teste |
| `browser` | `Browser` | worker | compartilhado entre testes do worker, por performance |
| `browserName` | `'chromium' \| 'firefox' \| 'webkit'` | worker | qual browser está rodando |
| `request` | `APIRequestContext` | teste | cliente HTTP que respeita `baseURL` e `extraHTTPHeaders` |
| `playwright` | — | worker | acesso a `playwright.request`, `playwright.devices` |

**`page` e `context` são o isolamento.** Cada teste recebe os seus, e é por isso que a ordem de execução não importa ([Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 1).

**`browser` é worker-scoped por desenho** — lançar browser é caro, criar contexto é barato. É a razão de o paralelismo do Playwright ser viável.

---

## 2. Fixture customizada

```ts
// tests/fixtures.ts
import { test as base } from '@playwright/test';
import { PaginaPedidos } from './pages/pedidos';

type MinhasFixtures = {
 paginaPedidos: PaginaPedidos;
};

export const test = base.extend<MinhasFixtures>({
 paginaPedidos: async ({ page }, use) => {
 const p = new PaginaPedidos(page);
 await p.abrir; // setup
 await use(p); // entrega ao teste
 await p.limpar; // teardown
 },
});

export { expect } from '@playwright/test';
```

```ts
// tests/pedidos.spec.ts
import { test, expect } from './fixtures';

test('cria um pedido', async ({ paginaPedidos }) => {
 await paginaPedidos.criar({ item: 'Café' });
 await expect(paginaPedidos.lista).toHaveCount(1);
});
```

**A forma é `await use(valor)`, não `return`.** O que vem depois de `use` é o teardown, e ele roda mesmo se o teste falhar. Um `return` no lugar de `use` faz a fixture entregar e nunca limpar (`PW-FIX-03`).

**Reexportar `expect` do módulo de fixtures** é o que evita o defeito de `PW-FIX-05`: o arquivo de teste importa tudo de um lugar só, e não há como pegar o `test` errado por descuido.

---

## 3. Escopo

### 3.1 Teste (default)

Setup e teardown por teste. É o certo para qualquer coisa que dependa de `page`.

### 3.2 Worker

```ts
export const test = base.extend<{}, { conta: Conta }>({
 conta: [async ({ browser }, use, workerInfo) => {
 const usuario = `user${workerInfo.workerIndex}`;
 const conta = await provisionarConta(usuario);
 await use(conta);
 await liberarConta(conta);
 }, { scope: 'worker' }],
});
```

Roda uma vez por processo de worker, com timeout próprio. Certo para recurso caro e reutilizável: conta de teste, conexão, servidor auxiliar, tenant.

> **A regra de higiene:** uma fixture worker-scoped é **compartilhada por vários testes em sequência**. Se ela guarda estado mutável — um carrinho, um registro, um contador — o teste N suja o teste N+1, e a falha aparece dependendo da ordem, o que é o pior tipo de flake para diagnosticar. Estado mutável pertence ao escopo de teste (`PW-FIX-02`).

Note a assinatura de `extend`: **o primeiro parâmetro genérico é o escopo de teste, o segundo é o de worker.** Declarar uma fixture worker-scoped no primeiro slot compila e produz comportamento errado.

### 3.3 Automática

```ts
salvarLogs: [async ({}, use, testInfo) => {
 const logs: string[] = [];
 await use;
 if (testInfo.status !== testInfo.expectedStatus) {
 const arquivo = testInfo.outputPath('logs.txt');
 await fs.promises.writeFile(arquivo, logs.join('\n'), 'utf8');
 }
}, { auto: true }],
```

`auto: true` roda para todo teste, mesmo sem ninguém pedir. É o mecanismo para `beforeEach`/`afterEach` **globais** — a substituição de um hook copiado em vinte arquivos:

```ts
// beforeEach global
forEachTest: [async ({ page }, use) => {
 await page.goto('/');
 await use;
}, { auto: true }],

// beforeAll/afterAll global
forEachWorker: [async ({}, use) => {
 console.log(`worker ${test.info.workerIndex} subindo`);
 await use;
}, { scope: 'worker', auto: true }],
```

Use com parcimônia: fixture automática cobra de todo teste, inclusive dos que não precisam — o que é exatamente a desvantagem do hook que ela substituiu. A vantagem que resta é ser central e tipada.

---

## 4. Option fixtures — parametrizar a suíte

Este é o mecanismo que substitui `process.env` espalhado pelos testes.

```ts
// fixtures.ts
export type MinhasOpcoes = {
 papel: 'admin' | 'operador';
 itemPadrao: string;
};

export const test = base.extend<MinhasOpcoes & MinhasFixtures>({
 papel: ['operador', { option: true }],
 itemPadrao: ['Algo razoável', { option: true }],

 paginaPedidos: async ({ page, papel }, use) => {
 const p = new PaginaPedidos(page, papel);
 await use(p);
 },
});
```

```ts
// playwright.config.ts
projects: [
 { name: 'admin', use: { papel: 'admin' } },
 { name: 'operador', use: { papel: 'operador' } },
],
```

Agora `npx playwright test --project=admin` roda a suíte inteira como admin, o valor aparece no relatório, e é tipado. Com `process.env.PAPEL` nada disso acontece: não há tipo, não há projeto no relatório, e não há como rodar os dois numa execução (`PW-FIX-04`).

O mesmo vale em `test.use({ papel: 'admin' })` para um arquivo.

---

## 5. Sobrescrever fixture embutida

```ts
export const test = base.extend({
 page: async ({ baseURL, page }, use) => {
 await page.goto(baseURL!);
 await use(page);
 },
});
```

Funciona para `page`, `context`, `storageState` e as demais. É o mecanismo de [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 3: sobrescrever `storageState` com um valor calculado por worker.

Cuidado: sobrescrever `page` para navegar é conveniente e faz todo teste pagar a navegação — inclusive os que iriam para outra rota. Fixture automática de navegação costuma ser melhor que sobrescrever `page`.

---

## 6. Opções avançadas

| Opção | Efeito |
| --- | --- |
| `{ timeout: n }` | timeout próprio da fixture, separado do teste — para setup genuinamente longo |
| `{ box: true }` | esconde os passos da fixture no relatório; para helper cujo detalhe é ruído |
| `{ title: 'nome' }` | rótulo da fixture no relatório e no trace |
| `{ auto: true }` | roda sempre |
| `{ scope: 'worker' }` | por worker |
| `{ option: true }` | parâmetro configurável por project |

**Combinar fixtures de módulos diferentes:**

```ts
import { mergeTests } from '@playwright/test';
import { test as dbTest } from './fixtures/db';
import { test as authTest } from './fixtures/auth';

export const test = mergeTests(dbTest, authTest);
```

---

## 7. Ordem de execução

Três regras, e elas explicam quase toda surpresa:

1. **Dependência define ordem.** Se A pede B, B monta antes e desmonta depois.
2. **Execução é preguiçosa.** Fixture não automática que ninguém pede **nunca roda**. É a diferença central em relação a `beforeEach`.
3. **Teardown é na ordem inversa.** Fixture de teste desmonta ao fim do teste; de worker, ao fim do worker.

Fixtures automáticas montam antes dos testes e dos hooks.

**Onde o tempo é contabilizado:** o timeout do teste (30 s) inclui o setup das fixtures de teste e os `beforeEach`. Uma fixture lenta come o orçamento do teste — daí a opção `{ timeout }`. Fixtures worker-scoped têm orçamento separado ([Playwright](playwright.md) § 0).

---

## 8. Fixture × hook × setup project × `globalSetup`

A tabela que decide, e é a razão de a § 5.3 do hub existir:

| Mecanismo | Escopo | Tipado | No relatório | Trace | Sob demanda |
| --- | --- | --- | --- | --- | --- |
| `beforeEach` | arquivo | não | não | — | não |
| **fixture** | projeto | **sim** | **sim** | **sim** | **sim** |
| **setup project** | execução | sim | **sim, como project** | **sim** | não |
| `globalSetup` | execução | não | **não** | **não** | não |

`globalSetup` é o único que roda **fora** do runner. A fonte compara os dois explicitamente e recomenda setup project: com `globalSetup` não há fixture, não há trace, e o passo não aparece no relatório — se ele falhar, o diagnóstico é um stack trace solto (`PW-CFG-03`).

O caso legítimo de `globalSetup` é o que precisa acontecer antes de o runner existir: subir um container, verificar uma variável de ambiente, escrever um arquivo que o próprio config vai ler.

Passar dado de `globalSetup` para os testes é por `process.env`:

```ts
// global-setup.ts
import type { FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
 process.env.TENANT_ID = await criarTenant;
}
export default globalSetup;
```

Isso é untyped e global — mais um motivo para preferir setup project, onde o dado passa por arquivo ou por `storageState`.

---

## 9. Regras — `PW-FIX-01` a `PW-FIX-06`

| ID | Regra |
| --- | --- |
| `PW-FIX-01` | Setup reusado entre arquivos **MUST** ser fixture, **NEVER** `beforeEach` copiado. |
| `PW-FIX-02` | Fixture worker-scoped **NEVER** guarda estado mutável que um teste possa sujar para o próximo. Estado mutável pertence ao escopo de teste. † |
| `PW-FIX-03` | Fixture **MUST** entregar o valor por `await use(valor)` e fazer teardown depois. `return` **NEVER**. |
| `PW-FIX-04` | Parametrização de suíte **MUST** ser option fixture (`{ option: true }`) lida por `projects[].use`. `process.env` espalhado pelos testes **NEVER**. † |
| `PW-FIX-05` | O `test` derivado por `test.extend` **MUST** vir de um módulo único do projeto. Importar o `test` base e o derivado no mesmo arquivo **NEVER** — as fixtures customizadas somem sem erro de compilação. |
| `PW-FIX-06` | Fixture automática (`auto: true`) **MUST** ser justificada: ela cobra de todo teste, inclusive dos que não a usam. † |

---

## 10. Antipadrões

### 10.1 `beforeEach` copiado entre arquivos

```ts
// ✗ em oito arquivos, com pequenas diferenças em cada
test.beforeEach(async ({ page }) => {
 await page.goto('/login');
 await page.getByLabel('E-mail').fill('a@b.com');
 await page.getByLabel('Senha').fill('123');
 await page.getByRole('button', { name: 'Entrar' }).click;
});
```

Dois defeitos: é fixture não extraída (`PW-FIX-01`) e é login por UI repetido, que é o assunto de [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 2.

### 10.2 `return` no lugar de `use`

```ts
// ✗ nunca limpa
paginaPedidos: async ({ page }) => {
 const p = new PaginaPedidos(page);
 await p.abrir;
 return p;
},
```

O teardown deixa de existir, e o vazamento aparece como flake em outro teste (`PW-FIX-03`).

### 10.3 Estado mutável em fixture de worker

```ts
// ✗
carrinho: [async ({}, use) => {
 const c = new Carrinho; // um só para todos os testes do worker
 await use(c);
}, { scope: 'worker' }],
```

O primeiro teste adiciona item, o segundo já começa com carrinho cheio, e a falha depende da ordem (`PW-FIX-02`).

### 10.4 `process.env` como parâmetro de suíte

```ts
// ✗
const papel = process.env.PAPEL ?? 'operador';
test('vê o painel', async ({ page }) => { /* usa papel */ });
```

Sem tipo, sem relatório, e impossível rodar os dois papéis numa execução (`PW-FIX-04`).

### 10.5 Misturar os dois `test`

```ts
// ✗
import { test } from '@playwright/test'; // ← o base
import { expect } from './fixtures';

test('cria pedido', async ({ paginaPedidos }) => { … });
// erro em runtime: fixture "paginaPedidos" não existe
```

Compila em alguns casos, e quando não compila a mensagem não aponta o import. Reexportar `test` e `expect` juntos do módulo de fixtures elimina a classe inteira (`PW-FIX-05`).

### 10.6 `globalSetup` para login

```ts
// ✗ sem trace, sem relatório; quando falha, o diagnóstico é um stack trace solto
globalSetup: require.resolve('./login'),
```

É o caminho que a própria fonte compara desfavoravelmente. Use setup project (`PW-CFG-03`).

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.3 é a árvore de decisão de setup
- [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) — o uso mais importante de fixture worker-scoped
- [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) — onde option fixtures são consumidas
- [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) — page object entregue por fixture
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — worker, paralelismo e o que "por worker" significa
- [React - Patterns](react-patterns.md) — o mesmo raciocínio de posse e fronteira, um domínio ao lado
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — decorator e `beforeEach` resolvem o problema análogo

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Fixtures](https://playwright.dev/docs/test-fixtures) — escopos, `auto`, `option`, `box`, `timeout`, `mergeTests`, ordem
- [Global setup and teardown](https://playwright.dev/docs/test-global-setup-teardown) — a comparação entre setup project e `globalSetup`
- [Parameterize tests](https://playwright.dev/docs/test-parameterize) — option fixtures e projects
- [Timeouts](https://playwright.dev/docs/test-timeouts) — o que entra no orçamento do teste
