---
titulo: Playwright - Locators
Link: https://playwright.dev/docs/locators
tags:
 - playwright
 - testing
 - locators
 - accessibility
 - agent-context
source: "Documentação oficial do Playwright — Locators, Other locators, Best Practices"
verificado-em: 2026-08-20
---

# Playwright — Locators

> Satélite de [Playwright](playwright.md). Cobre como um teste **encontra** um elemento — a decisão que mais determina se a suíte envelhece bem. A árvore de escolha está na § 5.1 do hub.
>
> **Por que esta nota vem primeiro.** Nenhum teste existe sem locator, e locator ruim é a origem de duas classes de dívida ao mesmo tempo: teste que quebra a cada refatoração de CSS, e teste que passa enquanto a interface está inacessível. As duas se resolvem com a mesma decisão.

---

## 1. O que um locator é

**Um locator é uma consulta, não um elemento.** Esta é a afirmação 1 do modelo mental do hub, e ela tem consequências que aparecem no código todos os dias.

```ts
const salvar = page.getByRole('button', { name: 'Salvar' });
// nada foi buscado ainda — nem uma query no DOM

await salvar.click; // busca agora, espera actionability, clica
await expect(salvar).toBeDisabled; // busca de novo, contra o DOM de agora
```

O locator é reavaliado a cada uso. Por isso:

- **Guardar locator em variável é correto e recomendado.** Ele não fica obsoleto quando a página re-renderiza — é a base do page object ([Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) § 2).
- **`ElementHandle` é o oposto** e não deve aparecer em código novo: ele aponta para um nó específico, que morre no próximo render (`PW-LOC-03`).
- **Um locator não tem estado.** Não existe "locator que já esperou". Cada uso espera de novo.

### 1.1 Strict mode

O default é **estrito**: se o locator resolve para mais de um elemento, a ação falha.

```ts
// A página tem 4 botões
await page.getByRole('button').click;
// ✗ Error: strict mode violation: resolved to 4 elements
```

Isso é uma feature, não um obstáculo. Um locator ambíguo que "funciona" clicando no primeiro elemento é um teste que vai clicar no lugar errado no dia em que a ordem mudar — e não vai avisar.

Operações que agem sobre o conjunto **não** são estritas, porque o conjunto é o alvo:

```ts
await expect(page.getByRole('listitem')).toHaveCount(3); // ok
await expect(page.getByRole('listitem')).toHaveText(['a','b','c']); // ok
```

---

## 2. Os locators voltados ao usuário

Em ordem de preferência, como a fonte a estabelece.

### 2.1 `getByRole` — o default

Busca por papel ARIA (explícito ou implícito) e nome acessível. É o que mais se aproxima de "como o usuário e a tecnologia assistiva percebem a página".

```ts
await page.getByRole('button', { name: 'Entrar' }).click;
await expect(page.getByRole('heading', { name: 'Cadastro', level: 1 })).toBeVisible;
await page.getByRole('textbox', { name: 'E-mail' }).fill('a@b.com');
await page.getByRole('checkbox', { name: 'Aceito os termos' }).check;
await page.getByRole('link', { name: 'Voltar' }).click;
```

Opções úteis: `name` (aceita string ou `RegExp`), `exact`, `level` (para `heading`), `checked`, `pressed`, `expanded`, `selected`, `disabled`, `includeHidden`.

O `name` é o **nome acessível**, não o `textContent`. Um botão com `aria-label="Fechar"` e um `×` dentro é `getByRole('button', { name: 'Fechar' })`.

> **A fonte é explícita num ponto que costuma ser mal citado:** "role locators do not replace accessibility audits". Localizar por papel dá *feedback precoce* de acessibilidade, não é auditoria. A auditoria é `@axe-core/playwright` — ver [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 5.

### 2.2 Os demais, por caso

| Locator | Quando | Exemplo |
| --- | --- | --- |
| `getByLabel` | campo de formulário com `<label>` associado | `page.getByLabel('Senha').fill('…')` |
| `getByPlaceholder` | campo **sem** label — e isso é um achado | `page.getByPlaceholder('nome@exemplo.com')` |
| `getByText` | texto não interativo | `page.getByText('Pedido confirmado')` |
| `getByAltText` | imagem | `page.getByAltText('logo da empresa')` |
| `getByTitle` | atributo `title` | `page.getByTitle('Contagem de issues')` |
| `getByTestId` | escape hatch estável | `page.getByTestId('menu-usuario')` |

**`getByText` normaliza espaço em branco** e por default casa **substring**, case-insensitive:

```ts
page.getByText('Olá, João'); // substring
page.getByText('Olá, João', { exact: true }); // exato, case-sensitive
page.getByText(/olá, [a-z]+$/i); // regex
```

### 2.3 `getByTestId` e o `testIdAttribute`

O atributo default é `data-testid`. Trocar é configuração de projeto, não de chamada:

```ts
// playwright.config.ts
export default defineConfig({
 use: { testIdAttribute: 'data-test' },
});
```

Test ID é o locator **mais resistente** a mudança — e o que carrega **menos** informação sobre o produto. Ele não verifica que o botão é um botão, nem que tem nome acessível. Usá-lo como default troca a única verificação gratuita de acessibilidade da suíte por conveniência (`PW-LOC-04`).

Onde ele é a escolha certa: elemento sem semântica por natureza (um container de layout, um canvas, uma linha de tabela virtualizada), ou dívida de acessibilidade que não vai ser paga neste PR — caso em que a dívida deve estar registrada.

### 2.4 CSS e XPath

```ts
await page.locator('css=button').click;
await page.locator('button').click; // css é o default
await page.locator('xpath=//button').click;
await page.locator('//button').click; // // implica xpath
```

Último recurso. A fonte é direta: eles "podem quebrar quando a estrutura do DOM muda".

**Uma diferença que importa:** todos os locators funcionam em **Shadow DOM** por default — **exceto XPath**. Num projeto com web components, XPath não é só frágil: ele não alcança.

---

## 3. Filtrar e encadear — a resposta certa à ambiguidade

Esta seção é a que substitui `.first` na maior parte dos casos.

### 3.1 `filter`

```ts
// por texto
page.getByRole('listitem').filter({ hasText: 'Produto 2' });
page.getByRole('listitem').filter({ hasText: /Produto \d/ });

// pela ausência de texto
await expect(page.getByRole('listitem').filter({ hasNotText: 'Esgotado' })).toHaveCount(5);

// por descendente
page.getByRole('listitem')
.filter({ has: page.getByRole('heading', { name: 'Produto 2' }) });

// pela ausência de descendente
await expect(page.getByRole('listitem')
.filter({ hasNot: page.getByText('Produto 2') })).toHaveCount(1);

// só os visíveis
page.locator('button').filter({ visible: true });
```

### 3.2 Encadear

O padrão canônico: estreitar para o container, agir dentro dele.

```ts
const produto = page.getByRole('listitem').filter({ hasText: 'Produto 2' });
await produto.getByRole('button', { name: 'Adicionar ao carrinho' }).click;

const dialogo = page.getByTestId('dialogo-config');
await dialogo.getByRole('button', { name: 'Salvar' }).click;
```

Isso resolve simultaneamente três problemas: ambiguidade, legibilidade e acoplamento — o teste passa a falar de "o botão dentro do produto 2", que é como a pessoa descreveria.

### 3.3 `and` / `or`

```ts
// as duas condições no mesmo elemento
const botao = page.getByRole('button').and(page.getByTitle('Assinar'));

// qualquer um dos dois — para caminho que bifurca
const novoEmail = page.getByRole('button', { name: 'Novo' });
const dialogo = page.getByText('Confirme as configurações de segurança');
await expect(novoEmail.or(dialogo).first).toBeVisible;
```

`or` é a ferramenta certa quando a aplicação legitimamente pode mostrar A **ou** B — não como remendo para incerteza sobre qual dos dois é.

---

## 4. Listas

```ts
// contagem
await expect(page.getByRole('listitem')).toHaveCount(3);

// todos os textos, em ordem
await expect(page.getByRole('listitem')).toHaveText(['maçã', 'banana', 'laranja']);

// um item específico — preferir identificar pelo conteúdo
await page.getByRole('listitem').filter({ hasText: 'laranja' }).click;

// por posição, quando a posição é o critério
const segundo = page.getByRole('listitem').nth(1);
```

**Iterar:**

```ts
// forma direta
for (const linha of await page.getByRole('listitem').all)
 console.log(await linha.textContent);

// por índice, quando a contagem importa
const linhas = page.getByRole('listitem');
const total = await linhas.count;
for (let i = 0; i < total; ++i)
 console.log(await linhas.nth(i).textContent);
```

**A armadilha do `all`:** ele resolve a lista **naquele instante** e não espera. Numa lista que ainda está carregando, `all` devolve o que existe agora — possivelmente vazio, e o `for` não roda, e o teste passa sem verificar nada. Antes de iterar, ancore a contagem:

```ts
await expect(page.getByRole('listitem')).toHaveCount(3); // agora a lista existe
for (const linha of await page.getByRole('listitem').all) { /* … */ }
```

Melhor ainda: quase todo laço sobre locators é uma asserção de conjunto disfarçada. `toHaveText([...])` verifica ordem e conteúdo de uma vez, com retry.

---

## 5. `describe` — nomear o locator no trace

```ts
const linha = page.getByRole('row').filter({ hasText: 'NF-2026-0042' })
.describe('linha da nota fiscal em disputa');
```

O rótulo aparece no trace e no relatório. Num teste com locators encadeados longos, é a diferença entre um trace legível e uma parede de seletores — e vale especialmente quando um agente vai ler esse trace depois ([Playwright - Debug e Trace](playwright-debug-e-trace.md) § 3).

---

## 6. O que não existe mais

Verificado nas notas de release; código com isso **não roda**:

| Removido | Versão | O que fazer |
| --- | --- | --- |
| `_react=` e `_vue=` | 1.58 | localizar por papel/texto; se for inevitável, `getByTestId` |
| engine `:light` | 1.58 | os locators já atravessam Shadow DOM (menos XPath) |
| `Locator.ariaRef` | 1.60 | `toMatchAriaSnapshot` — [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) |

E o que está **deprecado**, ainda funcionando:

- **Seletores de layout** — `:right-of`, `:left-of`, `:above`, `:below`, `:near` (`PW-LOC-05`). Eles amarram o teste ao layout visual, que é a coisa que muda mais.
- **`noWaitAfter`** em ações — "não tem efeito" ([Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) § 6).

---

## 7. Regras — `PW-LOC-01` a `PW-LOC-07`

| ID | Regra |
| --- | --- |
| `PW-LOC-01` | Locator **MUST** preferir papel e nome acessível (`getByRole`) a CSS ou XPath. |
| `PW-LOC-02` | `first`/`last`/`nth` **NEVER** são a resposta a uma strict mode violation; a resposta é `filter` ou encadeamento. Posição só quando a posição **é** o critério. |
| `PW-LOC-03` | Locator **MUST** ser guardado como valor reutilizável. `ElementHandle` **NEVER** em código novo. |
| `PW-LOC-04` | `testIdAttribute` **MUST** ser configurado uma vez em `use`. E `getByTestId` **NEVER** é o locator default do projeto — ele é escape hatch, e cada uso desnecessário apaga a verificação de acessibilidade que `getByRole` daria de graça. † |
| `PW-LOC-05` | Seletores de layout (`:right-of`, `:left-of`, `:above`, `:below`, `:near`) **NEVER** — a fonte os marca como deprecados. |
| `PW-LOC-06` | `_react`, `_vue` e o engine `:light` **NEVER** — foram removidos na 1.58. |
| `PW-LOC-07` | Afirmação sobre a UI **MUST** usar asserção web-first (`expect(locator).…`). `expect(await locator.isVisible)` e formas equivalentes **NEVER**. *(apelido de `PW-EXP-01` — cite o canônico)* |

---

## 8. Antipadrões

### 8.1 `.first` como resposta a strict mode

```ts
// ✗
await page.getByRole('button').first.click;
```

Silencia o aviso e mantém a ambiguidade. Quando um botão for inserido antes, o teste clica em outra coisa — e continua verde até quebrar por um motivo que não parece relacionado. A correção é `filter` ou encadear (`PW-LOC-02`).

### 8.2 Locator amarrado a classe utilitária

```ts
// ✗
page.locator('button.px-4.py-2.bg-blue-500.rounded-md');
```

Com Tailwind isso é especialmente frágil: as classes *são* o estilo, e mudam a cada ajuste de design. Ver `Tailwindcss`.

### 8.3 `getByText` para clicar em botão

```ts
// ✗
await page.getByText('Salvar').click;
// ✓
await page.getByRole('button', { name: 'Salvar' }).click;
```

`getByText` casa qualquer elemento com aquele texto — inclusive o `<span>` dentro do botão, uma legenda em outro lugar, ou um item de menu homônimo. E não verifica que o alvo é acionável por teclado.

### 8.4 Descer para CSS quando `getByRole` não alcança

```ts
// ✗ o sintoma
page.locator('div.card > div:nth-child(2) > span');
```

Se `getByRole` não alcança, na maior parte dos casos o elemento não tem papel nem nome acessível — e isso é defeito do componente, não do teste. O caminho é a ponte da § 8 do hub, não o seletor. Um `getByTestId` com dívida registrada é uma solução honesta; um seletor estrutural é a dívida escondida.

### 8.5 `ElementHandle` para "guardar" o elemento

```ts
// ✗
const el = await page.$('#total');
await page.getByRole('button', { name: 'Recalcular' }).click;
console.log(await el.textContent); // pode apontar para nó morto
```

O clique re-renderiza; o handle antigo aponta para o nó anterior. Locator resolve isso por construção (`PW-LOC-03`).

### 8.6 Iterar com `all` sem ancorar a lista

```ts
// ✗
for (const l of await page.getByRole('listitem').all)
 await expect(l).toBeVisible; // lista vazia → laço não roda → teste passa
```

Ver § 4. É um dos poucos antipadrões que produzem teste **verde** e inútil, e por isso o mais difícil de notar em revisão.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a árvore de escolha de locator está na § 5.1
- [Playwright - Assertions](playwright-assertions.md) — o par inseparável: localizar e afirmar
- [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) — onde os locators moram num page object
- [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) — `toMatchAriaSnapshot` e a auditoria de a11y
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — `codegen` e pick locator geram locator na ordem certa
- — o princípio de que isto é a aplicação prática
- [React - Patterns](react-patterns.md) — quando o achado é o componente, não o teste
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o mesmo critério de query, um nível abaixo
- `Tailwindcss` — por que classe utilitária não serve de seletor

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Locators](https://playwright.dev/docs/locators) — a página principal desta nota
- [Other locators](https://playwright.dev/docs/other-locators) — CSS, XPath, pseudo-classes, seletores de layout
- [Best Practices](https://playwright.dev/docs/best-practices) — a ordem de preferência e o encadeamento
- [Locator (API)](https://playwright.dev/docs/api/class-locator) — assinaturas, `describe`, o que está deprecado
- [Release notes](https://playwright.dev/docs/release-notes) — remoções da 1.58 e 1.60
