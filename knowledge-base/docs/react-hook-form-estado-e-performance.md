---
titulo: React Hook Form - Estado e Performance
Link: https://react-hook-form.com/docs/useform/formstate
tags:
 - react
 - forms
 - react-hook-form
 - performance
 - agent-context
source: "Documentação oficial — https://react-hook-form.com/docs"
verificado-em: 2026-08-15
---

# React Hook Form — Estado e Performance

> **Cobre:** `formState` e seu Proxy · as cinco formas de ler (`getValues`, `watch`, `useWatch`, `useFormState`, `subscribe`) · `setValue`, `reset`, `getFieldState` · `defaultValues` × `values` · `shouldUnregister` e `disabled` no nível do formulário · `useFieldArray` · formulário em várias etapas · a ordem de investigação de re-render.
>
> **Não cobre:** como um campo entra no formulário (`register`, `Controller`, `useController`, `FormProvider`) — [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md). O que é válido e o que fazer com erro (`mode`, `resolver`, `setError`, `trigger`) — [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md). Quem é dono da submissão e as pontes com o stack — [React Hook Form](react-hook-form.md) § 5.4 e § 8.

Entrada: [React Hook Form](react-hook-form.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: a assinatura é criada pela leitura

RHF guarda os valores fora do ciclo de render. A consequência é que **nada re-renderiza por padrão** — nem ao digitar, nem quando um erro aparece. Um componente só re-renderiza se assinou alguma coisa.

E a assinatura **não é declarada: é criada pela leitura**. `formState` vem embrulhado num `Proxy` que registra quais propriedades foram acessadas **durante o render**, e só recalcula e notifica essas. A fonte é literal:

> "Returned `formState` is wrapped with a Proxy to improve render performance and skip extra logic if a specific state is not subscribed to. Therefore, make sure you invoke or read it before a render in order to enable the state update."

```tsx
// ✅ o destructuring é a leitura — assina isDirty e isValid
const { formState: { isDirty, isValid } } = useForm<Perfil>
return <button disabled={!isDirty || !isValid}>Salvar</button>

// ❌ isDirty é lido e assinado; isValid NÃO — o `||` curto-circuita quando
// isDirty é true, então o Proxy nunca vê a leitura de isValid
const { formState } = useForm<Perfil>
return <button disabled={!formState.isDirty || !formState.isValid}>Salvar</button>
```

As duas formas parecem idênticas, e a segunda é a causa mais comum de "o botão não habilita". Note **exatamente** onde está o defeito, porque é fácil tirar a lição errada: o problema **não** é guardar o objeto `formState` — é o **acesso condicional**. O comentário da própria fonte é preciso: *"`formState.isValid` is accessed conditionally, so the Proxy does not subscribe to changes of that state."*

Ou seja, `const formState = useFormState({ control }); return <p>{formState.errors.nome?.message}</p>` funciona: `errors` é lido incondicionalmente. O que quebra é a propriedade que fica atrás de um `&&`, `||`, ternário ou `if`. Desestruturar no topo é a forma mais simples de nunca cair nisso — não a única.

Isso não é bug: é o mecanismo evitando calcular `isValid` para quem não pediu. `RHF-CORE-02`.

**Onde a leitura acontece define onde o re-render acontece.** É a partir daí que todo o resto desta nota se organiza: escolher entre `watch` e `useWatch` não é escolher entre duas formas de ler o mesmo valor — é escolher **qual componente re-renderiza**.

> **Corolário para `useEffect`.** A fonte declara que "`formState` is updated in batch. If you want to subscribe via `useEffect`, make sure that you place the entire `formState` in the optional array." A dependência correta é o objeto inteiro, não a propriedade:
>
> ```tsx
> // ✅ o objeto inteiro
> useEffect( => {
> if (formState.errors.nome) { /* … */ }
> }, [formState])
>
> // ❌ a propriedade — não dispara, porque a atualização vem em lote
> useEffect( => {
> if (formState.errors.nome) { /* … */ }
> }, [formState.errors])
> ```
>
> Isso vale para `formState` **não desestruturado**. Uma propriedade já extraída no corpo do componente (`const { isSubmitSuccessful } = formState`) é um valor comum e entra na lista normalmente — é o que `RHF-STATE-02` faz.

---

## 2. `formState` — o inventário

| Propriedade | Tipo | O que é | Desde |
| --- | --- | --- | --- |
| `errors` | `object` | erros por campo, no shape do formulário | — |
| `isDirty` | `boolean` | o usuário modificou algum input | — |
| `dirtyFields` | `object` | quais campos o usuário modificou | — |
| `touchedFields` | `object` | por quais campos o usuário passou | — |
| `defaultValues` | `object` | o default atual — o do `useForm` ou o atualizado via `reset` | v7.37.0 |
| `isSubmitted` | `boolean` | houve submit; permanece `true` até o `reset` | — |
| `isSubmitting` | `boolean` | submissão em curso | — |
| `isSubmitSuccessful` | `boolean` | a submissão terminou sem erro de runtime | — |
| `submitCount` | `number` | quantas vezes o formulário foi submetido | — |
| `isValid` | `boolean` | o formulário não tem erros — ver caveat | — |
| `isValidating` | `boolean` | validação em curso | — |
| `validatingFields` | `object` | **quais** campos estão em validação assíncrona | v7.51.0 |
| `isLoading` | `boolean` | carregando `defaultValues` **assíncronos** | v7.41.0 |
| `disabled` | `boolean` | o formulário está desabilitado via a prop `disabled` | v7.48.0 |
| `isReady` | `boolean` | a assinatura de `formState` terminou de ser montada | v7.56.0 |

### 2.1 `isDirty` × `dirtyFields`

Não são a mesma informação em granularidade diferente — são duas perguntas.

| | Pergunta | Forma |
| --- | --- | --- |
| `isDirty` | "algo neste formulário mudou?" | `boolean` agregado |
| `dirtyFields` | "o que exatamente mudou?" | objeto com os campos modificados |

Habilitar um botão Salvar é `isDirty`. Enviar um `PATCH` só com o que mudou é `dirtyFields`. Usar `isDirty` para a segunda pergunta envia o objeto inteiro; usar `dirtyFields` para a primeira obriga a contar chaves a cada render.

Três restrições verificadas:

- **A comparação é sempre contra `defaultValues`.** Sem `defaultValues` cobrindo o campo, compara-se contra `undefined` e o resultado não significa nada. `RHF-CORE-01`.
- **`File`, classes e objetos customizados não são suportados** nessa comparação. A fonte diz que inputs de arquivo "will need to be managed at the app level due to the ability to cancel file selection". Objetos com métodos no protótipo (Moment, Luxon) devem ser evitados em `defaultValues`.
- **`shouldDirty` do `setValue` só garante a marcação imediata do campo alvo.** Como `isDirty` sempre recompara contra `defaultValues`, uma alteração posterior em qualquer campo pode recalcular `dirtyFields`.

### 2.2 `isValid` é mais fraco do que parece

`setError` força `isValid` para `false` **imediatamente**, e a fonte registra que esse valor "is not derived from validation and will be overwritten the next time validation runs".

`isValid` responde "não há erro registrado agora". Não responde "o formulário está correto", e muito menos "o servidor aceitou" — para isso existe `isSubmitSuccessful`. `RHF-ERR-05`.

### 2.3 `isSubmitSuccessful`

"Indicates that the form was successfully submitted without any runtime error." A leitura importante está em *runtime error*: ele diz que o `onSubmit` **não lançou**, não que a operação de negócio deu certo. Como erro esperado não deve ser lançado de dentro do `onSubmit` (`RHF-ERR-03`), um `400` tratado com `setError` deixa `isSubmitSuccessful` em `true`.

Isso é consistente, não contraditório: a submissão do formulário ocorreu; o resultado de negócio é outro assunto. Se você resetar o formulário ao ver `isSubmitSuccessful`, resete apenas depois de a chamada ter tido sucesso de fato — ver § 4.3.

### 2.4 `isReady` resolve um bug de ordem

> "Renders children before the parent completes setup. Use an `isReady` flag to ensure the form is initialized before updating state from the child."

Um componente filho que chama `setValue` no mount pode fazê-lo antes de a assinatura existir — e a chamada se perde, em silêncio.

```tsx
// No componente que chamou useForm: a assinatura já existe
useEffect( => { setValue('cupom', cupomDaUrl) }, [])

// Em componente filho: precisa esperar
const { isReady } = useFormState({ control })
useEffect( => {
 if (isReady) setValue('cupom', cupomDaUrl)
}, [isReady])
```

É o mesmo problema de ordem que morde `useWatch` (§ 3.4).

---

## 3. As cinco formas de ler

Esta tabela é o centro do satélite. O eixo não é "o que devolve", é **onde o re-render acontece**.

| API | Assina? | Quem re-renderiza | Onde chamar | Use quando |
| --- | --- | --- | --- | --- |
| `getValues` | não | ninguém | qualquer lugar | leitura pontual dentro de um handler |
| `watch(name?)` | sim | o componente que chamou — normalmente a **raiz** | junto do `useForm` | você precisa mesmo do form inteiro na raiz |
| `useWatch({ control, name })` | sim | **só** o componente que chamou | qualquer componente | render que depende de um valor |
| `useFormState({ control })` | sim | **só** o componente que chamou | qualquer componente | render que depende de erro, dirty, submitting |
| `subscribe({ … })` | sim | **ninguém** | dentro de `useEffect` | efeito colateral sem UI |

### 3.1 `getValues` — leitura sem custo

```tsx
const onAplicarCupom = => {
 const cupom = getValues('cupom') // não assina, não re-renderiza
 if (cupom) validarCupom(cupom)
}
```

O erro simétrico também existe: usar `getValues` para **renderizar**. Como não assina, a tela não atualiza, e o valor exibido fica congelado no do último render por outro motivo.

### 3.2 `watch` — e por que quase sempre é a escolha errada

Quatro sobrecargas verificadas:

```ts
watch(name: string, defaultValue?: unknown): unknown
watch(names: string[], defaultValue?: { [k: string]: unknown }): unknown[]
watch: { [k: string]: unknown }
watch(callback, defaultValues?): { unsubscribe: => void } // Deprecated — ver § 3.6
```

```tsx
const tipo = watch('tipo') // re-renderiza ESTE componente a cada mudança
```

Chamado junto do `useForm`, "este componente" é o formulário inteiro. A fonte:

> "This API will trigger a re-render at the root of your application or form. Consider using a callback or the useWatch API if you experience performance issues."

Duas caveats de valor inicial:

- Sem `defaultValue`, o primeiro render devolve `undefined`, "because it is called before `register`".
- Quando `defaultValue` e `defaultValues` coexistem, **o do `useForm` vence**; o inline só serve de fallback quando não existe valor algum para o campo.

### 3.3 `useWatch` — o padrão

```tsx
function ResumoTotal({ control }: { control: Control<Pedido> }) {
 // defaultValue cobre o primeiro render: sem ele, `itens` pode vir undefined
 // e o reduce lança. Ver as caveats de valor inicial em § 3.2.
 const itens = useWatch({ control, name: 'itens', defaultValue: [] })
 const total = itens.reduce((s, i) => s + i.preco * i.quantidade, 0)
 return <strong>{formatarMoeda(total)}</strong>
}
```

Só `ResumoTotal` re-renderiza. O resto do formulário não sabe que algo mudou — o hook "isolates re-rendering at the custom hook level".

Props verificadas:

| Prop | Default | Nota |
| --- | --- | --- |
| `name` | — | reativo: mudar a prop atualiza a assinatura |
| `control` | — | opcional sob `FormProvider` |
| `defaultValue` | — | fallback antes do mount, só quando ainda não há valor |
| `disabled` | `false` | desliga a assinatura · v7.13.0 |
| `exact` | `false` | v7.20.0. Com `false`, dispara quando o nome assinado é prefixo do campo alterado, ou vice-versa |
| `compute` | — | v7.61.0 |

`compute` assina um valor **derivado** e evita o re-render quando o resultado do cálculo não muda:

```tsx
const acimaDoLimite = useWatch({
 control,
 compute: (form) => form.total > LIMITE, // só notifica quando o boolean vira
})
```

É a diferença entre re-renderizar a cada centavo digitado e re-renderizar duas vezes na vida do formulário.

> **Atenção ao default de `exact`.** É `false` aqui e em `useFormState`, mas `true` em `Controller`/`useController`. A inconsistência é real e está na fonte.

### 3.4 As duas armadilhas de `useWatch`

**Ordem.** "If you update a form value before the subscription is in place, then the updated value will be ignored." `setValue` chamado antes de o `useWatch` existir é descartado. Mesmo problema que `isReady` resolve (§ 2.4).

**`useEffect`.** A fonte é explícita:

> "useWatch's result is optimized for the render phase instead of useEffect dependencies. To detect value updates, you may want to use an external custom hook for value comparison."

Vale igualmente para `watch`. Para reagir a mudanças **fora do render**, a API é `subscribe`.

### 3.5 `useFormState` — o mesmo isolamento, para estado

```tsx
function BotaoSalvar({ control }: { control: Control<Perfil> }) {
 const { isDirty, isSubmitting } = useFormState({ control })
 return <button disabled={!isDirty || isSubmitting}>Salvar</button>
}
```

O Proxy vale aqui também, e a fonte repete a exigência: `const { isDirty } = useFormState` ✅ contra `const formState = useFormState` ❌.

`name` (v7.4.0) restringe a assinatura a campos específicos; `disabled` (v7.13.0) desliga a assinatura; `exact` (v7.20.0) tem default `false`.

**É esta a API a usar dentro de `FormProvider`** — nunca destructuring de `formState` vindo de `useFormContext`, porque a leitura aconteceria no componente errado. `RHF-STATE-01`, e o apelido `RHF-CTX-01` em [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) § 4.1.

### 3.6 `subscribe` — reagir sem renderizar

Disponível desde a **v7.55.0**. A fonte descreve o propósito em uma linha:

> "This function is dedicated to subscribing to form state without **render**"

```tsx
useEffect( => {
 const unsubscribe = subscribe({
 formState: { values: true },
 callback: ({ values }) => salvarRascunho(values),
 })
 return unsubscribe // RHF-STATE-05
}, [subscribe])
```

| Prop | Tipo | Papel |
| --- | --- | --- |
| `name` | `undefined \| string \| string[]` | form inteiro, um campo ou vários |
| `formState` | `Partial<ReadFormState>` | quais partes monitorar |
| `callback` | `Function` | recebe o payload da assinatura |
| `exact` | `boolean` | correspondência exata de nome |

Chaves aceitas em `formState`: `values`, `isDirty`, `dirtyFields`, `touchedFields`, `isValid`, `errors`, `validatingFields`, `isValidating`.

Devolve a função de cancelamento, que **precisa** ser retornada do efeito. Compartilha a mesma funcionalidade de `createFormControl.subscribe`, que inicializa fora de componentes React.

É a API certa para autosave, analytics e log. Nenhuma dessas coisas precisa de render, e usar `watch` para elas paga re-render na raiz inteira por um efeito invisível.

### 3.7 Regras — leitura

| ID | Regra |
| --- | --- |
| `RHF-PERF-01` | `watch` sem argumento **NEVER** em componente grande — re-renderiza a raiz. Use `useWatch` no menor componente que precisa do valor. |
| `RHF-PERF-02` | Reação sem UI (autosave, analytics, log) **MUST** usar `subscribe`. A sobrecarga `watch(callback)` está marcada **Deprecated** na fonte, com `subscribe` como substituto. |
| `RHF-PERF-03` | O retorno de `watch`/`useWatch` **NEVER** entra em array de dependências de `useEffect` — é otimizado para a fase de render. |
| `RHF-PERF-04` | Leitura que não afeta a UI **MUST** usar `getValues`, **NEVER** `watch`. |
| `RHF-STATE-01` | Em componente aninhado ou sob `FormProvider`, estado do formulário **MUST** vir de `useFormState({ control })`, **NEVER** de destructuring de `useFormContext`. |
| `RHF-STATE-03` | Componente filho que chama `setValue` no mount **MUST** aguardar `isReady`. |
| `RHF-STATE-04` | Ao ler `formState` **não desestruturado** dentro de um `useEffect`, a dependência **MUST** ser o objeto `formState` inteiro — `[formState.errors]` não dispara, porque a atualização é em lote. Propriedade **já desestruturada no corpo do componente** (`const { isSubmitSuccessful } = formState`) é um valor comum e vai na lista normalmente, como em `RHF-STATE-02`. |
| `RHF-STATE-05` | O retorno de `subscribe` **MUST** ser devolvido como cleanup do efeito. |

---

## 4. Escrever, redefinir e alimentar de fora

### 4.1 `setValue`

```tsx
setValue('endereco.cidade', 'Recife', { shouldValidate: true, shouldDirty: true })
```

| Opção | Efeito | Desde |
| --- | --- | --- |
| `shouldValidate` | valida o campo e recalcula a validade do formulário | — |
| `shouldDirty` | compara contra `defaultValues` e marca em `dirtyFields` | — |
| `shouldTouch` | marca o input como *touched* | v7.8.0 |
| `delayError` | atrasa a exibição do erro resultante, usando o delay configurado | v7.82.0 |

Pontos verificados:

- **Mire o campo folha, não o objeto pai.** A fonte chama `setValue('detalhes', { nome: v })` de "less performant" frente a `setValue('detalhes.nome', v)`, e recomenda evitar setar objetos inteiros sobre campos aninhados registrados.
- **Registre antes.** "It's recommended to register the input's name before invoking `setValue`" — e, com field array, garanta que o `useFieldArray` executou primeiro.
- **Para substituir um array inteiro**, a fonte manda preferir `replace` do `useFieldArray`, "the more explicit, purpose-built API".
- Campo sob `Controller` se atualiza por `field.onChange`, não por `setValue` — `RHF-CTRL-04`.

### 4.2 `defaultValues` × `values`

Duas opções do `useForm` que parecem alternativas e não são: uma define a **forma**, a outra o **conteúdo**.

| | `defaultValues` | `values` |
| --- | --- | --- |
| Natureza | estático, cacheado | **reativo** (v7.41.0) |
| Quando muda | só via `reset` | sempre que a prop muda |
| Papel | contrato do formulário: o que existe, e a base de `isDirty` | conteúdo vindo de fora (servidor, store) |

Verificado: `defaultValues` "are cached. To reset them, use the reset API", são incluídos no resultado da submissão por padrão, e **não** devem receber `undefined`, "as it conflicts with the default state of a controlled component". Aceita função assíncrona:

```tsx
useForm({ defaultValues: async => fetch('/api/perfil').then((r) => r.json) })
```

`values` sobrescreve `defaultValues` a menos que `resetOptions: { keepDefaultValues: true }`; quando muda, o `reset` interno é invocado conforme `resetOptions`.

O par certo para dado remoto é `defaultValues` para a forma e `values` para o conteúdo:

```tsx
const { data } = useQuery({ queryKey: ['perfil'], queryFn: buscarPerfil })

useForm({
 defaultValues: { nome: '', email: '' }, // forma — todo campo existe desde o início
 values: data, // conteúdo — reativo
 resetOptions: { keepDirtyValues: true }, // não apaga edição em curso
})
```

Sem `keepDirtyValues`, um refetch em background sobrescreve o que o usuário está digitando. A regra da ponte é `RHF-BRIDGE-03`, em [React Hook Form](react-hook-form.md) § 8 — não a redefino aqui.

### 4.3 `reset` — e a ordem que importa

`reset(values, options)`. O ponto que mais surpreende:

> "Calling `reset` with `values` updates the form's `defaultValues` unless `options.keepDefaultValues` is set. If `reset` is later called without `values` or with `{}`, the form resets to the last `values` provided instead of the initial `defaultValues`."

Ou seja: `reset(x)` **redefine o contrato**, e todo `isDirty` posterior passa a comparar contra `x`.

Opções verificadas: `keepErrors`, `keepDirty`, `keepDirtyValues` (v7.31.0), `keepValues`, `keepDefaultValues`, `keepIsSubmitted`, `keepIsSubmitSuccessful` (v7.47.0), `keepTouched`, `keepIsValidating` (v7.51.0), `keepIsValid`, `keepSubmitCount`, `keepFieldsRef` (v7.60.0).

`keepFieldsRef` preserva as referências internas dos inputs registrados — "useful when you want to reset form values without causing inputs to unmount and remount".

Desde a **v7.36.0**, `values` também aceita callback que recebe os valores atuais:

```tsx
reset((atuais) => ({...atuais, cupom: '' }))
```

**Limpar após submissão bem-sucedida** é o caso mais comum, e o lugar correto **não** é o `onSubmit`. A fonte recomenda o `useEffect` porque "execution order matters": resetar dentro do `onSubmit` compete com a atualização do próprio `isSubmitSuccessful` e produz estado inconsistente.

Mas a condição do effect **não pode ser `isSubmitSuccessful` sozinho**:

```tsx
// ERRADO — também reseta quando o servidor recusou
useEffect( => {
 if (isSubmitSuccessful) reset
}, [isSubmitSuccessful, reset])
```

Pela § 2.3, `isSubmitSuccessful` significa "o `onSubmit` não lançou". E como `RHF-ERR-03` proíbe lançar erro esperado de dentro do `onSubmit`, um `422` tratado com `setError` deixa a flag em `true` — o effect dispara e **apaga os campos e os erros que você acabou de exibir**, juntos.

```tsx
// CERTO — o sinal de sucesso é seu, não do RHF
const [salvou, setSalvou] = useState(false)

const onSubmit = handleSubmit(async (data) => {
 try {
 await mutateAsync(data)
 setSalvou(true)
 } catch (e) {
 setError('root.serverError', { message: mensagemDe(e) })
 }
})

useEffect( => {
 if (salvou) { reset; setSalvou(false) }
}, [salvou, reset])
```

`RHF-STATE-02`. Detalhe da armadilha em [React Hook Form](react-hook-form.md) § 6.1.

A fonte também recomenda "always provide `defaultValues` when resetting a form to ensure all inputs, especially controlled components, are restored correctly".

### 4.4 `shouldUnregister` e `disabled` no nível do formulário

**`shouldUnregister`** (default `false`) decide o que acontece com o valor de um campo **desmontado**.

| Valor | Comportamento |
| --- | --- |
| `false` *(default)* | o valor do campo desmontado **persiste** no formulário |
| `true` | desmontar remove o valor — o formulário passa a se comportar como um form HTML nativo |

Três notas verificadas: é "a global configuration that overrides child-level configurations"; com o default `false`, campos desmontados **não são validados** pela validação embutida; e detectar inputs desmontados exige notificação via `useEffect`.

**Existe também no nível do campo** — a frase acima já dizia isso ao falar em "child-level configurations", e a fonte completa: *"To have individual behavior, set the configuration at the component or hook level, not at `useForm`."* É opção de `RegisterOptions`, prop de `Controller`, prop de `useController` e prop de `useFieldArray`.

E há uma diferença que a tabela acima não cobre. No nível do campo, a doc de `Controller`/`useController` diz:

> "Input will be unregistered after unmount **and defaultValues will be removed as well**."

Ou seja: `shouldUnregister: true` num campo remove o **default** junto com o valor — o que colide de frente com `RHF-CORE-01`. Se o campo voltar a montar, ele não volta ao default; volta a não ter default nenhum.

| ID | Regra |
| --- | --- |
| `RHF-STATE-12` | `shouldUnregister: true` no nível do campo **MUST** ser acompanhado da consciência de que o `defaultValue` também some no unmount — se o campo pode remontar e precisa do default, use `unregister` explícito em vez da opção. |

O default é o certo para formulário em etapas ou com campos condicionais, em que sumir da tela não deve significar perder o que foi digitado. E ele é **incompatível com `useFieldArray`** — § 5.

**`disabled`** (v7.48.0) desabilita o formulário inteiro e todos os inputs associados, impedindo interação. Funciona com `register`, `<select>` e `Controller`, e a fonte cita a utilidade de "preventing user interaction during asynchronous tasks". O estado fica legível em `formState.disabled`.

```tsx
const { formState: { isSubmitting } } = useForm({ /* … */ })
useForm({ disabled: isSubmitting }) // congela o formulário durante o envio
```

> **Não verificado:** se o `disabled` de nível de formulário exclui os valores da submissão, como faz o `disabled` de nível de **campo** (`RHF-REG-05`, em [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md)). A página de `useForm` descreve apenas o bloqueio de interação, sem declarar o efeito sobre os valores enviados. Confirme na fonte antes de depender disso.

### 4.5 `getFieldState`

```tsx
const { isDirty, isTouched, invalid, isValidating, error } = getFieldState('email')
```

Disponível desde a v7.25.0. Duas exigências verificadas:

**Precisa de assinatura.** "getFieldState works by subscribing to form state updates." Sem `formState` lido via `useForm`, `useFormContext` ou `useFormState` — ou sem passar `formState` como segundo argumento — o retorno vem incompleto. E é **por propriedade**: `isDirty` exige assinatura de `dirtyFields`, `invalid` e `error` exigem `errors`, e assim por diante.

**Precisa de campo registrado.** "The prop must match a registered field name." Nome desconhecido devolve estado default/`false`, não erro — o que faz um typo passar despercebido.

### 4.6 Regras — escrita

| ID | Regra |
| --- | --- |
| `RHF-STATE-02` | `reset` pós-submissão **MUST** rodar em `useEffect`, **NEVER** dentro do `onSubmit`. E **MUST** ser condicionado a um sinal de sucesso **real**, não só a `isSubmitSuccessful` — que fica `true` mesmo quando o `onSubmit` capturou um erro de servidor com `setError`. Ver `RHF-STATE-09` em [React Hook Form](react-hook-form.md) § 6.1: resetar aí apaga os erros e o que o usuário digitou. |
| `RHF-STATE-06` | `setValue` **MUST** mirar o campo folha; **NEVER** substituir o objeto pai quando um campo basta. |
| `RHF-STATE-07` | Substituição de um array inteiro **MUST** usar `replace` do `useFieldArray`, **NEVER** `setValue`. |
| `RHF-STATE-08` | `getFieldState` **MUST** ter `formState` assinado — ou recebê-lo como segundo argumento —, senão devolve estado não inicializado. |

### 4.7 Campo condicional: `unregister` e `resetField`

O caso que mais quebra formulário dinâmico: um campo que só aparece sob condição (marcar "pedido especial" revela "observação"). O usuário marca, digita, desmarca — e o valor digitado **continua no form state**, porque o default de `shouldUnregister` é `false`. Ele viaja no submit sem que nada na tela o mostre.

Duas APIs resolvem, e fazem coisas diferentes:

```tsx
unregister(names?: string | string[], options?: UnregisterOptions): void
resetField(name: string, options?: ResetFieldOptions): void
```

| | `unregister` | `resetField` |
| --- | --- | --- |
| O campo continua registrado? | **não** — some do form state | **sim** |
| Efeito | remove referência, valor e regras de validação embutidas | volta ao `defaultValue`, reavalia `isDirty`/`isValid` |
| Opções | `keepValue`, `keepError`, `keepDirty`, `keepTouched`, `keepIsValid`, `keepDefaultValue`, `keepIsValidating` | `keepError`, `keepDirty`, `keepTouched`, `defaultValue` |
| Usar quando | o campo deixou de existir logicamente | o campo existe e você quer limpá-lo |

Dois avisos citados da fonte, e o segundo é o que engana:

> "This method will remove input reference and its value, which means built-in validation rules will be removed as well."

> "By unregister an input, it will not affect the schema validation."

**`unregister` não desliga o resolver.** Se o schema exige `observacao`, ele continua exigindo depois de o campo sumir da tela — e o formulário fica inválido por um campo que o usuário não consegue ver nem preencher. Tirar o campo da UI é metade do trabalho; a outra metade é o schema deixar de exigi-lo.

```tsx
// A condição vive no schema, não só no JSX
const pedidoSchema = z.discriminatedUnion('pedidoEspecial', [
 z.object({ pedidoEspecial: z.literal(false), itens: itensSchema }),
 z.object({
 pedidoEspecial: z.literal(true),
 observacao: z.string.min(1, 'Descreva o que torna o pedido especial.'),
 itens: itensSchema,
 }),
])

function Observacao {
 const { control, register, unregister } = useFormContext<Pedido>
 const especial = useWatch({ control, name: 'pedidoEspecial' })

 useEffect( => {
 if (!especial) unregister('observacao') // some do payload junto com a UI
 }, [especial, unregister])

 if (!especial) return null
 return <textarea {...register('observacao')} />
}
```

União discriminada é preferível a `.optional` + `.refine` porque o tipo de saída deixa de **admitir** a combinação impossível (`pedidoEspecial: false` com `observacao` preenchida), em vez de apenas rejeitá-la em runtime.

> **Por que `unregister` explícito e não `shouldUnregister` no campo.** A opção existe no nível do campo (§ 4.4), mas ali ela **também remove o `defaultValue`** (`RHF-STATE-12`), e a versão global é incompatível com `useFieldArray` (`RHF-ARRAY-03`). Num formulário com lista dinâmica — que é o caso desta seção — o `unregister` explícito é o caminho que não tem nenhum dos dois efeitos colaterais.

E a terceira RULE da página de `unregister`, que faz o padrão acima falhar em silêncio se esquecida:

> "Make sure you unmount that input which has register callback or else the input will get registered again."

O `return null` do exemplo não é detalhe de renderização: sem ele, o `register` roda de novo no próximo render e o campo se re-registra logo após o `unregister`.

| ID | Regra |
| --- | --- |
| `RHF-STATE-10` | Campo removido da UI por condição **MUST** ser removido do form state por `unregister` (ou zerado por `resetField`) — senão o valor órfão viaja no submit. |
| `RHF-STATE-11` | A condicionalidade **MUST** existir também no schema: `unregister` **NEVER** afeta a validação do resolver. Prefira união discriminada a campo opcional. |

---

## 5. Ordem de investigação de re-render

A ordem anunciada em [React Hook Form](react-hook-form.md) § 5.7, do mais barato ao mais caro. Ela é **normativa**: pular um passo para chegar ao `memo` é o erro que esta seção existe para impedir.

**0. Meça.** Profiler do React DevTools, com *Highlight updates* ligado. Um formulário RHF saudável **não pisca** ao digitar. Se pisca, alguém assinou algo alto demais. Sem medida, pare aqui — `REACT-PERF-01`, em [React - Performance e Concorrência](react-performance-e-concorrencia.md).

**1. Remova `useState` espelhando campo.** O valor já está no formulário; o `useState` paralelo reintroduz exatamente o render que a biblioteca eliminou, e cria uma segunda fonte de verdade que diverge. É aplicado a formulário.

**2. Desça a leitura de valores.** `watch` na raiz vira `useWatch` no componente folha. **Este passo resolve a maioria dos casos** — e frequentemente é o único necessário. Se o valor só alimenta um cálculo booleano, `compute` (§ 3.3) corta o resto.

**3. Desça a leitura de `formState`.** Em vez de ler `errors` no topo e passar por prop, cada consumidor assina o que precisa com `useFormState`. Um `<BotaoSalvar>` que assina `isDirty` e `isSubmitting` não re-renderiza quando um erro de campo aparece três seções acima. `RHF-STATE-01`.

**4. Revise cada `Controller`.** Ele reintroduz render controlado naquele campo. Onde o componente encaminha `ref`, `register` é mais barato — `RHF-CORE-03`, e a árvore de [React Hook Form](react-hook-form.md) § 5.1.

**5. Volume, não cálculo.** Lista longa com `useFieldArray` custa **nós no DOM**, não processamento. Memoizar a linha não resolve; a saída é paginar ou virtualizar — § 6.4.

**6. Só então `memo`.** Na linha ou no campo, com props estáveis. E só com a medida do passo 0 na mão.

> **O erro conceitual mais caro** é tratar RHF como se fosse estado do React e depois tentar memoizar o resultado. A biblioteca já eliminou o render; memoização só volta a ser necessária quando alguém o trouxe de volta. **Procure o que assinou demais antes de procurar o que memoizar** — os passos 2 e 3 são gratuitos e removem a causa, enquanto o passo 6 apenas encobre o sintoma e cobra comparação a cada render.

---

## 6. `useFieldArray`

```tsx
const { fields, append, remove, move } = useFieldArray({ control, name: 'itens' })

{fields.map((field, index) => (
 <div key={field.id}> {/* ✅ nunca o índice */}
 <input {...register(`itens.${index}.nome`)} />
 <button type="button" onClick={ => remove(index)}>Remover</button>
 </div>
))}
<button type="button" onClick={ => append({ nome: '', quantidade: 1 })}>
 Adicionar
</button>
```

### 6.1 Superfície verificada

| Método | Assinatura |
| --- | --- |
| `fields` | `(object & { id: string })[]` |
| `append` | `(obj: object \| object[], focusOptions) => void` |
| `prepend` | `(obj: object \| object[], focusOptions) => void` |
| `insert` | `(index: number, value: object \| object[], focusOptions) => void` |
| `swap` | `(from: number, to: number) => void` |
| `move` | `(from: number, to: number) => void` |
| `update` | `(index: number, obj: object) => void` · v7.11.0 |
| `replace` | `(obj: object[]) => void` · v7.15.0 |
| `remove` | `(index?: number \| number[]) => void` |

Props: `name` (obrigatório, **nomes dinâmicos não são suportados**), `control`, `shouldUnregister`, `keyName` (default `"id"`), `rules` (v7.34.0, mesma API de validação do `register`) e `disabled` (v7.79.0).

`rules` valida o array como um todo, e o erro vai para `errors.<name>.root` — não para uma entrada. `disabled` desabilita o array inteiro; a fonte registra que a flag em cada objeto de `fields` apenas espelha o `disabled` do hook, **não** é lida do que você passa em `append`/`prepend`/`insert` e **não** é encaminhada automaticamente ao input registrado.

### 6.2 As seis restrições, e por que existem

| Restrição | Consequência de violar |
| --- | --- |
| `key` **precisa** ser `field.id`, nunca o índice | valores embaralhados ao remover — § 6.3 |
| Cada entrada **precisa ser objeto**; arrays planos não são suportados | `{ tags: ['a','b'] }` ❌ · `{ tags: [{ valor: 'a' }] }` ✅ |
| `shouldUnregister: true` **não é suportado** | campos recém-adicionados são desregistrados no re-render e **perdem o valor** |
| `append`/`prepend`/`insert`/`update` **não aceitam `{}`** | `append` ❌ · `append({})` ❌ · `append({ nome: 'bill' })` ✅ |
| Não empilhe ações no mesmo handler | enfileire via `useEffect` — a segunda ação roda no render seguinte |
| Um `useFieldArray` por `name` | "Each useFieldArray is unique and has its own state update" — duas instâncias divergem |

A fonte é literal sobre `shouldUnregister`: "Field array relies on inputs being mounted and unmounted to manage its internal state". O array **usa** o ciclo de montagem como mecanismo; desligar a persistência do valor desmontado retira o chão de baixo dele.

E sobre empilhar ações, o exemplo oficial:

```tsx
// ❌ as duas ações competem no mesmo tick
onClick={ => { append({ test: 'test' }); remove(0) }}

// ✅ o remove acontece depois do segundo render
useEffect( => { remove(0) }, [remove])
onClick={ => { append({ test: 'test' }) }}
```

### 6.3 Índice × identidade

O erro do `key={index}` merece detalhe porque o sintoma não aponta para a causa.

Com `key` de índice, remover o item 0 faz o React reaproveitar o nó do DOM daquela posição para o que era o item 1. Como o campo é **não controlado**, o valor que estava no nó do DOM permanece ali — e a lista passa a exibir dados trocados, embora `getValues` devolva o array correto. A divergência entre o que se vê e o que se submete é o que torna esse bug caro: ele não quebra, ele mente.

`field.id` é gerado pela biblioteca exatamente para isso, e a fonte remete à página de listas do React para o porquê. O nome da chave é configurável por `keyName`, mas não há razão para mudá-lo — e na v8 beta ele deixa de existir (§ Notas de verificação).

### 6.4 Listas longas

`useFieldArray` não virtualiza. Com centenas de linhas o custo é **volume de nós no DOM**, e memoizar a linha não resolve — é o passo 5 da § 5.

Virtualizar, porém, tem um efeito colateral que a fonte descreve:

> "A common practice is to only render the items in the viewport; however, this causes issues as items are removed from the DOM when they are out of view and then re-added. This will cause items to reset to their default values when they re-enter the viewport."

Duas saídas oficiais: `FormProvider` + `useFormContext` nas linhas virtualizadas, ou `Controller` restaurando o valor via `getValues` ao renderizar cada item.

> E antes de otimizar `FormProvider`: "Using React Hook Form's DevTools alongside FormProvider can cause performance issues in some situations. Before diving deep in performance optimizations, consider this bottleneck first."

### 6.5 Regras — `RHF-ARRAY-*`

| ID | Regra |
| --- | --- |
| `RHF-ARRAY-01` | `key` da linha **MUST** ser `field.id`, **NEVER** o índice. |
| `RHF-ARRAY-02` | Cada entrada do array **MUST** ser objeto; array de primitivos **NEVER**. |
| `RHF-ARRAY-03` | `shouldUnregister: true` **NEVER** com `useFieldArray` — campos adicionados perdem o valor no re-render. |
| `RHF-ARRAY-04` | `append`/`prepend`/`insert`/`update` **MUST** receber todos os `defaultValues` da entrada; `{}` ou nenhum argumento **NEVER**. |
| `RHF-ARRAY-05` | Um `name` **MUST** ter no máximo um `useFieldArray`, e o `name` **NEVER** é dinâmico. |
| `RHF-ARRAY-06` | Duas ações de array **NEVER** são empilhadas no mesmo handler — a segunda vai para um `useEffect`. |

> `RHF-CTRL-06`, em [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md), enuncia o mesmo princípio de `RHF-ARRAY-03` pelo lado do campo. **`RHF-ARRAY-03` é o canônico**; cite-o em revisão.

---

## 7. Formulário em várias etapas

Um wizard força uma decisão que nenhum formulário de tela única obriga a tomar: **um `useForm` para tudo, ou um por etapa?** A resposta muda o schema, a validação, a persistência ao voltar e o botão "Avançar".

### 7.1 O que a fonte não responde

`trigger(['cliente.nome', 'cliente.email'])` devolve `Promise<boolean>` e é a via óbvia para liberar a etapa seguinte. O problema aparece quando há `resolver`: **o schema roda inteiro**, então um `itens: z.array.min(1)` produz erro já no `trigger` da etapa 1, quando o usuário nem chegou lá.

A fonte **não diz** se `formState.errors` fica com os erros de todas as etapas ou só dos campos nomeados — verifiquei a página de `trigger` e ela trata apenas de re-render. Ver [Notas de verificação](#notas-de-verificacao).

Isso importa porque é a diferença entre a etapa 1 mostrar erros de campos que não existem na tela e não mostrar. **A recomendação abaixo evita depender dessa resposta.**

### 7.2 A decisão: um formulário por etapa

```
As etapas compartilham validação cruzada
(uma regra que só faz sentido vendo dados de duas etapas)?
├── NÃO (o caso comum)
│ → UM FORMULÁRIO POR ETAPA, com acumulador no wizard.
│ Cada etapa tem seu schema, seu isValid, seu ciclo de vida.
└── SIM, e a regra precisa avisar ANTES da última etapa
 → um formulário só, com trigger por etapa.
 Aceite a incerteza da § 7.1 e teste o comportamento.

Em ambos: o schema COMPLETO valida o objeto acumulado antes do envio.
É ele que o servidor também usa.
```

Um formulário por etapa resolve, de uma vez, os quatro problemas que o wizard cria:

| Problema | Como some |
| --- | --- |
| `isValid` é global e o botão "Avançar" nunca habilita | cada etapa tem o seu `isValid`, que é só dela |
| Erros de etapas futuras vazando na etapa atual | o schema da etapa não conhece os outros campos |
| Voltar sem perder dados | o acumulador é a memória, não o RHF |
| `shouldUnregister` e campo desmontado | irrelevante: o formulário inteiro desmonta, e nada dependia dele lembrar |

### 7.3 Schemas compostos

Um schema por etapa, e o completo é a soma — não duas declarações do mesmo shape (`RHF-VAL-04`).

```tsx
const passo1Schema = z.object({
 cliente: z.object({
 nome: z.string.min(2, 'Informe ao menos 2 caracteres.'),
 email: z.email('E-mail inválido.'),
 }),
})

const passo2Schema = z.object({
 itens: z.array(z.object({
 descricao: z.string.min(1, 'Descreva o item.'),
 quantidadeCentavos: z.number.int.positive,
 })).min(1, 'Adicione ao menos um item.'),
})

const passo3Schema = z.object({
 observacoes: z.string.max(500).optional,
})

// O completo é a composição, não uma terceira declaração
const orcamentoSchema = z.object({
...passo1Schema.shape,
...passo2Schema.shape,
...passo3Schema.shape,
})

type Orcamento = z.infer<typeof orcamentoSchema>
type Passo1 = z.infer<typeof passo1Schema>
```

O spread de `.shape` funciona igual em Zod 3 e 4, e deixa explícito que o completo **é** a soma das partes. Regra cruzada entre etapas vai num `.refine` no `orcamentoSchema`, não nos parciais.

### 7.4 O acumulador

```tsx
export function WizardOrcamento {
 const [etapa, setEtapa] = useState(1)
 const [dados, setDados] = useState<Partial<Orcamento>>({})

 const avancar = (parcial: Partial<Orcamento>) => {
 setDados((d) => ({...d,...parcial }))
 setEtapa((e) => e + 1)
 }

 return (
 <>
 {etapa === 1 && <Passo1 dados={dados} onAvancar={avancar} />}
 {etapa === 2 && (
 <Passo2 dados={dados} onAvancar={avancar} onVoltar={ => setEtapa(1)} />
 )}
 {etapa === 3 && (
 <Passo3 dados={dados} onVoltar={ => setEtapa(2)} onEnviar={enviar} />
 )}
 </>
 )
}

function Passo1({ dados, onAvancar }: PassoProps) {
 const { register, handleSubmit, formState: { errors, isValid } } = useForm<Passo1>({
 resolver: zodResolver(passo1Schema),
 mode: 'onTouched',
 defaultValues: { cliente: { nome: '', email: '' } },
 values: dados as Passo1, // volta preenchido — RHF-BRIDGE-03
 })

 // handleSubmit é o "Avançar": valida esta etapa e só então segue
 return (
 <form onSubmit={handleSubmit(onAvancar)}>
 {/* campos */}
 <button disabled={!isValid}>Avançar</button>
 </form>
 )
}
```

Quatro decisões:

- **`handleSubmit` é o botão "Avançar".** Não é gambiarra: submeter a etapa **é** validá-la e entregar seus dados. Some o `trigger` com array, e com ele o custo de re-render que `RHF-VAL-07` alerta.
- **`isValid` volta a funcionar.** É o `isValid` desta etapa, com este schema. Era isto que o formulário único tornava impossível.
- **`values: dados`** alimenta a etapa ao voltar. Mesmo mecanismo do dado remoto (`RHF-BRIDGE-03`) — o acumulador é "de fora" tanto quanto um servidor é.
- **Um `<form>` por etapa**, cada um com dono único de submissão (`RHF-BRIDGE-01`). Não existe `<form>` aninhado nem botão disputando handler.

### 7.5 A validação que importa acontece no fim

O acumulador é `Partial<Orcamento>` — TypeScript não garante que ele esteja completo, e o usuário pode ter chegado ali por um caminho que você não previu. Antes de enviar, valide o objeto inteiro contra o schema completo:

```tsx
const enviar = async (ultimoPasso: Partial<Orcamento>) => {
 const completo = {...dados,...ultimoPasso }
 const parsed = orcamentoSchema.safeParse(completo)

 if (!parsed.success) {
 // etapa incompleta: leve o usuário de volta em vez de enviar lixo
 setEtapa(primeiraEtapaComErro(parsed.error))
 return
 }
 await api.criarOrcamento(parsed.data)
}
```

Isso não é redundante com a validação por etapa: as etapas validam **fragmentos**, e só o schema completo valida as **regras cruzadas** e a completude. E é o mesmo schema que o servidor usa — `RHF-CORE-05`.

### 7.6 Quando o formulário único é a escolha certa

Duas etapas curtas, sem lista dinâmica, com uma regra que precisa ver as duas ao mesmo tempo. Aí o custo de coordenar dois formulários supera o da incerteza da § 7.1.

Nesse caso: `trigger(['a','b'])` para avançar, `isValid` **não** serve para o botão (é global), e o botão "Avançar" valida no clique em vez de reagir. Exiba na etapa atual apenas `errors` dos campos dela — não confie em `formState.errors` estar limpo dos outros.

### 7.7 Regras — `RHF-STEP-*`

| ID | Regra |
| --- | --- |
| `RHF-STEP-01` | Wizard **MUST** ter um `useForm` por etapa, com schema próprio, salvo quando houver regra cruzada que precise avisar antes da última etapa. |
| `RHF-STEP-02` | O schema completo **MUST** ser a composição dos schemas de etapa, **NEVER** uma declaração paralela. Apelido de `RHF-VAL-04`. |
| `RHF-STEP-03` | Persistência entre etapas **MUST** viver num acumulador fora do RHF, realimentado por `values`; **NEVER** depender de o formulário lembrar campo desmontado. |
| `RHF-STEP-04` | Antes do envio, o objeto acumulado **MUST** ser validado contra o schema completo — as etapas validaram fragmentos. |
| `RHF-STEP-05` | Com formulário único, `formState.errors` **NEVER** é assumido como restrito à etapa visível; filtre pelos campos da etapa. |

---

## 8. Antipadrões

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `const { formState } = useForm` sem desestruturar o que usa | o Proxy assina por leitura no render; nada foi lido | desestruturar no topo · `RHF-CORE-02` |
| `useEffect(…, [formState.errors])` | `formState` atualiza em lote; a propriedade não dispara | `[formState]` · `RHF-STATE-04` |
| `watch` na raiz para exibir um campo | re-renderiza o formulário inteiro a cada tecla | `useWatch` na folha · `RHF-PERF-01` |
| `watch(callback)` para autosave | sobrecarga marcada Deprecated; força o caminho de render | `subscribe` · `RHF-PERF-02` |
| `useEffect(…, [watch('x')])` | o retorno é otimizado para render, não para dependências | `subscribe` · `RHF-PERF-03` |
| `getValues` para renderizar | não assina; a tela congela no último render | `useWatch` |
| `watch` para uma checagem dentro de handler | paga re-render por uma leitura invisível | `getValues` · `RHF-PERF-04` |
| `errors` lido de `useFormContext` | a leitura ocorre no componente errado; só o 1º render acerta | `useFormState({ control })` · `RHF-STATE-01` |
| `setValue` no mount de componente filho | roda antes de a assinatura existir; a chamada se perde | aguardar `isReady` · `RHF-STATE-03` |
| `subscribe` sem retornar o unsubscribe | assinatura vaza a cada remount | `return unsubscribe` · `RHF-STATE-05` |
| `reset` dentro do `onSubmit` | compete com a atualização de `isSubmitSuccessful` | `useEffect` com sinal de sucesso próprio · `RHF-STATE-02` |
| `useEffect( => { if (isSubmitSuccessful) reset })` | erro de servidor tratado com `setError` não lança, então a flag fica `true` e o reset apaga campos e erros | condicionar a um sinal de sucesso real · `RHF-STATE-02` |
| `setValue('obj', {…})` para um campo | a fonte marca como menos performático | mirar o campo folha · `RHF-STATE-06` |
| `setValue` para trocar o array inteiro | contorna a API própria e desacerta o estado do array | `replace` · `RHF-STATE-07` |
| `getFieldState` sem `formState` assinado | devolve estado não inicializado, sem erro | assinar antes · `RHF-STATE-08` |
| Dado do servidor em `defaultValues` estático | não é reativo; o refetch não chega ao formulário | `values` + `keepDirtyValues` · `RHF-BRIDGE-03` |
| `key={index}` em field array | o nó do DOM é reaproveitado e exibe valor de outra linha | `key={field.id}` · `RHF-ARRAY-01` |
| `{ tags: ['a', 'b'] }` em field array | arrays planos não são suportados | `[{ valor: 'a' }]` · `RHF-ARRAY-02` |
| `shouldUnregister: true` com `useFieldArray` | o array depende de mount/unmount para seu estado | remover a opção · `RHF-ARRAY-03` |
| `append({})` | a entrada nasce sem os campos registrados | passar os defaults · `RHF-ARRAY-04` |
| `append(...)` e `remove(0)` no mesmo handler | as ações competem no mesmo tick | segunda ação em `useEffect` · `RHF-ARRAY-06` |
| `isValid` como confirmação de sucesso | `setError` o força a `false` fora da validação | `isSubmitSuccessful` · `RHF-ERR-05` |
| `memo` antes de descer a assinatura | encobre o sintoma e cobra comparação por render | seguir a ordem da § 5 |
| Wizard com um `useForm` só e schema completo | o schema roda inteiro; erros de etapas futuras vazam | um form por etapa · `RHF-STEP-01` |
| `disabled={!isValid}` no "Avançar" com form único | `isValid` é do formulário todo, não da etapa | validar no clique · `RHF-STEP-05` |
| Etapas contando que o RHF lembre campo desmontado | promessa frágil, e desnecessária | acumulador + `values` · `RHF-STEP-03` |
| Enviar o acumulado sem validar o objeto inteiro | as etapas validaram fragmentos, não a completude | `safeParse` antes do envio · `RHF-STEP-04` |

---

## 9. Checklist de revisão

- [ ] Todo `formState` usado está desestruturado antes do render? → `RHF-CORE-02`
- [ ] Algum `useEffect` depende de uma propriedade de `formState` em vez do objeto? → `RHF-STATE-04`
- [ ] Existe `watch` sem argumento, ou `watch` em componente grande? → `RHF-PERF-01`
- [ ] Autosave, analytics ou log usam `subscribe`, e não `watch(callback)`? → `RHF-PERF-02`
- [ ] O retorno de `watch`/`useWatch` aparece em array de dependências? → `RHF-PERF-03`
- [ ] Leitura que não afeta a UI usa `getValues`? → `RHF-PERF-04`
- [ ] Sob `FormProvider`, o estado vem de `useFormState`? → `RHF-STATE-01`
- [ ] Componente filho chama `setValue` no mount sem esperar `isReady`? → `RHF-STATE-03`
- [ ] Todo `subscribe` devolve o unsubscribe como cleanup? → `RHF-STATE-05`
- [ ] O `reset` pós-submissão está em `useEffect` condicionado a um sinal de sucesso **real** — não a `isSubmitSuccessful` sozinho? → `RHF-STATE-02`
- [ ] Algum `setValue` substitui um objeto pai onde um campo folha bastaria? → `RHF-STATE-06`
- [ ] Troca de array inteiro usa `replace`? → `RHF-STATE-07`
- [ ] Todo `getFieldState` tem `formState` assinado? → `RHF-STATE-08`
- [ ] Dado remoto entra por `values` com `resetOptions`, não por `defaultValues` estático? → `RHF-BRIDGE-03`
- [ ] `defaultValues` cobre todo campo do formulário? → `RHF-CORE-01`
- [ ] Toda linha de field array usa `key={field.id}`? → `RHF-ARRAY-01`
- [ ] Toda entrada de field array é objeto? → `RHF-ARRAY-02`
- [ ] Há `shouldUnregister: true` em algum formulário com field array? → `RHF-ARRAY-03`
- [ ] `append`/`insert`/`update` recebem todos os defaults da entrada? → `RHF-ARRAY-04`
- [ ] Cada `name` de array tem um único `useFieldArray`, e não é dinâmico? → `RHF-ARRAY-05`
- [ ] Há duas ações de array no mesmo handler? → `RHF-ARRAY-06`
- [ ] A investigação de re-render seguiu a ordem da § 5 antes de chegar a `memo`? → `REACT-PERF-01`

---

## Relacionados

- [React Hook Form](react-hook-form.md) — entrada, árvore da § 5.2, ordem anunciada na § 5.7, pontes da § 8
- [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) — como o campo entra; `RHF-CTX-01`, `RHF-CTRL-04`, `RHF-REG-05`
- [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) — `isValid`, `setError` e `RHF-ERR-05`
- [React - Performance e Concorrência](react-performance-e-concorrencia.md) — `REACT-PERF-01`, medir antes de memoizar
- [React - Rules of React](react-rules-of-react.md) — base normativa; o Proxy não suspende nenhuma regra de pureza
- [React - Estado e Reatividade](react-estado-e-reatividade.md) · — o passo 1 da § 5
- [React - Hooks](react-hooks.md) — `useEffect` e dependências
- [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) — o outro lado da submissão, e a origem do dado de `values`

## Fontes consultadas

Verificadas em 2026-08-15:

- [formState](https://react-hook-form.com/docs/useform/formstate) — Proxy e leitura antes do render, atualização em lote, caveats de `isDirty`/`isValid`, `isReady`
- [watch](https://react-hook-form.com/docs/useform/watch) — as quatro sobrecargas, re-render na raiz, precedência de `defaultValues`
- [useWatch](https://react-hook-form.com/docs/usewatch) — isolamento de render, `compute` (v7.61.0), ordem com `setValue`, não usar em dependências
- [useFormState](https://react-hook-form.com/docs/useformstate) — `name` (v7.4.0), `disabled` (v7.13.0), `exact` default `false`
- [subscribe](https://react-hook-form.com/docs/useform/subscribe) — v7.55.0, assinatura sem render, chaves de `formState`
- [setValue](https://react-hook-form.com/docs/useform/setvalue) — campo folha, `replace` para arrays, caveat de `shouldDirty`, `delayError` (v7.82.0)
- [reset](https://react-hook-form.com/docs/useform/reset) — `keep*`, redefinição de `defaultValues`, reset em `useEffect`, callback (v7.36.0)
- [useForm](https://react-hook-form.com/docs/useform) — `defaultValues` × `values`, `resetOptions`, `shouldUnregister`, `disabled`
- [getFieldState](https://react-hook-form.com/docs/useform/getfieldstate) — exigência de assinatura por propriedade
- [useFieldArray](https://react-hook-form.com/docs/usefieldarray) — métodos, seção *Rules* completa, `disabled` (v7.79.0)
- [Advanced Usage](https://react-hook-form.com/advanced-usage) — listas virtualizadas, DevTools com `FormProvider`
- [Migrate V7 to V8 (BETA)](https://react-hook-form.com/migrate-v7-to-v8) — consultada para o status de `watch(callback)` e de `keyName`

### Notas de verificação

Pontos em que a fonte contraria o que se assume por hábito — ou o que esta doc afirmava antes:

- **A depreciação de `watch(callback)` não é da v7.0.0.** A página de `watch` traz, junto da sobrecarga de callback, o aviso *"Deprecated: consider use or migrate to subscribe"* **e** o selo `Since v7.0.0`. O selo marca **quando a sobrecarga foi introduzida**, como faz em toda a doc (`update` *Since v7.11.0*, `replace` *Since v7.15.0*). Ele não é a data da depreciação: `subscribe` só existe desde a **v7.55.0**, e uma depreciação não pode apontar para um substituto que ainda não existia. **A fonte não declara em que versão a depreciação ocorreu.** Ver a divergência registrada abaixo.
- **Em v8 (BETA), `watch(callback)` não foi removido.** A página de migração diz que o que saiu da API pública foi o **tipo** exportado `WatchObserver`; o callback "still works at runtime". A recomendação de migrar para `subscribe` continua, por ser "the supported, fully-typed API for this pattern".
- **Em v8 (BETA), `useFieldArray` renomeia `id` para `key` e remove `keyName`.** `RHF-ARRAY-01` continua valendo em v7 com `field.id`; quem for migrar precisa reescrever a `key`.
- **`isSubmitSuccessful` não significa "deu certo".** Significa que o `onSubmit` não lançou. Erro de negócio tratado com `setError` mantém o flag em `true` — o que é coerente, mas derruba o padrão de "resetei porque salvou".
- **`isValid` não vem sempre da validação.** `setError` o força a `false`, e a fonte diz que esse valor "is not derived from validation and will be overwritten the next time validation runs".
- **`exact` tem defaults diferentes na mesma biblioteca:** `false` em `useWatch` e `useFormState`, `true` em `Controller`/`useController`.
- **`shouldUnregister: false` (o default) não valida campos desmontados.** Os valores persistem, mas ficam fora da validação embutida — o que é fácil de confundir com "o campo passou".
- **`shouldUnregister` é configuração global** e sobrepõe a configuração de nível de campo, e não apenas coexiste com ela.
- **`reset(x)` redefine `defaultValues`.** Um `reset` posterior sem argumento volta para `x`, não para os valores originais do `useForm`.
- **`getFieldState` exige assinatura por propriedade**, não uma assinatura genérica: `isDirty` precisa de `dirtyFields` assinado, `error` precisa de `errors`, e assim por diante.
- **Nome desconhecido em `getFieldState` não dá erro** — devolve estado default, o que faz um typo passar como campo válido e limpo.

### Nota de verificação — `trigger` com resolver e subconjunto de campos

A página de `trigger` foi consultada especificamente para saber se, com `resolver` configurado, chamar `trigger(['a','b'])` popula `formState.errors` com os erros de **todos** os campos do schema ou só dos nomeados. **Ela não responde** — trata apenas de re-render ("Render-optimization isolation only applies when you target a single field").

Como o schema roda inteiro por definição do resolver, o comportamento seguro a assumir é o pessimista: os erros das demais etapas **podem** estar em `errors`. A § 7.2 recomenda a arquitetura que não depende disso; `RHF-STEP-05` cobre quem escolher a outra.

### Nota de verificação — a versão da depreciação de `watch(callback)`

O selo `Since v7.0.0` na sobrecarga de callback marca a **introdução** dela, não a depreciação. Como o substituto indicado pela própria fonte (`subscribe`) só existe desde a v7.55.0, "deprecado desde a v7.0.0" é insustentável.

O fato permanece: a sobrecarga está marcada **Deprecated**, com `subscribe` como substituto, e `RHF-PERF-02` vale. Apenas a versão não é afirmável — e por isso nem esta nota nem o hub a declaram.
