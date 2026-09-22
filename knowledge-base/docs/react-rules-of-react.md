---
titulo: React - Rules of React
Link: https://react.dev/reference/rules
tags:
 - react
 - rules
 - reference
 - agent-context
source: "Documentação oficial do React — react.dev/reference/rules"
verificado-em: 2026-08-14
---
# React — Rules of React

> A base normativa. Todo o resto da doc deriva daqui. Um agente que escreve ou modifica componentes **deve** ter esta nota carregada.

Entrada: [React.js](react-js.md) · Consulta de API: [React - Hooks](react-hooks.md) · Decisão estrutural: [React - Patterns](react-patterns.md)

---

## 1. Por que existem

React não promete apenas renderizar — ele promete renderizar **quando e quantas vezes julgar necessário**: pausar trabalho, descartar renders inacabados, repetir um render em desenvolvimento para revelar bugs, reordenar atualizações por prioridade. Nada disso é seguro se um componente muda o mundo ao ser executado.

As regras não são estilo. Elas são o **contrato** que permite ao React fazer esse trabalho. Quebrar uma delas não gera um erro imediato e claro — gera comportamento errático: valores obsoletos, render duplicado com efeito duplicado, estado que aparece no componente errado.

Consequência direta: o React Compiler só pode memoizar código que segue as regras. **Código fora das regras não é apenas arriscado — ele é inelegível para as otimizações automáticas.** É o argumento mais prático a favor de segui-las.

Complementa o Zettel que desenvolve a ideia com palavras próprias.

---

## 2. Componentes e Hooks devem ser puros

Fonte: [Components and Hooks must be pure](https://react.dev/reference/rules/components-and-hooks-must-be-pure).

### `REACT-PURE-01` — idempotência

> "React components are assumed to always return the same output with respect to their inputs – props, state, and context."

As mesmas entradas produzem a mesma saída. Isso exclui do render: `Date.now`, `Math.random`, leitura de `window` sem guarda, contadores externos, `fetch`.

```tsx
// ERRADO — saída muda a cada render sem que nada tenha mudado
function Clock {
 return <span>{new Date.toLocaleTimeString}</span>
}

// CERTO — o tempo é estado, atualizado por sincronização externa
function Clock {
 const [now, setNow] = useState( => new Date)
 useEffect( => {
 const id = setInterval( => setNow(new Date), 1000)
 return => clearInterval(id)
 }, [])
 return <span>{now.toLocaleTimeString}</span>
}
```

### `REACT-PURE-02` — side effects fora do render

> "Side effects should not run in render, as React can render components multiple times to create the best possible user experience."

Onde eles pertencem, em ordem de preferência:

1. **Event handler** — se responde a uma interação específica. É o destino da maioria.
2. **Effect** — se sincroniza com um sistema externo.
3. **Em lugar nenhum** — se o valor era derivável.

**Duas exceções autorizadas pela própria documentação**, e só estas:

- **APIs de preloading** (`preload`, `preconnect`, `preinit`…) podem ser chamadas durante o render — são idempotentes e servem justamente para adiantar rede no momento em que o React sabe o que virá. Ver [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) § 4.
- **`async`/`await` no render de um Server Component** é legítimo, porque não há re-render concorrente do lado do servidor. Não vale para Client Components. Ver [React - Server Components e Diretivas](react-server-components-e-diretivas.md) § 1.

```tsx
// ERRADO — escrita durante o render
function Cart({ items }: { items: Item[] }) {
 localStorage.setItem('count', String(items.length))
 return <span>{items.length}</span>
}

// CERTO — sincronização é Effect
function Cart({ items }: { items: Item[] }) {
 useEffect( => {
 localStorage.setItem('count', String(items.length))
 }, [items.length])
 return <span>{items.length}</span>
}
```

> **Ponte:** para persistência real no browser — o exemplo acima é didático, não um padrão de produção.

### `REACT-PURE-03` — props e estado são imutáveis

> "A component's props and state are immutable snapshots with respect to a single render. Never mutate them directly."

```tsx
// ERRADO — mutação; o React não detecta e a UI não atualiza
items.push(newItem)
setItems(items)

// CERTO — novo valor
setItems([...items, newItem])
```

O ponto sutil: dentro de um render, o estado é um **snapshot congelado**. `setState` não altera a variável atual — agenda um novo render. Por isso a forma updater existe:

```tsx
// Incrementa UMA vez: ambos leem o mesmo snapshot
setCount(count + 1)
setCount(count + 1)

// Incrementa DUAS vezes: cada updater recebe o valor pendente
setCount((c) => c + 1)
setCount((c) => c + 1)
```

### `REACT-PURE-04` — argumentos e retornos de Hooks são imutáveis

> "Once values are passed to a Hook, you should not modify them. Like props in JSX, values become immutable when passed to a Hook."

Um objeto passado a `useState`, `useMemo` ou a um Hook customizado pertence ao React a partir dali. Mutá-lo depois esconde a mudança do sistema de reconciliação.

### `REACT-PURE-05` — valores são imutáveis após irem para o JSX

> "Don't mutate values after they've been used in JSX. Move the mutation before the JSX is created."

```tsx
// ERRADO
const element = <Row item={item} />
item.selected = true

// CERTO — mutação antes de o JSX existir, ou melhor: novo objeto
const next = {...item, selected: true }
const element = <Row item={next} />
```

### Onde a mutação é legítima

Mutação **local** — de um objeto criado dentro do próprio render e ainda não exposto — é permitida e idiomática:

```tsx
function List({ items }: { items: Item[] }) {
 const rows = [] // criado aqui, ninguém mais vê
 for (const item of items) rows.push(<Row key={item.id} item={item} />)
 return <ul>{rows}</ul>
}
```

---

## 3. Quem chama componentes e Hooks é o React

Fonte: [React calls Components and Hooks](https://react.dev/reference/rules/react-calls-components-and-hooks).

### `REACT-CALL-01` — nunca chame um componente como função

> "Components should only be used in JSX. Don't call them as regular functions."

```tsx
// ERRADO — vira parte do render do pai: sem estado próprio,
// sem Hooks próprios, sem posição na árvore, sem reconciliação.
function Page {
 return <div>{Header({ title: 'Perfil' })}</div>
}

// CERTO
function Page {
 return <div><Header title="Perfil" /></div>
}
```

Chamar diretamente não é "um atalho equivalente": os Hooks do componente chamado passam a contar como Hooks do chamador, o que quebra `REACT-HOOK-01` na primeira condicional.

### `REACT-CALL-02` — Hooks não são valores

> "Hooks should only be called inside of components. Never pass it around as a regular value."

```tsx
// ERRADO — Hook como argumento, chamado dinamicamente
function useData(hook: => Data) {
 return hook
}

// CERTO — chame Hooks diretamente e componha o resultado
function useData {
 const a = useA
 const b = useB
 return { a, b }
}
```

Isso também vale para Hooks dentro de objetos, arrays ou renderizados dinamicamente por lookup.

---

## 4. Rules of Hooks

Fonte: [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks). Detalhamento e exemplos em [React - Hooks](react-hooks.md).

### `REACT-HOOK-01` — apenas no topo

> "Don't call Hooks inside loops, conditions, or nested functions. Instead, always use Hooks at the top level of your React function, before any early returns."

**Antes de qualquer early return** é a parte que mais escapa em código gerado.

### `REACT-HOOK-02` — apenas de funções React

> "Don't call Hooks from regular JavaScript functions."

Válidos: componentes e Hooks customizados. Inválidos: funções utilitárias, handlers definidos fora do componente, callbacks de `map` que não são componentes.

### `REACT-HOOK-03` — a exceção `use`

`use` é uma **API**, não um Hook, e pode ser chamada condicionalmente e dentro de blocos. Continua valendo que só pode ser chamada de dentro de um componente ou Hook. Ver [React - Suspense e Assincronia](react-suspense-e-assincronia.md).

---

## 5. Checklist de revisão

Ordem de verificação ao revisar um componente. As primeiras falham mais.

- [ ] Algum Hook depois de um early return, dentro de `if`, loop ou callback? → `REACT-HOOK-01`
- [ ] `fetch`, `localStorage`, `Date.now`, `Math.random` ou log no corpo do render? → `REACT-PURE-01` / `REACT-PURE-02`
- [ ] `.push`, `.sort`, `.splice` ou atribuição direta em props/estado? → `REACT-PURE-03`
- [ ] `setState(x + 1)` onde deveria ser `setState(c => c + 1)`? → `REACT-STATE-01` (não é mutação: é leitura de snapshot obsoleto)
- [ ] Componente invocado como `Componente(props)` em vez de `<Componente />`? → `REACT-CALL-01`
- [ ] Hook armazenado em variável, objeto ou passado como argumento? → `REACT-CALL-02`
- [ ] Hook chamado de função que não é componente nem Hook? → `REACT-HOOK-02`
- [ ] `eslint-disable` em `react-hooks/exhaustive-deps`? → quase sempre indica Effect que não deveria existir

**Ferramenta:** `eslint-plugin-react-hooks` cobre a maior parte de `REACT-HOOK-*` e parte de `REACT-CALL-*` automaticamente. `<StrictMode>` revela violações de pureza em desenvolvimento ao renderizar e executar Effects duas vezes — ver [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md).

---

## 6. Uso por um agente

Ao gerar React, verifique a checklist da § 5 **antes** de entregar. Ao revisar, cite o ID:

> `REACT-PURE-02` — `localStorage.setItem` no corpo do render. Mova para um Effect ou para o handler que causa a mudança.

Uma violação destas regras tem **precedência sobre qualquer preferência de estilo ou de organização**. Não negocie uma quebra de pureza em nome de concisão.

---

## Relacionados

- [React.js](react-js.md) — hub, mapa da API e árvores de decisão
- [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md)
- — o Zettel que desenvolve a ideia
- ·

## Fontes consultadas

Verificadas em 2026-08-14, com as regras citadas literalmente:

- [Rules of React](https://react.dev/reference/rules)
- [Components and Hooks must be pure](https://react.dev/reference/rules/components-and-hooks-must-be-pure)
- [React calls Components and Hooks](https://react.dev/reference/rules/react-calls-components-and-hooks)
- [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
