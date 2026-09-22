---
Link: https://storybook.js.org/docs/writing-tests
tags:
 - storybook
 - testing
 - vitest
 - acessibilidade
 - agent-context
source: "Documentação oficial do Storybook — Writing Tests, Interaction testing, Accessibility testing, Vitest addon, Portable stories"
verificado-em: 2026-08-19
---

# Storybook — Testes e Interações

> Satélite de [Storybook](storybook.md). Cobre **escrever** o teste. Operá-lo — o testing widget, cobertura e o job de CI — é [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md). Cobre a `play` function, `storybook/test`, o addon de acessibilidade, o addon do Vitest como runner, e portable stories.
>
> **Vale nos dois caminhos de framework.** O `@storybook/addon-vitest` exige um framework de Storybook baseado em Vite, e tanto `@storybook/tanstack-react` quanto `@storybook/react-vite` qualificam. Toda esta nota vale igual nos dois; só o token de import muda.
>
> A afirmação **5** do modelo mental é o que sustenta esta nota: o mesmo arquivo alimenta sidebar, docs e runner. Aqui é onde o runner cobra o preço — e devolve o benefício.

---

## 1. Conceito: três testes saem do mesmo arquivo

A doc descreve teste de UI como *"um teste que renderiza um componente no browser para alta fidelidade, simula interação como um teste E2E, e testa uma unidade de UI permitindo mock de implementação como um teste unitário"*. Da story pronta saem **três** camadas cobertas por esta doc, em ordem crescente de esforço — mais duas que existem e ficam fora do escopo:

| Camada | O que verifica | O que custa escrever |
| --- | --- | --- |
| **render (smoke)** | a story renderiza e falha se der erro | **nada** — vem de graça com a story |
| **interação** | comportamento após ação do usuário | uma `play` |
| **acessibilidade** | axe sobre a árvore renderizada | um parameter |
| **visual** | diferença de pixel contra baseline | ferramenta externa (Chromatic) — fora do escopo desta doc |

Existe ainda snapshot de markup, que a doc cita como forma de identificar mudança de marcação e erro de render.

**A camada de graça é a que mais se subestima.** Um catálogo com 80 stories já é uma suíte de 80 smoke tests no momento em que o runner existe. Nenhuma linha de teste foi escrita.

O que entra na rodada é decidido por tag: `test` é aplicada por default, e `'!test'` tira uma story do runner sem tirá-la da sidebar. Ver [Storybook - Stories e Args](storybook-stories-e-args.md) § 6.

---

## 2. `play`

### 2.1 Assinatura

`play` é assíncrona e roda **depois** do render. O contexto traz:

| Campo | O que é |
| --- | --- |
| `canvas` | queries do Testing Library com escopo na raiz da story |
| `canvasElement` | o elemento raiz, quando a query pronta não basta |
| `userEvent` | simulação de interação |
| `args` | os args da story — é aqui que se lê o spy |
| `step` | agrupa interações sob um rótulo |
| `mount` | renderiza; obrigatório quando há código a rodar antes do render |
| `context` | o contexto inteiro, para repassar a uma `play` composta (§ 2.4) |

```tsx
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import { expect, fn } from 'storybook/test';
import { CampoBusca } from './CampoBusca';

const meta = {
 component: CampoBusca,
 args: {
 onBuscar: fn,
 },
} satisfies Meta<typeof CampoBusca>;

export default meta;
type Story = StoryObj<typeof meta>;

export const BuscaPorTexto: Story = {
 play: async ({ args, canvas, userEvent, step }) => {
 await step('digitar o termo', async => {
 await userEvent.type(canvas.getByRole('searchbox'), 'ada');
 });

 await step('submeter', async => {
 await userEvent.click(canvas.getByRole('button', { name: 'Buscar' }));
 });

 await expect(args.onBuscar).toHaveBeenCalledWith('ada');
 },
};
```

Quatro pontos normativos nesse exemplo:

1. **Todo `expect` é `await`.** Não é estilo — é a diferença entre a asserção participar do teste e o teste terminar antes dela (`SB-TEST-01`).
2. **`onBuscar` é `fn` no `meta.args`.** O spy fica visível para o painel de ações, para a documentação e para a asserção. Declarar o spy dentro da `play` esconde ele das outras camadas (`SB-TEST-03`).
3. **As queries são por papel acessível.** `getByRole('searchbox')`, `getByRole('button', { name: … })`. Isso faz o teste falhar quando a acessibilidade quebra, o que é exatamente o que se quer de um design system (`SB-TEST-06`).
4. **`step` é rótulo, não estrutura.** Ele agrupa o log do painel de interações; a falha passa a dizer em qual etapa ocorreu.

### 2.2 `mount`: quando é obrigatório

Sem desestruturar `mount`, o Storybook **já começou a renderizar** quando a `play` roda. Se há código que precisa acontecer antes do render, ele chega tarde:

```tsx
export const NoDiaDosNamorados: Story = {
 play: async ({ mount, canvas }) => {
 MockDate.set('2026-06-12'); // antes do render
 await mount; // agora renderiza
 await expect(canvas.getByText('12 de junho')).toBeInTheDocument;
 },
};
```

A fonte lista três situações que exigem `mount`: rodar código antes do render, criar dado de mock dentro da `play` para passar ao componente, e frameworks/builders que transpilam para ES2017+ preservando `async/await` (`SB-TEST-02`).

> Para congelar relógio de forma que valha para várias stories, `beforeEach` no `meta` é mais limpo que `mount` em cada uma — ver [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) § 5.

### 2.3 Esperar o que ainda não está na tela

`play` roda **depois do render**, não depois da rede. Num componente que busca dado, o instante em que a `play` começa é o instante do estado de carregando — o conteúdo final ainda não existe no DOM. `getByRole` é síncrono e falha ali.

A forma correta é a query assíncrona:

```tsx
play: async ({ canvas, userEvent }) => {
 // espera o botão aparecer depois que a requisição resolve
 const botao = await canvas.findByRole('button', { name: 'Concluir' });
 await userEvent.click(botao);
},
```

| Prefixo | Aguarda? | Quando usar |
| --- | --- | --- |
| `findBy…` / `findAllBy…` | **sim** | o elemento aparece depois de uma operação assíncrona |
| `getBy…` / `getAllBy…` | não | o elemento já está no DOM no primeiro frame |
| `queryBy…` / `queryAllBy…` | não | verificar **ausência** sem lançar |

**Regra prática:** se a story depende de MSW, de `useQuery`, de `loader` ou de qualquer promise, a primeira query da `play` é `findBy…` (`SB-TEST-10`). Trocar por `getBy…` produz um teste que passa na máquina rápida e falha em CI — a pior categoria de instabilidade.

> `waitFor` e `waitForElementToBeRemoved` **não aparecem** nos exemplos de `play` da fonte verificada. Para esperar algo **sumir** — um spinner, por exemplo — a forma verificada aqui é asseverar a chegada do conteúdo final com `findBy…`, não a saída do spinner.

### 2.4 Compor `play` de outra story

```tsx
export const FormularioPreenchido: Story = { play: async ({ canvas, userEvent }) => { /* … */ } };

export const FormularioEnviado: Story = {
 play: async (context) => {
 const { canvas, userEvent } = context;
 await FormularioPreenchido.play?.(context);
 await userEvent.click(canvas.getByRole('button', { name: 'Enviar' }));
 },
};
```

Isso recria fluxo completo sem repetir passo. Dois detalhes que o exemplo torna explícitos: a `play` composta recebe **o contexto inteiro**, então vale receber `context` e desestruturar dele — e `play` é opcional em `StoryObj`, então a chamada precisa de `?.` para passar em `strict`.

### 2.5 `storybook/test`

| Export | Uso |
| --- | --- |
| `expect` | asserção — sempre `await` |
| `fn` | spy para callback em `args` |
| `userEvent` | interação |
| `mocked` | acesso tipado ao mock de módulo — [Storybook - Mocking](storybook-mocking.md) |
| `sb` | registro de automock, só no preview — [Storybook - Mocking](storybook-mocking.md) |

O import é **`storybook/test`, sem `@`** (`SB-CORE-01`).

Mocks criados por `fn` **não precisam de restauração manual**: a fonte afirma que o Storybook já os reseta entre stories.

### 2.6 Regras — `SB-TEST-01` a `SB-TEST-03`, `SB-TEST-06` a `SB-TEST-10`

| ID | Regra |
| --- | --- |
| `SB-TEST-01` | Toda chamada a `expect` dentro de `play` **MUST** ser aguardada com `await`. |
| `SB-TEST-02` | `play` que precisa rodar código **antes** do render **MUST** desestruturar `mount` e chamá-lo. |
| `SB-TEST-03` | Callback recebido por **prop** **MUST** ser `fn` declarado em `args`; a asserção lê `args.onX`. Função importada de módulo é outro caso — [Storybook - Mocking](storybook-mocking.md) § 2.4.1. |
| `SB-TEST-06` | Query de DOM **MUST** usar papel ou rótulo acessível quando existir. † |
| `SB-TEST-07` | Estado de teste compartilhado **MUST** ser restaurado na limpeza de `beforeEach`. `fn` é a exceção: o Storybook reseta. |
| `SB-TEST-08` | Interação de usuário **MUST** ser simulada por `userEvent`. † |
| `SB-TEST-09` | `play` **NEVER** assevera implementação interna — só o que o usuário observa. † |
| `SB-TEST-10` | Em story que depende de operação assíncrona, a primeira query **MUST** ser `findBy…`. `getBy…` **NEVER**. † |

---

## 3. Acessibilidade

### 3.1 O parâmetro

```tsx
//.storybook/preview.tsx
const preview = {
 parameters: {
 a11y: {
 test: 'error',
 },
 },
} satisfies Preview;
```

| Campo | Default | O que faz |
| --- | --- | --- |
| `context` | `'body'` | seletor CSS do que analisar |
| `config` | ver abaixo | vai para `axe.configure` |
| `options` | `{}` | vai para `axe.run` |
| `test` | `undefined` | `'off'` · `'todo'` · `'error'` |

**O default de `config` desabilita a regra `region`**, para não gerar falso **positivo** em story de componente isolado — um botão fora de landmark é o normal do Storybook, não defeito.

> **Por isso o exemplo acima não passa `config: {}`.** O exemplo da fonte inclui `context: 'body'`, `config: {}` e `options: {}` para mostrar os campos, mas passar um `config` vazio sobrescreve o default — e reativa `region`, que com `test: 'error'` reprova todas as stories de componente isolado. Declare só o que você realmente muda (`SB-CTX-01` garante que o resto sobrevive).

### 3.2 `test`, e a armadilha

| Valor | Efeito |
| --- | --- |
| `'off'` | não roda; a verificação manual continua disponível na UI |
| `'todo'` | roda, e a violação aparece como aviso na UI |
| `'error'` | roda, e a violação **falha** o teste |

**A armadilha:** a fonte é explícita de que com `'todo'` **não há erro, aviso nem saída em CI**. Um projeto inteiro em `'todo'` tem verificação de acessibilidade que só existe para quem abre a UI — em CI ela é silêncio (`SB-TEST-04`). `'todo'` é um TODO literal no código, e serve para rastrear dívida, não para ligar a checagem.

Num design system, o default deveria ser `'error'` no `preview`, com `'todo'` pontual e datado nos componentes que ainda não foram corrigidos. Como parameters fazem merge por chave (`SB-CTX-01`), isso é uma linha por story.

### 3.3 Desligar regra, excluir elemento, suspender story

```tsx
// desabilitar uma regra específica
parameters: {
 a11y: {
 config: {
 rules: [
 { id: 'image-alt', enabled: false },
 { id: 'autocomplete-valid', selector: '*:not([autocomplete="nope"])' },
 ],
 },
 },
}

// excluir parte da árvore
parameters: {
 a11y: { context: { include: ['body'], exclude: ['.sem-verificacao-a11y'] } },
}

// suspender a análise automática de uma story
export const SoParaVisual: Story = {
 globals: { a11y: { manual: true } },
};
```

Note que suspender é `globals`, não `parameters`.

### 3.4 Regras — `SB-TEST-04`

| ID | Regra |
| --- | --- |
| `SB-TEST-04` | Violação de a11y só quebra CI se `parameters.a11y.test` for `'error'`. `'todo'` **NEVER** produz saída em CI. |

---

## 4. O runner: `@storybook/addon-vitest`

### 4.1 O que ele faz

Um plugin do Vitest transforma cada story em teste, e o Vitest executa **em browser real via Playwright** — não em JSDOM ou HappyDOM. É a decisão de desenho que torna o resultado confiável para componente visual, e é também o que fixa os requisitos.

```bash
npx storybook add @storybook/addon-vitest
```

Requisitos verificados:

| Requisito | Valor |
| --- | --- |
| framework do Storybook | precisa usar Vite |
| Vitest | ≥ 3.0 **declarado** — mas o exemplo de config da doc já é o de Vitest 4, e o `latest` do npm é **4.1.11**. Instalação nova cai em 4; ver § 4.2 |
| MSW, se já estiver no projeto | ≥ 2.0 |

### 4.2 A config, e o corte entre Vitest 3 e 4

Este é o ponto onde a maior parte dos exemplos circulando está desatualizada. **Em Vitest 4 o provider deixou de ser string:**

```ts
// vitest.config.ts — Vitest 4
import { defineConfig, mergeConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';
import { storybookTest } from '@storybook/addon-vitest/vitest-plugin';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import viteConfig from './vite.config';

const dirname = path.dirname(fileURLToPath(import.meta.url));

export default mergeConfig(
 viteConfig,
 defineConfig({
 test: {
 projects: [
 {
 extends: true,
 plugins: [
 storybookTest({
 configDir: path.join(dirname, '.storybook'),
 storybookScript: 'bun run storybook --no-open',
 }),
 ],
 test: {
 name: 'storybook',
 browser: {
 enabled: true,
 provider: playwright({}),
 headless: true,
 instances: [{ browser: 'chromium' }],
 },
 setupFiles: ['./.storybook/vitest.setup.ts'],
 },
 },
 ],
 },
 }),
);
```

Em Vitest 3 (e abaixo de 3.2, via `defineWorkspace`) o mesmo campo é `provider: 'playwright'`, string. Copiar um exemplo de Vitest 3 para um projeto que instalou o `latest` produz erro de config que não diz o que está errado.

Opções do plugin:

| Opção | Default | O que faz |
| --- | --- | --- |
| `configDir` | `.storybook` | onde está a config do Storybook |
| `storybookScript` | — | script que sobe o Storybook em watch mode |
| `storybookUrl` | `http://localhost:6006` | onde o Storybook está servido |
| `disableAddonDocs` | `true` | desliga o parse de MDX durante os testes |

### 4.2.1 `.storybook/vitest.setup.ts`

O `setupFiles` da config aponta para esse arquivo, e ele é **gerado pelo `npx storybook add @storybook/addon-vitest`** — não se escreve à mão no fluxo normal. Ele é o que aplica as anotações de projeto (decorators globais, providers, CSS) aos testes; sem ele, as stories rodam sem o ambiente do `preview`, com o mesmo sintoma descrito na § 5 para portable stories.

**O conteúdo exato não foi verificado nesta doc:** a página do addon referencia o arquivo no exemplo de config e não o transcreve. Se precisar escrevê-lo à mão, o mecanismo é o mesmo de `setProjectAnnotations` da § 5 — mas confirme na fonte antes, em vez de deduzir daqui.

### 4.3 Rodar

```json
{
 "scripts": {
 "test-storybook": "vitest run --project=storybook"
 }
}
```

**`vitest run`, não `vitest`.** Sem o `run`, o Vitest entra em watch mode. A fonte dá as duas formas e aponta `vitest run` como a de CI.

**Os binários do Playwright precisam existir.** O `npx storybook add @storybook/addon-vitest` oferece instalá-los durante o setup; a fonte registra que dá para instalar a qualquer momento com `playwright install`. Numa imagem de CI limpa, esse passo é obrigatório — ou use uma imagem que já os traga.

Na UI do Storybook há um painel de teste na sidebar, com caixas para cobertura, acessibilidade e watch mode. Em CI, o exemplo da doc roda dentro do container `mcr.microsoft.com/playwright` com Node 22.12 — **sem tag de imagem declarada na fonte**, e sem Bun, o que importa se o `storybookScript` invocar `bun run`. Ver [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md).

### 4.4 Filtrar por tag

```ts
storybookTest({
 configDir: path.join(dirname, '.storybook'),
 tags: {
 include: ['test'],
 exclude: ['experimental'],
 skip: [],
 },
})
```

Quando uma tag aparece em `include` e `exclude`, **`exclude` vence**.

### 4.5 A fronteira com `bun test`

O addon exige Vitest. Ele **não roda sob `bun test`**, que é o runner do backend em `Bun - Testes`. O monorepo convive com dois runners por desenho:

| Runner | Cobre |
| --- | --- |
| `bun test` | `apps/server` — lógica de runtime Bun |
| `vitest --project=storybook` | as stories — componente em browser real |

Não é duplicação a eliminar: são níveis diferentes. E há um detalhe operacional em CI — o `--filter` do Bun não alcança o segundo, e filtro negado não funciona no Bun (ver `Monorepo com Bun - estrutura e tooling` § 4). Os dois comandos são invocados separadamente.

### 4.6 Regras — `SB-TEST-05`

| ID | Regra |
| --- | --- |
| `SB-TEST-05` | O addon-vitest exige Vitest e browser mode. `bun test` **NEVER** executa stories. |

---

## 5. Portable stories

Quando a story precisa entrar num teste que já existe, em vez de rodar pela UI:

```ts
import { composeStories, setProjectAnnotations } from '@storybook/tanstack-react';
import * as previewAnnotations from '../.storybook/preview';
import * as stories from './Button.stories';

const annotations = setProjectAnnotations([previewAnnotations]);
beforeAll(annotations.beforeAll);

const { Primary } = composeStories(stories);

test('renderiza o botão primário', async => {
 await Primary.run;
});
```

A story composta expõe `args`, `argTypes`, `id`, `parameters`, `play` e `run`. `run` monta o componente e executa o pipeline inteiro, **incluindo a `play`**.

`setProjectAnnotations` é o que traz as anotações de projeto (decorators globais, providers, CSS). **Sem ele, a story roda sem o ambiente do `preview`** — e o sintoma é um componente sem tema, sem provider, quebrando por motivo que não existe no Storybook.

A doc recomenda o addon-vitest como caminho padrão e mantém portable stories para quem prefere. O critério prático: se o teste é sobre o componente, use o addon; se a story é só um *fixture* dentro de um teste maior que já existe, portable story.

### 5.1 Snapshot de markup

Snapshot de DOM é o uso mais direto de portable story — e é como a fonte apresenta snapshot testing hoje:

```ts
import { composeStories } from '@storybook/tanstack-react';
import * as stories from './Button.stories';

const { Primary } = composeStories(stories);

test('snapshot do botão primário', async => {
 await Primary.run;
 expect(document.body.firstChild).toMatchSnapshot;
});
```

Três fatos verificados sobre isso:

- **Storyshots está deprecado.** O caminho atual é portable stories, com Vitest, Jest ou Playwright CT.
- **O addon-vitest não roda snapshot** — é a diferença dele em relação ao `test-runner` legado. Snapshot exige portable story.
- **A própria fonte desencoraja o caso geral:** snapshot captura HTML, não aparência, e ela diz que teste visual *"normalmente é a escolha melhor"* para componente de UI.

O critério que sobra: snapshot de markup vale para o que **não é visual** — a estrutura semântica de um componente de acessibilidade, a saída de um gerador de markup. Para aparência, é a ferramenta errada. Ver [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 1, onde aria snapshot resolve o caso semântico com diff legível.

---

## 6. Antipadrões

### 6.1 `expect` sem `await`

```tsx
play: async ({ canvas }) => {
 expect(canvas.getByRole('alert')).toBeInTheDocument; // ❌
},
```

O teste pode terminar antes da asserção resolver, e passa sem ter verificado nada. É a falha mais perigosa da lista porque produz verde falso (`SB-TEST-01`).

### 6.2 Spy criado dentro da `play`

```tsx
play: async ({ canvas, userEvent }) => {
 const aoClicar = fn; // ❌ não é o handler do componente
 await userEvent.click(canvas.getByRole('button'));
 await expect(aoClicar).toHaveBeenCalled;
},
```

Esse spy nunca foi passado ao componente. A asserção testa a variável local. O spy pertence a `meta.args` (`SB-TEST-03`).

### 6.3 Query por classe ou `data-testid` quando existe papel

```tsx
canvasElement.querySelector('.btn-primary') // ❌
canvas.getByRole('button', { name: 'Salvar' }) // ✅
```

A segunda quebra quando o botão perde o nome acessível — que é o defeito que o design system deveria pegar (`SB-TEST-06`).

### 6.4 Asseverar estado interno

`play` não deve inspecionar estado de hook, prop interna ou chamada de função que o usuário não observa. O que se assevera é o que aparece na tela e o que o componente chama para fora (`SB-TEST-09`).

### 6.5 Projeto inteiro em `a11y.test: 'todo'`

Dá sensação de cobertura e produz zero saída em CI (`SB-TEST-04`).

### 6.6 Copiar config de addon-vitest de exemplo antigo

`provider: 'playwright'` como string num projeto com Vitest 4. Ver § 4.2.

### 6.7 Portable story sem `setProjectAnnotations`

O componente roda sem decorator global. Falha por falta de provider, e o rastro aponta para o componente, não para a config do teste.

---

## Relacionados

- [Storybook](storybook.md) — hub
- [Storybook - Stories e Args](storybook-stories-e-args.md) — tags, e o que entra no runner
- [Storybook - Mocking](storybook-mocking.md) — `mocked`, `sb.mock` e MSW dentro do teste
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — `beforeEach` e limpeza
- `Bun - Testes` — o outro runner do monorepo
- `Monorepo com Bun - estrutura e tooling` — o comportamento de `--filter` em CI

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Writing Tests](https://storybook.js.org/docs/writing-tests)
- [Interaction testing](https://storybook.js.org/docs/writing-tests/interaction-testing)
- [Accessibility testing](https://storybook.js.org/docs/writing-tests/accessibility-testing)
- [Vitest addon](https://storybook.js.org/docs/writing-tests/integrations/vitest-addon)
- [Portable stories (Vitest)](https://storybook.js.org/docs/api/portable-stories/portable-stories-vitest)
- [Play function](https://storybook.js.org/docs/writing-stories/play-function)

**Notas de verificação:**

- **`mount` é obrigatório** quando há código antes do render; sem desestruturá-lo, o Storybook já começou a renderizar. A fonte lista três casos, incluindo builder que transpila para ES2017+.
- **Mocks `fn` não precisam de restauração manual** — o Storybook reseta entre stories.
- **O default do addon de a11y desabilita a regra `region`.**
- **`a11y.test: 'todo'` não produz nada em CI** — nem erro, nem aviso, nem saída. Afirmação literal da fonte.
- **Suspender a análise de a11y de uma story é `globals: { a11y: { manual: true } }`**, não `parameters`.
- **A config do addon-vitest mudou entre Vitest 3 e 4:** `provider: 'playwright'` (string) virou `provider: playwright({})` importado de `@vitest/browser-playwright`. O `latest` do npm é Vitest 4.1.11.
- **O requisito declarado é Vitest ≥ 3.0** — mas o exemplo corrente da doc já é o de Vitest 4.
- **O addon roda em browser real com Playwright**, não em JSDOM.
- **Em `tags`, `exclude` vence `include`** quando a mesma tag aparece nos dois.
- **`disableAddonDocs` é `true` por default** no plugin: MDX não é parseado durante os testes.
- **`run` de portable story executa a `play`**, não só o render.
- **A doc recomenda migrar de `test-runner` para `addon-vitest`.**
- **Queries assíncronas existem e são `findBy…`/`findAllBy…`** — a fonte mostra `await canvas.findByRole('button', { name: 'Submit' })` e marca só esses dois prefixos como aguardados. `waitFor` não aparece em `play` na página verificada.
- **`vitest run` é a forma de CI**; `vitest` puro entra em watch mode.
- **Os browsers do Playwright são instalação separada** — `playwright install`, oferecida durante o `storybook add`.
- **O conteúdo de `.storybook/vitest.setup.ts` não é transcrito pela fonte**; ele é gerado pelo comando de setup.
