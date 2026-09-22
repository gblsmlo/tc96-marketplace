---
Link: https://react.dev/reference/react/Suspense
tags:
 - react
 - suspense
 - async
 - agent-context
source: "Documentação oficial do React — Suspense, lazy, use"
verificado-em: 2026-08-14
---

# React — Suspense e Assincronia

> `<Suspense>` · `lazy` · `use` · Error Boundaries
>
> Como o React expressa "isto ainda não está pronto" e "isto falhou" de forma declarativa, sem espalhar `isLoading` e `error` por toda a árvore.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: espera como posição na árvore

O modelo imperativo espalha estado de carregamento por componente:

```tsx
if (isLoading) return <Spinner />
if (error) return <Error />
return <Content />
```

Suspense inverte isso: o componente **declara o que precisa** e **suspende** se ainda não estiver disponível. O fallback é escolhido pelo ancestral `<Suspense>` mais próximo.

```tsx
<Suspense fallback={<PerfilSkeleton />}>
 <Perfil userId={userId} />
</Suspense>
```

A consequência de projeto é a que importa: **onde você coloca o boundary define o que some da tela durante a espera.**

```tsx
// Um boundary na raiz: a página inteira vira skeleton por causa de um comentário lento
<Suspense fallback={<PageSkeleton />}>
 <Header /><Article /><Comments />
</Suspense>

// Boundaries por região: header e artigo aparecem imediatamente
<Header />
<Suspense fallback={<ArticleSkeleton />}><Article /></Suspense>
<Suspense fallback={<CommentsSkeleton />}><Comments /></Suspense>
```

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-01` | Boundaries de Suspense **MUST** ser posicionados por região de UI, não apenas na raiz. |
| `REACT-ASYNC-02` | O `fallback` **MUST** ocupar aproximadamente o mesmo espaço do conteúdo real, para evitar layout shift. |

### O que ativa Suspense

Apenas fontes integradas a ele:

- componentes carregados com `lazy`;
- Promises lidas com `use`;
- data fetching de bibliotecas com suporte a Suspense — no TanStack Query isso exige os **hooks dedicados** `useSuspenseQuery` / `useSuspenseInfiniteQuery`, não uma flag no `useQuery` normal;
- RSC com streaming.

**`useEffect` + `fetch` não ativa Suspense.** Um `<Suspense>` ao redor de um componente que busca dados em Effect nunca mostra o fallback — este é o mal-entendido mais comum sobre a API.

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-03` | `<Suspense>` **NEVER** é combinado com fetch em `useEffect` esperando fallback — não funciona. |

---

## 2. `lazy`

```tsx
import { lazy, Suspense } from 'react'

const Settings = lazy( => import('./Settings'))

<Suspense fallback={<Spinner />}>
 <Settings />
</Suspense>
```

Adia o carregamento do código até o primeiro render. Duas regras práticas:

**Declare no escopo do módulo.** Chamar `lazy` dentro de um componente cria um tipo novo a cada render, o que remonta a subárvore e descarta seu estado.

```tsx
// ERRADO — novo componente a cada render
function Page {
 const Settings = lazy( => import('./Settings'))
 //...
}
```

**O módulo precisa de `export default`** — ou o carregador deve mapear para um named export explicitamente:

```tsx
const Settings = lazy( =>
 import('./Settings').then((m) => ({ default: m.Settings })),
)
```

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-04` | `lazy` **MUST** ser chamado no escopo do módulo, nunca dentro de um componente. |
| `REACT-ASYNC-05` | Todo `lazy` **MUST** ter um `<Suspense>` ancestral. |

Onde vale a pena: rotas, modais pesados, editores, gráficos. Onde não vale: componentes pequenos — o custo do request extra supera o do bundle.

> **Ponte:** com [TanStack Router](tanstack-router.md), code splitting por rota já é resolvido pelo roteador. Use `lazy` para o que está **fora** da fronteira de rota.

---

## 3. `use`

```tsx
const value = use(promiseOrContext)
```

Lê uma Promise ou um contexto. É uma **API, não um Hook** — e por isso é a única coisa da superfície que pode ser chamada condicionalmente ou dentro de blocos (`REACT-HOOK-03`).

```tsx
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
 const comments = use(commentsPromise) // suspende até resolver
 return <ul>{comments.map((c) => <li key={c.id}>{c.text}</li>)}</ul>
}

// O pai fornece a Promise e o boundary
<Suspense fallback={<CommentsSkeleton />}>
 <Comments commentsPromise={fetchComments} />
</Suspense>
```

### A restrição decisiva

**A Promise não pode ser criada durante o render do componente que a lê.** Uma Promise criada no render seria recriada a cada render, e cada uma suspenderia de novo — loop infinito.

```tsx
// ERRADO — nova Promise a cada render
function Comments {
 const comments = use(fetch('/api/comments').then((r) => r.json))
}
```

A Promise deve vir de fora: de um Server Component, de um cache, ou de uma biblioteca que garanta identidade estável.

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-06` | A Promise passada a `use` **NEVER** é criada durante o render do componente que a consome. |
| `REACT-ASYNC-07` | `use` **MUST** ser chamado de dentro de um componente ou Hook, mesmo podendo ser condicional. |

Em uma SPA sem RSC, essa restrição é o motivo pelo qual `use` raramente é a ferramenta certa para data fetching — o cache estável é justamente o que TanStack Query fornece. Ver.

### `use` para contexto

```tsx
function Item({ compact }: { compact: boolean }) {
 if (compact) {
 const theme = use(ThemeContext) // condicional — impossível com useContext
 return <span className={theme}>…</span>
 }
 return <Full />
}
```

---

## 4. Error Boundaries

Suspense trata **espera**; Error Boundary trata **falha**. As duas fronteiras são complementares e geralmente ficam juntas.

```tsx
<ErrorBoundary fallback={<ErroAoCarregar />}>
 <Suspense fallback={<Skeleton />}>
 <Perfil userId={userId} />
 </Suspense>
</ErrorBoundary>
```

### O React não exporta um Error Boundary

Não existe `<ErrorBoundary>` embutido. Ele é **obrigatoriamente um componente de classe**, porque os métodos que o definem não têm equivalente em Hook. As duas opções:

**A. `react-error-boundary`** (biblioteca, o caminho normal):

```tsx
import { ErrorBoundary } from 'react-error-boundary'

<ErrorBoundary
 fallbackRender={({ error, resetErrorBoundary }) => (
 <div role="alert">
 <p>Não foi possível carregar o perfil.</p>
 <button onClick={resetErrorBoundary}>Tentar de novo</button>
 </div>
 )}
 onError={(error, info) => reportarErro(error, info)}
>
 <Suspense fallback={<Skeleton />}>
 <Perfil userId={userId} />
 </Suspense>
</ErrorBoundary>
```

**B. Implementação própria**, quando não quiser a dependência:

```tsx
type Props = { fallback: React.ReactNode; children: React.ReactNode }
type State = { error: Error | null }

export class ErrorBoundary extends React.Component<Props, State> {
 state: State = { error: null }

 static getDerivedStateFromError(error: Error): State {
 return { error } // atualiza o estado para renderizar o fallback
 }

 componentDidCatch(error: Error, info: React.ErrorInfo) {
 reportarErro(error, info) // efeito colateral: log, telemetria
 }

 render {
 return this.state.error ? this.props.fallback : this.props.children
 }
}
```

Os dois métodos têm papéis distintos: `getDerivedStateFromError` decide **o que renderizar** e deve ser puro; `componentDidCatch` é onde vai o **efeito colateral** de reportar. Uma implementação própria precisa ainda de uma forma de resetar — normalmente uma `key` que muda, ou um botão que zera o estado.

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-11` | Um boundary sem caminho de recuperação (retry ou reset) **NEVER** é suficiente — o usuário fica preso no fallback. |

Conceito desenvolvido em. Dois pontos operacionais:

**Nem todo erro vai para o boundary.** Erros esperados — validação falhou, item não encontrado, sem permissão — são **estado da UI**, não exceções. Ver.

**Boundaries não capturam** erros em event handlers, código assíncrono fora do render, nem erros do próprio boundary. Handlers precisam de `try/catch` próprio.

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-08` | Todo boundary de Suspense em fronteira de dados **MUST** ter um Error Boundary associado. |
| `REACT-ASYNC-09` | Erro esperado **NEVER** é lançado para um boundary — é estado. |

---

## 5. Suspense + transições

Sem transição, atualizar um estado que suspende **substitui** o conteúdo visível pelo fallback — a UI pisca de volta ao skeleton.

```tsx
// Mantém o conteúdo atual visível enquanto o novo carrega
startTransition( => setTab('comments'))
```

Regra geral: **navegação e troca de conteúdo já visível devem ser transições.** Ver [React - Performance e Concorrência](react-performance-e-concorrencia.md) § 4.

| ID | Regra |
| --- | --- |
| `REACT-ASYNC-10` | Atualização que pode suspender conteúdo já visível **MUST** ser envolvida em transição. |

---

## 6. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `<Suspense>` ao redor de fetch em Effect | biblioteca com suporte a Suspense · `REACT-ASYNC-03` |
| Um único boundary na raiz | boundaries por região · `REACT-ASYNC-01` |
| `lazy` dentro de componente | escopo do módulo · `REACT-ASYNC-04` |
| Promise criada no render passada a `use` | Promise estável de fora · `REACT-ASYNC-06` |
| Fallback de altura diferente do conteúdo | skeleton dimensionado · `REACT-ASYNC-02` |
| Suspense sem Error Boundary | par obrigatório · `REACT-ASYNC-08` |
| Navegação sem transição, piscando skeleton | `startTransition` · `REACT-ASYNC-10` |

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Performance e Concorrência](react-performance-e-concorrencia.md) · [React - Server Components e Diretivas](react-server-components-e-diretivas.md)
- · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [Suspense](https://react.dev/reference/react/Suspense) · [lazy](https://react.dev/reference/react/lazy) · [use](https://react.dev/reference/react/use)
- [Server Components](https://react.dev/reference/rsc/server-components)
