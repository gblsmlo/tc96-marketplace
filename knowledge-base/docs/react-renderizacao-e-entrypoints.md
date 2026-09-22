---
Link: https://react.dev/reference/react-dom/client
tags:
 - react
 - rendering
 - ssr
 - agent-context
source: "Documentação oficial do React — react-dom/client, react-dom/server, react-dom/static, StrictMode, preloading"
verificado-em: 2026-08-14
---

# React — Renderização e Entrypoints

> `createRoot` · `hydrateRoot` · APIs de `react-dom/server` e `/static` · `<StrictMode>` · preloading · `act`
>
> Onde a árvore React encontra o DOM ou o HTML. Poucas linhas de código, mas escolhas que definem hidratação, streaming e o que quebra em produção.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Cliente: `createRoot` × `hydrateRoot`

```tsx
import { createRoot } from 'react-dom/client'

const root = createRoot(document.getElementById('root')!)
root.render(<App />)
```

```tsx
import { hydrateRoot } from 'react-dom/client'

hydrateRoot(document.getElementById('root')!, <App />)
```

| | `createRoot` | `hydrateRoot` |
| --- | --- | --- |
| Estado inicial do container | vazio | já contém HTML do servidor |
| O que faz | cria o DOM do zero | anexa listeners ao DOM existente |
| Usar em | SPA pura | app com SSR/SSG |

`root.unmount` desmonta a árvore. `ReactDOM.render` e `unmountComponentAtNode` foram removidos — não existem mais.

| ID | Regra |
| --- | --- |
| `REACT-DOM-01` | HTML vindo do servidor **MUST** ser hidratado com `hydrateRoot`, nunca com `createRoot` — este descartaria o HTML e perderia o benefício do SSR. |

### Erro de hidratação

Ocorre quando a árvore renderizada no cliente não bate com o HTML do servidor. Causas típicas:

| Causa | Correção |
| --- | --- |
| `Date.now`, `Math.random`, `new Date` no render | `REACT-PURE-01` — mover para estado ou passar do servidor |
| `typeof window !== 'undefined'` ramificando o render | renderizar igual e ajustar em Effect |
| `localStorage` lido no render | ler em `useEffect` após a montagem |
| HTML inválido (`<div>` dentro de `<p>`) | corrigir a marcação |
| Formatação dependente de locale/timezone | fixar locale/timezone explicitamente |

O padrão para conteúdo genuinamente client-only:

```tsx
const [montado, setMontado] = useState(false)
useEffect( => setMontado(true), [])
if (!montado) return <Placeholder /> // igual ao que o servidor renderizou
return <ConteudoDeCliente />
```

`suppressHydrationWarning` silencia o aviso em um nó específico (timestamp gerado no servidor, por exemplo). **Não corrige** a divergência — apenas cala o alerta.

| ID | Regra |
| --- | --- |
| `REACT-DOM-02` | Erro de hidratação **NEVER** é resolvido com `suppressHydrationWarning` sem entender a causa. |
| `REACT-DOM-03` | O render **NEVER** ramifica em `typeof window` — renderize igual nos dois lados e ajuste em Effect. |

---

## 2. Servidor: `react-dom/server`

Inventário e runtimes conforme a referência oficial:

| API | Runtime | Nota |
| --- | --- | --- |
| `renderToPipeableStream` | Node.js Streams | **recomendado em Node** |
| `resumeToPipeableStream` | Node.js Streams | retoma um `prerenderToNodeStream` |
| `renderToReadableStream` | Web Streams | Deno, edge, browser |
| `resume` | Web Streams | retoma um `prerender` |
| `renderToString` | sem streaming | **legado**, funcionalidade limitada |
| `renderToStaticMarkup` | sem streaming | **legado**, HTML não interativo |

Duas notas verificadas na fonte:

- as APIs de **Web Streams existem em Node por compatibilidade, mas não são recomendadas ali** por performance pior — em Node, use as de Node Streams;
- `renderToString` e `renderToStaticMarkup` são explicitamente marcadas como legado, com funcionalidade limitada frente às de streaming, e destinadas apenas a ambientes sem streaming.

| ID | Regra |
| --- | --- |
| `REACT-DOM-04` | Em Node, SSR **MUST** usar `renderToPipeableStream`, não as APIs de Web Streams. |
| `REACT-DOM-05` | `renderToString` **NEVER** entra em código novo com streaming disponível — não suporta os benefícios de Suspense em streaming. |

### `react-dom/static`

`prerender` (Web Streams) e `prerenderToNodeStream` (Node Streams) geram HTML estático esperando todos os dados resolverem — para SSG. O par `resume`/`resumeToPipeableStream` permite retomar depois com o conteúdo dinâmico.

> Na prática, quem chama essas APIs é o framework. Elas importam para **entender** o que Next.js ou TanStack Start faz — não para escrever à mão.

---

## 3. `<StrictMode>`

```tsx
createRoot(document.getElementById('root')!).render(
 <StrictMode>
 <App />
 </StrictMode>,
)
```

Somente em desenvolvimento, o React:

1. **renderiza componentes duas vezes** — revela impureza de render (`REACT-PURE-01`);
2. **executa Effects duas vezes** (setup → cleanup → setup) — revela cleanup faltando ou incompleto (`REACT-EFFECT-01`);
3. **executa reducers e inicializadores de estado duas vezes** — revela impureza neles (`REACT-STATE-05`);
4. **avisa sobre APIs depreciadas**.

Nada disso acontece em produção e nada disso é bug do React. **Cada execução dupla que quebra algo é um bug seu sendo mostrado.** A resposta nunca é remover `<StrictMode>`.

| ID | Regra |
| --- | --- |
| `REACT-DOM-06` | `<StrictMode>` **NEVER** é removido para "consertar" execução dupla — é o bug de pureza sendo revelado. |

Observação verificada: a action de `useActionState` **não** é invocada duas vezes em StrictMode, justamente porque pode ter side effects — ver [React - Formulários e Actions](react-formularios-e-actions.md).

---

## 4. Preloading de recursos

APIs de `react-dom` para antecipar trabalho de rede. Sinais, não garantias — o browser decide.

| API | Faz |
| --- | --- |
| `prefetchDNS(href)` | resolve o DNS de um domínio |
| `preconnect(href)` | abre conexão com um servidor |
| `preload(href, options)` | baixa stylesheet, fonte, imagem ou script |
| `preloadModule(href, options)` | baixa um módulo ESM |
| `preinit(href, options)` | baixa **e avalia** script, ou baixa e insere stylesheet |
| `preinitModule(href, options)` | baixa e avalia um módulo ESM |

```tsx
import { preload, preconnect } from 'react-dom'

function Galeria({ proximaUrl }: { proximaUrl: string }) {
 preconnect('https://cdn.exemplo.com')
 preload(proximaUrl, { as: 'image' })
 //...
}
```

Escala de custo crescente: `prefetchDNS` < `preconnect` < `preload` < `preinit`. Pré-carregar tudo compete por banda com o que é crítico agora e piora o resultado.

| ID | Regra |
| --- | --- |
| `REACT-DOM-07` | Preloading **MUST** ser aplicado a poucos recursos de alta probabilidade de uso — pré-carregar em massa degrada. |

---

## 5. `act` em testes

```tsx
import { act } from 'react'

await act(async => {
 root.render(<App />)
})
```

Garante que renders, Effects e atualizações agendadas terminem antes das asserções. Testing Library já envolve suas APIs em `act` — chamá-lo manualmente costuma indicar que o teste observa implementação em vez de comportamento. Ver.

> `act` vem de `react`, não de `react-dom/test-utils`.

---

## 6. Checklist de revisão

- [ ] SSR hidratando com `hydrateRoot`, não `createRoot`? → `REACT-DOM-01`
- [ ] Algum `Date.now`, `Math.random` ou `localStorage` no render? → `REACT-PURE-01` / `REACT-PURE-02` (causa raiz da divergência de hidratação)
- [ ] `typeof window` ramificando o render? → `REACT-DOM-03`
- [ ] SSR em Node usando as APIs de Node Streams? → `REACT-DOM-04`
- [ ] `renderToString` em código novo? → `REACT-DOM-05`
- [ ] `<StrictMode>` presente e não removido para calar avisos? → `REACT-DOM-06`
- [ ] Preloading restrito ao que é provável? → `REACT-DOM-07`

---

## Relacionados

- [React.js](react-js.md) · [React - Rules of React](react-rules-of-react.md) · [React - Patterns](react-patterns.md)
- [React - Server Components e Diretivas](react-server-components-e-diretivas.md) · [React - Suspense e Assincronia](react-suspense-e-assincronia.md) · [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md)
- · `Next.js` · [TanStack Router](tanstack-router.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [react-dom/client](https://react.dev/reference/react-dom/client) — `createRoot`, `hydrateRoot`
- [react-dom/server](https://react.dev/reference/react-dom/server) — inventário e recomendações de runtime
- [react-dom/static](https://react.dev/reference/react-dom/static)
- [StrictMode](https://react.dev/reference/react/StrictMode) · [act](https://react.dev/reference/react/act)
- [react-dom APIs](https://react.dev/reference/react-dom) — família de preloading
