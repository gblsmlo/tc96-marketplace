---
titulo: React Hook Form - Validação e Resolvers
Link: https://react-hook-form.com/docs/useform
tags:
  - react
  - forms
  - react-hook-form
  - zod
  - validation
  - agent-context
source: "Documentação oficial do React Hook Form — useForm, setError, trigger, resolvers"
verificado-em: 2026-08-15
---

# React Hook Form — Validação e Resolvers

> `mode` · `resolver` · `zodResolver` · `setError` · `trigger` · erros de servidor
>
> O que é válido, quando isso é checado, e o que acontece com o que o servidor recusa.

Entrada: [React Hook Form](react-hook-form.md) · Conceito:

---

## 1. Conceito: três camadas, uma fonte

RHF oferece três formas de dizer o que é válido — e elas **não se somam livremente**.

| Camada | Onde mora | Convive com resolver? |
| --- | --- | --- |
| Regras por campo | `register('x', { required, min, … })` | Não — o resolver assume a validação |
| Schema externo | `useForm({ resolver: zodResolver(schema) })` | é a própria camada |
| Validação de formulário | `useForm({ validate })` (v7.72.0) | **Não — mutuamente exclusivas** |

> **Verificado na fonte:** a opção `validate` do `useForm` **não roda quando há `resolver` configurado**. São alternativas, não complementos. Escrever as duas não dá erro — a segunda simplesmente é ignorada, o que é pior.

**A recomendação desta doc é o resolver com schema**, por um motivo que não é de conveniência: o mesmo schema valida no cliente e no servidor, e o tipo do formulário deriva dele. As regras inline permanecem legítimas para formulário pequeno num projeto que não tem schema — não são um antipadrão, são uma escolha com menos alcance.

A quarta camada não é opcional e não está nesta lista: **o servidor**. Validação de cliente é fronteira de UX. `RHF-CORE-05`.

---

## 2. Quando validar

### 2.1 `mode` e `reValidateMode`

`mode` vale **antes** do primeiro submit. `reValidateMode` vale **depois**.

| `mode` | Dispara | Uso típico |
| --- | --- | --- |
| `'onSubmit'` *(default)* | no submit | o padrão certo para a maioria |
| `'onBlur'` | ao sair do campo | formulário longo, sem punir quem está digitando |
| `'onChange'` | a cada tecla | **a fonte alerta para o impacto de performance** |
| `'onTouched'` | primeiro blur, depois a cada mudança | o melhor equilíbrio de UX na prática |
| `'all'` | blur e change | raramente justificável |

`reValidateMode` aceita `'onChange'` (default), `'onBlur'`, `'onSubmit'`.

**A combinação que resolve a maior parte dos casos** é `mode: 'onTouched'`: o usuário não vê erro enquanto preenche pela primeira vez, mas passa a ver correção imediata depois de já ter errado ali. `onChange` puro acusa "e-mail inválido" no primeiro caractere digitado.

Desde a v7.56.0, `mode` e `reValidateMode` são **reativos** — mudá-los em runtime tem efeito.

### 2.2 `criteriaMode` e `delayError`

`criteriaMode: 'all'` coleta **todos** os erros de cada campo em vez de só o primeiro, e os expõe em `errors.campo.types`. Só faz sentido quando a UI de fato exibe a lista (checklist de requisitos de senha é o caso clássico).

`delayError: 500` atrasa a **exibição** do erro. A correção some com o erro instantaneamente, sem esperar o delay — o atraso pune só o aparecimento, o que é exatamente o que se quer.

### 2.3 Regras — `RHF-VAL-*` (quando)

| ID | Regra |
| --- | --- |
| `RHF-VAL-01` | `resolver` e `validate` de `useForm` **NEVER** coexistem — a fonte declara que `validate` não roda com resolver presente. |
| `RHF-VAL-03` | `mode: 'onChange'` **MUST** ter justificativa registrada; o default de trabalho é `'onSubmit'` ou `'onTouched'`. |

---

## 3. Resolver com Zod

```bash
npm install @hookform/resolvers zod
```

```tsx
import { useId } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const cadastroSchema = z.object({
  nome: z.string().min(2, 'Informe ao menos 2 caracteres.'),
  email: z.email('E-mail inválido.'),
  senha: z.string().min(8, 'Mínimo de 8 caracteres.'),
  confirmacao: z.string(),
}).refine((d) => d.senha === d.confirmacao, {
  message: 'As senhas não coincidem.',
  path: ['confirmacao'],          // ✅ sem isto o erro vira erro de raiz
})

type Cadastro = z.infer<typeof cadastroSchema>   // ✅ tipo derivado, não escrito

export function FormCadastro() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<Cadastro>({
    resolver: zodResolver(cadastroSchema),
    mode: 'onTouched',
    defaultValues: { nome: '', email: '', senha: '', confirmacao: '' },
  })

  const id = useId()

  return (
    <form onSubmit={handleSubmit(async (data) => { await criarConta(data) })}>
      <label htmlFor={`${id}-nome`}>Nome</label>
      <input
        {...register('nome')}
        id={`${id}-nome`}
        aria-invalid={errors.nome ? true : undefined}
        aria-describedby={errors.nome ? `${id}-nome-erro` : undefined}
      />
      {errors.nome && (
        <p id={`${id}-nome-erro`} role="alert">{errors.nome.message}</p>
      )}
      {/* demais campos seguem o mesmo par label/aria-describedby.
          Em produção, extraia isto para um componente de campo:
          [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) § 3.3 */}
      <button disabled={isSubmitting}>Criar conta</button>
    </form>
  )
}
```

Três decisões:

- **`path: ['confirmacao']` no `refine`** — sem ele, o erro de comparação não pertence a campo nenhum e vai parar em `errors.root`, onde o campo não o exibe. É a causa mais comum de "a validação roda mas não aparece nada".
- **`z.infer` em vez de uma `interface` escrita à mão** — `RHF-VAL-04`. Duas declarações do mesmo shape divergem no primeiro campo adicionado.
- **`defaultValues` completo** — `RHF-CORE-01`. O schema define o que é válido; `defaultValues` define o que existe.

### 3.1 A pegadinha de `.transform()` e `.default()`

Se o schema transforma, o tipo de **entrada** e o de **saída** deixam de ser o mesmo. `z.infer` devolve o de saída — e o formulário trabalha com o de entrada.

```tsx
const schema = z.object({
  idade: z.string().transform(Number),        // entra string, sai number
  ativo: z.boolean().default(true),           // pode não existir na entrada
})

// ❌ um generic só: os tipos brigam e handleSubmit fica com o tipo errado
useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) })

// ✅ os três generics: entrada, contexto, saída
useForm<z.input<typeof schema>, unknown, z.output<typeof schema>>({
  resolver: zodResolver(schema),
})
```

O terceiro generic é o que faz `handleSubmit` entregar o dado **já transformado**. É uma das três regras desta estrutura que dependem de tipos, junto de `RHF-VAL-04` e `RHF-CTRL-07`.

### 3.2 O que um resolver é, por baixo

Uma função que recebe os valores e devolve `{ values, errors }`. Isso importa em dois momentos: ao escrever um resolver customizado, e ao interpretar um bug de mapeamento de erro.

**A estrutura de erro do resolver é hierárquica, não plana** — a fonte é explícita:

```ts
// ✅
{ participantes: [null, { nome: { type: 'required', message: '…' } }] }

// ❌ não funciona
{ 'participantes.1.nome': { … } }
```

Outros pontos verificados: a função do resolver é **cacheada**; durante a interação, a revalidação acontece **um campo por vez**; e a checagem de erro em nível de pai se limita ao pai direto.

`context` (a opção do `useForm`) chega ao resolver como segundo argumento — é a via para validar contra algo que muda em runtime sem recriar o schema (papel do usuário, feature flag, etc.).

### 3.3 Validação assíncrona: onde ela mora depende de haver resolver

Este é o ponto da doc em que a leitura desatenta produz código que nunca roda. A referência de `resolver` declara que ele **"cannot be used with built-in validators"** — e as `rules` do `register`, **`validate` inclusive**, são built-in validators.

> **Com um `resolver` configurado, as `rules` do `register` não rodam — nem `validate`, nem `deps`.** O sintoma é o pior possível: nenhum erro, nenhuma exceção, a função simplesmente nunca é chamada. Como esta doc recomenda resolver (§ 1), este é o caso padrão, não a exceção.

**Com resolver**, uma regra que exige I/O (unicidade de e-mail, cupom válido) tem duas vias:

**Via 1 — assíncrona dentro do schema.** Coerente com "o schema é a fonte". O adaptador aceita `mode: 'async'`.

```tsx
const cadastroSchema = z.object({
  email: z.email('E-mail inválido.').refine(
    async (email) => await emailDisponivel(email),
    { message: 'Este e-mail já está em uso.' },
  ),
})
```

**Via 2 — só na submissão, via `setError`.** Frequentemente a melhor: uma chamada por submit em vez de uma por interação, e o servidor é a autoridade de qualquer forma. Ver § 4.3.

**Sem resolver**, a via é o `validate` do `register`:

```tsx
<input {...register('email', {
  validate: async (email) =>
    (await emailDisponivel(email)) || 'Este e-mail já está em uso.',
})} />
```

Enquanto qualquer uma delas roda, `isValidating` fica `true`, e `validatingFields` (v7.51.0) diz **quais** campos estão em voo — o que permite spinner por campo em vez de bloquear o formulário.

> **O custo que a fonte não menciona e que morde em produção.** `mode: 'onTouched'` tem `reValidateMode` default `'onChange'`: depois do primeiro erro, é **uma chamada de API por tecla**. Validação assíncrona por campo exige debounce e cancelamento (`AbortController`), senão a resposta antiga chega depois da nova e sobrescreve o resultado. Isso é `race condition`, o mesmo problema descrito em [React.js](react-js.md) § 1. Nenhum dos dois é fornecido pelo RHF. Se você não vai implementá-los, use a Via 2.

**Campos que dependem de outro campo.** `deps` revalida o vizinho junto — mas, sendo `rule` do `register`, tem a mesma restrição acima:

```tsx
// Sem resolver:
<input {...register('confirmacao', { deps: ['senha'] })} />

// Com resolver: a regra cruzada vai para o schema, com path (RHF-VAL-05),
// e a revalidação do vizinho é forçada por trigger.
await trigger('confirmacao')
```

`trigger` valida manualmente e devolve `Promise<boolean>` — é o que um wizard usa para liberar o próximo passo:

```tsx
const podeAvancar = await trigger(['nome', 'email'])
```

> **Custo de `trigger`.** A fonte é específica: o isolamento de render só vale ao passar **um único nome como string**. Passar array, ou chamar `trigger()` sem argumento, re-renderiza o estado do formulário inteiro. Num wizard isso é aceitável — acontece uma vez por passo. Dentro de um `onChange`, não é.

### 3.4 Regras — `RHF-VAL-*` (schema)

| ID | Regra |
| --- | --- |
| `RHF-VAL-02` | Schema com `.transform()` ou `.default()` **MUST** declarar os três generics: `useForm<z.input<S>, unknown, z.output<S>>`. |
| `RHF-VAL-04` | O tipo do formulário **MUST** derivar do schema (`z.infer`/`z.input`); **NEVER** ser escrito em paralelo. |
| `RHF-VAL-05` | Regra que cruza campos **MUST** usar `.refine()`/`.superRefine()` com `path`, **NEVER** `validate` duplicado nos dois campos. |
| `RHF-VAL-06` | Com `resolver` ativo, `rules` do `register` — `validate` e `deps` inclusive — **NEVER** são usadas. Regra que exige I/O **MUST** ir para o schema (`.refine()` assíncrono) ou para a submissão (`setError`). |
| `RHF-VAL-10` | Validação assíncrona por campo **MUST** ter debounce e cancelamento, ou ser movida para a submissão. |
| `RHF-VAL-07` | `trigger` com array ou sem argumento **MUST** ser restrito a transições de passo; **NEVER** em handler de digitação. |

---

## 4. Erros

### 4.1 A estrutura

```ts
errors.email                 // FieldError    → { type, message, types?, ref? }
errors.endereco?.cidade      // aninhado segue o shape do formulário
errors.itens?.[0]?.nome      // arrays por índice
errors.itens?.root           // erro das rules do próprio field array (v7.34.0)
errors.root?.serverError     // erro global — não pertence a campo nenhum
```

`errors.campo.types` só é preenchido com `criteriaMode: 'all'`.

**`errors.root.*` tem um comportamento próprio, verificado na fonte: não persiste entre submissões.** Isso é conveniente — o erro global some sozinho na próxima tentativa — e é uma armadilha se você contava com ele para exibir um resumo persistente.

### 4.2 `setError` — e as suas duas caveats

```tsx
setError('email', { type: 'server', message: 'E-mail já cadastrado.' })
setError('root.serverError', { type: '503', message: 'Serviço indisponível.' })
setError('cpf', { type: 'server', message: '…' }, { shouldFocus: true })
```

Duas coisas que a fonte declara e que mudam o desenho do código:

**1. O erro não persiste se o campo passa nas regras do `register`.** Um erro de servidor colocado num campo **registrado com validação** é apagado na próxima rodada de validação daquele campo. Para "e-mail já cadastrado" isso é até desejável (o usuário digita outro, o erro some). Para um erro que precisa sobreviver, o lugar é `root.serverError`.

**2. `setError` força `isValid` para `false` imediatamente** — mas esse valor não vem da validação e será sobrescrito na próxima rodada. Não use `isValid` como prova de que o servidor aceitou.

`shouldFocus` não funciona em campo desabilitado.

### 4.3 Erros de servidor: o fluxo completo

```tsx
const onSubmit = handleSubmit(async (data) => {
  try {
    await api.criarConta(data)
  } catch (e) {
    if (e instanceof ApiError && e.fieldErrors) {
      // 422 com detalhamento por campo → cada erro no seu campo
      for (const [campo, mensagem] of Object.entries(e.fieldErrors)) {
        setError(campo as FieldPath<Cadastro>, { type: 'server', message: mensagem })
      }
      return
    }
    // esperado, mas sem campo: vai para a raiz
    setError('root.serverError', {
      type: String(e instanceof ApiError ? e.status : 'unknown'),
      message: 'Não foi possível criar a conta. Tente novamente.',
    })
  }
})
```

E na UI:

```tsx
{errors.root?.serverError && (
  <p role="alert">{errors.root.serverError.message}</p>
)}
```

**Por que `try/catch` e não deixar lançar:** a fonte diz que `handleSubmit` **não engole** exceções do `onSubmit`. Uma exceção que escapa sobe para o Error Boundary, remove o formulário da tela junto com tudo que o usuário digitou, e deixa `isSubmitSuccessful` incorreto. Erro esperado é estado. `REACT-ASYNC-09`.

**A exceção à exceção:** erro genuinamente inesperado — contrato quebrado, bug — **deve** subir. A distinção é a de: esperado é o que a UI sabe apresentar.

### 4.4 A opção `errors` do `useForm`

Desde a v7.49.0, erros do servidor podem entrar de forma reativa, sem `setError`:

```tsx
useForm({ errors: errosDoServidor })
```

Útil quando os erros já vivem num estado externo (retorno de `useActionState`, cache de mutation). **A fonte alerta:** o objeto precisa ter **referência estável**, senão o formulário entra em re-render infinito. Objeto literal inline é justamente o que quebra.

### 4.5 `SubmitErrorHandler`

`handleSubmit` aceita um segundo callback, chamado quando a validação **falha**:

```tsx
handleSubmit(onValid, (errors) => {
  analytics.track('form_invalid', { campos: Object.keys(errors) })
})
```

É o lugar certo para telemetria de formulário — e evita o `useEffect` observando `errors` que costuma aparecer no lugar.

> **Escopo de `RHF-ERR-04`, e as duas escalas de tempo que a fonte não separa.** São coisas diferentes:
>
> | Onde | Some quando |
> | --- | --- |
> | `errors.<campo>` posto por `setError` | **aquele campo** revalida |
> | `errors.root.*` | há uma **nova submissão** |
>
> A fonte descreve a primeira como "não persiste se o input passa nas regras do `register`". Com `resolver`, `register` não tem regras (`RHF-VAL-06`) — mas o campo **é** validado, pelo schema. O que apaga o erro é a revalidação do campo, qualquer que seja a fonte dela.
>
> **Na prática:** "e-mail já em uso" no campo é o comportamento desejado (o usuário digita outro, o erro some). Um 503 no campo seria apagado por qualquer digitação — por isso vai para `root`. E se você precisa de um resumo que sobreviva **também** à nova submissão, nenhum dos dois serve: isso é estado da sua aplicação, não do formulário.

### 4.6 Regras — `RHF-ERR-*`

| ID | Regra |
| --- | --- |
| `RHF-ERR-01` | Erro esperado **MUST** ser exibido pelo formulário; **NEVER** por exceção não capturada. |
| `RHF-ERR-02` | Erro de servidor **MUST** entrar por `setError`: de campo no campo, sem campo em `root.serverError`. |
| `RHF-ERR-03` | Erro esperado **NEVER** é lançado de dentro do `onSubmit` — `handleSubmit` não o engole e `isSubmitSuccessful` fica errado. Apelido de `REACT-ASYNC-09`. |
| `RHF-ERR-04` | Erro de servidor que precisa sobreviver à revalidação **MUST** ir para `root.*`. Um erro posto num campo é apagado quando **aquele campo** revalida — e num projeto com `resolver` isso vale para todo campo, já que o schema valida todos. Ver a nota de escopo abaixo. |
| `RHF-ERR-05` | `isValid` **NEVER** é usado como prova de aceitação pelo servidor. |
| `RHF-ERR-06` | O objeto passado à opção `errors` **MUST** ter referência estável — literal inline causa re-render infinito. |
| `RHF-ERR-07` | Telemetria de falha de validação **MUST** usar o segundo callback de `handleSubmit`, **NEVER** um `useEffect` observando `errors`. |

---

## 5. Validação nativa do browser

Duas opções distintas que costumam ser confundidas — e que a fonte declara **independentes**.

| Opção | O que faz |
| --- | --- |
| `shouldUseNativeValidation` (v7.9.0) | delega a exibição à Constraint Validation API do browser; habilita `:valid`/`:invalid` no CSS |
| `progressive` (v7.44.0) | **só** emite `required`, `min`, `max`, `minLength`, `maxLength` e `pattern` como atributos HTML no `register` |

`shouldUseNativeValidation` tem restrições verificadas: funciona apenas com `mode` `onSubmit` ou `onChange`, e a mensagem de cada regra **precisa ser string**.

`progressive` é o que serve a progressive enhancement: o HTML sai do servidor já com os atributos, e o formulário valida no browser antes de a hidratação acontecer. Não depende de `shouldUseNativeValidation`, nem o contrário.

| ID | Regra |
| --- | --- |
| `RHF-VAL-08` | `shouldUseNativeValidation` **MUST** vir com `mode` `'onSubmit'` ou `'onChange'` e mensagens em string. |
| `RHF-VAL-09` | `progressive` **NEVER** é assumido como equivalente a `shouldUseNativeValidation` — são independentes. |

---

## 6. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `resolver` e `validate` no mesmo `useForm` | escolher um · `RHF-VAL-01` |
| `interface FormData` escrita ao lado do schema | `z.infer` · `RHF-VAL-04` |
| `z.infer` com schema que usa `.transform()` | três generics · `RHF-VAL-02` |
| `refine` sem `path` | o erro some na raiz · `RHF-VAL-05` |
| Mesma regra cruzada duplicada em dois `validate` | `.refine()` · `RHF-VAL-05` |
| `validate` no `register` com resolver ativo — nunca roda | `.refine()` assíncrono ou `setError` no submit · `RHF-VAL-06` |
| Validação assíncrona por tecla, sem debounce nem cancelamento | debounce + `AbortController`, ou mover para o submit · `RHF-VAL-10` |
| `trigger()` sem argumento a cada digitação | alvo único, ou só na transição · `RHF-VAL-07` |
| `throw` de erro de validação no `onSubmit` | `setError` · `RHF-ERR-03` |
| Erro de servidor em `toast` e não no formulário | `setError` · `RHF-ERR-02` |
| `setError` em campo com regras, esperando persistência | `root.serverError` · `RHF-ERR-04` |
| `errors={{ … }}` literal inline no `useForm` | referência estável · `RHF-ERR-06` |
| `useEffect` observando `errors` para telemetria | 2º callback de `handleSubmit` · `RHF-ERR-07` |
| `mode: 'onChange'` como default do projeto | `'onTouched'` · `RHF-VAL-03` |
| Confiar na validação de cliente | revalidar no servidor · `RHF-CORE-05` |

---

## Relacionados

- [React Hook Form](react-hook-form.md) — entrada, árvore da § 5.3 e § 5.5
- [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) · [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md)
- ·
- ·
- [React - Suspense e Assincronia](react-suspense-e-assincronia.md) — `REACT-ASYNC-09`, o ID canônico
- — a mesma fronteira, no lado do servidor

## Fontes consultadas

Verificadas em 2026-08-15:

- [useForm](https://react-hook-form.com/docs/useform) — `mode`, `criteriaMode`, `delayError`, contrato do resolver, exclusividade de `validate` × `resolver`
- [setError](https://react-hook-form.com/docs/useform/seterror) — não persistência em campo com regras, `root.serverError`, efeito em `isValid`
- [trigger](https://react-hook-form.com/docs/useform/trigger) — isolamento de render só com nome único
- [handleSubmit](https://react-hook-form.com/docs/useform/handlesubmit) — exceções não são engolidas; `SubmitErrorHandler`
- [formState](https://react-hook-form.com/docs/useform/formstate) — `isValidating`, `validatingFields`, comportamento de `isValid`
- [register](https://react-hook-form.com/docs/useform/register) — `validate`, `deps`
- [@hookform/resolvers](https://github.com/react-hook-form/resolvers) — `zodResolver`, tipagem de valores transformados
- [TypeScript](https://react-hook-form.com/ts) — `Resolver`, `ValidateForm`, generics de `useForm`
