---
Link: https://react-hook-form.com/docs/useform/register
tags:
 - react
 - forms
 - react-hook-form
 - a11y
 - agent-context
source: "Documentação oficial do React Hook Form — register, Controller, useController, useFormContext"
verificado-em: 2026-08-15
---

# React Hook Form — Registro e Controle

> `register` · coerção · transform/parse (moeda, percentual, máscara) · `Controller` · `useController` · `FormProvider` / `useFormContext` · acessibilidade
>
> Como um campo entra no formulário. É a decisão que define se o formulário será rápido, acessível e tipado — ou nenhuma das três.

Entrada: [React Hook Form](react-hook-form.md) · Base normativa do React: [React - Rules of React](react-rules-of-react.md)

---

## 1. Conceito: por que existem duas vias

RHF é **não controlado por padrão**: o valor mora no nó do DOM, e o formulário fala com ele por `ref`. Digitar não re-renderiza nada. É daí que vem a performance da biblioteca — e é isso que `Controller` parcialmente abre mão.

```tsx
// register: o formulário conecta o input via ref. Zero render por tecla.
<input {...register('email')} />
```

`register` devolve exatamente as quatro coisas que um input nativo precisa:

| Propriedade | Papel |
| --- | --- |
| `name` | identidade do campo no formulário |
| `ref` | como o RHF lê o valor, e como foca o campo em caso de erro |
| `onChange` | notifica mudança |
| `onBlur` | notifica interação (alimenta `touchedFields`) |

Quando `progressive: true` está ligado no `useForm`, o retorno também traz `required`, `min`, `max`, `minLength`, `maxLength` e `pattern` como atributos HTML nativos. E traz `disabled` quando a opção está setada.

**O problema:** boa parte dos componentes de UI não aceita `ref` nem emite `onChange` com o evento nativo. Um `<Select>` que só entende `value` e `onChange={(valor) => …}` não tem onde encaixar um `ref`. Para esses, `Controller` faz a tradução — e reintroduz o render controlado **naquele campo apenas**, não no formulário inteiro.

> **O critério é técnico, não estético.** A pergunta é "este componente encaminha `ref` e emite evento nativo?". Se sim, `register`. Se não, `Controller`. Usar `Controller` onde `register` bastaria custa render sem ganho; usar `register` onde não dá custa um campo que simplesmente não funciona. Ver a árvore em [React Hook Form](react-hook-form.md) § 5.1.

---

## 2. `register`

```tsx
register(name: string, options?: RegisterOptions): UseFormRegisterReturn
```

### 2.1 Regras de nome

O nome é uma **rota** dentro do objeto de valores, não um rótulo.

```tsx
register('email') // { email: … }
register('endereco.cidade') // { endereco: { cidade: … } }
register('itens.0.quantidade') // { itens: [{ quantidade: … }] }
```

| Regra da fonte | Consequência |
| --- | --- |
| Nome é obrigatório e único — exceto radio e checkbox nativos, que compartilham nome de propósito | dois campos com o mesmo nome se sobrescrevem silenciosamente |
| **Apenas dot notation**; `itens[0].nome` não é suportado | o path não resolve e o valor não aparece no submit |
| Um **segmento** de nome não pode começar com número quando é chave de objeto | `register('2fa')` e `register('perfil.2fa')` quebram a resolução de path. **Índice de array é a exceção e é a forma correta**: em `itens.0.nome`, o `0` é posição, não chave — é exatamente o que `RHF-REG-01` manda escrever |
| Reservados do RHF: `ref` e `_f` | colisão com o interno da biblioteca |
| Reservados de erro: `type`, `root`, `ref`, `types`, `message`, `form` | colidem com a estrutura de `FieldError` — o erro do campo fica inacessível |

### 2.2 Regras de validação inline

Aceitas na forma curta ou com mensagem:

```tsx
<input {...register('titulo', { required: true })} />

<input {...register('titulo', {
 required: { value: true, message: 'Título é obrigatório.' },
 minLength: { value: 5, message: 'Mínimo de 5 caracteres.' },
})} />
```

Disponíveis: `required`, `min`, `max`, `minLength`, `maxLength`, `pattern`, `validate`.

`validate` aceita função ou objeto de funções nomeadas, e a função recebe **os valores do formulário como segundo argumento** — é assim que se valida um campo contra outro:

```tsx
register('produto', {
 validate: {
 disponivel: async (produto, { categoria }) => {
 if (!categoria) return 'Escolha uma categoria primeiro.'
 return (await temEstoque(categoria, produto)) || 'Produto indisponível.'
 },
 },
})
```

**Quando existe um `resolver`, estas regras não são usadas** — a fonte diz que o resolver "cannot be used with built-in validators". Vale para todas, `validate` e `deps` inclusive, e o sintoma é silencioso: a função nunca é chamada. Ver `RHF-VAL-06` e a § 3.3 de [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md).

### 2.3 A pegadinha do re-registro

Chamar `register` de novo no mesmo nome **mescla** as opções com as anteriores; não substitui.

```tsx
register('idade', { required: true, min: 18 })
register('idade', { min: 21 }) // resultado: { required: true, min: 21 }
register('idade', { required: undefined }) // ❌ NÃO remove nada
register('idade', { required: false }) // ✅ remove
```

Isso morde em componentes que re-registram condicionalmente. Para desligar uma regra, passe `false` explícito.

### 2.4 Coerção: o DOM sempre devolve string

`<input type="number">` produz `"42"`. `<input type="date">` produz `"2026-08-15"`. Sem coerção explícita, o schema recebe string onde espera número, e a validação falha por um motivo que não é o real.

| Opção | Uso | Cuidado |
| --- | --- | --- |
| `valueAsNumber: true` | numérico simples | campo vazio vira `NaN`, não `undefined` |
| `valueAsDate: true` | data | entrada inválida vira `Invalid Date` |
| `setValueAs: (v) => T` | conversão de **mão única**: trim, normalizar, parsear | roda também com valor vazio — trate o caso. **NÃO serve para moeda nem máscara** — ver § 3.4 · `RHF-CTRL-09` |

```tsx
// ✅ vazio vira undefined em vez de NaN — o schema decide se é obrigatório
<input type="number" {...register('quantidade', {
 setValueAs: (v) => (v === '' ? undefined : Number(v)),
})} />
```

> **Qual dos três usar — e o critério que os separa.**
>
> | Situação | Mecanismo |
> | --- | --- |
> | Só mudar o tipo, e já existe schema no projeto | `z.coerce.number` — mantém a conversão junto da regra, e o servidor herda a mesma coerção |
> | Só mudar o tipo, sem schema | `valueAsNumber` / `setValueAs` |
> | **Exibir formatado e guardar outro valor** | nem um nem outro: `Controller` com `input`/`output` — § 3.4 · `RHF-CTRL-09` |
>
> `setValueAs` transforma apenas o que **entra**. Não existe `displayValueAs`. No instante em que o que se vê deixa de ser o que se guarda, o campo é controlado por definição, e o mecanismo muda.

### 2.5 Campo desabilitado apaga o valor

`disabled: true` faz o valor do campo ser `undefined` na submissão. Isso é comportamento nativo do HTML, e é frequentemente o oposto do que se quer ("mostrar mas não deixar editar").

```tsx
<input {...register('cpf', { disabled: true })} /> // some do submit
<input {...register('cpf')} readOnly /> // ✅ vai no submit
```

Para congelar um bloco inteiro mantendo os valores, use `<fieldset disabled>` com `readOnly` nos campos, ou a opção `disabled` do `useForm` quando a intenção **for** mesmo excluir tudo da submissão.

### 2.6 Regras — `RHF-REG-*`

| ID | Regra |
| --- | --- |
| `RHF-REG-01` | Nome de campo **MUST** usar dot notation (`itens.0.nome`); colchetes **NEVER**. |
| `RHF-REG-02` | Nome **NEVER** começa com número, e **NEVER** usa `type`, `root`, `ref`, `types`, `message`, `form` ou `_f`. |
| `RHF-REG-03` | Valor de campo numérico ou de data **MUST** ter coerção explícita — `valueAsNumber`, `valueAsDate`, `setValueAs` ou `z.coerce.*`. |
| `RHF-REG-04` | Para remover uma regra num re-registro, o valor **MUST** ser `false`; `undefined` **NEVER** remove. |
| `RHF-REG-05` | `disabled: true` **MUST** ser usado só quando a intenção for excluir o campo da submissão; caso contrário, `readOnly`. |

---

## 3. `Controller` e `useController`

São a mesma coisa: `Controller` é o componente, `useController` é o hook que o move. A escolha é de forma, não de comportamento.

| Use | Quando |
| --- | --- |
| `<Controller>` | uso pontual, escrito inline no JSX do formulário |
| `useController` | você está empacotando um **componente de campo reutilizável** |

```tsx
<Controller
 name="dataNascimento"
 control={control}
 render={({ field, fieldState }) => (
 // espalhe field: name e disabled também fazem parte dele. RHF-CTRL-01
 <DatePicker {...field} aria-invalid={fieldState.invalid || undefined} />
 )}
/>
```

> **Convenção de `aria-invalid` nesta doc:** `fieldState.invalid || undefined` (ou `erro ? true : undefined`), nunca `!!erro`. A forma com `!!` emite `aria-invalid="false"` em **todo** campo válido, o que é ruído para o leitor de tela; `undefined` omite o atributo.

### 3.1 O objeto `field`

| Propriedade | Papel | Se você esquecer |
| --- | --- | --- |
| `value` | valor atual | o componente não mostra nada |
| `onChange` | devolve o valor ao formulário | o valor nunca chega ao submit |
| `onBlur` | reporta interação | `touchedFields` e `mode: 'onBlur'` param de funcionar |
| `ref` | permite ao RHF focar o campo com erro | `shouldFocusError` e `setFocus` viram no-op nesse campo |
| `name` | identidade | — |
| `disabled` | estado desabilitado (v7.46.0) | — |

E `fieldState` traz `invalid`, `isTouched`, `isDirty` e `error` **daquele campo**, sem assinar o formulário inteiro.

### 3.2 As três armadilhas

**`onChange(undefined)` é inválido.** A fonte é explícita. Limpar um campo controlado com `undefined` faz o React tratar o input como não controlado de novo, e ele passa a avisar no console.

```tsx
onChange={(v) => field.onChange(v ?? null)} // ✅ null ou '' — nunca undefined
```

**Espalhe `field` antes de sobrescrever.** É o erro mais comum ao transformar valores: sobrescrever `onChange` sem espalhar o resto derruba `onBlur`, `name` e `ref` junto — e o campo perde foco automático e estado de *touched* sem dar nenhum sinal.

```tsx
// ❌ perde onBlur, name e ref
<input onChange={(e) => field.onChange(Number(e.target.value))} value={field.value} />

// ✅
<input {...field} onChange={(e) => field.onChange(Number(e.target.value))} />
```

**Não use `setValue` para atualizar um campo controlado.** A via é `field.onChange`. `setValue` funciona, mas contorna o caminho do `Controller` e desacerta `isDirty`/`isTouched`.

### 3.3 Componente de campo reutilizável

O padrão que `useController` existe para servir. O ganho não é estético: é ter `aria-*`, `id` e mensagem de erro corretos **uma vez**, em vez de em cada campo.

```tsx
import { useId } from 'react'
import {
 useController,
 type Control,
 type FieldValues,
 type FieldPath,
} from 'react-hook-form'

type CampoTextoProps<T extends FieldValues> = {
 control: Control<T>
 name: FieldPath<T> // ✅ autocompleta e valida contra o shape do form
 label: string
 type?: 'text' | 'email' | 'password'
}

export function CampoTexto<T extends FieldValues>({
 control, name, label, type = 'text',
}: CampoTextoProps<T>) {
 const { field, fieldState } = useController({ control, name })
 const id = useId
 const erroId = `${id}-erro`

 return (
 <div>
 <label htmlFor={id}>{label}</label>
 <input
 {...field}
 id={id}
 type={type}
 value={field.value ?? ''} // nunca undefined
 aria-invalid={fieldState.invalid || undefined}
 aria-describedby={fieldState.error ? erroId : undefined}
 />
 {fieldState.error && (
 <p id={erroId} role="alert">{fieldState.error.message}</p>
 )}
 </div>
 )
}
```

Quatro decisões que não são óbvias:

- **`FieldPath<T>` em vez de `string`** — o `name` passa a autocompletar e a falhar em compilação se o campo não existir no formulário. Sem isso, um typo só aparece em runtime, como campo que nunca valida.
- **`useId` para o par `label`/`input`/erro** — o id precisa ser estável entre servidor e cliente. Ver `REACT-UTIL-01` em [React - Hooks Utilitários](react-hooks-utilitarios.md).
- **`value={field.value ?? ''}`** — protege contra o input começar não controlado quando o `defaultValues` não cobre o campo. É rede de segurança, não substituto de `RHF-CORE-01`.
- **Uma chamada de `useController` por componente** — a fonte recomenda explicitamente. Cada chamada cria sua própria assinatura, e várias no mesmo componente multiplicam re-render sem ganho.

### 3.4 Transform e parse: quando o exibido difere do guardado

Até aqui, `register` + coerção (§ 2.4) resolveu conversão de tipo. Ele não resolve **formatação**, e a diferença entre as duas é o que decide o mecanismo.

| | O usuário vê | O formulário guarda | Mecanismo |
| --- | --- | --- | --- |
| **Mão única** | o que digitou | outro **tipo** do mesmo valor | `register` + `valueAsNumber` / `setValueAs` |
| **Mão dupla** | um valor **formatado** | outro valor | `Controller` com `input`/`output` |

Moeda, percentual, telefone mascarada, data em formato local — todos são mão dupla: `R$ 1.234,56` na tela e `123456` no submit não são o mesmo texto. Mão dupla é **inerentemente controlada**, e é por isso que `setValueAs` não dá conta: ele só transforma o que entra, e não existe contraparte para o que sai.

Esta é a resposta oficial da documentação (*Advanced Usage*, "Transform and Parse"), e a razão que ela dá para não parar em `valueAsNumber`: essas opções deixam `NaN` e `null` sem tratamento.

#### O padrão

Duas funções puras, uma para cada direção, aplicadas dentro do `render`:

```tsx
import { useId } from 'react'
import { Controller, type Control, type FieldPath, type FieldValues } from 'react-hook-form'

// input — do que guardamos para o que se vê. Centavos → texto formatado.
const paraExibicao = (centavos: number | null | undefined) =>
 new Intl.NumberFormat('pt-BR', {
 style: 'currency', currency: 'BRL',
 }).format((centavos ?? 0) / 100)

// output — do que foi digitado para o que guardamos. Só dígitos: nunca toca em float.
const paraCentavos = (texto: string) => Number(texto.replace(/\D/g, '') || 0)

export function CampoMoeda<T extends FieldValues>({
 control, name, label,
}: { control: Control<T>; name: FieldPath<T>; label: string }) {
 const id = useId

 return (
 <Controller
 control={control}
 name={name}
 render={({ field, fieldState }) => (
 <>
 <label htmlFor={id}>{label}</label>
 <input
 {...field} // RHF-CTRL-01
 id={id}
 type="text" // NÃO type="number"
 inputMode="numeric"
 value={paraExibicao(field.value as number)} // input: guardado → visto
 onChange={(e) => field.onChange(paraCentavos(e.target.value))} // output
 aria-invalid={fieldState.invalid || undefined}
 aria-describedby={fieldState.error ? `${id}-erro` : undefined}
 />
 {fieldState.error && (
 <p id={`${id}-erro`} role="alert">{fieldState.error.message}</p>
 )}
 </>
 )}
 />
 )
}
```

#### As seis decisões

**1. Guarde centavos como inteiro, nunca reais como float.** `19.99 * 100` é `1998.9999999999998` em JavaScript. Qualquer aritmética de dinheiro em ponto flutuante acumula erro, e o formulário é onde o valor nasce. `paraCentavos` remove tudo que não é dígito e trata o resultado **já como centavos** — não há multiplicação, logo não há float em lugar nenhum.

**2. `type="text"` com `inputMode="numeric"`, não `type="number"`.** Um `<input type="number">` recusa `R$ 1.234,56` como valor — o campo simplesmente fica vazio. Além disso ele traz spinners e permite `e`, `+`, `-`. `inputMode="numeric"` traz o teclado numérico no celular sem nenhum desses custos.

**3. `{...field}` antes de sobrescrever.** `RHF-CTRL-01`. Aqui `value` e `onChange` são substituídos, mas `onBlur`, `name` e `ref` precisam continuar passando, senão o campo perde `isTouched` e foco automático em erro.

**4. O modelo de digitação é "por centavos".** O usuário digita `1`, `2`, `3`, `4` e vê `R$ 0,01` → `R$ 0,12` → `R$ 1,23` → `R$ 12,34`. Parece estranho descrito e é o que todo app de banco faz, por um motivo prático: **o cursor fica sempre no fim**, e o problema de reposicionar cursor no meio de uma máscara deixa de existir. A alternativa — digitação livre com formatação no `blur` — exige gerenciar `selectionStart` manualmente a cada render, o que está fora do escopo do RHF e é a origem da maioria dos bugs de campo mascarado.

**5. `defaultValues` recebe `0`, não `''`.** O tipo guardado é `number`. `RHF-CORE-01` continua valendo, e `paraExibicao` já trata `null`/`undefined` com `?? 0` como rede de segurança.

**6. O schema valida o domínio, não a apresentação.** Como o `output` já converteu, o schema recebe número:

```tsx
const pedidoSchema = z.object({
 valor: z.number.int.positive('Informe um valor.'),
})
```

Sem `z.coerce`, sem `.transform` — e portanto **sem a exigência dos três generics de `RHF-VAL-02`**. Deslocar a conversão para o `Controller` em vez do schema é o que mantém `z.input` e `z.output` iguais.

#### Fechando o laço com dado do servidor

Este é o ponto em que a ponte `RHF-BRIDGE-03` e a formatação se encontram. O servidor devolve centavos; `values` os injeta; `input` os formata. Nada além disso é necessário — e nenhuma das duas pontas precisa saber da outra.

```tsx
const { data } = useQuery({ queryKey: ['pedido', id], queryFn: buscarPedido })

useForm({
 defaultValues: { valor: 0 },
 values: data, // { valor: 123456 } em centavos
 resetOptions: { keepDirtyValues: true },
})
```

Se em vez disso o backend enviasse `"R$ 1.234,56"`, a formatação seria contrato de API — e aí a conversão pertence à camada de fetch, não ao formulário.

#### Além da moeda: as três perguntas que generalizam

Moeda é o caso completo. Percentual, telefone e data local usam o mesmo esqueleto, mas **as seis decisões acima não transferem inteiras** — três perguntas decidem quais valem.

**1. O que guardar?** O tipo que o consumidor espera. Se for numérico com **casas decimais fixas** (dinheiro, taxa, peso), guarde o inteiro na menor unidade — pelo motivo da decisão 1. Se for identificador (telefone, CPF, CEP), guarde a string de dígitos: não é número, não se soma, e zero à esquerda é significativo.

**2. A unidade fica dentro ou fora do `value`?** Esta é a pergunta que a seção de moeda não precisou fazer, e é a que quebra o percentual.

| | Exemplo | Pode ficar dentro do `value`? |
| --- | --- | --- |
| **Prefixo** | `R$ ` | **Sim** — a digitação acrescenta no fim, longe dele |
| **Sufixo** | ` %`, ` kg` | **Não** — o cursor teria que parar antes dele, e você volta a gerenciar caret |
| **Separador interno** | `(81) 99999-9999` | Sim — cresce no fim, e os separadores são reescritos a cada tecla |

Sufixo vai **fora do input**, como texto adjacente. Não é detalhe estético: é o que preserva a propriedade que faz todo o padrão funcionar.

**3. O crescimento acontece no fim?** Se sim, `input`/`output` puros bastam e o cursor se resolve sozinho. Se não — edição no meio de uma máscara, campo de data com navegação por segmento — você precisa de gerenciamento de `selectionStart`, que está fora do escopo do RHF e desta doc.

#### Percentual

Backend quer `0.15`; o usuário vê `15%`. Duas armadilhas, e a primeira é a mesma da moeda vista de outro ângulo.

```tsx
// Guardamos pontos-base: 1500 = 15,00%. Inteiro, como a decisão 1 manda.
const paraExibicao = (pontosBase: number | null | undefined) =>
 ((pontosBase ?? 0) / 100).toLocaleString('pt-BR', { minimumFractionDigits: 2 })

const paraPontosBase = (texto: string) => Number(texto.replace(/\D/g, '') || 0)

// O sufixo fica FORA do input — pergunta 2
<div className="flex items-baseline gap-1">
 <input
 {...field}
 id={id}
 type="text"
 inputMode="numeric"
 value={paraExibicao(field.value as number)}
 onChange={(e) => field.onChange(paraPontosBase(e.target.value))}
 />
 <span aria-hidden="true">%</span>
</div>
```

**A armadilha do float é a mesma, e a saída também.** `0.15 * 100` é `15.000000000000002`. Guardando pontos-base, nenhuma multiplicação acontece durante a digitação — só uma divisão, e só na exibição.

**A conversão para `0.15` acontece na fronteira, uma vez.** O mesmo critério da seção anterior sobre `"R$ 1.234,56"` vindo do backend: se o contrato da API é `0.15`, essa é a forma do **payload**, não a forma do **formulário**. Converta onde o payload é montado:

```tsx
const orcamentoSchema = z.object({
 descontoPontosBase: z.number.int.min(0).max(10000),
})

const onSubmit = handleSubmit(async (data) => {
 await api.salvar({ desconto: data.descontoPontosBase / 10000 }) // única divisão
})
```

Se a conversão precisar mesmo morar no formulário, use `.transform` no schema — e aí `RHF-VAL-02` volta a valer: três generics.

> **`aria-hidden` no `%`.** O símbolo fora do input é decoração visual: o leitor de tela deve ouvi-lo pelo `<label>` ("Desconto em porcentagem"), não solto depois do valor. Se o rótulo não deixa a unidade clara, o lugar de dizê-la é o `<label>` ou um `aria-describedby` — não um `<span>` órfão.

#### Máscara de comprimento variável — telefone

O caso que a seção de moeda não cobre: **o formato depende de quantos dígitos existem**.

```tsx
const paraDigitos = (texto: string) => texto.replace(/\D/g, '').slice(0, 11)

const paraMascara = (digitos: string) => {
 const d = digitos ?? ''
 const ddd = d.slice(0, 2)
 const resto = d.slice(2)

 if (d.length <= 2) return ddd // "8", "81" — sem parênteses ainda
 if (d.length <= 6) return `(${ddd}) ${resto}` // "(81) 9999"
 if (d.length <= 10) return `(${ddd}) ${resto.slice(0, 4)}-${resto.slice(4)}` // fixo
 return `(${ddd}) ${resto.slice(0, 5)}-${resto.slice(5)}` // celular
}

<input
 {...field}
 id={id}
 type="text"
 inputMode="tel" // teclado de telefone, não numérico
 value={paraMascara(field.value as string)}
 onChange={(e) => field.onChange(paraDigitos(e.target.value))}
/>
```

Quatro decisões que a moeda não exigiu:

- **Guardamos string, não número.** `"081..."` perderia o zero como número, e telefone não é quantidade.
- **`slice(0, 11)` no `output`, não no `input`.** O truncamento pertence ao que se guarda. Colar 15 dígitos guarda 11 e exibe 11 — sem estado inconsistente entre o visto e o guardado.
- **Estados parciais não inventam pontuação.** Com 1 ou 2 dígitos o retorno é `"8"`/`"81"`, sem `(`. Abrir um parêntese que o usuário não digitou faz o campo parecer travado quando ele apaga tudo.
- **10 × 11 dígitos** decide onde o hífen cai. Fixo agrupa 4-4; celular, 5-4. Um `if` no `input`, porque é apresentação — o `output` continua sendo só dígitos.

**A validação continua no schema**, não na máscara: `z.string.length(11, 'Telefone incompleto.')`. A máscara formata; ela não decide o que é válido.

#### Quando isto é exagero

Se o campo aceita o valor **cru** e só precisa mudar de tipo (`"42"` → `42`), fique em `register` + `valueAsNumber`. `Controller` reintroduz render controlado naquele campo (§ 1), e pagar isso por uma conversão de mão única é o que `RHF-CTRL-08` proíbe.

### 3.5 Regras — `RHF-CTRL-*`

| ID | Regra |
| --- | --- |
| `RHF-CTRL-01` | Ao sobrescrever `onChange` ou `value`, `field` **MUST** ser espalhado antes — `onBlur`, `name` e `ref` precisam continuar chegando. |
| `RHF-CTRL-02` | `field.onChange` **NEVER** recebe `undefined`. Use `null` ou `''`. Apelido de `RHF-CORE-06`. |
| `RHF-CTRL-03` | `useController` **SHOULD** ser chamado no máximo uma vez por componente — cada chamada cria assinatura própria e paga re-render. É recomendação de performance da fonte, não regra de correção: dois `useController` num componente funcionam. |
| `RHF-CTRL-04` | Campo controlado **MUST** ser atualizado por `field.onChange`, **NEVER** por `setValue`. |
| `RHF-CTRL-05` | `field.ref` **MUST** chegar ao elemento focável, senão `shouldFocusError` e `setFocus` não funcionam nesse campo. |
| `RHF-CTRL-06` | `shouldUnregister` **NEVER** é usado em campo dentro de `useFieldArray` — remount e reordenação quebram o estado. |
| `RHF-CTRL-07` | `name` de componente de campo reutilizável **MUST** ser tipado como `FieldPath<T>`, **NEVER** como `string`. |
| `RHF-CTRL-08` | `Controller`/`useController` em campo nativo **MUST** ter motivo declarado — encapsular acessibilidade num componente reutilizável conta; conveniência não. Sem motivo, use `register`. |
| `RHF-CTRL-09` | Transformação de **mão dupla** (exibido ≠ guardado) **MUST** usar `Controller` com funções `input`/`output`; `setValueAs` **NEVER** dá conta, porque só transforma a entrada. |
| `RHF-CTRL-10` | Valor numérico com **casas decimais fixas** (dinheiro, taxa, peso) **MUST** ser guardado como inteiro na menor unidade — centavos, pontos-base. `float` **NEVER**. Identificador formatado (telefone, CPF, CEP) **MUST** ser guardado como string de dígitos: zero à esquerda é significativo. |
| `RHF-CTRL-11` | Campo com máscara ou formatação **MUST** usar `type="text"` com `inputMode` adequado (`numeric` para quantidade, `tel` para telefone, `decimal` para valor com vírgula), **NEVER** `type="number"` — que recusa o valor formatado. |
| `RHF-CTRL-12` | **Sufixo** de unidade (`%`, `kg`) **MUST** ficar fora do `value`, como texto adjacente com `aria-hidden`; dentro do `value` ele obriga a gerenciar o cursor. Prefixo (`R$`) pode ficar dentro. |
| `RHF-CTRL-13` | Truncamento de comprimento **MUST** acontecer no `output` (o que se guarda), **NEVER** só no `input` — senão o exibido e o guardado divergem. |

> **A ressalva que o exemplo da § 3.3 exige.** `CampoTexto` usa `useController` num `<input>` **nativo**, que pela árvore da § 5.1 seria caso de `register`. O motivo é `RHF-CTRL-08`: `fieldState.error` é local ao campo e não obriga o componente a receber `errors` por prop nem a assinar o formulário inteiro — o que é o ponto de um componente de campo reutilizável.
>
> **O preço, que precisa ser sabido:** `valueAsNumber`, `valueAsDate` e `setValueAs` são opções de `register` e **não existem** em `useController`. Um componente de campo construído assim perde essa via de coerção.
>
> Restam três, e a escolha é a da tabela da § 2.4:
>
> 1. **`register` com as opções de coerção** — se o componente não precisa de `fieldState` nem de `Controller`.
> 2. **Coagir no schema** (`z.coerce.*`) — a via natural quando já existe resolver.
> 3. **Converter no próprio `Controller`**, com `input`/`output` — é a § 3.4, e é obrigatória quando a transformação é de mão dupla.
>
> As três satisfazem `RHF-REG-03`, que exige coerção **explícita**, não um mecanismo específico.

---

## 4. `FormProvider` e `useFormContext`

Para formulários grandes, com campos em componentes profundos, `FormProvider` evita repassar `control` por níveis que não o usam.

```tsx
const methods = useForm<Perfil>({ defaultValues })

<FormProvider {...methods}>
 <form onSubmit={methods.handleSubmit(onSubmit)}>
 <DadosPessoais /> {/* useFormContext<Perfil> lá dentro — § 4.2 */}
 <Endereco />
 </form>
</FormProvider>
```

### 4.1 A regra que a fonte destaca

**Não leia `formState` do `useFormContext`.** A doc oficial diz para usar `useFormState`. O motivo é o Proxy: a assinatura se cria quando a propriedade é **lida durante o render do componente que vai re-renderizar**. Pegar `formState` do contexto entrega o objeto, mas a leitura acontece no lugar errado.

```tsx
// ❌ o valor inicial vem certo — e depois nunca atualiza
const { formState: { errors } } = useFormContext

// ✅
const { control } = useFormContext
const { errors } = useFormState({ control })
```

O sintoma engana justamente porque o primeiro render funciona. O mecanismo do Proxy está na § 1 de [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md).

### 4.2 `control` por prop ou por contexto?

A contradição aparente: a § 4 justifica `FormProvider` como "evita repassar `control`", e os componentes de campo da § 3.3 e § 3.4 recebem `control` como prop **obrigatória**. Parece que um padrão desfaz o outro.

Não desfaz, porque são **dois tipos de consumidor com necessidades opostas**.

| Consumidor | Como pega o formulário | Por quê |
| --- | --- | --- |
| **Seção deste formulário** — `<DadosPessoais />`, `<Endereco />` | `useFormContext<Perfil>` | Ela existe para *este* formulário. Conhece `Perfil`, e pode declará-lo no generic |
| **Campo reutilizável** — `<CampoTexto />`, `<CampoMoeda />` | `control: Control<T>` por prop | Ele é usado em formulários **diferentes**. Não pode conhecer o tipo — `T` vem de quem o renderiza |
| **`Controller` inline** no JSX do próprio form | nenhum dos dois: `control` já está em escopo | — |

**O que decide é de onde vem o tipo.** `useFormContext` sem generic devolve `Control<FieldValues>`, e `FieldValues` é `Record<string, any>` — com ele, `FieldPath<T>` aceita qualquer string e `RHF-CTRL-07` deixa de valer na prática. O componente compila, o autocomplete some, e um typo em `name` volta a ser bug de runtime.

```tsx
// ✅ Seção: conhece o formulário, declara o tipo, não recebe prop
function DadosPessoais {
 const { control } = useFormContext<Perfil> // ← o generic é o ponto
 return (
 <>
 <CampoTexto control={control} name="nome" label="Nome" />
 <CampoTexto control={control} name="email" label="E-mail" />
 </>
 )
}

// ✅ Campo reutilizável: T é inferido do control que chega
function CampoTexto<T extends FieldValues>({ control, name }: {
 control: Control<T>
 name: FieldPath<T> // autocompleta com os campos de Perfil no call site acima
}) { /* … */ }
```

**Isso não é prop drilling.** Drilling é atravessar níveis que não usam o valor. Aqui o `control` anda **um nível**, da seção que o obteve do contexto para o campo que ela renderiza. O que o `FormProvider` eliminou foi o caminho `<Form>` → `<Passo>` → `<Grupo>` → `<DadosPessoais>`, que é onde o custo estava.

**E se o campo reutilizável pegasse do contexto?** É possível — `Controller` e `useController` aceitam omitir `control` sob `FormProvider`, e a fonte confirma que a prop é opcional nesse caso. O custo é exatamente o descrito acima: sem o generic, o componente perde a checagem de `name`. Um `control` opcional com fallback (`control ?? contexto`) tem o mesmo problema, porque o tipo do fallback continua sendo `FieldValues`.

**Regra prática:** a prop existe para carregar o **tipo**, não o valor. Onde o tipo é conhecido, use o contexto com generic. Onde não é, passe a prop.

### 4.3 Custo e mitigação

`FormProvider` é Context: quem consome re-renderiza quando o contexto muda. A doc registra dois pontos:

- usar o **DevTools do RHF junto com `FormProvider`** pode causar problema de performance;
- a mitigação é `memo` nos componentes de seção **somada** a leitura de `formState` via `useFormState` no menor componente possível.

Antes de recorrer a `memo`, aplique a ordem de [React Hook Form](react-hook-form.md) § 5.7 — normalmente o problema é `formState` lido alto demais, não falta de memoização.

### 4.4 `ConnectForm` para componentes muito profundos

Padrão da própria documentação (*Advanced Usage*), útil quando um componente aninhado precisa de vários métodos:

```tsx
export const ConnectForm = ({ children }: { children: (m: UseFormReturn) => ReactNode }) =>
 children(useFormContext)

// uso
<ConnectForm>{({ register }) => <input {...register('cep')} />}</ConnectForm>
```

### 4.5 Regras — `RHF-CTX-*`

| ID | Regra |
| --- | --- |
| `RHF-CTX-01` | Dentro de `FormProvider`, `formState` **MUST** vir de `useFormState`, **NEVER** de destructuring de `useFormContext`. Apelido de `RHF-STATE-01`. |
| `RHF-CTX-02` | O retorno de `useFormContext`/`useForm` **NEVER** entra inteiro em array de dependências de `useEffect` — desestruture o método específico. |
| `RHF-CTX-03` | `useFormContext` **MUST** ser chamado com o generic do formulário (`useFormContext<Perfil>`) sempre que o componente conhecer o tipo. Sem ele o retorno é `Control<FieldValues>` e `RHF-CTRL-07` deixa de ter efeito. |
| `RHF-CTX-04` | Componente de campo **reutilizável entre formulários** **MUST** receber `control` por prop, **NEVER** lê-lo do contexto — é a prop que carrega o tipo `T`. Componente de **seção** faz o oposto: lê do contexto com generic. |

> `RHF-CTX-02` vem de um aviso explícito da fonte: o objeto retornado por `useForm` passará a ser memoizado, e depender dele inteiro é frágil. `useEffect( => reset(x), [reset])`, não `[methods]`.

---

## 5. Acessibilidade

A doc oficial dedica a abertura de *Advanced Usage* a isto, e é a parte que código gerado mais omite. O alvo é o leitor de tela anunciar `"Nome, editar, entrada inválida, Este campo é obrigatório"` — o que exige três coisas ligadas entre si.

```tsx
const id = useId
const erro = errors.nome

<label htmlFor={id}>Nome</label>
<input
 id={id}
 {...register('nome', { required: 'Este campo é obrigatório.' })}
 aria-invalid={erro ? true : undefined}
 aria-describedby={erro ? `${id}-erro` : undefined}
/>
{erro && <p id={`${id}-erro`} role="alert">{erro.message}</p>}
```

| Peça | Por quê |
| --- | --- |
| `htmlFor` ↔ `id` | sem isso o campo não tem nome acessível |
| `aria-invalid` | anuncia o estado de erro |
| `aria-describedby` → `id` do parágrafo | liga a **mensagem** ao campo; sem isso o erro é lido solto, ou não é lido |
| `role="alert"` | interrompe o leitor para anunciar o erro assim que ele aparece |

**`role="alert"` só para erro.** Confirmação de sucesso usa `role="status"`, que espera a pausa em vez de interromper. Mesmo critério de [React - Formulários e Actions](react-formularios-e-actions.md) § 3.

**Foco.** `shouldFocusError` (default `true`) leva o foco ao primeiro campo com erro no submit — mas só funciona se o `ref` chegou a um elemento do DOM, e a **ordem é a de registro**, não a visual. Em layout com colunas, isso pode focar um campo que está longe do topo. `setFocus(name)` resolve caso a caso.

### 5.1 Regras — `RHF-A11Y-*`

| ID | Regra |
| --- | --- |
| `RHF-A11Y-01` | Campo com erro **MUST** ter `aria-invalid` e a mensagem ligada por `aria-describedby`. |
| `RHF-A11Y-02` | Mensagem de erro **MUST** usar `role="alert"`; confirmação de sucesso, `role="status"`. |
| `RHF-A11Y-03` | Todo campo **MUST** ter `<label htmlFor>` associado por `id` estável (`useId`), **NEVER** só `placeholder`. |
| `RHF-A11Y-04` | Em formulário com layout multi-coluna, a ordem de registro **MUST** ser conferida contra a ordem visual, ou o foco de erro salta. |

---

## 6. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `useState` por campo, sincronizado com o formulário | remover; o valor já está no RHF |
| `Controller` em `<input>` nativo **sem motivo** | `register` · `RHF-CTRL-08` |
| `register` espalhado em componente que não encaminha `ref` | `Controller` · `RHF-CORE-03` |
| `{...register('x')}` **e** `<Controller name="x">` no mesmo campo | escolher um · `RHF-CORE-04` |
| `onChange` sobrescrito sem espalhar `field` | espalhar antes · `RHF-CTRL-01` |
| `field.onChange(undefined)` para limpar | `null` ou `''` · `RHF-CTRL-02` |
| `setValue` para editar campo sob `Controller` | `field.onChange` · `RHF-CTRL-04` |
| `errors` lido de `useFormContext` | `useFormState({ control })` · `RHF-CTX-01` |
| `useFormContext` sem generic em componente que conhece o form | `useFormContext<Perfil>` · `RHF-CTX-03` |
| Campo reutilizável lendo `control` do contexto | receber por prop; a prop carrega o tipo · `RHF-CTX-04` |
| `register('itens[0].nome')` | dot notation · `RHF-REG-01` |
| `<input type="number">` sem coerção | `valueAsNumber` / `z.coerce.number` · `RHF-REG-03` |
| `setValueAs` tentando exibir valor formatado | é mão dupla: `Controller` com `input`/`output` · `RHF-CTRL-09` |
| Moeda ou taxa guardada como `float` | inteiro na menor unidade · `RHF-CTRL-10` |
| Telefone/CPF guardado como número | string de dígitos · `RHF-CTRL-10` |
| `type="number"` em campo mascarado | `type="text"` + `inputMode` · `RHF-CTRL-11` |
| `%` ou `kg` dentro do `value` do input | fora, como texto adjacente · `RHF-CTRL-12` |
| Máscara truncando só na exibição | truncar no `output` · `RHF-CTRL-13` |
| Máscara decidindo o que é válido | a validação é do schema; a máscara só formata |
| `z.coerce`/`.transform` num campo que já tem `Controller` com `output` | conversão duplicada; deixe só no `output` |
| `disabled` para "mostrar sem editar" | `readOnly` · `RHF-REG-05` |
| `placeholder` no lugar de `<label>` | `label` + `htmlFor` · `RHF-A11Y-03` |
| Mensagem de erro sem `aria-describedby` | ligar por `id` · `RHF-A11Y-01` |
| `name: string` em componente de campo reutilizável | `FieldPath<T>` · `RHF-CTRL-07` |

---

## Relacionados

- [React Hook Form](react-hook-form.md) — entrada, árvores de decisão, contrato de skill
- [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) · [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md)
- [React - Refs e DOM](react-refs-e-dom.md) — `ref` como prop no React 19
- [React - Hooks Utilitários](react-hooks-utilitarios.md) — `useId` e `REACT-UTIL-01`
- [React - Formulários e Actions](react-formularios-e-actions.md) — o mesmo critério de `role="alert"` / `role="status"`
-

## Fontes consultadas

Verificadas em 2026-08-15:

- [register](https://react-hook-form.com/docs/useform/register) — merge no re-registro, nomes reservados e restrições de nome confirmados
- [Controller](https://react-hook-form.com/docs/usecontroller/controller) — `exact` default `true` desde v7.68.0; alerta sobre `onChange(undefined)`
- [useController](https://react-hook-form.com/docs/usecontroller) — recomendação de uma chamada por componente
- [useFormContext](https://react-hook-form.com/docs/useformcontext) — orientação explícita de usar `useFormState` para `formState`
- [Advanced Usage](https://react-hook-form.com/advanced-usage) — acessibilidade, `ConnectForm`, performance de `FormProvider`, e a seção *Transform and Parse* que fundamenta a § 3.4: o padrão `input`/`output` no `Controller` e a justificativa de que `valueAsNumber`/`valueAsDate` deixam `NaN` e `null` sem tratamento
- [TypeScript](https://react-hook-form.com/ts) — `FieldPath`, `Control`, `ControllerRenderProps`
