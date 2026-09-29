---
titulo: React - Hooks Utilitários
Link: https://react.dev/reference/react/useId
tags:
  - react
  - hooks
  - agent-context
source: "Documentação oficial do React — useId, useSyncExternalStore, useDebugValue"
verificado-em: 2026-08-14
---

# React — Hooks Utilitários

> `useId` · `useSyncExternalStore` · `useDebugValue`
>
> Três Hooks de uso pontual. Cada um resolve um problema específico e é frequentemente usado para a coisa errada.

Entrada: [React.js](react-js.md) · Base normativa: [React - Hooks](react-hooks.md)

---

## 1. `useId`

```tsx
const id = useId()
```

Gera um ID único e **estável entre servidor e cliente** — é isso que o diferencia de qualquer gerador próprio.

```tsx
function CampoSenha() {
  const id = useId()
  return (
    <>
      <label htmlFor={`${id}-senha`}>Senha</label>
      <input id={`${id}-senha`} type="password" aria-describedby={`${id}-dica`} />
      <p id={`${id}-dica`}>Mínimo de 12 caracteres.</p>
    </>
  )
}
```

Um contador global ou `Math.random()` produziria valores diferentes no servidor e no cliente, causando erro de hidratação — ver [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) § 1. `useId` é gerado a partir da **posição do componente na árvore**, então é o mesmo dos dois lados.

**Um `useId` por componente, com sufixos**, é o padrão recomendado quando há vários elementos relacionados — como no exemplo acima. Chamar o Hook várias vezes funciona, mas é desnecessário.

| ID | Regra |
| --- | --- |
| `REACT-UTIL-01` | IDs de acessibilidade (`htmlFor`, `aria-describedby`, `aria-labelledby`) **MUST** vir de `useId`, não de contador nem de random. |
| `REACT-UTIL-02` | `useId` **NEVER** é usado como `key` de lista — a key deve vir da identidade do dado. |

`REACT-UTIL-02` é o erro mais comum com este Hook. `key` identifica **qual dado** é aquele item entre renders; `useId` identifica uma **posição na árvore**. Usar `useId` como key não resolve o problema que a key existe para resolver. Ver [React - Patterns](react-patterns.md) § 8.

---

## 2. `useSyncExternalStore`

```tsx
const snapshot = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot?)
```

Assina uma store **fora** do React de forma segura sob renderização concorrente.

| Parâmetro | O que é |
| --- | --- |
| `subscribe` | recebe um callback, registra o listener e **retorna a função de unsubscribe** |
| `getSnapshot` | retorna o valor atual da store |
| `getServerSnapshot?` | valor usado no SSR e na hidratação inicial |

```tsx
function useLarguraJanela() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('resize', callback)
      return () => window.removeEventListener('resize', callback)
    },
    () => window.innerWidth,
    () => 1024,   // sem window no servidor
  )
}
```

### O problema que ele resolve

A alternativa ingênua — `useEffect` + `useState` — permite **tearing**: durante uma renderização concorrente interrompível, partes da árvore podem ler valores diferentes da mesma store no mesmo frame. `useSyncExternalStore` garante consistência.

### A armadilha central

**`getSnapshot` deve retornar um valor com identidade estável enquanto nada mudar.** Retornar um objeto novo a cada chamada gera loop infinito de render.

```tsx
// ERRADO — novo objeto a cada chamada → loop infinito
() => ({ largura: window.innerWidth, altura: window.innerHeight })

// CERTO — valor primitivo
() => window.innerWidth

// CERTO — objeto cacheado na store, com identidade nova só quando muda
() => store.getEstadoCacheado()
```

| ID | Regra |
| --- | --- |
| `REACT-UTIL-03` | `getSnapshot` **MUST** retornar valor imutável e com identidade estável enquanto a store não mudar. |
| `REACT-UTIL-04` | `subscribe` **MUST** ter identidade estável — defina fora do componente ou memoize, ou o React reassina a cada render. |
| `REACT-UTIL-05` | Em app com SSR, `getServerSnapshot` **MUST** ser fornecido, sem acessar APIs de browser. |

### Quando você precisa dele

Quase nunca diretamente. Bibliotecas de estado (Redux) já o usam internamente. Use-o à mão para APIs do browser (`navigator.onLine`, `matchMedia`, `localStorage`) ou uma store própria pequena.

Para dado remoto, não é a ferramenta.

---

## 3. `useDebugValue`

```tsx
useDebugValue(value, format?)
```

Rótulo do Hook customizado no React DevTools. Só isso.

```tsx
function useOnlineStatus() {
  const online = useSyncExternalStore(subscribe, () => navigator.onLine, () => true)
  useDebugValue(online ? 'Online' : 'Offline')
  return online
}
```

O segundo parâmetro adia a formatação — a função só roda quando o Hook é inspecionado no DevTools, evitando custo em cada render:

```tsx
useDebugValue(date, (d) => d.toISOString())
```

| ID | Regra |
| --- | --- |
| `REACT-UTIL-06` | `useDebugValue` **MUST** aparecer apenas em Hooks customizados compartilhados; em Hook usado num único lugar é ruído. |
| `REACT-UTIL-07` | Formatação custosa **MUST** ir no segundo parâmetro, não computada inline. |

Não afeta o comportamento em produção e não substitui log nem teste.

---

## 4. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `useId` como `key` de lista | id do domínio · `REACT-UTIL-02` |
| ID de acessibilidade por contador global | `useId` · `REACT-UTIL-01` |
| `getSnapshot` retornando objeto novo | primitivo ou valor cacheado · `REACT-UTIL-03` |
| `subscribe` recriado a cada render | definir fora do componente · `REACT-UTIL-04` |
| `useSyncExternalStore` para dado remoto | TanStack Query |
| `useEffect` + `useState` para assinar store | `useSyncExternalStore` (evita tearing) |
| `useDebugValue` em todo Hook | apenas em Hooks compartilhados · `REACT-UTIL-06` |

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Estado e Reatividade](react-estado-e-reatividade.md) · [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md)
- · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [useId](https://react.dev/reference/react/useId)
- [useSyncExternalStore](https://react.dev/reference/react/useSyncExternalStore)
- [useDebugValue](https://react.dev/reference/react/useDebugValue)
