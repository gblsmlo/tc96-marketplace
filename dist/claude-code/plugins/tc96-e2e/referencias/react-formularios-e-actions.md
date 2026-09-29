---
titulo: React - Formulários e Actions
Link: https://react.dev/reference/react/useActionState
tags:
  - react
  - forms
  - actions
  - agent-context
source: "Documentação oficial do React — useActionState, useOptimistic, useFormStatus"
verificado-em: 2026-08-14
---

# React — Formulários e Actions

> `useActionState` · `useOptimistic` · `useFormStatus` · `<form action>`
>
> O modelo de Actions do React: submissão, pendência, erro e feedback otimista sem gerenciar quatro `useState` por formulário.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: Action

Uma **Action** é uma função (frequentemente `async`) passada ao React para executar uma operação, com o React gerenciando pendência, erros e ordenação. Ela roda dentro de uma Transition — daí a integração natural com `isPending` e com Suspense.

Substitui o padrão manual:

```tsx
// ANTES — quatro estados coordenados à mão
const [isLoading, setIsLoading] = useState(false)
const [error, setError] = useState<string | null>(null)
const [data, setData] = useState<Result | null>(null)

async function handleSubmit(e: React.FormEvent) {
  e.preventDefault()
  setIsLoading(true)
  setError(null)
  try {
    setData(await submit(new FormData(e.currentTarget)))
  } catch (err) {
    setError((err as Error).message)
  } finally {
    setIsLoading(false)
  }
}
```

> **Verificado na fonte:** `useActionState` **funciona em React puro, sem framework**. Só o parâmetro `permalink` (progressive enhancement) exige um framework com Server Components. Isso torna as Actions utilizáveis numa SPA Vite, não só em Next.js.
>
> **Requisito de versão:** todo o modelo de Actions — `useActionState`, `useOptimistic`, `useFormStatus`, `<form action>` — chegou no **React 19**. Em React 18 nada disto existe (`useFormState`, o antecessor de `useActionState`, só existia em canary com framework). Confirme a versão antes de usar.

---

## 2. `<form action>`

```tsx
<form action={minhaAction}>
  <input name="titulo" />
  <button type="submit">Salvar</button>
</form>
```

A função recebe o `FormData` do formulário. O React:

- previne o comportamento padrão automaticamente — **sem `e.preventDefault()`**;
- envolve a submissão em uma Transition, sem `startTransition` manual;
- reseta o formulário não controlado após uma Action bem-sucedida.

`formAction` em `<button>` e `<input type="submit">` permite ações diferentes no mesmo formulário.

| ID | Regra |
| --- | --- |
| `REACT-FORM-01` | Com `<form action>`, **NEVER** chamar `e.preventDefault()` — o React já previne. |
| `REACT-FORM-02` | Campos que a Action lê **MUST** ter `name`; `FormData` é indexado por `name`, não por id nem por estado. |

---

## 3. `useActionState`

```tsx
const [state, formAction, isPending] = useActionState(action, initialState, permalink?)
```

| Retorno | O que é |
| --- | --- |
| `state` | `initialState` na primeira vez; depois, o retorno da action |
| `formAction` | a função a passar para `action` do form (ou a despachar manualmente) |
| `isPending` | `true` enquanto qualquer action despachada estiver pendente |

A action recebe `(previousState, payload)` — com `<form action>`, o payload é o `FormData`.

```tsx
import { useActionState, useId } from 'react'
import { z } from 'zod'

const topicoSchema = z.object({
  titulo: z.string().min(5, 'O título deve ter no mínimo 5 caracteres.'),
})

type FormState = {
  ok: boolean
  message?: string                          // erro geral (rede, 500)
  fieldErrors?: Record<string, string>      // erro por campo
}

async function criarTopico(_prev: FormState, formData: FormData): Promise<FormState> {
  // formData.get() devolve string | File | null — coagir antes de validar
  const parsed = topicoSchema.safeParse({ titulo: String(formData.get('titulo') ?? '') })

  if (!parsed.success) {
    // flatten() devolve { fieldErrors: Record<string, string[]> } — pegamos a 1ª mensagem
    const { fieldErrors } = z.flattenError(parsed.error)
    return {
      ok: false,
      fieldErrors: Object.fromEntries(
        Object.entries(fieldErrors).map(([campo, msgs]) => [campo, msgs![0]]),
      ),
    }
  }

  try {
    await api.criarTopico(parsed.data)
    return { ok: true }
  } catch {
    // falha inesperada vira mensagem, não exceção: lançar derrubaria o formulário
    return { ok: false, message: 'Não foi possível salvar. Tente de novo.' }
  }
}

function NovoTopico() {
  const [state, formAction, isPending] = useActionState(criarTopico, { ok: false })
  const id = useId()
  const erro = state.fieldErrors?.titulo

  return (
    <form action={formAction}>
      <label htmlFor={`${id}-titulo`}>Título</label>
      <input
        id={`${id}-titulo`}
        name="titulo"
        aria-invalid={!!erro}
        aria-describedby={erro ? `${id}-titulo-erro` : undefined}
      />
      {erro && <p id={`${id}-titulo-erro`} role="alert">{erro}</p>}

      {state.message && <p role="alert">{state.message}</p>}
      {state.ok && <p role="status">Tópico criado.</p>}

      <button disabled={isPending}>{isPending ? 'Salvando…' : 'Salvar'}</button>
    </form>
  )
}
```

Quatro decisões do exemplo que não são óbvias:

- **`String(... ?? '')`** — `formData.get()` devolve `string | File | null`. Campo vazio devolve `''`, campo ausente devolve `null`; o schema precisa receber string.
- **IDs via `useId`** — `aria-describedby` precisa apontar para o parágrafo de erro, e o ID tem que ser estável entre servidor e cliente. Ver `REACT-UTIL-01` em [React - Hooks Utilitários](react-hooks-utilitarios.md).
- **`role="alert"` para erro, `role="status"` para sucesso** — o primeiro interrompe o leitor de tela, o segundo espera a pausa. Erro de submissão justifica interrupção; confirmação não.
- **Falha de rede vira `message`, não exceção** — lançar acionaria o Error Boundary e removeria o formulário da tela, junto com o que o usuário digitou.

O padrão-chave: **erro esperado é retornado como estado, não lançado.** Lançar manda o erro para o Error Boundary e derruba a UI do formulário — comportamento errado para "título obrigatório". `REACT-ASYNC-09`.

### Caveats verificados

| Caveat | Consequência prática |
| --- | --- |
| Despachos são enfileirados e executados em sequência | submissões rápidas não competem |
| Fora de `<form action>`, o dispatch **MUST** rodar em `startTransition` | chamada manual exige o wrapper |
| `formAction` tem identidade estável | seguro omitir de dependências de Effect |
| Se a action lança, o React cancela a fila e aciona o Error Boundary | erro esperado deve ser retornado, não lançado |
| Em `<StrictMode>` a action **não** é invocada duas vezes | ela pode ter side effects, ao contrário de um reducer |
| Com Server Functions, `initialState` e payload **MUST** ser serializáveis | nada de classes ou funções no estado |
| Ao setar estado depois de um `await`, envolva em novo `startTransition` | `REACT-PERF-06` |

| ID | Regra |
| --- | --- |
| `REACT-FORM-03` | Todo erro **esperado** **MUST** ser retornado no estado da action, nunca lançado. Vale para validação, mas também para conflito (409), não encontrado (404), sem permissão (403) e falha de rede — qualquer coisa que o formulário saiba apresentar. Só erro genuinamente inesperado sobe para o boundary. Apelido de `REACT-ASYNC-09`. |
| `REACT-FORM-04` | Dispatch fora de `<form action>` **MUST** ocorrer dentro de `startTransition`. |

---

## 4. `useFormStatus`

```tsx
import { useFormStatus } from 'react-dom'

const { pending, data, method, action } = useFormStatus()
```

Lê o status do `<form>` **ancestral**. Único Hook exportado por `react-dom`.

```tsx
function SubmitButton() {
  const { pending } = useFormStatus()
  return <button disabled={pending}>{pending ? 'Enviando…' : 'Enviar'}</button>
}

// Precisa estar DENTRO do form, em um componente separado
<form action={minhaAction}>
  <input name="email" />
  <SubmitButton />
</form>
```

**A restrição que quebra o uso ingênuo:** o Hook lê um form ancestral. Chamado no mesmo componente que renderiza o `<form>`, ele não enxerga esse form e `pending` fica sempre `false`. Um componente filho é obrigatório.

| ID | Regra |
| --- | --- |
| `REACT-FORM-05` | `useFormStatus` **MUST** ser chamado em um componente descendente do `<form>`, nunca no componente que o renderiza. |

**Qual usar, com regra de precedência:** se o componente já tem `isPending` do `useActionState` em escopo, use-o — é uma dependência a menos e não depende de posição na árvore. `useFormStatus` existe para o caso em que essa informação **não pode ser passada por prop**: um `<SubmitButton>` de design system, usado em formulários que você não controla. Se o botão é reutilizável **e** você controla o formulário, prefira passar `isPending` como prop; explícito vence implícito.

---

## 5. `useOptimistic`

```tsx
const [optimisticState, setOptimistic] = useOptimistic(value, reducer?)
```

Mostra o resultado esperado **imediatamente**, enquanto a Action está pendente.

```tsx
function Mensagens({ mensagens, enviar }: Props) {
  const [otimistas, addOtimista] = useOptimistic(
    mensagens,
    (state: Mensagem[], nova: string) => [...state, { texto: nova, pendente: true }],
  )

  async function action(formData: FormData) {
    const texto = String(formData.get('texto'))
    addOtimista(texto)                 // aparece na hora
    await enviar(texto)                // ao concluir, converge para `mensagens`
  }

  return (
    <>
      {otimistas.map((m, i) => (
        <p key={i}>{m.texto}{m.pendente && ' (enviando…)'}</p>
      ))}
      <form action={action}><input name="texto" /></form>
    </>
  )
}
```

Caveats verificados:

- o setter **deve** ser chamado dentro de uma Transition ou de uma Action, senão o React alerta e o estado otimista reverte imediatamente;
- o estado otimista só existe enquanto a Action está pendente;
- o setter **não** pode ser chamado durante o render;
- não há render extra para "limpar" o otimista — otimista e real convergem no mesmo render.

O rollback é automático: se a Action falha, o estado volta a `value`. Isso é diferente de uma mutation otimista de cache, onde snapshot e rollback são explícitos.

| ID | Regra |
| --- | --- |
| `REACT-FORM-06` | O setter de `useOptimistic` **MUST** ser chamado dentro de uma Action ou Transition. |
| `REACT-FORM-07` | `useOptimistic` **NEVER** é fonte de verdade — a verdade é `value`, que converge ao fim da Action. |

---

## 6. Ponte com o stack

| Cenário | Ferramenta |
| --- | --- |
| Formulário simples, poucos campos, validação no submit | Actions nativas desta nota |
| Formulário complexo: validação por campo, arrays, wizard | React Hook Form — [React Hook Form](react-hook-form.md) § 5.4 decide a fronteira |
| Validação de schema (cliente e servidor) | |
| Mutação remota com cache a invalidar | mutation do TanStack Query |
| Update otimista sobre cache remoto | mutation otimista, não `useOptimistic` — |
| Operação no servidor | |

**Critério de não empilhar:** `useOptimistic` e mutation otimista da Query resolvem o mesmo problema em camadas diferentes. Se o dado vive no cache da Query, o otimismo pertence à mutation. Usar os dois produz duas fontes de verdade divergindo.

| ID | Regra |
| --- | --- |
| `REACT-FORM-08` | Toda função de servidor invocada por uma Action **MUST** revalidar e autorizar na fronteira, independentemente da validação no cliente. |

---

## 7. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `e.preventDefault()` com `<form action>` | remover · `REACT-FORM-01` |
| Campos sem `name` lidos via `FormData` | adicionar `name` · `REACT-FORM-02` |
| Lançar erro de validação da action | retornar no estado · `REACT-FORM-03` |
| `useFormStatus` no mesmo componente do `<form>` | extrair componente filho · `REACT-FORM-05` |
| `setOptimistic` fora de Action/Transition | envolver · `REACT-FORM-06` |
| `useState` espelhando o estado da action | usar `state` do `useActionState` |
| `useOptimistic` + mutation otimista juntos | escolher uma camada |
| Confiar só na validação do cliente | validar no servidor · `REACT-FORM-08` |

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Suspense e Assincronia](react-suspense-e-assincronia.md) · [React - Server Components e Diretivas](react-server-components-e-diretivas.md)
- [React Hook Form](react-hook-form.md) — a alternativa para formulário complexo, com o critério de escolha na § 5.4
- · · · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [useActionState](https://react.dev/reference/react/useActionState) — caveats e independência de framework confirmados
- [useOptimistic](https://react.dev/reference/react/useOptimistic) — confirmado estável
- [useFormStatus](https://react.dev/reference/react-dom/hooks/useFormStatus)
- [`<form>`](https://react.dev/reference/react-dom/components/form)
