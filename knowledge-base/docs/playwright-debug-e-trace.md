---
Link: https://playwright.dev/docs/trace-viewer
tags:
 - playwright
 - testing
 - debugging
 - trace
 - agent-context
source: "Documentação oficial do Playwright — Trace viewer, UI Mode, Debugging Tests, Test generator"
verificado-em: 2026-08-20
---

# Playwright — Debug e Trace

> Satélite de [Playwright](playwright.md). Cobre como descobrir **por que** um teste falhou, em vez de adivinhar. É o satélite que uma skill deve carregar antes de alterar qualquer teste que já falha (`PW-DBG-01`).
>
> **A afirmação que organiza a nota.** Um teste que falha é evidência, não inconveniente. O trace contém, para cada ação: o DOM antes e depois, o log de actionability, a rede, o console e a linha de código. Nada disso precisa ser reconstruído por tentativa e erro — e reconstruir por tentativa é como um bug de produto se converte em teste verde.

---

## 1. Gravar

```ts
use: {
 trace: 'on-first-retry',
 screenshot: 'only-on-failure',
 video: 'retain-on-failure',
}
```

### 1.1 `trace` — os sete valores

A referência de API lista sete, não os cinco da página-guia:

| Valor | Significa |
| --- | --- |
| `'off'` | não grava |
| `'on'` | grava e guarda sempre — pesado, não recomendado |
| `'on-first-retry'` | grava e guarda só na primeira retry — **o default recomendado** |
| `'on-all-retries'` | grava e guarda em toda retry |
| `'retain-on-failure'` | grava sempre, guarda só o que falhou |
| `'retain-on-first-failure'` | grava só a **primeira** execução (não as retries), guarda se falhou |
| `'retain-on-failure-and-retries'` | grava sempre, guarda o que falhou **e** toda retry |

Default: `'off'`.

**Como escolher:** `'on-first-retry'` é o equilíbrio — custo perto de zero quando tudo passa, trace disponível quando não. `'retain-on-failure'` custa a gravação em toda execução e serve quando o teste falha na primeira e passa na retry (o trace da primeira falha é o que interessa). `'on'` só para depurar uma coisa específica.

### 1.2 `video` — os sete valores

Os mesmos sete nomes de `trace`, com o mesmo significado. Default `'off'`.

Vídeo é inferior ao trace para diagnóstico — não tem DOM, nem rede, nem log de actionability. A fonte, na página de boas práticas, recomenda **trace em vez de vídeo/screenshot** para falha de CI. Vídeo serve para mostrar a alguém que não vai abrir um trace.

### 1.3 `screenshot` — os quatro valores

`'off'` · `'on'` · `'only-on-failure'` · `'on-first-failure'`. Default `'off'`.

### 1.4 Pela API (fora do runner)

```ts
await context.tracing.start({ screenshots: true, snapshots: true });
const page = await context.newPage;
await page.goto('/');
await context.tracing.stop({ path: 'trace.zip' });
```

É o caminho para gravar trace num `globalSetup` — que, por não ter trace automático, é justamente onde a falha fica opaca ([Playwright - Fixtures](playwright-fixtures.md) § 8):

```ts
try {
 await context.tracing.start({ screenshots: true, snapshots: true });
 // … setup …
 await context.tracing.stop({ path: './test-results/setup-trace.zip' });
} catch (erro) {
 await context.tracing.stop({ path: './test-results/failed-setup-trace.zip' });
 throw erro;
}
```

---

## 2. Abrir

```bash
npx playwright show-trace test-results/…/trace.zip
npx playwright show-trace https://exemplo.com/trace.zip
npx playwright show-report # e clicar no trace anexado
```

Ou arrastar o `.zip` em **[trace.playwright.dev](https://trace.playwright.dev)** — é uma PWA, o arquivo não sai da máquina.

**Em CI:** o trace vai anexado ao relatório HTML. O caminho é baixar o artefato `playwright-report` e rodar `npx playwright show-report <pasta>` ([Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) § 6).

---

## 3. Ler

As abas, e o que cada uma responde:

| Aba | Responde |
| --- | --- |
| **Actions** | que locator foi usado, quanto durou, DOM antes/depois |
| **Screenshots** | filmstrip com linha do tempo |
| **Snapshots** | DOM em Before / Action / After, com o alvo destacado |
| **Source** | a linha de código da ação selecionada |
| **Call** | duração, locator, strict mode, teclas |
| **Log** | o que o Playwright fez por dentro — rolou até a viewport, esperou visibilidade, esperou estabilidade |
| **Errors** | a mensagem, marcada na linha do tempo e na fonte |
| **Console** | log do browser e do arquivo de teste |
| **Network** | requisições por tipo, status, método, duração, tamanho |
| **Metadata** | browser, viewport, duração |
| **Attachments** | diff de imagem, com slider |

**O caminho de leitura que resolve mais rápido**, em quatro passos:

1. **Errors** — qual ação falhou.
2. **Log** daquela ação — *em qual checagem* ela travou. "waiting for element to be visible" é diferente de "element is not stable" e de "element intercepts pointer events". As três têm causas e correções distintas ([Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) § 1).
3. **Snapshot Before** — o que estava na tela naquele instante. Aqui se descobre a maioria dos casos: modal aberto, spinner ainda girando, tela de erro, ou a página de login que ninguém esperava.
4. **Network** — se a tela está incompleta, qual requisição falhou ou não voltou.

> O passo 2 é o que o trace tem e nenhum `console.log` dá. "Element intercepts pointer events" diz exatamente que há um overlay — e é a diferença entre remover o overlay e aplicar `force: true` sobre um bug real (`PW-ACT-01`).

**`locator.describe`** melhora essa leitura, especialmente para um agente que vai processar o trace depois:

```ts
page.getByRole('row').filter({ hasText: 'NF-0042' }).describe('linha da nota em disputa');
```

---

## 4. UI mode

```bash
npx playwright test --ui
npx playwright test --ui-host=0.0.0.0 # Docker / Codespaces
npx playwright test --ui-port=8080 --ui-host=0.0.0.0
```

É o trace viewer com execução ao vivo. O que ele adiciona:

- **Watch mode** — o ícone de olho reexecuta ao salvar o arquivo.
- **Filtro** por nome, tag, project e status.
- **Pick locator** — passar o mouse no snapshot mostra o locator; clicar leva ao playground.
- **Pop out do DOM snapshot** em janela própria, com DevTools do browser.
- **Open in VS Code** na linha exata.

**A pegadinha:** setup project **não roda automaticamente** em UI mode. A suíte abre deslogada na primeira vez ([Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 2.4).

---

## 5. Depurar ao vivo

```bash
npx playwright test --debug # Inspector + browser
npx playwright test pedidos.spec.ts:42 --debug # um teste
npx playwright test --project=chromium --debug
PWDEBUG=console npx playwright test # helpers no console do DevTools
DEBUG=pw:api npx playwright test # log verboso da API
```

```ts
await page.pause; // breakpoint que abre o Inspector
```

Com `PWDEBUG=console` e um `page.pause`, o console do browser ganha um objeto `playwright`:

```js
playwright.$('.seletor')
playwright.locator('.seletor')
playwright.inspect('.seletor')
playwright.selector($0) // gera locator para o elemento selecionado no Elements
```

> **`--debug` implica `timeout=0` e `workers=1`** (`PW-DBG-02`). Ele não é modo de execução: é modo de inspeção. Medir tempo nele, ou concluir que "sob debug passa, então não é flake", é conclusão inválida — o timeout desligado é exatamente o que faz passar.

`slowMo` desacelera cada operação:

```ts
use: { launchOptions: { slowMo: 250 } }
```

Útil para assistir; inútil para diagnosticar, porque altera o timing que produz o defeito.

---

## 6. Codegen

```bash
npx playwright codegen http://localhost:3000
npx playwright codegen --device="iPhone 13" http://localhost:3000
npx playwright codegen --color-scheme=dark http://localhost:3000
npx playwright codegen --lang="pt-BR" --timezone="America/Sao_Paulo" http://localhost:3000
npx playwright codegen --geolocation="-23.5505,-46.6333" http://localhost:3000
npx playwright codegen --save-storage=auth.json http://localhost:3000
npx playwright codegen --load-storage=auth.json http://localhost:3000
npx playwright codegen --user-data-dir=/caminho/perfil http://localhost:3000
```

O gravador oferece **assert visibility**, **assert text** e **assert value**, mais a aba de aria snapshot, e o modo **Pick locator**.

**O valor real do codegen não é gerar o teste** — é gerar o **locator** na ordem de prioridade correta. Ele prioriza papel, texto e test id sozinho, o que resolve `PW-LOC-01` sem exigir disciplina.

**O que ele não faz:** estrutura. A saída é uma sequência linear de ações, sem page object, sem fixture, sem nome de teste que descreva comportamento. Tratar a saída do codegen como teste pronto é como acumular a dívida que [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) existe para evitar. O fluxo certo é: gravar → extrair locators → reescrever como teste.

O `--save-storage`/`--load-storage` é a forma de gravar num app autenticado sem refazer o login em cada sessão de codegen.

---

## 7. Regras — `PW-DBG-01` a `PW-DBG-06`

| ID | Regra |
| --- | --- |
| `PW-DBG-01` | Falha de CI **MUST** ser investigada pelo trace antes de qualquer alteração no teste. |
| `PW-DBG-02` | `--debug` **NEVER** serve para medir tempo nem para rodar suíte: ele força `timeout=0` e `workers=1`. |
| `PW-DBG-03` | Teste com mais de um passo de negócio **MUST** envolvê-los em `test.step`. † |
| `PW-DBG-04` | `console.log` **NEVER** substitui trace e `test.step` como instrumento de diagnóstico versionado. † |
| `PW-DBG-05` | `trace` **MUST** ser no mínimo `'on-first-retry'`; `video: 'on'` como substituto de trace **NEVER**. † |
| `PW-DBG-06` | Saída de `codegen` **NEVER** é commitada como teste sem reestruturação. † |

---

## 8. `test.step` — instrumentar de propósito

```ts
test('finaliza uma compra', async ({ page }) => {
 await test.step('escolhe o produto', async => {
 await page.goto('/produtos');
 await page.getByRole('link', { name: 'Café especial' }).click;
 });

 await test.step('adiciona ao carrinho', async => {
 await page.getByRole('button', { name: 'Adicionar ao carrinho' }).click;
 await expect(page.getByTestId('badge-carrinho')).toHaveText('1');
 });

 await test.step('finaliza', async => {
 await page.getByRole('link', { name: 'Finalizar' }).click;
 await page.getByLabel('Cartão').fill('4242424242424242');
 await page.getByRole('button', { name: 'Pagar' }).click;
 await expect(page.getByText('Pedido confirmado')).toBeVisible;
 });
});
```

Os passos aparecem no relatório e no trace como grupos. Num teste de 30 ações, é a diferença entre "falhou na ação 19" e "falhou ao finalizar" (`PW-DBG-03`).

Isto vale duplamente quando um **agente** vai ler o resultado: `test.step` dá ao healer a fronteira semântica de onde consertar, em vez de uma lista plana de cliques ([Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) § 4).

---

## 9. Antipadrões

### 9.1 Consertar o teste sem ler o trace

```ts
// ✗ o padrão mais comum, e o mais caro
// falhou → adiciona waitForTimeout → passa → commita
```

O defeito real continua no produto; o teste passou a não detectá-lo (`PW-DBG-01`, `PW-CORE-05`).

### 9.2 `console.log` como diagnóstico

```ts
// ✗
console.log('cheguei aqui');
console.log(await page.content);
```

O trace já tem o DOM inteiro, navegável, e por ação. O `console.log` fica no código depois (`PW-DBG-04`).

### 9.3 `trace: 'off'` em CI

Toda falha vira adivinhação, e o teste é alterado por hipótese (`PW-DBG-05`, `PW-CFG-02`).

### 9.4 `video: 'on'` como substituto de trace

Mais peso, menos informação: sem DOM, sem rede, sem log de actionability (`PW-DBG-05`).

### 9.5 Concluir que não é flake porque `--debug` passa

`--debug` desliga o timeout. Ele *sempre* passa (`PW-DBG-02`).

### 9.6 Commitar a saída do codegen

```ts
// ✗
test('test', async ({ page }) => {
 await page.goto('http://localhost:3000/');
 await page.getByRole('link', { name: 'Entrar' }).click;
 // … 40 linhas lineares, nome de teste "test", URL absoluta …
});
```

Três violações de uma vez: nome que não descreve nada (`PW-STR-04`), URL absoluta (`PW-CFG-05`), zero estrutura (`PW-DBG-06`).

### 9.7 `slowMo` no config versionado

```ts
// ✗ deixa a suíte inteira lenta em CI
use: { launchOptions: { slowMo: 250 } }
```

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.2 é a árvore de diagnóstico
- [Playwright - Ações e Auto-waiting](playwright-acoes-e-auto-waiting.md) — o log de actionability é o que a aba Log mostra
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — como o trace chega do CI até você
- [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) — onde `trace`/`video`/`screenshot` são declarados
- [Playwright - Estrutura de Testes](playwright-estrutura-de-testes.md) — `test.step` e por que codegen não é teste
- [Playwright - Agents, CLI e MCP](playwright-agents-cli-e-mcp.md) — o healer lê exatamente estes artefatos
- [Playwright - Locators](playwright-locators.md) — pick locator e a ordem de prioridade
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — `step` no Storybook resolve o problema análogo

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Trace viewer](https://playwright.dev/docs/trace-viewer) — gravação, abertura, as abas, a API de tracing
- [UI Mode](https://playwright.dev/docs/test-ui-mode) — flags, watch mode, pick locator
- [Debugging Tests](https://playwright.dev/docs/debug) — `--debug`, `PWDEBUG`, `page.pause`, `DEBUG=pw:api`
- [Test generator](https://playwright.dev/docs/codegen) — as flags de emulação e as asserções do gravador
- [TestOptions (API)](https://playwright.dev/docs/api/class-testoptions) — os sete valores de `trace` e `video`, os quatro de `screenshot`
- [Command line](https://playwright.dev/docs/test-cli) — `--debug` implica `timeout=0` e `workers=1`
- [Best Practices](https://playwright.dev/docs/best-practices) — trace em vez de vídeo para CI
