---
Link: https://react.dev/reference/react
tags:
 - react
 - frontend
 - reference
 - agent-context
source: "Documentação oficial do React — react.dev/reference"
verificado-em: 2026-08-14
---
# React.js — referência conduzida

> **O que esta nota é.** O ponto de entrada único para React neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar React. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [react.dev/reference](https://react.dev/reference/react) vence, e esta nota deve ser corrigida.

Inventário verificado diretamente em react.dev em **2026-08-14**.
Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a seção 2 (modelo mental) uma vez. Depois use a seção 4 como índice e a seção 5 quando estiver na dúvida entre duas APIs. Os satélites são para leitura sob demanda, não em ordem.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| ----- | -------------------------------- | ------------------------------------------------------------------------- |
| 1 | Esta nota (seções 2, 5, 6) | Sempre que a tarefa envolver React |
| 2 | [React - Rules of React](react-rules-of-react.md) | Sempre que for **escrever ou modificar** componentes/Hooks |
| 3 | O satélite do domínio específico | Quando a tarefa toca uma API concreta — use a seção 4 para descobrir qual |
| 4 | [React - Patterns](react-patterns.md) | Decisões de estrutura: onde mora o estado, como compor, o que extrair |
| 5 | [React - Hooks](react-hooks.md) | Referência de assinatura, parâmetros e caveats de um Hook |

**Regra de economia de contexto:** nunca carregue todos os satélites.

### Convenções e vocabulário

**Todos os exemplos são TypeScript.** A doc assume TS em todo o corpus (anotações, unions discriminadas, generics). Em JS, ignore as anotações — nenhuma regra depende de tipos.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **valor reativo** | props, estado, contexto, e qualquer coisa calculada a partir deles |
| **snapshot** | o valor congelado de um estado dentro de um render específico |
| **identidade** (referencial) | se duas referências são o mesmo objeto (`Object.is`). Um objeto, array ou função criado no render tem identidade **nova** a cada render, mesmo com conteúdo igual — é por isso que `memo` falha e que dependências disparam |
| **igualdade rasa** (shallow) | comparar cada prop de primeiro nível por identidade, sem descer na estrutura. É o que `memo` faz |
| **lifting** (elevar estado) | mover o estado para o ancestral comum dos componentes que o leem |
| **prop drilling** | repassar uma prop por níveis intermediários que não a usam |
| **estado do servidor** | dado remoto que outra pessoa pode alterar sem você saber; oposto de estado de cliente |
| **race condition** | duas requisições em voo cuja ordem de chegada inverte, e a resposta velha sobrescreve a nova |
| **tearing** | partes da árvore lerem valores diferentes da mesma store no mesmo frame |
| **virtualização** (windowing) | renderizar só as linhas visíveis de uma lista longa, em vez de todas |

### As duas estruturas satélite

Além dos satélites temáticos, duas notas funcionam como sub-índices autônomos e apontam de volta para cá:

- **[React - Hooks](react-hooks.md)**: a superfície de API por Hook: assinatura, parâmetros, retorno, caveats. É referência de consulta.
- **[React - Patterns](react-patterns.md)**: padrões de composição e arquitetura, conectando a referência oficial aos Zettels conceituais já existentes no vault. É referência de decisão.

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro de React que um agente comete viola uma delas.

**1. Um componente é uma função pura de suas entradas.** Dadas as mesmas props, estado e contexto, ele produz o mesmo JSX. O React assume isso para poder renderizar, pausar, descartar e repetir trabalho livremente. É a base normativa de [React - Rules of React](react-rules-of-react.md) e do Zettel.

**2. Estado é um snapshot, não uma variável.** Dentro de um render, o valor do estado é fixo. `setState` não altera a variável atual — ele **agenda** um novo render. Por isso `setCount(count + 1)` duas vezes seguidas incrementa uma vez, e a forma updater `setCount(c => c + 1)` incrementa duas.

**3. Render e commit são fases distintas.** Render é o cálculo puro do JSX; commit é quando o React aplica as mudanças ao DOM. Efeitos rodam **depois** do commit. Nada que observe ou mexa no mundo externo pertence ao render.

**4. Reatividade vem de valores, não de dependências declaradas.** Props, estado e tudo derivado deles são valores reativos. A array de dependências de um Effect não é um controle de "quando rodar" — ela **descreve** o que o Effect lê. Ajustar a lista para evitar um loop trata o sintoma; o problema quase sempre é que o Effect não deveria existir.

**5. Efeito é sincronização com sistema externo — não é "código que roda depois".** Se não há um sistema fora do React (DOM não gerenciado, subscription, timer, socket, analytics), provavelmente não é um Effect. Isso elimina a maioria dos `useEffect` que um agente escreve por hábito.

> **Buscar dados na rede é a exceção que confunde.** Tecnicamente a rede é um sistema externo, mas fetch em `useEffect` é explicitamente proibido em código novo por `REACT-EFFECT-06` — ele não resolve race condition, cache, dedupe nem retry. Use uma biblioteca de data fetching. Ver § 6.1 e [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) § 3.

---

## 3. Fronteiras de pacote

Saber de onde algo é importado evita metade dos erros de import.

| Pacote | Contém | Roda onde |
| --- | --- | --- |
| `react` | Hooks, componentes built-in, APIs de definição de componente | Cliente e servidor |
| `react-dom` | Portais, flush síncrono, preloading de recursos, `useFormStatus` | Cliente |
| `react-dom/client` | `createRoot`, `hydrateRoot` | Cliente |
| `react-dom/server` | Renderização para stream/string | Servidor |
| `react-dom/static` | Pré-renderização estática | Build/servidor |

`use` é uma **API**, não um Hook — e por isso é a única coisa da lista que pode ser chamada condicionalmente. Ver [React - Suspense e Assincronia](react-suspense-e-assincronia.md).

---

## 4. Mapa da API

Superfície ativa do reference oficial — o que se usa em código novo. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** APIs legadas ou de uso raro que a doc não cobre — `createElement`, `cloneElement`, `isValidElement`, `Children`, `createRef`, `Component`, `PureComponent`, e a seção Legacy APIs do reference. Se a tarefa exigir uma delas, consulte react.dev diretamente: a ausência aqui significa "não verificado nesta doc", não "não existe".

### `react` — Hooks

| Hook | Para que serve | Satélite |
| --- | --- | --- |
| `useState` | Estado local declarado diretamente | [React - Estado e Reatividade](react-estado-e-reatividade.md) |
| `useReducer` | Estado local com transições em um reducer | [React - Estado e Reatividade](react-estado-e-reatividade.md) |
| `useContext` | Ler e assinar um contexto | [React - Estado e Reatividade](react-estado-e-reatividade.md) |
| `useRef` | Valor mutável que não dispara render; ref de DOM | [React - Refs e DOM](react-refs-e-dom.md) |
| `useImperativeHandle` | Customizar a ref exposta por um componente (raro) | [React - Refs e DOM](react-refs-e-dom.md) |
| `useEffect` | Sincronizar com sistema externo | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useLayoutEffect` | Medir layout antes do paint | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useInsertionEffect` | Inserir CSS dinâmico (bibliotecas CSS-in-JS) | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useEffectEvent` | Extrair lógica não reativa de dentro de um Effect | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `useMemo` | Cachear cálculo caro entre renders | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useCallback` | Cachear identidade de função entre renders | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useTransition` | Marcar atualização como não bloqueante, com flag de pendência | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useDeferredValue` | Adiar a atualização de uma parte não crítica da UI | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `useActionState` | Estado, ação e pendência de uma Action | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `useOptimistic` | Estado otimista durante uma Action pendente | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `useId` | ID único e estável, alinhado entre servidor e cliente | [React - Hooks Utilitários](react-hooks-utilitarios.md) |
| `useSyncExternalStore` | Assinar store externa de forma segura em concorrência | [React - Hooks Utilitários](react-hooks-utilitarios.md) |
| `useDebugValue` | Rótulo de Hook customizado no DevTools | [React - Hooks Utilitários](react-hooks-utilitarios.md) |

### `react` — Componentes built-in

| Componente | Para que serve | Satélite |
| --- | --- | --- |
| `<Fragment>` (`<>...</>`) | Agrupar nós sem criar elemento no DOM. Só precisa da forma longa `<Fragment key={…}>` ao renderizar lista — a forma curta `<>` não aceita `key` | — |
| `<Suspense>` | Exibir fallback enquanto filhos carregam | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `<StrictMode>` | Checagens extras em desenvolvimento | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `<Profiler>` | Medir performance de render programaticamente | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `<Activity>` | Ocultar e restaurar UI **preservando estado interno** | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |

### `react` — APIs

| API | Para que serve | Satélite |
| --- | --- | --- |
| `createContext` | Criar um contexto | [React - Estado e Reatividade](react-estado-e-reatividade.md) |
| `memo` | Pular re-render quando as props não mudam | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `lazy` | Adiar o carregamento do código de um componente | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `use` | Ler uma Promise ou um contexto — pode ser condicional | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `startTransition` | Marcar atualização como não urgente, fora de componente | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `act` | Envolver render/interação em testes | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `forwardRef` | **Não é mais necessário** — `ref` é prop desde o React 19 | [React - Refs e DOM](react-refs-e-dom.md) |

### `react-dom`

| API | Para que serve | Satélite |
| --- | --- | --- |
| `createPortal` | Renderizar filhos em outro ponto da árvore do DOM | [React - Refs e DOM](react-refs-e-dom.md) |
| `flushSync` | Forçar flush síncrono de uma atualização | [React - Refs e DOM](react-refs-e-dom.md) |
| `useFormStatus` | Ler o status do `<form>` ancestral | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `<form action>` | Submissão gerenciada pelo React, com `FormData` | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `ref` como prop / ref callback com cleanup | Acesso a nó do DOM (React 19) | [React - Refs e DOM](react-refs-e-dom.md) |
| `suppressHydrationWarning` | Silenciar divergência de hidratação em um nó | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| Error Boundary | Isolar falha de render — **não é exportado pelo React** | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `preload`, `preinit`, `preloadModule`, `preinitModule`, `preconnect`, `prefetchDNS` | Sinalizar recursos ao browser antecipadamente | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |

### `react-dom/client`, `/server`, `/static`

| API | Runtime | Satélite |
| --- | --- | --- |
| `createRoot`, `hydrateRoot` | Browser | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `renderToPipeableStream`, `resumeToPipeableStream` | Node Streams (recomendado em Node) | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `renderToReadableStream`, `resume` | Web Streams (Deno, edge, browser) | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `renderToString`, `renderToStaticMarkup` | Sem streaming — **legado**, funcionalidade limitada | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |
| `prerender`, `prerenderToNodeStream` | Geração estática | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |

### RSC e React Compiler

| Item | Para que serve | Satélite |
| --- | --- | --- |
| `'use client'` | Marca a fronteira a partir da qual o código vai para o cliente | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `'use server'` | Marca funções de servidor chamáveis pelo cliente | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `cache` | Memoizar função por argumentos em um passe de render de servidor | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `experimental_taintObjectReference`, `experimental_taintUniqueValue` | Impedir que dados sensíveis cruzem para o cliente — **experimental, fora de produção** | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `'use memo'` / `'use no memo'` | Opt-in / opt-out de compilação por função | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |

---

## 5. Árvores de decisão

O objetivo aqui é mapear **sintoma → API correta**, porque é nessa escolha que código React gerado costuma errar.

### Preciso guardar um valor. Onde?

Duas perguntas, nesta ordem: **qual mecanismo** e **em qual componente**. Pular a segunda é a causa mais comum de prop drilling e de re-render global.

**A. Qual mecanismo?** A checagem de origem vem primeiro — errar aqui viola `REACT-PAT-03`.

```
O dado vem do servidor?
├── SIM → não é estado de cliente. Não use useState como fonte de verdade.
│ → TanStack Query. Ver § 8
└── NÃO
 └── É derivável de props/estado que já existem?
 ├── SIM → calcule no render. Não crie estado.
 │ Caro de verdade (medido)? → useMemo
 │ →
 └── NÃO
 └── Mudá-lo deve redesenhar a UI?
 ├── NÃO → useRef
 └── SIM
 ├── Pertence à URL (filtro, aba, paginação,
 │ qualquer coisa que deva sobreviver a
 │ refresh e ser compartilhável por link)
 │ → estado de rota. Ver § 8
 ├── Vem de uma store fora do React
 │ → useSyncExternalStore
 ├── Várias transições relacionadas, ou estados
 │ que não podem coexistir → useReducer
 └── Caso geral → useState
```

**B. Em qual componente?**

```
Quantos componentes leem este estado?
├── Um → nele mesmo (colocation)
├── Vários irmãos → no ancestral comum MAIS PRÓXIMO, e pare ali
│ └── A subida está atravessando níveis que não usam o dado?
│ → composição (children/slots) antes de Context
└── A árvore inteira, leitura frequente e escrita rara → Context
 └── Escrita frequente? → store externa
```

E o derivado consumido por mais de um irmão: **calcule uma vez no dono do estado** e passe o resultado; não repita o mesmo `filter` em cada filho. Detalhe e exemplos em [React - Patterns](react-patterns.md) § 2.

### Preciso rodar um efeito colateral. Onde?

```
O código responde a uma interação específica do usuário?
└── SIM → event handler. Não é Effect. Pare aqui.

Não. Então: existe um sistema externo a sincronizar
(DOM não gerenciado, subscription, timer, socket, analytics)?
├── NÃO → provavelmente não deveria existir.
│ Estado derivado → calcule no render
│ Reagir a mudança de props → calcule ou use key
│ Buscar dados → biblioteca de data fetching
└── SIM
 ├── Precisa medir layout antes do paint → useLayoutEffect
 ├── Injeta CSS (biblioteca) → useInsertionEffect
 └── Caso geral → useEffect
 └── Lê um valor que NÃO deve reexecutar o Effect
 → extraia com useEffectEvent
```

### A UI trava durante uma atualização

**Não comece pela memoização.** A ordem abaixo vai do mais barato ao mais caro e é normativa — está detalhada em [React - Performance e Concorrência](react-performance-e-concorrencia.md) § 1.

```
0. MEDIU? Profiler ou DevTools. Sem medida, pare aqui. (REACT-PERF-01)
 └── React Compiler ativo no projeto? Então memoização manual
 é redundante — resolva pelos passos 1-3. (REACT-PERF-02)

1. Está criando estado desnecessário? → calcule no render
2. O estado está alto demais na árvore? → desça ao dono real
3. Composição resolve? → mover estado para componente menor,
 ou passar children como prop, elimina re-render SEM memoizar

4. Ainda lento? Quantos nós estão sendo renderizados?
 ├── Milhares de linhas/itens no DOM
 │ → o custo é volume, não cálculo. Concorrência NÃO resolve.
 │ → reduza o que é renderizado: virtualização ou paginação
 └── Poucos nós, mas cálculo pesado a cada tecla/atualização
 ├── Quero despriorizar a ATUALIZAÇÃO que eu disparo
 │ ├── e preciso de flag de pendência → useTransition
 │ └── e estou fora de um componente → startTransition
 └── Quero que o CONSUMIDOR pesado fique para trás enquanto
 o input responde na hora → useDeferredValue
 (+ memo no cálculo derivado, senão o trabalho roda igual)

5. Re-render desnecessário de filho, confirmado no Profiler
 → memo + estabilidade de props (useCallback / useMemo)
```

> **`useTransition` × `useDeferredValue`.** O critério da documentação é o acesso ao `set`: *"You can wrap an update into a Transition only if you have access to the `set` function of that state. If you want to start a Transition in response to some prop or a custom Hook value, try `useDeferredValue` instead."* Sem acesso ao `set` — o valor chega por prop ou de um Hook de terceiro — só resta `useDeferredValue`.
>
> Quando você **tem** acesso e os dois são possíveis (campo de busca é o caso típico), o que decide é o alvo: `useTransition` marca **a atualização** como interrompível e te dá `isPending`; `useDeferredValue` deixa **o consumidor pesado** exibindo o valor antigo enquanto o input responde na hora. Para input controlado + lista cara, `useDeferredValue` é o usual — e note a caveat oficial de que transições **não** servem para controlar campos de texto.

### Preciso lidar com algo assíncrono

```
Dado remoto em uma app cliente → TanStack Query
Componente pesado a carregar sob demanda → lazy + <Suspense>
Promise criada no servidor, lida no cliente → use + <Suspense>
Submissão de formulário com pendência e erro → useActionState
Feedback imediato antes da resposta chegar
 ├── o dado vive no cache de uma query → mutation otimista, NÃO useOptimistic
 │ →
 └── não vive → useOptimistic
Falha de render a isolar → Error Boundary
 →
```

> A ramificação do feedback otimista importa: `useOptimistic` e mutation otimista resolvem o mesmo problema em camadas diferentes, e usar os dois no mesmo dado produz duas fontes de verdade divergindo (`REACT-FORM-07`).

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `REACT-PURE-01` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

### `REACT-PURE-*` — pureza (fonte: Rules of React)

| ID | Regra |
| --- | --- |
| `REACT-PURE-01` | Um componente **MUST** retornar a mesma saída para as mesmas props, estado e contexto. |
| `REACT-PURE-02` | Side effects **NEVER** rodam durante o render — apenas em event handlers ou Effects. |
| `REACT-PURE-03` | Props e estado **NEVER** são mutados diretamente. |
| `REACT-PURE-04` | Valores passados a um Hook **NEVER** são modificados depois. |
| `REACT-PURE-05` | Valores usados em JSX **NEVER** são mutados após a criação do JSX. |

### `REACT-CALL-*` — quem chama o quê

| ID | Regra |
| --- | --- |
| `REACT-CALL-01` | Componentes **NEVER** são chamados como funções comuns; só usados em JSX. |
| `REACT-CALL-02` | Hooks **NEVER** são passados como valores. |

### `REACT-HOOK-*` — Rules of Hooks

| ID | Regra |
| --- | --- |
| `REACT-HOOK-01` | Hooks **MUST** ser chamados no topo, nunca em loops, condicionais, funções aninhadas ou após early return. |
| `REACT-HOOK-02` | Hooks **MUST** ser chamados apenas de componentes ou de outros Hooks. |
| `REACT-HOOK-03` | `use` é a **única** exceção a `REACT-HOOK-01`: pode ser chamado condicionalmente. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo.

| ID | Regra | Satélite |
| --- | --- | --- |
| `REACT-PAT-01` | Valor derivável **NEVER** vira estado próprio. | [React - Patterns](react-patterns.md) |
| `REACT-PAT-03` | Dado remoto **NEVER** é `useState` como fonte de verdade. | [React - Patterns](react-patterns.md) |
| `REACT-EFFECT-04` | Effect **NEVER** deriva estado de outro estado ou prop. | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `REACT-EFFECT-05` | Lógica que responde a interação **MUST** ficar no event handler. | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `REACT-EFFECT-06` | Fetch em `useEffect` **NEVER** em código novo. | [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `REACT-ASYNC-03` | `<Suspense>` **NEVER** funciona com fetch em `useEffect`. | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `REACT-ASYNC-08` | Boundary de Suspense em fronteira de dados **MUST** ter Error Boundary. | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `REACT-ASYNC-09` | Erro esperado **NEVER** é lançado para um boundary — é estado. | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| `REACT-PERF-01` | Memoização **MUST** ter justificativa medida. | [React - Performance e Concorrência](react-performance-e-concorrencia.md) |
| `REACT-FORM-03` | Erro esperado **MUST** ser retornado no estado da action, nunca lançado. | [React - Formulários e Actions](react-formularios-e-actions.md) |
| `REACT-RSC-03` | `'use client'` **MUST** ficar o mais baixo possível na árvore. | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `REACT-RSC-06` | Server Function **MUST** autenticar, validar e autorizar — é endpoint público. | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| `REACT-DOM-01` | HTML de servidor **MUST** ser hidratado com `hydrateRoot`. | [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) |

### 6.2 IDs canônicos

Cinco princípios aparecem em mais de um satélite, com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — os demais são apelidos e não devem aparecer em revisão.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Valor derivável nunca vira estado | `REACT-PAT-01` | `REACT-STATE-03`, `REACT-EFFECT-04` |
| Erro esperado é estado, não exceção para boundary | `REACT-ASYNC-09` | `REACT-PAT-07`, `REACT-FORM-03` |
| Server Function valida e autoriza na fronteira | `REACT-RSC-06` | `REACT-PAT-09`, `REACT-FORM-08` |
| `'use client'` o mais baixo possível | `REACT-RSC-03` | `REACT-PAT-08` |
| Props e estado nunca são mutados | `REACT-PURE-03` | `REACT-STATE-02` |

### Famílias completas nos satélites

`REACT-STATE-*` · `REACT-EFFECT-*` · `REACT-REF-*` · `REACT-PERF-*` · `REACT-ASYNC-*` · `REACT-FORM-*` · `REACT-RSC-*` · `REACT-DOM-*` · `REACT-PAT-*` · `REACT-UTIL-*`

---

## 7. Contrato de skill

Como uma skill de React deve consumir esta doc.

### O que uma skill de React deve carregar

```
SEMPRE: Docs/React.js.md § 2 (modelo mental)
 Docs/React.js.md § 5 (árvores de decisão)
 Docs/React.js.md § 6 + § 6.1 (regras normativas e críticas)

AO ESCREVER/EDITAR componentes:
 Docs/React - Rules of React.md

SOB DEMANDA, via § 4 (mapa da API):
 o satélite do domínio tocado pela tarefa

EM DECISÃO DE ESTRUTURA:
 Docs/React - Patterns.md

NUNCA: todos os satélites de uma vez
```

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `REACT-EFFECT-04` — `useEffect` usado para derivar estado. Calcule no render.
> Ver [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na seção 4, ela não foi verificada nesta doc. Consulte react.dev e atualize a nota — não invente comportamento.
2. **A fonte vence.** Divergência entre esta nota e react.dev é bug desta nota.
3. **Regra antes de estilo.** Uma violação de `REACT-PURE-*` ou `REACT-HOOK-*` tem precedência sobre qualquer preferência estética.
4. **Não otimizar sem medida.** `memo`, `useMemo` e `useCallback` exigem evidência de problema. Ver `REACT-PERF-*`.
5. **Preferir a ponte.** Quando a seção 8 indica que o stack resolve o problema, use o stack em vez da primitiva crua do React.

### Ao criar uma nova skill de React

Derive-a de um satélite, não desta nota inteira: uma skill focada em formulários carrega [React - Formulários e Actions](react-formularios-e-actions.md) + § 2 + § 6, e nada mais. Registre no início da skill qual satélite é sua fonte, para que a atualização da doc propague.

---

## 8. Pontes com o stack

O corpo desta doc é React puro, fiel a react.dev. Mas no meu stack ([TanStack Router](tanstack-router.md), [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md), TanStack Start, `Tailwindcss`, `TypeScript`) várias práticas cruas do React são substituídas. Os satélites marcam esses pontos como *ponte*.

| Problema | Primitiva crua do React | O que usar no stack |
| --- | --- | --- |
| Buscar dados remotos | `useEffect` + `useState` | TanStack Query — |
| Cache e frescor de dados | manual | `staleTime`, invalidação — |
| Update otimista | `useOptimistic` | mutation otimista da Query — |
| Navegação e estado de URL | `useState` + history | TanStack Router — [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) |
| Mutação no servidor | Server Function | validar sempre na fronteira — |
| Estado global de cliente | Context | quando houver escrita frequente |
| Validação de fronteira | manual | |
| Formulário complexo: validação por campo, arrays, wizard | `useState` por campo | React Hook Form — [React Hook Form](react-hook-form.md) |

**Critério — Actions numa SPA Vite.** Separe duas coisas que costumam ser confundidas:

- **`useActionState` e `<form action>` funcionam em React puro, sem framework** (verificado na fonte). Só `permalink` exige RSC. São a forma recomendada de submeter formulário mesmo em SPA Vite: substituem os quatro `useState` de pendência/erro/dados.
- **`useOptimistic` é a resposta do React quando o dado não vive num cache.** Se o dado está no cache do TanStack Query, o otimismo pertence à mutation da Query, com snapshot e rollback explícitos —. Não empilhe os dois: viram duas fontes de verdade divergindo.

**`useActionState` + `useMutation` juntos?** Escolha um dono da submissão. Se a operação invalida cache, deixe a mutation da Query ser o dono e use `<form>` comum com handler. Se é uma submissão isolada sem cache a invalidar, `useActionState` sozinho basta.

---

## Relacionados

- [React - Hooks](react-hooks.md) — superfície de API por Hook
- [React - Patterns](react-patterns.md) — padrões de composição e arquitetura
- [React - Rules of React](react-rules-of-react.md) — base normativa
- [React Hook Form](react-hook-form.md) — formulário complexo; a § 5.4 de lá decide entre RHF e Actions nativas
- [Frontend roadmap](../pages/frontend-roadmap.md) — trilha de estudos que consome estas notas
- `Next.js` · [TanStack Router](tanstack-router.md) · `Tailwindcss` · `TypeScript`

## Fontes consultadas

Verificadas diretamente em **2026-08-14**:

- [React Reference Overview](https://react.dev/reference/react)
- [Hooks](https://react.dev/reference/react/hooks) · [Components](https://react.dev/reference/react/components) · [APIs](https://react.dev/reference/react/apis)
- [Rules of React](https://react.dev/reference/rules)
- [react-dom](https://react.dev/reference/react-dom) · [react-dom/server](https://react.dev/reference/react-dom/server) · [react-dom hooks](https://react.dev/reference/react-dom/hooks)
- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- [React Compiler Directives](https://react.dev/reference/react-compiler/directives)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- `useEffectEvent` aparece no índice de Hooks como **estável**, sem marcação de experimental.
- **`forwardRef` ainda não está deprecado.** O banner diz que "deixou de ser necessário" e que "será deprecado numa versão futura" — são coisas diferentes.
- **React Compiler é 1.0 estável desde 07/10/2025** ([anúncio](https://react.dev/blog/2025/10/07/react-compiler-1)), compatível com React 17+. A página de configuração do reference não declara status; foi preciso ir ao blog.
- **`useActionState` funciona sem framework.** Só `permalink` exige RSC.
- **As APIs de taint são experimentais** (`experimental_taintObjectReference`), e a própria doc alerta para não tratá-las como mecanismo de segurança.
- **`startTransition` aceita função `async`**; a restrição é só para `setState` depois de um `await`.
- `renderToString` e `renderToStaticMarkup` estão marcados como legado, com funcionalidade limitada.

**Sobre revisão:** esta estrutura passou por teste de leitura com quatro agentes sem contexto (formulários, data fetching, colocação de estado, performance) e uma auditoria de contradições, em 2026-08-14. As correções aplicadas incluíram: inversão da ordem da árvore de estado (origem do dado passou a ser a primeira pergunta), promoção das regras críticas dos satélites para § 6.1, criação da tabela de IDs canônicos, e correção de três citações de ID erradas. Ao editar esta doc, repetir o teste é mais barato que confiar na releitura.
