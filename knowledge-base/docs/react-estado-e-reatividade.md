---
Link: https://react.dev/reference/react/useState
tags:
 - react
 - state
 - hooks
 - agent-context
source: "Documentação oficial do React — useState, useReducer, useContext, createContext"
verificado-em: 2026-08-14
---

# React — Estado e Reatividade

> `useState` · `useReducer` · `useContext` · `createContext`
>
> Onde o estado vive e por que o React re-renderiza. Para decidir *de quem é o dado*, vá a [React - Patterns](react-patterns.md) § 2. Para assinaturas, [React - Hooks](react-hooks.md).

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: estado é snapshot

Estado não é uma variável que você altera — é um **valor associado a uma posição na árvore**, do qual cada render enxerga um snapshot congelado.

```tsx
function Counter {
 const [count, setCount] = useState(0)

 function handleClick {
 setCount(count + 1) // count é 0 neste snapshot
 setCount(count + 1) // ainda 0 → resultado final: 1
 console.log(count) // 0 — não mudou nesta execução
 }

 return <button onClick={handleClick}>{count}</button>
}
```

O `console.log` imprime `0` porque `count` é uma constante deste render. `setCount` **agenda** um render novo; ele não reescreve a variável. Entender isso resolve de uma vez a categoria inteira de bugs de "estado atrasado".

### Forma updater

Quando o próximo valor depende do anterior, passe uma função. O React aplica a fila de updaters em ordem sobre o valor pendente:

```tsx
setCount((c) => c + 1) // 0 → 1
setCount((c) => c + 1) // 1 → 2
```

| ID | Regra |
| --- | --- |
| `REACT-STATE-01` | Quando o próximo estado depende do anterior, **MUST** usar a forma updater. |
| `REACT-STATE-02` | Estado **NEVER** é mutado — sempre novo objeto/array (`REACT-PURE-03`). |
| `REACT-STATE-03` | Estado derivável de props/estado existentes **NEVER** é criado (`REACT-PAT-01`). |

### Batching

Múltiplos `setState` na mesma interação produzem **um** render. Isso vale para handlers, Effects e código assíncrono. Não escreva código que dependa de um render intermediário — ele não acontece. Quando precisar de sincronia real com o DOM, ver `flushSync` em [React - Refs e DOM](react-refs-e-dom.md).

### Inicialização preguiçosa

```tsx
// ERRADO — createInitialState roda em TODO render, e o retorno é descartado
const [state, setState] = useState(createInitialState(items))

// CERTO — a função é chamada apenas na montagem
const [state, setState] = useState( => createInitialState(items))
```

| ID | Regra |
| --- | --- |
| `REACT-STATE-04` | Inicializador caro **MUST** ser passado como função, não como valor já computado. |

---

## 2. `useState` × `useReducer`

```tsx
const [state, setState] = useState(initialState)
const [state, dispatch] = useReducer(reducer, initialArg, init?)
```

Migre para `useReducer` quando:

- várias peças de estado mudam **juntas** na mesma interação;
- existem estados que **não podem coexistir** (`isLoading` e `error` simultâneos, por exemplo);
- a lógica de transição ficou grande demais para caber legivelmente nos handlers;
- você quer testar as transições sem renderizar.

```tsx
type State =
 | { status: 'idle' }
 | { status: 'uploading'; sent: number }
 | { status: 'error'; message: string }
 | { status: 'done'; url: string }

type Action =
 | { type: 'start' }
 | { type: 'progress'; sent: number }
 | { type: 'fail'; message: string }
 | { type: 'succeed'; url: string }

function reducer(state: State, action: Action): State {
 switch (action.type) {
 case 'start': return { status: 'uploading', sent: 0 }
 case 'progress': return state.status === 'uploading'
 ? {...state, sent: action.sent }
 : state
 case 'fail': return { status: 'error', message: action.message }
 case 'succeed': return { status: 'done', url: action.url }
 }
}
```

O ganho real está na **union discriminada**: estados contraditórios deixam de ser representáveis, e o TypeScript passa a cobrar o tratamento de cada caso. É o argumento de levado ao tipo.

**O reducer é uma função pura** — mesmas entradas, mesma saída, sem side effects. Aplicam-se `REACT-PURE-01` e `REACT-PURE-02`. Em `<StrictMode>` ele roda duas vezes em desenvolvimento justamente para revelar impureza.

| ID | Regra |
| --- | --- |
| `REACT-STATE-05` | O reducer **MUST** ser puro; nenhuma requisição, log ou escrita dentro dele. |
| `REACT-STATE-06` | Estados mutuamente exclusivos **MUST** ser modelados como union discriminada, não como booleanos paralelos. |

---

## 3. Context

Context resolve **um** problema: entregar um valor a uma subárvore sem repassá-lo por props em cada nível. Não é um gerenciador de estado.

### API atual

```tsx
import { createContext, useContext } from 'react'

type Theme = 'light' | 'dark'
const ThemeContext = createContext<Theme>('light')

// React 19: o próprio contexto é o provider
function App {
 return (
 <ThemeContext value="dark">
 <Page />
 </ThemeContext>
 )
}

function Button {
 const theme = useContext(ThemeContext)
 return <button className={theme}>OK</button>
}
```

Três notas de versão verificadas na fonte:

- **A partir do React 19**, `<SomeContext value={...}>` funciona como provider. `<SomeContext.Provider>` continua válido e é o que se usa em versões anteriores.
- **`<SomeContext.Consumer>` é a forma legada** — a documentação recomenda explicitamente `useContext` em código novo.
- **O valor padrão de `createContext` é estático** e nunca muda; ele é o último recurso quando não há provider acima.

### O custo

Todo consumidor re-renderiza quando o `value` do provider muda por identidade. Um objeto criado inline no render muda de identidade a cada render:

```tsx
// ERRADO — novo objeto a cada render do App: todos os consumidores re-renderizam sempre
<AuthContext value={{ user, login, logout }}>

// CERTO — identidade estável
const auth = useMemo( => ({ user, login, logout }), [user, login, logout])
<AuthContext value={auth}>
```

| ID | Regra |
| --- | --- |
| `REACT-STATE-07` | Valor de provider construído inline **MUST** ter identidade estabilizada quando houver consumidores custosos. Esta é exceção explícita a `REACT-PERF-01`: não exige medição prévia, porque o custo é estrutural. |
| `REACT-STATE-08` | Context **NEVER** é usado para estado de escrita frequente — use store externa. |

### Context × store externa

| Critério | Context | Store externa |
| --- | --- | --- |
| Escrita | rara (tema, sessão, locale) | frequente |
| Granularidade | subárvore inteira re-renderiza | seleção por fatia |
| Dependência de árvore | sim — precisa de provider | não |

Regra prática: Context para **dependências ambientais**; store para **estado que muda muito**. Para dado remoto, nenhum dos dois — ver.

---

## 4. Antipadrões

### Estado derivado

```tsx
// ERRADO — duas fontes de verdade, um render extra, dessincronização garantida
const [items, setItems] = useState<Item[]>([])
const [total, setTotal] = useState(0)
useEffect( => setTotal(items.length), [items])

// CERTO
const [items, setItems] = useState<Item[]>([])
const total = items.length
```

Ver e.

### Estado espelhando props

```tsx
// ERRADO — só lê a prop na montagem; mudanças posteriores são ignoradas
function Form({ initialName }: { initialName: string }) {
 const [name, setName] = useState(initialName)
}
```

Se a intenção é **valor inicial**, deixe explícito no nome (`initialName`) e documente. Se a intenção é **resetar quando a identidade muda**, use `key` — ver [React - Patterns](react-patterns.md) § 2.

### Um `useState` por campo em objeto grande

Cinco campos que sempre mudam juntos são um objeto ou um reducer, não cinco Hooks. Cinco campos independentes são cinco Hooks. O critério é o acoplamento das transições, não a contagem.

### Guardar no estado o que não redesenha

Timer id, instância de observer, valor da última renderização para comparação — nada disso deve disparar render. É `useRef`. Ver [React - Refs e DOM](react-refs-e-dom.md).

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- · · · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [useState](https://react.dev/reference/react/useState) · [useReducer](https://react.dev/reference/react/useReducer)
- [useContext](https://react.dev/reference/react/useContext) · [createContext](https://react.dev/reference/react/createContext)
