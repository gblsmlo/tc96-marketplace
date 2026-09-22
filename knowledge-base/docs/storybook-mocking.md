---
titulo: Storybook - Mocking
Link: https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-modules
tags:
  - storybook
  - mocking
  - msw
  - testing
  - agent-context
source: "Documentação oficial do Storybook — Mocking modules, Mocking network requests, framework TanStack React"
verificado-em: 2026-08-19
---

# Storybook — Mocking

> Satélite de [Storybook](storybook.md). Cobre as três coisas que se substitui numa story: **callback**, **módulo** e **rede**. A árvore de decisão está na § 5.4 do hub.
>
> **Uma divergência de caminho.** A camada de mocks automáticos para módulos `@tanstack/*` existe **só** sob `@storybook/tanstack-react` (§ 4). Sob [Storybook - React Vite](storybook-react-vite.md), todo mock é explícito. O resto da nota vale igual nos dois.
>
> Num design system bem desenhado, a maior parte das stories não precisa de nada disto — componente de `packages/ui` recebe dado por prop. Mocking entra quando a story sobe um nível: composição de página, componente que fala com o BFF, ou módulo que só existe no servidor.

---

## 1. As três substituições

| O que substituir | Ferramenta | Onde se declara |
| --- | --- | --- |
| callback que a story quer observar | `fn()` | `meta.args` |
| módulo do projeto ou pacote npm | `sb.mock()` | **só** `.storybook/preview.*` |
| requisição HTTP | MSW | `preview` + `beforeEach` |

A primeira é assunto de [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 2. As outras duas são esta nota.

---

## 2. `sb.mock()` — automock de módulo

### 2.1 O registro é de projeto

```tsx
// .storybook/preview.tsx
import { sb } from 'storybook/test';

sb.mock(import('../../../packages/ui/src/lib/sessao.ts'));
sb.mock(import('uuid'), { spy: true });

const preview = { /* … */ } satisfies Preview;
export default preview;
```

**Esta é a restrição que mais surpreende:** a fonte diz que só é possível registrar módulo mockado na configuração de nível de projeto, *"para garantir mocking consistente e performante em todas as stories"*. Um `sb.mock()` dentro de um arquivo de story não funciona — e não falha de forma óbvia (`SB-MOCK-01`).

A divisão de trabalho fica assim, e vale memorizar:

> **O preview decide *o quê* é mockado. A story decide *como ele se comporta*.**

### 2.2 `spy: true` × automock completo

| Forma | Efeito |
| --- | --- |
| `sb.mock(import('./x.ts'))` | **automock**: todo export vira mock do Vitest, sem implementação |
| `sb.mock(import('./x.ts'), { spy: true })` | mantém a implementação real, e permite observar e sobrescrever |

`spy: true` é o que se quer quando a função real é pura e barata, e você só precisa afirmar que ela foi chamada — ou trocar o retorno em uma story específica. Automock completo é para o que não pode rodar: cliente de banco, SDK que abre socket, módulo que lê `process.env` de servidor (`SB-MOCK-05`).

### 2.3 Regras do caminho

Para módulo local, a fonte exige: **caminho relativo, com extensão, sem alias** (`SB-MOCK-02`).

**Relativo ao arquivo que chama** — ou seja, a `.storybook/preview.tsx`, já que é o único lugar onde `sb.mock()` pode ser registrado (`SB-MOCK-01`). Não é relativo à raiz do pacote nem ao componente.

> **A extensão `.ts` no specifier atrita com TypeScript.** Importar `'./x.ts'` num projeto TS exige configuração de compilador que a fonte do Storybook não nomeia. Registrado em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md) — se o typecheck reclamar, o problema é esse, não o `sb.mock`.

```ts
sb.mock(import('../src/lib/sessao.ts'));   // ✅
sb.mock(import('@escopo/ui/lib/sessao'));  // ❌ alias
sb.mock(import('../src/lib/sessao'));      // ❌ sem extensão
```

**No monorepo isso dói.** `apps/storybook/.storybook/preview.tsx` mockando algo de `packages/ui` produz um caminho relativo longo e frágil — e é o único formato aceito. Duas mitigações:

1. **Mockar o mínimo.** Se a story precisa mockar um módulo profundo de outro pacote, geralmente o componente é que está buscando dado sozinho. Ver [React - Patterns](react-patterns.md).
2. **Mockar na fronteira do pacote**, não no arquivo interno: o módulo que o `packages/ui` exporta, não o detalhe que ele usa por dentro.

Pacote npm é pelo nome, sem essas restrições: `sb.mock(import('uuid'))`.

### 2.4 Comportamento por story, com `mocked()`

```tsx
import { mocked } from 'storybook/test';
import { obterUsuarioDaSessao } from '../src/lib/sessao';

export const UsuarioAdministrador: Story = {
  beforeEach: async () => {
    mocked(obterUsuarioDaSessao).mockReturnValue({ nome: 'Ada', papel: 'admin' });
  },
};

export const SessaoExpirada: Story = {
  beforeEach: async () => {
    mocked(obterUsuarioDaSessao).mockReturnValue(null);
  },
};
```

`mocked()` dá acesso **tipado** ao mock. Os métodos verificados na fonte:

| Método | Para que |
| --- | --- |
| `mockReturnValue(v)` | retorno síncrono |
| `mockResolvedValue(v)` | resolução assíncrona |
| `mockImplementation(fn)` | implementação própria |

O comportamento vive em `beforeEach`, não no corpo do módulo de story — o corpo não roda de forma confiável (`SB-CORE-06`, `SB-MOCK-04`).

### 2.4.1 Asseverar que o módulo foi chamado

O caso que a árvore de decisão do hub roteia para cá, e que a fonte não exemplifica: *cliquei, e a função importada do módulo foi chamada*.

```tsx
import { expect, mocked } from 'storybook/test';
import { concluirTarefa } from '../src/lib/tarefas';

export const ConcluiTarefa: Story = {
  beforeEach: async () => {
    mocked(concluirTarefa).mockResolvedValue(undefined);
  },
  play: async ({ canvas, userEvent }) => {
    const botao = await canvas.findByRole('button', { name: 'Concluir' });
    await userEvent.click(botao);
    await expect(mocked(concluirTarefa)).toHaveBeenCalledWith('1');
  },
};
```

Duas diferenças em relação ao spy de prop (`SB-TEST-03`): o alvo vem de `mocked(fn)`, não de `args.onX`; e o registro do mock está no `preview`, não neste arquivo (`SB-MOCK-01`).

`findByRole` porque a lista vem da rede — ver [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 2.3.

**Composição não verificada:** que `mocked()` funcione dentro de `play` (e não só em `beforeEach`), e que `toHaveBeenCalledWith` opere sobre automock do `sb.mock` do mesmo jeito que sobre `fn()`, são leituras coerentes com a fonte mas **sem exemplo próprio nela**. Registrado em [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md).

### 2.5 `__mocks__`

Alternativa ao automock: um arquivo de mock ao lado do módulo.

| Alvo | Onde fica |
| --- | --- |
| módulo local `lib/sessao.ts` | `lib/__mocks__/sessao.js` |
| pacote `uuid` | `__mocks__/uuid.js`, na raiz do projeto |

**Restrição literal da fonte:** esses arquivos precisam ser escritos em **JavaScript (não TypeScript) com ES Modules (não CJS)**, e exportar os mesmos named exports do original (`SB-MOCK-03`). É a regra mais fácil de violar por hábito, porque todo o resto do repositório é TS.

### 2.6 Subpath imports — a alternativa do Node

Terceiro caminho, baseado em condição de import do próprio Node:

```json
// package.json
{
  "imports": {
    "#lib/sessao": {
      "storybook": "./lib/sessao.mock.ts",
      "default": "./lib/sessao.ts"
    }
  }
}
```

```ts
// lib/sessao.mock.ts
import { fn } from 'storybook/test';
import * as real from './sessao';

export const obterUsuarioDaSessao = fn(real.obterUsuarioDaSessao)
  .mockName('obterUsuarioDaSessao');
```

O código da aplicação passa a importar `#lib/sessao`, e a resolução muda conforme a condição. Vantagem: o arquivo de mock pode ser TypeScript. Custo: mexe no código de produção, e todo import precisa usar o alias `#`.

### 2.7 O que não dá para desfazer

A fonte registra que **o grafo de módulos é fixo no build de produção**, sem possibilidade de "desmockar". Um módulo registrado em `sb.mock()` está mockado para o Storybook inteiro — o que uma story pode fazer é definir comportamento, inclusive delegando ao real via `spy: true`.

### 2.8 Regras — `SB-MOCK-01` a `SB-MOCK-05`

| ID | Regra |
| --- | --- |
| `SB-MOCK-01` | `sb.mock()` **MUST** ser chamado apenas em `.storybook/preview.*`. Em arquivo de story, **NEVER**. |
| `SB-MOCK-02` | Caminho de módulo local em `sb.mock()` **MUST** ser relativo e com extensão, sem alias. |
| `SB-MOCK-03` | Arquivo em `__mocks__` **MUST** ser JavaScript com ESM. TypeScript ou CJS **NEVER**. |
| `SB-MOCK-04` | Comportamento de mock **MUST** ser definido em `beforeEach`, via `mocked()`. |
| `SB-MOCK-05` | `{ spy: true }` **MUST** ser usado quando a implementação real deve continuar rodando. |

---

## 3. Rede, com MSW

### 3.1 Instalação e registro

```bash
npm install msw msw-storybook-addon --save-dev
npx msw init ./public --save
```

```ts
// .storybook/main.ts
staticDirs: ['../public'],
```

```tsx
// .storybook/preview.tsx
import { mswLoader } from 'msw-storybook-addon/csf3';

const preview = {
  loaders: [mswLoader()],
} satisfies Preview;
```

O `staticDirs` não é opcional: o MSW precisa que o service worker seja servido como estático (`SB-CFG-05`).

### 3.2 Handlers por story

```tsx
import { http, HttpResponse } from 'msw';

export const ListaCarregada: Story = {
  beforeEach({ msw }) {
    msw.use(
      http.get('https://api.exemplo/tarefas', () => HttpResponse.json(tarefas)),
    );
  },
};

export const ErroDoServidor: Story = {
  beforeEach({ msw }) {
    msw.use(
      http.get('https://api.exemplo/tarefas', () => new HttpResponse(null, { status: 500 })),
    );
  },
};
```

Para o estado de **carregando**, a fonte usa `delay` do próprio MSW dentro do resolver:

```tsx
import { delay, http, HttpResponse } from 'msw';

export const Carregando: Story = {
  beforeEach({ msw }) {
    msw.use(
      http.get('https://api.exemplo/tarefas', async () => {
        await delay(800);
        return HttpResponse.json(tarefas);
      }),
    );
  },
};
```

GraphQL segue a mesma forma com `graphql.query(...)`.

**Níveis.** A fonte afirma que `beforeEach` com handlers vale também no `meta` (todas as stories do arquivo) e no `preview` (todo o projeto) — mas **só exemplifica o nível de story**. A sintaxe dos outros dois não foi verificada aqui. Sem handler default no projeto, uma story que não declara `msw.use()` faz requisição não interceptada, e o que acontece então não é documentado.

**A API mudou na v3 do addon.** O padrão antigo `parameters.msw.handlers` foi substituído por `mswLoader()` mais `beforeEach({ msw })`. Exemplo com `parameters.msw` é de versão anterior.

### 3.3 Por que a story de erro importa

`ErroDoServidor` acima não é caso de borda: é o estado que o design system precisa mostrar e que o time esquece de desenhar. É também onde a ponte com o React vale: erro esperado é **estado**, não exceção lançada para um boundary — `REACT-ASYNC-09` em [React - Suspense e Assincronia](react-suspense-e-assincronia.md).

E é onde a ponte com o backend vale: nem o cliente `hc` do Hono nem o Eden Treaty do Elysia lançam em status de erro. Uma `queryFn` ingênua deixa a query em `success` com o erro dentro de `data`. Se a story de erro renderiza o estado de sucesso, o defeito pode estar aí, não no mock — ver [Hono - Validação e RPC](hono-validacao-e-rpc.md) e [Elysia - Schema e Eden](elysia-schema-e-eden.md).

### 3.4 Regra — `SB-MOCK-07`

| ID | Regra |
| --- | --- |
| `SB-MOCK-07` | O tipo da resposta mockada **MUST** reusar o tipo exportado pelo servidor. Redigitar o shape à mão **NEVER**. † |

---

## 4. Módulos server-only

Story que alcança código de servidor quebra no browser com erro de módulo Node — `node:fs`, `node:crypto`, driver de banco. A doc do framework TanStack descreve três camadas:

1. **Mocks de framework** — automáticos para os módulos `@tanstack/*`. **Só no caminho `tanstack-react`**: sob `react-vite` esta camada não existe, e o mock precisa ser declarado (`SB-RV-07`).
2. **Mock de aplicação** — `sb.mock()` no preview, com arquivo em `__mocks__` quando preciso.
3. **Identificação do módulo** — ler o *stack trace* do erro para descobrir **qual** dependência Node foi puxada.

O passo 3 é o que se pula e é o que resolve. O erro não diz "seu componente importa o client de banco"; ele diz que `node:fs` não existe. O caminho é ler o rastro até achar o módulo do seu código que iniciou a cadeia, e mockar **esse**, não o módulo do Node.

```tsx
// .storybook/preview.tsx
import { sb } from 'storybook/test';
sb.mock(import('../../../apps/web/src/db/client.ts'));
```

**Não existe conserto no browser.** O módulo não pode existir no bundle: ou é mockado, ou a árvore de import do componente precisa mudar (`SB-MOCK-06`).

> Num app com BFF separado — o desenho de [Backend no runtime Bun](backend-no-runtime-bun.md) — isso deveria ser raro por construção: `apps/web` fala com `apps/server` por HTTP e importa dele **só tipo**, apagado no build. Se uma story está puxando módulo de servidor, a suspeita primeira é import de valor onde deveria ser `import type`. Ver [Monorepo com Bun - estrutura e tooling](../pages/monorepo-com-bun-estrutura-e-tooling.md) § 2.

### 4.1 Regra — `SB-MOCK-06`

| ID | Regra |
| --- | --- |
| `SB-MOCK-06` | Módulo server-only alcançado pela árvore de import de uma story **MUST** ser mockado. Tratar o erro no browser **NEVER** resolve. |

---

## 5. Antipadrões

### 5.1 `sb.mock()` dentro do arquivo de story

O erro mais comum, porque é onde a intuição manda colocar. Registro é no preview (`SB-MOCK-01`).

### 5.2 Mock em `__mocks__` escrito em TypeScript

Todo o repositório é TS, então a mão escreve `.ts` por reflexo. A fonte exige JavaScript com ESM (`SB-MOCK-03`).

### 5.3 Comportamento de mock no topo do módulo

```tsx
mocked(obterUsuario).mockReturnValue({ nome: 'Ada' }); // ❌ fora de beforeEach
export const Default: Story = {};
```

O corpo do módulo não é ponto de execução confiável, e o valor vaza para as outras stories do arquivo (`SB-MOCK-04`).

### 5.4 Mockar `fetch` na mão

Substituir `globalThis.fetch` num decorator ignora cache, cancelamento e a camada de rede que a app usa de verdade. É MSW.

### 5.5 Automockar o que só precisava de spy

Automock completo de um módulo com dez exports, quando a story só queria observar um. O resto vira `undefined` e a story quebra em lugar aparentemente aleatório (`SB-MOCK-05`).

### 5.6 Redigitar o shape da resposta no mock

```tsx
const tarefas = [{ id: '1', titulo: 'x', feito: false }]; // ❌ tipo solto
```

Quando o servidor muda o contrato, o mock continua verde e a story documenta uma API que não existe mais (`SB-MOCK-07`).

---

## Relacionados

- [Storybook](storybook.md) — hub
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — `fn()`, `mocked()` dentro da `play`
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — `beforeEach` e limpeza
- [Storybook - TanStack React](storybook-tanstack-react.md) — mocks de router e de server function
- [Storybook - React Vite](storybook-react-vite.md) — onde `routeOverrides` não existe e o mock de módulo o substitui
- [React - Patterns](react-patterns.md) — de quem é a responsabilidade de buscar dado
- [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — os tipos que o mock deve reusar
- [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) — o cache que o mock alimenta

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [Mocking modules](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-modules)
- [Mocking network requests](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests)
- [Storybook for TanStack React](https://storybook.js.org/docs/get-started/frameworks/tanstack-react)

**Notas de verificação:**

- **`sb.mock()` só pode ser registrado na configuração de projeto.** A fonte dá a razão: consistência e performance em todas as stories.
- **Caminho local precisa ser relativo, com extensão e sem alias.** É a restrição que mais atrita com monorepo.
- **Arquivos em `__mocks__` precisam ser JavaScript com ESM** — não TypeScript, não CJS — e exportar os mesmos named exports.
- **`spy: true` preserva a implementação real** e ainda permite observar e sobrescrever; o default (`spy: false`) substitui todo export por mock do Vitest.
- **O grafo de módulos é fixo no build de produção**: não há como desmockar.
- **A API do `msw-storybook-addon` v3 é `mswLoader()` + `beforeEach({ msw })`**, não `parameters.msw.handlers`.
- **`npx msw init ./public --save` e `staticDirs`** são parte obrigatória do setup de MSW.
- **O framework TanStack descreve três camadas para dependência server-only**, e o passo de identificar o módulo pelo stack trace é explícito.
- **`delay` do MSW é a forma da fonte para simular latência** e produzir estado de carregando.
- **Handlers de nível `meta` e projeto são afirmados pela fonte, sem exemplo de sintaxe.**
- **Não há exemplo, em nenhuma página verificada, de asserção sobre módulo mockado** — a § 2.4.1 compõe a partir de peças verificadas e está marcada como tal.
