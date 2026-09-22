---
titulo: Playwright - Snapshots e Visual
Link: https://playwright.dev/docs/aria-snapshots
tags:
 - playwright
 - testing
 - snapshots
 - visual-regression
 - accessibility
 - agent-context
source: "Documentação oficial do Playwright — Snapshot testing (aria), Visual comparisons, Accessibility testing"
verificado-em: 2026-08-20
---

# Playwright — Snapshots e Visual

> Satélite de [Playwright](playwright.md). Cobre as três formas de comparar um estado inteiro contra uma referência — aria snapshot, screenshot e snapshot de valor — mais a varredura de acessibilidade. A árvore de escolha está na § 5.6 do hub.
>
> **A tese desta nota.** Aria snapshot é subutilizado e screenshot é superutilizado. Aria snapshot verifica **estrutura e semântica**, tem diff legível, não depende de SO e ainda dá sinal de acessibilidade. Screenshot verifica pixel, que é o que menos se quer verificar na maioria dos casos, e cobra o preço mais alto em manutenção.

---

## 1. Aria snapshot — o default

Uma representação YAML da árvore de acessibilidade.

```ts
await expect(page.getByRole('main')).toMatchAriaSnapshot(`
 - heading "Meus pedidos" [level=1]
 - list:
 - listitem: Café — R$ 12,00
 - listitem: Chá — R$ 9,00
 - button "Novo pedido"
`);
```

### 1.1 A sintaxe

```
- papel "nome" [atributo=valor]
```

| Parte | Regra |
| --- | --- |
| **papel** | papel ARIA ou HTML: `heading`, `list`, `listitem`, `button`, `link`, `textbox`, `checkbox`… |
| **"nome"** | nome acessível. String entre aspas é **exata**; `/padrão/` é regex |
| **[atributo=valor]** | `checked`, `disabled`, `expanded`, `invalid`, `level`, `pressed`, `selected` |

```yaml
- heading "Título" [level=1]
- heading /Issues \d+/ # regex no nome
- link "Saiba mais":
 - /url: "#detalhes" # a URL como filho
- textbox "E-mail" [invalid]: nao-e-email
- checkbox [checked]
- button "Alternar" [pressed=true]
- textbox: Digite seu nome # nome omitido = casa qualquer
```

### 1.2 Casamento parcial é o default

Omitir nome ou atributo **relaxa** a comparação:

```yaml
- button # qualquer botão, qualquer rótulo
- checkbox # marcado ou não
```

Isso é o que torna aria snapshot utilizável: verifica-se a estrutura que importa e ignora-se o que varia.

### 1.3 Casamento estrito de filhos

```yaml
- list
 - /children: equal
 - listitem: Item A
 - listitem: Item B
```

| Valor | Significa |
| --- | --- |
| `contain` (**default**) | os filhos declarados estão presentes, na ordem |
| `equal` | exatamente esses filhos, nessa ordem |
| `deep-equal` | idem, recursivamente |

Global:

```ts
export default defineConfig({
 expect: { toMatchAriaSnapshot: { children: 'equal' } },
});
```

**O default `contain` é o que se quer** na maioria dos casos: ele deixa o snapshot sobreviver a um item novo no fim da lista. `equal` é para quando a completude *é* o que se verifica — "a lista tem exatamente estes três itens e nada mais".

### 1.4 Em arquivo externo

```ts
await expect(page.getByRole('main')).toMatchAriaSnapshot({ name: 'pedidos.aria.yml' });
```

Os arquivos ficam em `{arquivoDeTeste}-snapshots/`, com caminho configurável por `snapshotPathTemplate`.

Inline × arquivo: inline é melhor para snapshot pequeno (o diff aparece no próprio teste); arquivo é melhor para árvore grande, para não afogar o teste.

### 1.5 Gerar e atualizar

```ts
await expect(locator).toMatchAriaSnapshot(''); // vazio; será preenchido
```

```bash
npx playwright test --update-snapshots
```

Programaticamente:

```ts
console.log(await page.ariaSnapshot);
console.log(await locator.ariaSnapshot);
```

O codegen também tem aba "Aria snapshot" e ação "Assert snapshot" ([Playwright - Debug e Trace](playwright-debug-e-trace.md) § 5).

---

## 2. Screenshot — `toHaveScreenshot`

```ts
test('página inicial', async ({ page }) => {
 await page.goto('/');
 await expect(page).toHaveScreenshot;
});
```

Na primeira execução a referência é gerada e o teste **falha** (não há o que comparar). Depois, compara.

O runner tira screenshots repetidas até **duas consecutivas** coincidirem — é a defesa embutida contra animação.

### 2.1 O aviso que decide se vale a pena

A fonte é direta: a renderização *"pode variar conforme o SO do host, versão, configurações, hardware, fonte de energia (bateria × tomada), modo headless e outros fatores"*.

Consequência: **a referência tem de ser gerada no mesmo ambiente do CI** (`PW-SNAP-02`). Em prática, isso significa gerar dentro de container, com a mesma imagem do CI. Referência gerada no macOS de quem escreveu o teste falha no Linux do CI por antialiasing de fonte — e o diff não diz isso.

O nome do arquivo carrega a plataforma justamente por isso:

```
exemplo.spec.ts-snapshots/
 pagina-inicial-1-chromium-linux.png
 pagina-inicial-1-chromium-darwin.png
```

### 2.2 Nome e formato

```ts
await expect(page).toHaveScreenshot('inicial.png');
await expect(page).toHaveScreenshot('inicial.webp'); // WebP, sem perda
await expect(page).toHaveScreenshot(['pt-br', 'inicial.png']); // subpasta
```

WebP reduz muito o peso no repositório — relevante numa suíte com dezenas de referências.

### 2.3 Tolerância

```ts
await expect(page).toHaveScreenshot({ maxDiffPixels: 100 });
```

```ts
expect: { toHaveScreenshot: { maxDiffPixels: 100 } }
```

Também existem `maxDiffPixelRatio` e `threshold`.

> **A regra de higiene:** inflar `maxDiffPixels` para calar um teste é a forma mais eficiente de transformar teste visual em decoração. Ele passa a não detectar exatamente a classe de regressão que justificava existir. Região não determinística se resolve **removendo a região**, não afrouxando o limiar (`PW-SNAP-04`).

### 2.4 Neutralizar o que varia

**`stylePath`** — a ferramenta preferível:

```css
/* screenshot.css */
iframe,.live-chat, [data-testid="relogio"] { visibility: hidden; }
* { animation: none !important; transition: none !important; }
```

```ts
await expect(page).toHaveScreenshot({ stylePath: path.join(__dirname, 'screenshot.css') });
```

```ts
expect: { toHaveScreenshot: { stylePath: './screenshot.css' } }
```

**`mask`** — cobre elementos com um retângulo:

```ts
await expect(page).toHaveScreenshot({ mask: [page.getByTestId('avatar')] });
```

**Outras opções** de `toHaveScreenshot`: `fullPage`, `animations`, `caret`, `clip`, `omitBackground`, `scale`, `timeout`.

**E o que resolve mais que todas elas:** congelar o relógio. `page.clock.setFixedTime` elimina de uma vez toda a variação por data, hora e "há 2 minutos" ([Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 7).

**A armadilha cruzada:** bloquear imagens por `route` para acelerar a suíte quebra screenshot em silêncio — a referência tem as imagens, a execução não ([Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 1.3).

---

## 3. Snapshot de valor — `toMatchSnapshot`

```ts
expect(await page.getByRole('heading').textContent).toMatchSnapshot('titulo.txt');
```

Para texto e dado serializável. Fica no mesmo diretório `-snapshots` e **deve ser versionado**, porque o diff é a revisão.

Onde vale: payload de API grande e estável, saída de um gerador, um contrato. Onde não vale: qualquer coisa com id, timestamp ou ordem instável — nesses casos matchers assimétricos dão sinal melhor ([Playwright - Assertions](playwright-assertions.md) § 8).

---

## 4. Atualizar snapshots

```bash
npx playwright test --update-snapshots
npx playwright test -u
npx playwright test --update-snapshots=changed
```

| `updateSnapshots` | Efeito |
| --- | --- |
| `'missing'` (**default**) | cria o que falta, não toca no que existe |
| `'changed'` | atualiza os que diferem |
| `'all'` | reescreve todos |
| `'none'` | não escreve nada |

E, para os snapshots que vivem **dentro** do código (aria inline):

| `updateSourceMethod` | Efeito |
| --- | --- |
| `'patch'` (**default**) | grava um arquivo de patch, **não altera a fonte** |
| `'3way'` | aplica com marcadores de conflito |
| `'overwrite'` | sobrescreve a fonte |

```bash
npx playwright test --update-snapshots --update-source-method=3way
```

> **Isto surpreende quem vem de outra ferramenta:** `-u` **não** reescreve o arquivo de teste por default — ele produz um patch. E o default de `updateSnapshots` é `'missing'`, não `'all'`. Quem esperava reescrita e vê o teste ainda falhando conclui que o comando não funcionou (`PW-SNAP-03`).
>
> O desenho é deliberado e certo: atualizar snapshot é aceitar uma mudança de comportamento, e isso merece revisão explícita. Um `-u` que sobrescreve tudo em silêncio é como uma suíte inteira aprova regressão.

---

## 5. Acessibilidade — `@axe-core/playwright`

Pacote de terceiro, não do Playwright.

```ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('a página inicial não tem violação de a11y', async ({ page }) => {
 await page.goto('/');
 const r = await new AxeBuilder({ page }).analyze;
 expect(r.violations).toEqual([]);
});
```

```ts
// escopo, tags WCAG, exclusões
const r = await new AxeBuilder({ page })
.include('#menu-lateral')
.exclude('#widget-de-terceiro')
.withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
.disableRules(['duplicate-id'])
.analyze;
```

Por fixture, para não repetir a configuração:

```ts
export const test = base.extend<{ makeAxeBuilder: => AxeBuilder }>({
 makeAxeBuilder: async ({ page }, use) => {
 await use( => new AxeBuilder({ page })
.withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
.exclude('#widget-de-terceiro'));
 },
});
```

Anexar o resultado ao relatório com `testInfo.attach` torna o achado acionável em vez de um `toEqual([])` falhando.

**A ressalva da fonte, e ela é importante:** varredura automática *"detecta alguns problemas comuns"*, mas *"muitos problemas de acessibilidade só podem ser descobertos com teste manual"*. Suíte verde no axe não é aplicação acessível. Ver [Playwright - Locators](playwright-locators.md) § 2.1: localizar por papel é o outro meio caminho, e nenhum dos dois é auditoria.

---

## 6. Regras — `PW-SNAP-01` a `PW-SNAP-06`

| ID | Regra |
| --- | --- |
| `PW-SNAP-01` | Verificação de estrutura de UI **MUST** preferir `toMatchAriaSnapshot` a `toHaveScreenshot`. |
| `PW-SNAP-02` | Screenshot de referência **MUST** ser gerado no mesmo SO e versão de browser do CI. |
| `PW-SNAP-03` | `--update-snapshots` **MUST** ter o diff revisado. O default grava **patch** (`updateSourceMethod: 'patch'`) e atualiza só o que falta (`updateSnapshots: 'missing'`) — o comando não reescreve tudo. |
| `PW-SNAP-04` | Região não determinística **MUST** ser neutralizada por `stylePath`, `mask` ou `page.clock`. Inflar `maxDiffPixels` **NEVER**. † |
| `PW-SNAP-05` | Snapshot **NEVER** é usado para verificar uma condição única — condição única é asserção comum. † |
| `PW-SNAP-06` | Suíte que usa `toHaveScreenshot` **NEVER** bloqueia imagens por `route` no mesmo project. † |

---

## 7. Antipadrões

### 7.1 Screenshot onde aria snapshot serviria

```ts
// ✗ falha por qualquer ajuste de padding, e o diff não diz o que mudou
await expect(page.getByRole('navigation')).toHaveScreenshot;
// ✓ diff legível, independente de SO, e verifica semântica
await expect(page.getByRole('navigation')).toMatchAriaSnapshot(`
 - link "Início"
 - link "Pedidos"
 - link "Configurações"
`);
```

(`PW-SNAP-01`)

### 7.2 Referência gerada na máquina de quem escreveu

Passa local, falha em CI, e o diff mostra antialiasing de fonte. Gere em container (`PW-SNAP-02`).

### 7.3 `maxDiffPixels` inflado

```ts
// ✗ tolera qualquer coisa; o teste deixou de detectar regressão visual
await expect(page).toHaveScreenshot({ maxDiffPixels: 50_000 });
```

(`PW-SNAP-04`)

### 7.4 Snapshot de página inteira para verificar um botão

```ts
// ✗
await expect(page).toMatchAriaSnapshot(/* 120 linhas */);
// ✓
await expect(page.getByRole('button', { name: 'Salvar' })).toBeEnabled;
```

(`PW-SNAP-05`)

### 7.5 `-u` como reflexo

Rodar `-u` sempre que um snapshot falha converte a suíte em registro do que a aplicação faz, não do que deveria fazer. O patch existe para ser lido (`PW-SNAP-03`).

### 7.6 `children: 'equal'` global

```ts
// ✗ todo item novo em qualquer lista quebra um snapshot
expect: { toMatchAriaSnapshot: { children: 'equal' } }
```

O default `contain` existe para isso. `equal` é decisão por snapshot, onde a completude é o assunto.

### 7.7 Tratar axe verde como acessibilidade garantida

Ver § 5 — a própria fonte adverte.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.6 escolhe entre os três snapshots
- [Playwright - Assertions](playwright-assertions.md) — snapshot é uma asserção web-first, com retry
- [Playwright - Locators](playwright-locators.md) — `getByRole` e aria snapshot leem a mesma árvore
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — `page.clock` e o conflito com bloqueio de imagem
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — o diff de imagem aparece na aba Attachments
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — por que gerar referência em container
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — a a11y no nível do componente, e por que `'todo'` não falha CI
- — o princípio de que aria snapshot é a aplicação literal

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Snapshot testing](https://playwright.dev/docs/aria-snapshots) — sintaxe YAML, casamento parcial, `/children`, geração
- [Visual comparisons](https://playwright.dev/docs/test-snapshots) — `toHaveScreenshot`, nome de arquivo, `stylePath`, tolerância, WebP
- [Accessibility testing](https://playwright.dev/docs/accessibility-testing) — `AxeBuilder`, escopo, tags, fixture, e a ressalva sobre teste manual
- [TestConfig (API)](https://playwright.dev/docs/api/class-testconfig) — defaults de `updateSnapshots` e `updateSourceMethod`
