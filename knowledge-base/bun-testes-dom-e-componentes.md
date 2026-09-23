---
titulo: Bun - Testes - DOM e Componentes
Link: https://bun.com/docs/test/dom
tags:
  - bun
  - testing
  - react
  - agent-context
source: "Documentação oficial — https://bun.com/docs/test/dom e https://bun.com/docs/guides/test/testing-library"
verificado-em: 2026-08-20
---

# Bun - Testes - DOM e Componentes

> A receita executável de ponta a ponta: happy-dom por preload, Testing Library, `expect.extend` (o passo que costuma faltar), tipos · interação com `userEvent` e a escolha entre `findBy*`, `waitFor` e `act` · **o que o componente importa e `bun test` não resolve como o Vite** · stubs do que happy-dom não implementa · como a isolação muda o registro do DOM.
>
> **Não cobre:** o que asseverar num teste de componente · stories e teste em browser real ([Storybook - Testes e Interações](storybook-testes-e-interacoes.md)) · resolução de `paths` e `import.meta.env` no geral ([Bun - Runtime e APIs](bun-runtime-e-apis.md)).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `07`, `12`, `25`, `26`)

---

## 1. Conceito: o runner não traz DOM, e isso é uma decisão sua

`document` e `window` não existem em `bun test`. Não há chave `environment: "jsdom"` para ligar, porque não há camada de configuração de ambiente: **o DOM entra como código, num script de preload, registrando globais antes de qualquer teste rodar.**

Isso tem uma consequência de desenho que vale mais que a receita: como o DOM é opt-in por preload e o preload é global, **a suíte inteira tem DOM ou não tem**. Não existe "este arquivo roda com jsdom e aquele sem". Se o projeto tem backend e frontend na mesma suíte, o backend também paga o registro do DOM — e a saída, quando isso incomoda, é separar por `root`/`pathIgnorePatterns` e rodar dois comandos ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 2).

A escolha de implementação é **happy-dom**, que a fonte apresenta como *"leaner and faster"* que o jsdom e trata como o substituto de `testEnvironment: "jsdom"`. **jsdom não é documentado como alternativa suportada:** nada impede tecnicamente injetar seus globais, mas não há receita verificada.

---

## 2. Setup: dois preloads, e a ordem entre eles importa

```bash
bun add -d @happy-dom/global-registrator \
           @testing-library/react @testing-library/dom @testing-library/jest-dom \
           @testing-library/user-event
```

```ts
// test/happydom.ts — preload 1: injeta os globais de browser
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
```

```ts
// test/testing-library.ts — preload 2: registra matchers e limpeza
import { afterEach, expect } from "bun:test";
import { cleanup } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";

expect.extend(matchers);

afterEach(() => {
  cleanup();
  document.body.innerHTML = "";
});
```

```toml
# bunfig.toml
[test]
preload = ["./test/happydom.ts", "./test/testing-library.ts"]
```

```ts
// test/matchers.d.ts — só tipos; sem isto, `toHaveTextContent` não existe para o tsc
import { TestingLibraryMatchers } from "@testing-library/jest-dom/matchers";
import { Matchers, AsymmetricMatchers } from "bun:test";

declare module "bun:test" {
  interface Matchers<T> extends TestingLibraryMatchers<typeof expect.stringContaining, void> {}
  interface AsymmetricMatchers extends TestingLibraryMatchers<any, any> {}
}
```

```tsx
/// <reference lib="dom" />
import { test, expect } from "bun:test";
import { render, screen } from "@testing-library/react";
import { ResumoCarrinho } from "./ResumoCarrinho";

test("mostra o total do carrinho", () => {
  render(<ResumoCarrinho itens={[{ id: "1", preco: 1990 }]} />);
  expect(screen.getByRole("status")).toHaveTextContent("R$ 19,90");
});
```

Quatro detalhes, e três deles são a diferença entre a receita funcionar e não funcionar:

**1. `expect.extend(matchers)` é obrigatório.** `import "@testing-library/jest-dom"` sozinho — a forma que funciona no Jest e no Vitest — **não** registra os matchers em `bun:test`. Sem `expect.extend`, `toHaveTextContent` e `toBeInTheDocument` não existem em runtime.

> **Divergência interna da fonte, registrada.** A página curta de DOM testing mostra `import '@testing-library/jest-dom'` no arquivo de teste e num `test-setup.ts`; o guia dedicado de Testing Library usa a forma explícita, importando de `@testing-library/jest-dom/matchers` e passando por `expect.extend`. As duas páginas da mesma doc divergem. Esta nota segue o guia — é a forma que funciona.

**2. Dois arquivos de preload, nesta ordem, e não um só.** A fonte declara o motivo: num preload único, os pacotes `@testing-library/*` precisam ser carregados com `await import()` **depois** de `GlobalRegistrator.register()`, porque eles inspecionam globais de browser no momento em que são avaliados. Dois arquivos na ordem certa resolvem sem `await import()`.

**3. `/// <reference lib="dom" />` no topo do arquivo de teste** resolve *"Cannot find name 'document'"*. É problema de tipo, não de runtime — e é por arquivo.

**4. `cleanup()` em `afterEach`, no preload.** O `document` é compartilhado entre testes do mesmo arquivo: sem limpeza, `getByRole` passa a encontrar elementos renderizados pelo teste anterior e falha por "found multiple elements". A doc mostra `cleanup()` mais `document.body.innerHTML = ""` — a segunda linha cobre o que foi escrito no DOM fora do `render`.

| ID | Regra |
| --- | --- |
| `BUN-TEST-07` | Registro de DOM (`GlobalRegistrator.register()`) **MUST** acontecer em `[test] preload`, **NEVER** dentro de um arquivo de teste. |
| `BUN-TEST-12` | Matcher de `@testing-library/jest-dom` **MUST** ser registrado com `expect.extend` num preload — o `import` do pacote sozinho não registra nada em `bun:test`. |
| `BUN-TEST-25` | `GlobalRegistrator.register()` e os pacotes `@testing-library/*` **MUST** viver em preloads separados, nesta ordem — num arquivo único, os pacotes **MUST** ser carregados por `await import()` depois do registro. |
| `BUN-TEST-26` | Arquivo que renderiza componente **MUST** ter `cleanup()` em `afterEach` (de preferência no preload) — o `document` é compartilhado entre os testes do arquivo. |

### DOM sem React

A receita completa é para componente. Para testar código que só manipula DOM, o preload 1 basta:

```ts
test("registra o custom element", () => {
  class Contador extends HTMLElement {
    constructor() { super(); this.innerHTML = "<p>0</p>"; }
  }
  customElements.define("app-contador", Contador);

  document.body.innerHTML = "<app-contador></app-contador>";
  expect(document.querySelector("app-contador p")?.textContent).toBe("0");
});
```

---

## 3. Interação: clicar, digitar, esperar

Nada aqui é específico do Bun — `userEvent`, `fireEvent`, `waitFor` e `act` são da Testing Library e funcionam sobre os globais que o happy-dom instalou. O que muda em `bun test` é só que não há ambiente para configurar.

```tsx
/// <reference lib="dom" />
import { test, expect } from "bun:test";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

test("adiciona o item ao carrinho ao clicar", async () => {
  const user = userEvent.setup();          // sempre antes do render
  render(<BotaoAdicionar produtoId="p-1" />);

  await user.click(screen.getByRole("button", { name: /adicionar/i }));

  // findBy* já embute waitFor — prefira a ele em vez de waitFor + getBy*
  expect(await screen.findByRole("status")).toHaveTextContent("1 item");

  // waitFor para condição que não é "elemento existe"
  await waitFor(() => expect(screen.getByRole("button")).toBeDisabled());
});
```

| Precisa de | Use | Não use |
| --- | --- | --- |
| Simular um usuário (click, type, tab, hover) | `userEvent` — dispara a sequência real de eventos | `fireEvent.click` para fluxo de usuário |
| Disparar **um** evento específico (`change` de input controlado por lib, `scroll`) | `fireEvent` | `userEvent` para um evento sintético isolado |
| Esperar algo aparecer | `await screen.findBy*` | `waitFor` + `getBy*` — mais verboso, mesma coisa |
| Esperar condição que não é "elemento existe" | `await waitFor(() => expect(…))` | `Bun.sleep` — teste com sleep é teste flaky |
| Envolver atualização de estado feita fora de evento | `act()` | envolver `render`/`userEvent`, que já chamam `act` internamente |

**`userEvent` é assíncrono.** `user.click` devolve Promise, e esquecer o `await` produz asserção que roda antes do re-render. Combinado com `BUN-TEST-06` (asserção em callback sem contagem), é o par de erros mais comum em teste de componente.

**Sobre relógio:** `@testing-library/react` detecta fake timers e avança o relógio em vez de esperar tempo real — o que torna `useFakeTimers` viável em teste de componente com debounce ([Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 5).

---

## 4. O que o componente importa e `bun test` não resolve como o Vite

Esta é a lista que decide se a receita funciona no **seu** componente. Cada linha é algo que o Vite fazia por plugin e que aqui é outra coisa — ou nada.

| No componente | Sob `bun test` | Estado |
| --- | --- | --- |
| `import logo from "./logo.svg"` | loader `file`: Bun verifica que o arquivo existe e o import resolve para o **caminho absoluto em disco** | verificado — é uma **string diferente** da URL que o Vite entrega; asserção sobre o `src` renderizado precisa refletir isso |
| `import { ReactComponent as Logo } from "./logo.svg"` (SVGR) | **não funciona** — é plugin do Vite, e Bun não tem a cadeia de plugins do Vite | verificado por ausência |
| `import "./Botao.css"` | **não verificado** — a fonte documenta `css` como loader e o comportamento no *bundler*, e não declara o que acontece no runtime | ver a sonda abaixo |
| `import estilos from "./Botao.module.css"` (CSS Modules) | **não verificado** | idem |
| `import texto from "./termos.txt"` | loader `text`: o conteúdo chega como string | verificado |
| `import dados from "./seed.json"` | parseado, como no Vite | verificado |
| `import { api } from "@/lib/api"` | resolvido por `compilerOptions.paths`; **`resolve.alias` do `vite.config.ts` é ignorado** | verificado — [Bun - Runtime e APIs](bun-runtime-e-apis.md) § 2 |
| `import.meta.env.VITE_API_URL` | **funciona** se a variável estiver no ambiente ou num `.env` que o Bun carregue — Bun não filtra por prefixo | verificado |
| `import.meta.env.MODE` / `.DEV` / `.PROD` / `.BASE_URL` | **`undefined`** — são constantes injetadas pelo Vite; sob Bun, `import.meta.env` é `process.env` | verificado — [Bun - Runtime e APIs](bun-runtime-e-apis.md) § 4 |
| `<Componente />` (JSX) | nativo, sem plugin, desde que `compilerOptions.jsx` não seja `"preserve"` | verificado |

**A saída para os imports não verificados (CSS e CSS Modules):** não descubra em produção de teste. Rode uma sonda e veja o que acontece na sua versão:

```bash
echo 'import "./src/Botao.css"; console.log("ok");' > /tmp/probe.ts && bun /tmp/probe.ts
```

Se falhar ou trouxer algo inesperado, o remédio verificado é mapear a extensão para um loader inofensivo:

```toml
# bunfig.toml — trata .css como texto em vez de deixar o resultado indefinido
loader = { ".css" = "text" }
```

Isso desativa qualquer asserção sobre classe gerada por CSS Modules — o que, para um teste que observa comportamento, é o resultado certo de qualquer forma.

**E a saída que dispensa a lista inteira:** componente que recebe configuração por prop, e teste que renderiza o componente puro em vez do container, não toca em `import.meta.env` nem em asset. A lacuna acima é proporcional a quanto o componente depende do build.

---

## 5. Limites do happy-dom, e o que fazer com eles

O que não vem pronto: a própria doc mostra o preload **registrando stubs**, o que é o reconhecimento de que APIs de layout e de mídia não estão lá.

```ts
// test/happydom.ts — depois de GlobalRegistrator.register()
import { jest } from "bun:test";

global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: jest.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});
```

`ResizeObserver` e `matchMedia` são os dois que a fonte stuba explicitamente. **`IntersectionObserver` não é mencionado pela fonte** — se o componente usa lazy-load por viewport, assuma que precisa do mesmo tratamento e verifique antes.

E o limite que nenhum stub resolve: **nada disso mede.** `getBoundingClientRect` devolve zeros. Teste que depende de dimensão real, de layout ou de rolagem não é teste de unidade — é teste de browser, e o lugar dele é outro ([Storybook - Testes e Interações](storybook-testes-e-interacoes.md), ou Playwright).

---

## 6. Isolação e o registro do DOM

Sob `--isolate` — implícito em `--parallel` — a fonte declara que, entre arquivos, Bun cria um `globalThis` novo, limpa os registros de módulo, fecha servidores e sockets, e **reexecuta os scripts de preload** ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4). Consequência direta: **`GlobalRegistrator.register()` roda uma vez por arquivo de teste**, e cada arquivo ganha um `document` limpo.

O lado bom é grande: o vazamento de DOM entre arquivos — o `getByRole` que encontra dois elementos porque o arquivo anterior não limpou — deixa de ser possível por construção. `cleanup()` continua necessário **entre testes do mesmo arquivo** (`BUN-TEST-26`), e é por isso que ele mora no `afterEach` do preload.

**O que não foi verificado:** se `GlobalRegistrator.register()` é idempotente e qual o custo de repeti-lo por arquivo. A fonte do Bun declara que o preload é reexecutado; o comportamento do registrator sob reexecução é do happy-dom, e não há declaração a respeito. **Meça antes de concluir que `--parallel` acelera uma suíte de DOM:** com muitos arquivos pequenos, o custo de reconstruir o DOM por arquivo pode superar o ganho, e `--parallel --no-isolate` é a alternativa — ao preço de devolver o vazamento entre arquivos do mesmo worker.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `GlobalRegistrator.register()` dentro do arquivo de teste | registra tarde para módulos que checam `typeof window` no topo, e precisa ser repetido em cada arquivo | `[test] preload` — `BUN-TEST-07` |
| `import "@testing-library/jest-dom"` e esperar `toHaveTextContent` | o import sozinho não registra matcher em `bun:test`; o matcher não existe em runtime | `expect.extend(matchers)` no preload — `BUN-TEST-12` |
| Juntar happy-dom e Testing Library num preload só, com import estático | os pacotes inspecionam globais de browser na avaliação, antes do registro | dois preloads, nesta ordem — `BUN-TEST-25` |
| `@testing-library/react` sem `cleanup()` em `afterEach` | o `document` é compartilhado; `getByRole` encontra elementos do teste anterior | `cleanup()` + limpar `document.body` — `BUN-TEST-26` |
| `user.click(...)` sem `await` | `userEvent` é assíncrono; a asserção roda antes do re-render | `await user.click(...)` — § 3 |
| `waitFor` + `getBy*` para esperar elemento aparecer | mais verboso e com pior mensagem de erro que a forma pronta | `await screen.findBy*` — § 3 |
| `await Bun.sleep(300)` para esperar render | teste com sleep é flaky e lento | `findBy*` / `waitFor` — § 3 |
| Asserir sobre `import.meta.env.MODE`/`.DEV` num componente sob `bun test` | são constantes do Vite; sob Bun, `import.meta.env` é `process.env` e elas são `undefined` | receber configuração por prop — § 4 |
| Confiar em `resolve.alias` do `vite.config.ts` no teste | Bun não lê o `vite.config`; o import não resolve | declarar em `compilerOptions.paths` — § 4 |
| Asserção sobre `src` de imagem importada esperando URL do Vite | o loader `file` resolve para caminho absoluto em disco | asserir sobre presença/`alt`, não sobre a string do caminho — § 4 |
| Teste que depende de `getBoundingClientRect` real | happy-dom não mede; devolve zeros | teste de browser — § 5 |
| Assumir que `IntersectionObserver` existe porque `ResizeObserver` foi stubado | a fonte não menciona o primeiro | stubar e verificar — § 5 |
| Concluir que `--parallel` acelera a suíte de DOM sem medir | o DOM é reconstruído por arquivo; pode custar mais que o ganho | medir; considerar `--no-isolate` — § 6 |

---

## Checklist de revisão

- [ ] O registro de happy-dom está em `[test] preload`? → `BUN-TEST-07`
- [ ] Os matchers de `jest-dom` passam por `expect.extend`? → `BUN-TEST-12`
- [ ] Happy-dom e Testing Library estão em preloads separados, nesta ordem? → `BUN-TEST-25`
- [ ] Há `cleanup()` em `afterEach`? → `BUN-TEST-26`
- [ ] Todo `userEvent` é aguardado? → § 3
- [ ] As esperas usam `findBy*`/`waitFor`, nunca `sleep`? → § 3
- [ ] O componente sob teste recebe configuração por prop, em vez de ler `import.meta.env`? → § 4
- [ ] Os aliases estão em `compilerOptions.paths`, e `compilerOptions.jsx` não é `"preserve"`? → § 4
- [ ] Os stubs necessários (`ResizeObserver`, `matchMedia`, e `IntersectionObserver` se usado) estão no preload? → § 5
- [ ] O arquivo de teste tem `/// <reference lib="dom" />`? → § 2

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- — o que asseverar num teste de componente
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o mesmo componente testado em browser real
- [React.js](react-js.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) — `paths`, `import.meta.env`, loaders

## Fontes consultadas

Verificadas em **2026-08-20**: [DOM testing](https://bun.com/docs/test/dom) · [Using Testing Library with Bun](https://bun.com/docs/guides/test/testing-library) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Loaders](https://bun.com/docs/bundler/loaders) · [JSX](https://bun.com/docs/runtime/jsx) · [Bun 1.4](https://bun.com/blog/bun-v1.4) (fake timers e Testing Library).
