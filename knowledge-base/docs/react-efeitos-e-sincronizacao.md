---
titulo: React - Efeitos e Sincronização
Link: https://react.dev/reference/react/useEffect
tags:
 - react
 - effects
 - hooks
 - agent-context
source: "Documentação oficial do React — useEffect, useLayoutEffect, useInsertionEffect, useEffectEvent"
verificado-em: 2026-08-14
---

# React — Efeitos e Sincronização

> `useEffect` · `useLayoutEffect` · `useInsertionEffect` · `useEffectEvent`
>
> O satélite mais importante para revisar código gerado por IA: **a maioria dos `useEffect` que um agente escreve não deveria existir.**

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: Effect é sincronização, não "código que roda depois"

Um Effect existe para **sincronizar o React com um sistema externo** — algo que vive fora da árvore de componentes: uma conexão, uma subscription do browser, um timer, um nó de DOM não gerenciado, uma biblioteca de terceiros.

Não é um gancho de ciclo de vida. Não é "onde colocar código que precisa rodar depois do render". Reformular a pergunta muda a resposta:

> ❌ "Quando isso deve rodar?"
> ✅ "Que sistema externo isto mantém em sincronia, e como se desfaz essa sincronização?"

Se a segunda pergunta não tem resposta, não é um Effect.

### O ciclo é sincronizar / dessincronizar

Um Effect não tem "montar" e "desmontar" — tem **começar a sincronizar** e **parar de sincronizar**. O cleanup não é opcional nem é só para desmontagem: ele roda antes de cada re-execução também.

```tsx
useEffect( => {
 const connection = createConnection(serverUrl, roomId)
 connection.connect
 return => connection.disconnect // desfaz exatamente o que o setup fez
}, [serverUrl, roomId])
```

Ao trocar `roomId`: o React desconecta da sala antiga e conecta na nova. O mesmo código cobre montagem, atualização e desmontagem — porque descreve sincronização, não eventos de ciclo de vida.

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-01` | Todo Effect que cria subscription, conexão, timer, listener **ou requisição em voo** **MUST** retornar cleanup que desfaz exatamente o setup. |

### O callback do Effect nunca é `async`

```tsx
// ERRADO — a função async retorna uma Promise, e o React interpreta
// esse retorno como se fosse a função de cleanup
useEffect(async => {
 const data = await carregar
 setData(data)
}, [])

// CERTO — async por dentro, cleanup de verdade por fora
useEffect( => {
 let active = true
 carregar.then((data) => { if (active) setData(data) })
 return => { active = false }
}, [])
```

O React espera que o setup devolva **uma função de cleanup ou nada**. Uma função `async` sempre devolve Promise, então o cleanup some silenciosamente — sem erro, sem aviso.

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-12` | O callback de `useEffect` **NEVER** é `async` — declare a função assíncrona dentro dele. |

### Por que `<StrictMode>` roda o Effect duas vezes

Em desenvolvimento, o React monta, desmonta e remonta cada componente para verificar se o cleanup realmente desfaz o setup. Se algo quebra com a execução dupla, o cleanup está incompleto — **é o bug sendo revelado, não um bug do React**. A correção nunca é suprimir o comportamento.

---

## 2. A array de dependências

Ela **descreve** o que o Effect lê. Não é um seletor de "quando rodar".

Todo valor reativo (props, estado, e qualquer coisa derivada deles) usado dentro do Effect **deve** estar na lista. O linter `react-hooks/exhaustive-deps` computa isso corretamente; discordar dele é quase sempre estar errado.

| Lista | Significado |
| --- | --- |
| omitida | roda após todo render |
| `[]` | roda na montagem e no cleanup da desmontagem |
| `[a, b]` | re-sincroniza quando `a` ou `b` mudam por identidade |

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-02` | Dependências **MUST** listar todo valor reativo lido pelo Effect. |
| `REACT-EFFECT-03` | `eslint-disable` em `exhaustive-deps` **NEVER** é a correção — é sinal de que o Effect está errado. |

### Como remover uma dependência de verdade

Não apague da lista. Faça o valor deixar de ser lido:

| Situação | Correção |
| --- | --- |
| Objeto/função recriado a cada render | mova para fora do componente, ou para dentro do Effect |
| Só precisa do valor anterior do estado | forma updater: `setX(x =>...)` |
| Valor lido mas **não deve** re-sincronizar | `useEffectEvent` (§ 4) |
| É estado derivado | não é Effect — calcule no render |

---

## 3. Quando **não** usar Effect

A tabela que mais corrige código gerado.

| Intenção | ❌ Effect | ✅ Correto |
| --- | --- | --- |
| Derivar valor de props/estado | `useEffect( => setB(f(a)), [a])` | `const b = f(a)` no render |
| Cálculo caro | Effect + estado | `useMemo( => f(a), [a])` |
| Resetar estado ao trocar de item | Effect comparando props | `key` no componente |
| Ajustar estado quando prop muda | Effect | calcular no render, ou repensar a posse |
| Responder a um clique/submit | Effect observando estado | event handler |
| Buscar dados | `useEffect` + `fetch` | TanStack Query |
| Notificar o pai de uma mudança | Effect chamando `onChange` | chamar no handler que causou |

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-04` | Effect **NEVER** deriva estado a partir de outro estado ou prop. |
| `REACT-EFFECT-05` | Lógica que responde a uma interação específica **MUST** ficar no event handler. |

### Data fetching: por que é o pior caso

```tsx
// ERRADO — sem cancelamento, sem cache, sem dedupe, com race condition
useEffect( => {
 fetch(`/api/users/${id}`)
.then((r) => r.json)
.then(setUser)
}, [id])
```

Se `id` muda rápido, a resposta da primeira requisição pode chegar **depois** da segunda e sobrescrever o dado correto. O mínimo aceitável é ignorar respostas obsoletas:

```tsx
useEffect( => {
 let active = true
 fetch(`/api/users/${id}`)
.then((r) => r.json)
.then((data) => { if (active) setUser(data) })
 return => { active = false }
}, [id])
```

Com `AbortController`, a requisição obsoleta é de fato cancelada, não apenas ignorada:

```tsx
useEffect( => {
 const controller = new AbortController

 fetch(`/api/users/${id}`, { signal: controller.signal })
.then((r) => r.json)
.then(setUser)
.catch((err) => {
 if (err.name === 'AbortError') return // cancelamento não é erro
 setError(err)
 })

 return => controller.abort
}, [id])
```

O `catch` precisa filtrar `AbortError` explicitamente — senão todo cleanup vira um erro na tela.

Mesmo corrigido, continua sem cache, sem revalidação, sem dedupe e sem retry. **Ponte:** no meu stack isso é TanStack Query — e.

### "Meu fetch dispara duas vezes em dev"

É `<StrictMode>` fazendo o que deve: montar, desmontar e remontar para verificar o cleanup. Com `AbortController` ou flag no cleanup, a duplicata é inofensiva. **Sem cleanup, a execução dupla é o aviso de que existe uma race condition esperando um usuário real.** Não remova o StrictMode — ver [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md) § 3.

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-06` | Fetch em `useEffect` **NEVER** entra em código novo. Se for inevitável, **MUST** tratar race condition com flag ou `AbortController`. |

**O que conta como "inevitável"** — sem critério, a regra vira negociável em PR. Aceite apenas: (a) o projeto não tem e não vai adotar biblioteca de data fetching, decisão já tomada e registrada; (b) é uma chamada única, sem cache, sem revalidação e sem outro consumidor do mesmo dado — telemetria, health check, warm-up. Fora disso, "seria trabalhoso migrar" não é inevitabilidade. Para código legado que já funciona, a regra não obriga refatorar: obriga não repetir, e obriga corrigir a race condition se o Effect for tocado.

---

## 4. `useEffectEvent`

```tsx
const onEvent = useEffectEvent(callback)
```

Resolve um conflito específico: o Effect precisa **ler** um valor, mas mudanças nesse valor **não devem** re-sincronizar.

```tsx
function ChatRoom({ roomId, theme }: { roomId: string; theme: Theme }) {
 const onConnected = useEffectEvent( => {
 showNotification('Conectado!', theme) // lê theme sempre atualizado
 })

 useEffect( => {
 const connection = createConnection(roomId)
 connection.on('connected', => onConnected)
 connection.connect
 return => connection.disconnect
 }, [roomId]) // theme fora da lista, corretamente
}
```

Sem `useEffectEvent`, incluir `theme` reconectaria o chat a cada troca de tema; omitir `theme` mostraria a notificação com o tema antigo. O Effect Event lê sempre os valores mais recentes do render e é **excluído das dependências por definição**.

### Restrições (citadas da fonte)

> "you can only call it **at the top level of your component** or your own Hooks. You can't call it inside loops or conditions."

> "Effect Events can only be called from inside Effects or other Effect Events. Do not call them during rendering or pass them to other components or Hooks."

> "Effect Event functions do not have a stable identity. Their identity intentionally changes on every render."

E o aviso que importa mais:

> "Do not use `useEffectEvent` to avoid specifying dependencies in your Effect's dependency array. This hides bugs and makes your code harder to understand. Only use it for logic that is genuinely an event fired from Effects."

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-07` | Effect Event **NEVER** é chamado no render, nem passado como prop a outro componente ou Hook. |
| `REACT-EFFECT-08` | Effect Event **NEVER** entra na array de dependências. |
| `REACT-EFFECT-09` | `useEffectEvent` **NEVER** é usado para silenciar o linter — apenas para lógica que é genuinamente um evento disparado por um Effect. |

O `eslint-plugin-react-hooks` faz cumprir essas restrições.

---

## 5. As três variantes

| Hook | Quando roda | Usar quando |
| --- | --- | --- |
| `useEffect` | após o paint, sem bloquear | **caso geral** |
| `useLayoutEffect` | após o commit, **antes** do paint | precisa medir layout e ajustar antes que o usuário veja |
| `useInsertionEffect` | antes de o React mexer no DOM | **apenas bibliotecas CSS-in-JS** injetando `<style>` |

```tsx
// Caso legítimo de useLayoutEffect: medir para posicionar sem flicker
useLayoutEffect( => {
 const { height } = ref.current!.getBoundingClientRect
 setTooltipHeight(height)
}, [])
```

`useLayoutEffect` **bloqueia o paint**. Usá-lo por hábito degrada performance visível. `useInsertionEffect` não deve aparecer em código de aplicação — não há acesso a refs nem é possível agendar atualizações dali.

| ID | Regra |
| --- | --- |
| `REACT-EFFECT-10` | `useLayoutEffect` **MUST** ser justificado por medição de layout antes do paint. |
| `REACT-EFFECT-11` | `useInsertionEffect` **NEVER** aparece em código de aplicação. |

---

## 6. Checklist de revisão

- [ ] Existe um sistema externo real? Se não → o Effect não deveria existir
- [ ] Setup com subscription/timer/listener tem cleanup simétrico? → `REACT-EFFECT-01`
- [ ] Todas as dependências reativas estão listadas, sem `eslint-disable`? → `REACT-EFFECT-02/03`
- [ ] O Effect chama `setState` com valor derivado de props/estado? → `REACT-EFFECT-04`
- [ ] Há `fetch` dentro? → `REACT-EFFECT-06`
- [ ] `useLayoutEffect` sem medição de layout? → `REACT-EFFECT-10`
- [ ] Effect Event chamado fora de um Effect ou passado adiante? → `REACT-EFFECT-07`

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- ·
- ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [useEffect](https://react.dev/reference/react/useEffect) · [useLayoutEffect](https://react.dev/reference/react/useLayoutEffect) · [useInsertionEffect](https://react.dev/reference/react/useInsertionEffect)
- [useEffectEvent](https://react.dev/reference/react/useEffectEvent) — confirmado como estável, sem marcação de experimental
- [Rules of React](https://react.dev/reference/rules)
