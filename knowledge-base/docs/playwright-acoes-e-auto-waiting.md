---
Link: https://playwright.dev/docs/actionability
tags:
 - playwright
 - testing
 - actions
 - auto-waiting
 - agent-context
source: "Documentação oficial do Playwright — Auto-waiting, Actions, Navigations, Events"
verificado-em: 2026-08-20
---

# Playwright — Ações e Auto-waiting

> Satélite de [Playwright](playwright.md). Cobre o que acontece **antes** de uma ação (as checagens de actionability), como escrever a ação certa, e como esperar por navegação e eventos sem inventar tempo. A árvore de diagnóstico de flake está na § 5.2 do hub.

---

## 1. Actionability — o que a ferramenta espera por você

Antes de agir, o Playwright verifica que o alvo está pronto. Esta é a tabela da fonte, e vale memorizar porque ela explica quase toda mensagem de timeout:

| Ação | Visível | Estável | Recebe eventos | Habilitado | Editável |
| --- | --- | --- | --- | --- | --- |
| `click`, `dblclick`, `tap`, `check`, `uncheck`, `setChecked` | ✓ | ✓ | ✓ | ✓ | — |
| `hover`, `dragTo` | ✓ | ✓ | ✓ | — | — |
| `screenshot` | ✓ | ✓ | — | — | — |
| `fill`, `clear` | ✓ | — | — | ✓ | ✓ |
| `selectOption` | ✓ | — | — | ✓ | — |
| `selectText` | ✓ | — | — | — | — |
| `scrollIntoViewIfNeeded` | — | ✓ | — | — | — |
| `blur`, `dispatchEvent`, `focus`, `press`, `pressSequentially`, `setInputFiles` | — | — | — | — | — |

**As definições, na letra da fonte:**

| Checagem | Significa |
| --- | --- |
| **Visível** | bounding box não vazio e sem `visibility: hidden`. Tamanho zero e `display: none` não são visíveis; **`opacity: 0` é visível** |
| **Estável** | manteve o mesmo bounding box por ao menos **dois frames de animação consecutivos** |
| **Recebe eventos** | é o hit target real no ponto de clique — não está coberto por overlay |
| **Habilitado** | não tem `disabled`, não está em `fieldset` desabilitado, não tem ancestral `aria-disabled` |
| **Editável** | habilitado e não `readonly` (nem `aria-readonly=true`) |

Duas leituras não óbvias:

- **`opacity: 0` conta como visível.** Um elemento em fade-in ou um overlay "invisível" por opacidade é clicável para o Playwright — e pode ser exatamente o que rouba o clique. O sintoma é um timeout na checagem "recebe eventos".
- **"Estável" é a razão de o clique esperar animação.** Um botão que desliza para a posição não recebe clique até parar. É por isso que suíte com muita animação fica lenta, e é um dos poucos casos em que `animations: 'disabled'` ([Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 2) ajuda também fora de screenshot.

**A linha de baixo da tabela é a mais importante:** `press`, `focus`, `dispatchEvent` e `setInputFiles` **não fazem checagem nenhuma**. Eles agem sobre o que estiver ali. São ferramentas para contornar UI hostil, não atalhos — e um teste que usa `dispatchEvent('click')` no lugar de `click` deixou de verificar que o botão é clicável.

### 1.1 `force`

`force: true` desliga as checagens não essenciais — notadamente "recebe eventos".

```ts
await page.getByRole('button', { name: 'Salvar' }).click({ force: true });
```

Isso quase sempre esconde um defeito real: um overlay que não deveria estar ali, um `pointer-events` errado, um tooltip que não fecha. O teste passa e o usuário continua sem conseguir clicar. Quando `force` é genuinamente necessário, o motivo vai escrito na linha acima (`PW-ACT-01`).

### 1.2 `trial`

```ts
await locator.click({ trial: true }); // roda as checagens, NÃO clica
```

Útil para afirmar "este botão está pronto para ser clicado" sem efeito colateral.

---

## 2. Escrever texto

```ts
await page.getByRole('textbox', { name: 'Nome' }).fill('Maria');
await page.getByLabel('Data de nascimento').fill('2020-02-02');
await page.getByRole('textbox').clear;
```

`fill` foca o elemento, define o valor e dispara um único evento `input`. É a forma default (`PW-ACT-02`).

`pressSequentially` emite tecla por tecla:

```ts
await page.locator('#area').pressSequentially('Olá!', { delay: 50 });
```

Use **só** quando a página reage a cada tecla — autocomplete que busca a cada caractere, máscara de input, editor com atalho. Como default, ele é ordens de magnitude mais lento e ainda introduz timing.

> **Fronteira com máscara e moeda.** Campo mascarado costuma ser o caso em que `fill` produz valor diferente do esperado. Isso é comportamento do componente, não do Playwright — a decisão de parse/format é de [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md). Escolher `pressSequentially` para "fazer a máscara funcionar" no teste é testar o workaround.

---

## 3. Clicar, marcar, selecionar

```ts
await page.getByRole('button').click;
await page.getByText('Item').dblclick;
await page.getByText('Item').click({ button: 'right' });
await page.getByText('Item').click({ modifiers: ['Shift'] });
await page.getByText('Item').click({ modifiers: ['ControlOrMeta'] });
await page.getByText('Item').click({ position: { x: 0, y: 0 } });
await page.getByRole('button').hover;
```

`'ControlOrMeta'` resolve Ctrl no Linux/Windows e Cmd no macOS — é o que evita teste que só passa num SO.

```ts
await page.getByLabel('Aceito os termos').check;
await page.getByLabel('Receber novidades').uncheck;
await page.getByLabel('XL').setChecked(true);
await expect(page.getByLabel('Receber novidades')).not.toBeChecked;

await page.getByLabel('Cor').selectOption('azul');
await page.getByLabel('Cor').selectOption({ label: 'Azul' });
await page.getByLabel('Cores').selectOption(['vermelho', 'verde']);
```

`setChecked(valor)` é preferível a `check`/`uncheck` quando o estado desejado vem de uma variável — evita o `if` que ninguém testa nos dois ramos.

---

## 4. Teclado

```ts
await page.getByRole('button', { name: 'Enviar' }).press('Enter');
await page.getByRole('textbox').press('Control+ArrowRight');
await page.getByRole('textbox').press('$');
await page.keyboard.press('Escape');
```

Nomes de tecla: `Backquote`, `Minus`, `Equal`, `Backslash`, `Backspace`, `Tab`, `Delete`, `Escape`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `ArrowUp`, `End`, `Home`, `Enter`, `Insert`, `PageDown`, `PageUp`, `F1`–`F12`, `Digit0`–`Digit9`, `KeyA`–`KeyZ`, caractere único, e os modificadores `Shift`, `Control`, `Alt`, `Meta`.

**Navegação por teclado é teste de acessibilidade barato.** `Tab` até o controle e `Enter` verifica de uma vez que o elemento é focável, tem ordem de foco razoável e responde a teclado — três coisas que o clique não verifica.

---

## 5. Arquivos

```ts
await page.getByLabel('Anexo').setInputFiles(path.join(__dirname, 'nota.pdf'));
await page.getByLabel('Anexos').setInputFiles([
 path.join(__dirname, 'a.txt'),
 path.join(__dirname, 'b.txt'),
]);
await page.getByLabel('Pasta').setInputFiles(path.join(__dirname, 'pasta'));
await page.getByLabel('Anexo').setInputFiles([]); // limpa

// arquivo sintético, sem tocar o disco — o caminho preferível em teste
await page.getByLabel('Anexo').setInputFiles({
 name: 'nota.txt',
 mimeType: 'text/plain',
 buffer: Buffer.from('conteúdo de teste'),
});
```

Quando o upload é por botão custom em vez de `<input type=file>` visível:

```ts
const escolhaPromise = page.waitForEvent('filechooser');
await page.getByRole('button', { name: 'Anexar' }).click;
const escolha = await escolhaPromise;
await escolha.setFiles(path.join(__dirname, 'nota.pdf'));
```

Note o padrão: **a espera é armada antes do clique** (§ 7).

---

## 6. Arrastar e rolar

```ts
await page.locator('#origem').dragTo(page.locator('#destino'));

// controle manual, quando dragTo não é suficiente
await page.locator('#origem').hover;
await page.mouse.down;
await page.locator('#destino').hover;
await page.mouse.up;

await page.getByText('Rodapé').scrollIntoViewIfNeeded;
await page.getByTestId('lista').hover;
await page.mouse.wheel(0, 200);
```

Quase toda ação já rola o alvo até a viewport. `scrollIntoViewIfNeeded` explícito é raramente necessário — e quando é, geralmente o alvo real é uma lista virtualizada, cujo item pode nem existir no DOM ainda.

---

## 7. Esperar por navegação e por evento

### 7.1 Navegação

`page.goto` espera o evento `load`, e segue redirecionamento de cliente.

```ts
await page.goto('/dashboard'); // relativo, via baseURL
```

Navegação disparada por clique **normalmente não precisa de espera**: a ação seguinte já espera actionability do próximo alvo.

```ts
await page.goto('/');
await page.getByRole('link', { name: 'Entrar' }).click;
await page.getByLabel('E-mail').fill('a@b.com'); // já espera a nova página
```

Quando o clique pode disparar **mais de uma** navegação, ou quando a URL final é o que se quer afirmar:

```ts
await page.getByRole('button', { name: 'Entrar' }).click;
await page.waitForURL('**/dashboard');
```

**`waitUntil: 'networkidle'` não.** A fonte o desencoraja explicitamente. Ele é indeterminístico por natureza — qualquer polling, websocket, analytics ou heartbeat impede o "idle" de acontecer, e o teste passa a depender de tráfego que não tem relação com o que ele verifica (`PW-ACT-04`). Os valores utilizáveis são `'load'` (default), `'domcontentloaded'` e `'commit'`.

### 7.2 Hidratação

A fonte descreve o problema com precisão: o Playwright "começa a interagir com a página no momento em que a vê", e num app hidratando os listeners podem não estar prontos — o clique acontece e nada responde. A correção prescrita é **do produto**: manter os controles interativos desabilitados até a hidratação terminar.

Isso é relevante para o stack: um app React com SSR/RSC tem essa janela por construção. Ver [React - Server Components e Diretivas](react-server-components-e-diretivas.md). Um `waitForTimeout` aqui é o remendo clássico — e ele volta a falhar na primeira máquina de CI mais lenta.

### 7.3 Eventos

**A regra estrutural: arme a espera antes da ação.**

```ts
// ✓
const popupPromise = page.waitForEvent('popup'); // sem await
await page.getByText('abrir popup').click;
const popup = await popupPromise;

const downloadPromise = page.waitForEvent('download');
await page.getByRole('button', { name: 'Exportar' }).click;
const download = await downloadPromise;

const requestPromise = page.waitForRequest('**/api/pedidos');
await page.getByRole('button', { name: 'Salvar' }).click;
const request = await requestPromise;
```

Se a espera vier depois do clique, o evento pode já ter acontecido — e o teste espera para sempre por algo que passou (`PW-ACT-03`). Este é o caso em que o defeito **parece** ser lentidão da aplicação e é, na verdade, ordem de código.

Listeners contínuos:

```ts
page.on('request', r => console.log('→', r.url));
page.once('dialog', d => d.accept('42'));

const l = (r: Request) => console.log('✓', r.url);
page.on('requestfinished', l);
await page.goto('/');
page.off('requestfinished', l);
```

### 7.4 Diálogos

O Playwright **dispensa diálogos automaticamente** se ninguém escutar — `alert`, `confirm` e `prompt` são recusados por default, e a página segue. Para aceitar:

```ts
page.once('dialog', d => d.accept);
await page.getByRole('button', { name: 'Excluir' }).click;
```

Consequência prática: um fluxo que depende de `confirm` **passa silenciosamente pelo caminho de cancelamento** se o teste não registrar o handler. O teste "de exclusão" verifica que nada foi excluído.

---

## 8. Regras — `PW-ACT-01` a `PW-ACT-07`

| ID | Regra |
| --- | --- |
| `PW-ACT-01` | Ação **MUST** confiar nos actionability checks. `force: true` só com o motivo escrito no código. † |
| `PW-ACT-02` | `fill` **MUST** ser a forma default de escrever em campo. `pressSequentially` só quando a página reage a cada tecla. |
| `PW-ACT-03` | Espera por evento **MUST** ser armada **antes** da ação que o dispara. |
| `PW-ACT-04` | `waitUntil: 'networkidle'` **NEVER** — a fonte o desencoraja explicitamente. |
| `PW-ACT-05` | `noWaitAfter` **NEVER** — a opção está deprecada e não tem efeito. |
| `PW-ACT-06` | `dispatchEvent` e `focus` **NEVER** substituem `click` e `fill` por conveniência: eles não fazem checagem alguma e removem a verificação que era o valor do teste. † |
| `PW-ACT-07` | `page.waitForTimeout` **NEVER** em teste versionado. *(apelido de `PW-CORE-05` — cite o canônico)* |

---

## 9. Antipadrões

### 9.1 `waitForTimeout` como espera

```ts
// ✗
await page.getByRole('button', { name: 'Salvar' }).click;
await page.waitForTimeout(3000);
await expect(page.getByText('Salvo')).toBeVisible;
```

Lento sempre, insuficiente às vezes. A asserção já reespera (`PW-CORE-05`).

### 9.2 `force: true` para vencer um overlay

```ts
// ✗
await page.getByRole('button', { name: 'Confirmar' }).click({ force: true });
```

O overlay que rouba o clique no teste rouba o clique do usuário. `force` converte um bug de produto em teste verde (`PW-ACT-01`).

### 9.3 Esperar o evento depois de disparar

```ts
// ✗
await page.getByRole('button', { name: 'Exportar' }).click;
const download = await page.waitForEvent('download'); // pode já ter passado
```

Ver § 7.3 (`PW-ACT-03`).

### 9.4 `networkidle` para "esperar a página ficar pronta"

```ts
// ✗
await page.goto('/dashboard', { waitUntil: 'networkidle' });
```

Um único polling na aplicação torna isso um timeout garantido. O que se quer afirmar é sempre um estado concreto — `await expect(page.getByRole('heading', { name: 'Painel' })).toBeVisible` (`PW-ACT-04`).

### 9.5 `pressSequentially` como default

```ts
// ✗
await page.getByLabel('Descrição').pressSequentially('texto longo de 200 caracteres');
```

200 eventos de teclado onde um `fill` bastava (`PW-ACT-02`).

### 9.6 Fluxo com `confirm` sem handler

```ts
// ✗ verifica o caminho de cancelamento acreditando verificar a exclusão
await page.getByRole('button', { name: 'Excluir' }).click;
await expect(page.getByRole('row')).toHaveCount(2);
```

Ver § 7.4. Como o Playwright recusa o diálogo por default, o teste passa — afirmando que nada aconteceu.

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.2 é a árvore de diagnóstico de flake
- [Playwright - Locators](playwright-locators.md) — o alvo da ação
- [Playwright - Assertions](playwright-assertions.md) — o que vem depois da ação
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — `waitForResponse` e interceptação
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — o log de actionability aparece no trace, ação por ação
- [React - Server Components e Diretivas](react-server-components-e-diretivas.md) — a janela de hidratação da § 7.2
- [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) — máscara, moeda e o que `fill` produz
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — `userEvent` em `play` segue os mesmos princípios

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Auto-waiting](https://playwright.dev/docs/actionability) — a tabela de checagens e suas definições
- [Actions](https://playwright.dev/docs/input) — `fill`, `press`, `check`, `selectOption`, `setInputFiles`, arrastar
- [Navigations](https://playwright.dev/docs/navigations) — `goto`, `waitForURL`, hidratação, o aviso sobre `networkidle`
- [Events](https://playwright.dev/docs/events) — o padrão de armar a espera antes da ação
- [Dialogs](https://playwright.dev/docs/dialogs) — o comportamento de dispensa automática
- [Locator (API)](https://playwright.dev/docs/api/class-locator) — `force`, `trial`, e `noWaitAfter` deprecado
