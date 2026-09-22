---
titulo: React - Refs e DOM
Link: https://react.dev/reference/react/useRef
tags:
 - react
 - refs
 - dom
 - agent-context
source: "Documentação oficial do React — useRef, useImperativeHandle, createPortal, flushSync"
verificado-em: 2026-08-14
---

# React — Refs e DOM

> `useRef` · `useImperativeHandle` · `ref` como prop · `createPortal` · `flushSync`
>
> A saída de emergência do modelo declarativo. Cada API aqui existe para um caso que o React não consegue expressar declarativamente — e cada uma é usada em excesso por código gerado.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. `useRef`: memória que não redesenha

```tsx
const ref = useRef(initialValue) // { current: initialValue }
```

Uma ref é uma caixa mutável que **sobrevive entre renders e não dispara render** ao mudar. Dois usos:

**A. Valor que não pertence à UI**

```tsx
const timeoutRef = useRef<number | null>(null)

function start {
 timeoutRef.current = window.setTimeout( => { /*... */ }, 1000)
}
function stop {
 if (timeoutRef.current !== null) clearTimeout(timeoutRef.current)
}
```

Timer id, instância de observer, controller de request, contador de tentativas, valor anterior para comparação. Nada disso deve redesenhar nada.

**B. Referência a um nó do DOM**

```tsx
const inputRef = useRef<HTMLInputElement>(null)

function focus {
 inputRef.current?.focus
}

return <input ref={inputRef} />
```

### `useState` × `useRef`

| | `useState` | `useRef` |
| --- | --- | --- |
| Mudança dispara render | sim | **não** |
| Legível durante o render | sim | **não deve ser** |
| Imutável no render | sim (snapshot) | não (mutável) |

| ID | Regra |
| --- | --- |
| `REACT-REF-01` | `ref.current` **NEVER** é lido ou escrito durante o render (viola `REACT-PURE-02`). Apenas em handlers e Effects. |
| `REACT-REF-02` | Se mudar o valor deve atualizar a UI, **MUST** ser estado, não ref. |

A exceção a `REACT-REF-01` é a inicialização preguiçosa e idempotente na primeira execução — mas prefira `useState` com inicializador quando possível.

---

## 2. `ref` como prop (React 19)

Verificado na fonte — e a distinção importa: `forwardRef` **ainda não está deprecado**; ele deixou de ser necessário e será deprecado no futuro. Continua exportado e funcional, sem warning.

> "In React 19, `forwardRef` is no longer necessary. Pass `ref` as a prop instead. `forwardRef` will be deprecated in a future release."

Ou seja: código existente com `forwardRef` não está quebrado e não exige migração urgente. `REACT-REF-03` abaixo é política para código **novo**, não correção de bug.

```tsx
// React 19 — ref é uma prop comum
type InputProps = React.ComponentPropsWithRef<'input'> & { label: string }

function TextField({ label, ref,...props }: InputProps) {
 return (
 <label>
 {label}
 <input ref={ref} {...props} />
 </label>
 )
}

// Uso
<TextField label="Nome" ref={inputRef} />
```

| ID | Regra |
| --- | --- |
| `REACT-REF-03` | Código novo **NEVER** usa `forwardRef`; `ref` é prop. |

### Ref callback com cleanup

Também novo no React 19: o callback de ref pode **retornar uma função de limpeza**.

```tsx
<div ref={(node) => {
 const observer = new ResizeObserver(handleResize)
 if (node) observer.observe(node)
 return => observer.disconnect // chamado ao desanexar
}} />
```

Da documentação, sobre o comportamento legado:

> "To support backwards compatibility, if a cleanup function is not returned from the `ref` callback, `node` will be called with `null` when the `ref` is detached. This behavior will be removed in a future version."

Ou seja: **retornar cleanup é a forma correta agora**; a chamada com `null` é compatibilidade em vias de remoção.

| ID | Regra |
| --- | --- |
| `REACT-REF-04` | Ref callback que registra observer/listener **MUST** retornar cleanup em vez de depender da chamada com `null`. |

---

## 3. `useImperativeHandle`

```tsx
useImperativeHandle(ref, createHandle, dependencies?)
```

Restringe o que a ref de um componente expõe. A própria documentação classifica como **raro**.

```tsx
function VideoPlayer({ ref, src }: { ref: React.Ref<VideoHandle>; src: string }) {
 const videoRef = useRef<HTMLVideoElement>(null)

 useImperativeHandle(ref, => ({
 play: => videoRef.current?.play,
 pause: => videoRef.current?.pause,
 }), [])

 return <video ref={videoRef} src={src} />
}
```

Legítimo quando a superfície imperativa precisa ser **deliberadamente menor** que o nó do DOM — aqui o consumidor não pode alterar `currentTime`, `volume` ou o `src`.

| ID | Regra |
| --- | --- |
| `REACT-REF-05` | `useImperativeHandle` **MUST** ser justificado por restrição intencional da API; expor o nó inteiro é ref normal. |
| `REACT-REF-06` | Handle imperativo **NEVER** substitui props para o que é expressável declarativamente. |

O antipadrão frequente: expor `setValue`, `setError`, `reset` via handle imperativo em vez de controlar por props. Isso cria uma segunda fonte de verdade fora do fluxo unidirecional — ver.

---

## 4. `createPortal`

```tsx
import { createPortal } from 'react-dom'

createPortal(children, domNode, key?)
```

Renderiza filhos em outro ponto do **DOM**, mantendo-os no mesmo ponto da **árvore React**. Para modais, tooltips e popovers que precisam escapar de `overflow: hidden` ou de um `z-index` de stacking context.

```tsx
function Modal({ children, onClose }: { children: React.ReactNode; onClose: => void }) {
 return createPortal(
 <div className="backdrop" onClick={onClose}>
 <div className="dialog" onClick={(e) => e.stopPropagation}>{children}</div>
 </div>,
 document.body,
 )
}
```

**A consequência que engana:** eventos continuam propagando pela árvore **React**, não pela do DOM. Um clique dentro do portal dispara handlers dos ancestrais React mesmo estando em `document.body`.

| ID | Regra |
| --- | --- |
| `REACT-REF-07` | Portal **NEVER** dispensa acessibilidade: foco preso, `Esc` para fechar, `role`/`aria-modal` e devolução do foco continuam sendo responsabilidade sua. |

Na prática, use um primitivo acessível pronto (Radix, base do shadcn) em vez de montar o modal do zero — `createPortal` é o mecanismo, não a solução completa.

---

## 5. `flushSync`

```tsx
import { flushSync } from 'react-dom'

flushSync( => setItems([...items, novo]))
listRef.current?.scrollTo({ top: listRef.current.scrollHeight })
```

Força o React a processar a atualização e aplicar o DOM **sincronamente**, saindo do batching. Sem isso, o `scrollTo` acima rodaria antes de o novo item existir no DOM.

Prejudica performance e desativa otimizações de concorrência. Legítimo apenas quando é preciso ler o DOM logo após uma atualização.

| ID | Regra |
| --- | --- |
| `REACT-REF-08` | `flushSync` **MUST** ser último recurso, justificado por leitura de DOM imediatamente após atualização. |

---

## 6. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| Ler `ref.current` durante o render | mova para handler/Effect · `REACT-REF-01` |
| Ref para evitar re-render de valor que a UI mostra | é estado · `REACT-REF-02` |
| `forwardRef` em código novo | `ref` como prop · `REACT-REF-03` |
| Handle imperativo para o que props resolvem | props · `REACT-REF-06` |
| Manipular DOM gerenciado pelo React (`innerHTML`, `remove`) | deixe o React reconciliar |
| `flushSync` para "garantir" ordem de estado | forma updater / repensar o fluxo |
| Modal com `createPortal` sem foco e `Esc` | primitivo acessível · `REACT-REF-07` |

O quinto merece nota: alterar por ref um nó que o React gerencia coloca a árvore real fora de sincronia com a virtual, e o próximo render pode reverter ou quebrar. Manipulação direta só é segura em nós que o React **não** renderiza.

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Estado e Reatividade](react-estado-e-reatividade.md) — a decisão estado × ref
- ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [useRef](https://react.dev/reference/react/useRef) · [useImperativeHandle](https://react.dev/reference/react/useImperativeHandle)
- [forwardRef](https://react.dev/reference/react/forwardRef) — banner de depreciação citado literalmente
- [Common components — ref callback](https://react.dev/reference/react-dom/components/common) — cleanup de ref callback citado literalmente
- [createPortal](https://react.dev/reference/react-dom/createPortal) · [flushSync](https://react.dev/reference/react-dom/flushSync)
