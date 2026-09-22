---
Link: https://react-hook-form.com/get-started
tags:
 - react
 - forms
 - react-hook-form
 - frontend
 - reference
 - agent-context
source: "Documentação oficial do React Hook Form — react-hook-form.com"
verificado-em: 2026-08-15
---

# React Hook Form — referência conduzida

> **O que esta nota é.** O ponto de entrada único para React Hook Form neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar formulários. Não é um resumo linear do Get Started — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [react-hook-form.com](https://react-hook-form.com/docs) vence, e esta nota deve ser corrigida.

Superfície verificada diretamente em react-hook-form.com em **2026-08-15**, na linha **v7** (referências de versão vão até v7.85.0).
Ver [Fontes consultadas](#fontes-consultadas).

Esta doc pressupõe [React.js](react-js.md). RHF não substitui nenhuma regra do React — ele adiciona uma camada. `REACT-PURE-*` e `REACT-HOOK-*` continuam valendo dentro de todo componente de formulário.

---

## 1. Como usar esta doc

### Para um humano

Leia a seção 2 uma vez — ela é curta e explica por que a API tem o formato que tem. Depois use a seção 5 quando estiver na dúvida entre duas APIs, e a seção 4 como índice. Os satélites são leitura sob demanda.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver formulário em React |
| 2 | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) | Ao **conectar campos** — `register`, componente de biblioteca, componente reutilizável, campo formatado (moeda, máscara) |
| 3 | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) | Ao definir **o que é válido** ou tratar erro vindo do servidor |
| 4 | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) | Ao **ler** estado do form, reagir a valores, listas dinâmicas, ou investigar re-render |
| 5 | [React - Formulários e Actions](react-formularios-e-actions.md) | Quando a decisão da § 5.4 apontar para Actions nativas |

**Regra de economia de contexto:** carregue um satélite por vez, guiado pela § 5.

> **A exceção que a regra precisa admitir:** um formulário de CRUD realista — componente de UI controlado + validação por schema + lista dinâmica — dispara as três condições ao mesmo tempo. Nesse caso carregue os três; a regra existe para impedir carga preventiva "por precaução", não para impedir cobertura do que a tarefa realmente toca. O sinal de que você está violando o espírito da regra é abrir um satélite **antes** de saber que precisa dele.

### Convenções e vocabulário

**Todos os exemplos são TypeScript**, e assumem `react-hook-form` v7 com `@hookform/resolvers` + (a forma `z.email` de topo é de Zod 4; em Zod 3 é `z.string.email`).

Três regras dependem de tipos e não têm sentido em JS: `RHF-VAL-02`, `RHF-VAL-04` e `RHF-CTRL-07`. Fora essas, em JS basta ignorar as anotações.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **campo não controlado** (uncontrolled) | o valor mora no nó do DOM; o React não o re-renderiza a cada tecla. É o modo padrão do RHF |
| **campo controlado** | o valor mora no estado de alguém e volta como prop a cada render. É o que `Controller` passa a gerenciar |
| **registrar** | apresentar um campo ao formulário, dando-lhe nome e regras — via `register`, `Controller` ou `useController` |
| **assinatura** (subscription) | o vínculo que faz um componente re-renderizar quando algo do formulário muda. No RHF ela é **criada por leitura**, não declarada |
| **`formState`** | o objeto de estado do formulário (erros, dirty, submitting…), entregue atrás de um Proxy |
| **resolver** | adaptador que delega a validação a um schema externo e devolve `{ values, errors }` |
| **dirty** | difere de `defaultValues`. Não é o mesmo que *touched*, que é "o usuário passou por aqui" |
| **erro de raiz** (root error) | erro que não pertence a nenhum campo, guardado em `errors.root.*` |
| **coerção** | converter o que o DOM devolve (sempre string) no tipo que o domínio espera |
| **`control`** | o objeto devolvido por `useForm` que carrega a conexão com o formulário. É o que se passa a `useController`, `useWatch`, `useFormState` e `Controller` para que um componente **fora** do `useForm` se conecte a ele. Sob `FormProvider`, é opcional |
| **`rules`** | as regras de validação declaradas no `register`/`Controller` (`required`, `min`, `validate`, `deps`…). **Não rodam quando há `resolver`** — `RHF-VAL-06` |
| **`deps`** | regra do `register` que manda revalidar outros campos junto deste |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro de RHF que um agente comete viola uma delas.

**1. O formulário não vive no estado do React.** RHF guarda os valores fora do ciclo de render — no próprio nó do DOM, via `ref`, e num store interno. Digitar não re-renderiza nada. É a inversão que explica o resto da API: se você reintroduz `useState` por campo, ou espalha `watch` pela raiz, paga de volta exatamente o custo que a biblioteca eliminou.

**2. `register` é a via padrão; `Controller` é a ponte.** O critério não é preferência estética: é se o componente **encaminha `ref` e emite eventos nativos**. Um `<input>` do DOM encaminha — `register` basta. Um `<Select>` de design system que só aceita `value`/`onChange` não encaminha — precisa de `Controller`, que reintroduz o render controlado *daquele campo apenas*.

**3. `formState` é um Proxy de assinatura, não um objeto.** Você só recebe atualização das propriedades que **leu incondicionalmente durante o render**. Uma propriedade acessada atrás de `&&`, `||`, ternário ou `if` pode nunca ser lida — o Proxy não a assina, e ela simplesmente não atualiza. Isso não é bug: é o mecanismo que evita calcular `isValid` para quem não pediu.

**4. `defaultValues` é o contrato do formulário.** `isDirty` e `dirtyFields` comparam contra ele. `reset` volta para ele. Componente controlado depende dele para não começar não controlado. Campo ausente do `defaultValues` compara contra `undefined`, e o React acusa input mudando de não controlado para controlado no primeiro caractere.

**5. Validação no cliente é fronteira de UX, não garantia.** O resolver converte entrada não confiável em dado tipado **no browser** — o que melhora a experiência e não protege nada. O servidor revalida sempre, e o que ele recusar volta pela via de erro do formulário, não por exceção. Ver.

> **A consequência que mais surpreende.** Como o valor não está no estado do React, ler um campo **é uma escolha com custo**, não um acesso gratuito. Por isso existem cinco formas de ler (`getValues`, `watch`, `useWatch`, `useFormState`, `subscribe`) em vez de uma: cada uma paga um preço diferente de render. A árvore da § 5.2 é a parte desta doc que mais evita código ruim.

---

## 3. Fronteiras de pacote

| Pacote | Contém | Nota |
| --- | --- | --- |
| `react-hook-form` | `useForm`, `useController`/`Controller`, `useFormContext`/`FormProvider`, `useWatch`, `useFormState`, `useFieldArray`, `<Form>`, `createFormControl` | o core; nenhuma dependência de validador |
| `@hookform/resolvers` | `zodResolver` e adaptadores para ~19 bibliotecas (Yup, Joi, Valibot, ArkType, Vest, Ajv, TypeBox, standard-schema…) | instalar junto com o validador escolhido |
| `@hookform/error-message` | `<ErrorMessage>` | opcional; conveniência de exibição |
| `@hookform/lenses` | `useLens` | **pacote separado.** Aparece no índice da doc oficial, o que induz a tratá-lo como core — não é |
| `@hookform/devtools` | painel de inspeção | só em desenvolvimento. A doc alerta que usá-lo junto com `FormProvider` pode causar problema de performance |

```bash
npm install react-hook-form @hookform/resolvers zod
```

---

## 4. Mapa da API

Superfície verificada. A coluna **Satélite** diz o que carregar.

**Deliberadamente fora deste mapa:** integrações de terceiros, adaptadores de validadores que não sejam Zod, e a documentação de React Native. Se a tarefa exigir uma delas, consulte a fonte: a ausência aqui significa "não verificado nesta doc", não "não existe".

### Hooks

| Hook | Para que serve | Satélite |
| --- | --- | --- |
| `useForm` | Cria e possui o formulário; devolve todos os métodos | esta nota § 4.3 |
| `useController` | Conecta um componente controlado; é o motor de `Controller` | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `useFormContext` | Lê os métodos do form em componente aninhado | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `useWatch` | Assina valores **isolando o re-render** no componente que chama | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `useFormState` | Assina `formState` isolando o re-render | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `useFieldArray` | Listas de campos: append, remove, move, replace | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |

### Componentes

| Componente | Para que serve | Satélite |
| --- | --- | --- |
| `<Controller>` | Envolve componente controlado, inline no JSX | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `<FormProvider>` | Distribui o contexto do formulário para a subárvore | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `<Form>` | Submissão gerenciada com envio HTTP embutido — **BETA** desde v7.44.0 | esta nota § 5.4 |

### 4.3 Métodos de `useForm`

Agrupados por intenção, porque é assim que a escolha acontece.

| Intenção | Métodos |
| --- | --- |
| **Conectar campos** | `register`, `unregister`, `control` |
| **Submeter** | `handleSubmit` |
| **Ler valores** | `getValues`, `watch` (+ os hooks `useWatch`, `useFormState`) — as **cinco formas de ler** da § 2 são estas mais `subscribe` |
| **Ler estado de um campo** | `getFieldState` — exige assinatura de `formState`; ver `RHF-STATE-08` |
| **Observar sem render** | `subscribe` |
| **Escrever** | `setValue`, `setValues`, `reset`, `resetField`, `resetDefaultValues` |
| **Erros e validação manual** | `setError`, `clearErrors`, `trigger` |
| **Foco** | `setFocus` |

> **Correção de uma verificação anterior.** Uma versão desta nota marcou `setValues`, `resetDefaultValues` e `createFormControl` como "não verificados" por 404. O 404 era de **URL**: a página é `/docs/createFormControl`, em camelCase. As três existem e estão verificadas:
>
> | API | Página | Since | O que faz |
> | --- | --- | --- | --- |
> | `setValues` | `/docs/useform/setvalues` | v7.74.0 | escreve vários campos **em um único re-render**, em vez de N chamadas de `setValue`. Aceita `shouldValidate`/`shouldDirty`/`shouldTouch`/`delayError` |
> | `resetDefaultValues` | `/docs/useform/resetdefaultvalues` | v7.77.0 | troca a **baseline** de `defaultValues` e recomputa `isDirty`/`dirtyFields` contra ela, **sem** alterar os valores atuais do formulário |
> | `createFormControl` | `/docs/createFormControl` | v7.55.0 | cria a assinatura do formulário **fora de um componente**; devolve `formControl` para o `useForm`, `control` para os hooks, e `subscribe` para observar sem re-render. É a alternativa ao Context |
>
> `resetDefaultValues` é o que faltava para o caso "carreguei dado remoto e quero que o `isDirty` passe a comparar contra ele" — antes disso, `reset` com `keepDirtyValues` era a única saída (`RHF-BRIDGE-03`).

### 4.4 Opções de `useForm`

| Opção | Default | O que faz | Satélite |
| --- | --- | --- | --- |
| `mode` | `'onSubmit'` | Quando validar **antes** do primeiro submit | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `reValidateMode` | `'onChange'` | Quando revalidar **depois** do primeiro submit | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `defaultValues` | — | Valores iniciais; aceita função `async` | esta nota § 2 |
| `values` | — | Valores **reativos** vindos de fora (servidor, store). v7.41.0 | § 8.2 e `RHF-BRIDGE-03` |
| `errors` | — | Erros reativos vindos do servidor. v7.49.0 | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `resetOptions` | — | O que preservar quando `values` muda (`keepDirtyValues`, `keepErrors`) | § 8 |
| `resolver` | — | Delega validação a um schema externo | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `context` | — | Objeto mutável repassado ao resolver | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `validate` | — | Validação a nível de formulário. v7.72.0 — **exclusiva com `resolver`** | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `criteriaMode` | `'firstError'` | Um erro por campo ou todos | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `delayError` | — | Atrasa a **exibição** do erro em ms | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `shouldFocusError` | `true` | Foca o primeiro campo com erro no submit | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `shouldUnregister` | `false` | Se campo desmontado perde o valor | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `shouldUseNativeValidation` | `false` | Usa a Constraint Validation API do browser | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `progressive` | `false` | Emite `required`/`min`/`pattern` como atributos HTML. v7.44.0 | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `disabled` | `false` | Desabilita o formulário inteiro. v7.48.0 | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `formControl` | — | Recebe um control criado fora do React | § 4.3 (ressalva) |

---

## 5. Árvores de decisão

O objetivo é mapear **sintoma → API correta**, porque é nessa escolha que código de formulário gerado costuma errar.

### 5.1 Como conecto este campo?

```
O campo é um elemento nativo (input, select, textarea)?
├── SIM
│ └── O que o usuário VÊ é o que o formulário GUARDA?
│ ├── SIM, só muda o TIPO ("42" → 42, "2026-08-15" → Date)
│ │ → register + coerção explícita: valueAsNumber, valueAsDate,
│ │ setValueAs, ou z.coerce.* no schema.
│ │ O DOM SEMPRE devolve string. RHF-REG-03
│ └── NÃO — exibe formatado e guarda outra coisa
│ (moeda, percentual, telefone, máscara)
│ → mão dupla. setValueAs NÃO resolve: ele só transforma
│ a entrada. Use Controller com input/output.
│ → [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) § 3.4
│ RHF-CTRL-09
└── NÃO — é componente de biblioteca ou de design system
 └── Ele encaminha `ref` e emite onChange com o evento nativo?
 ├── SIM → register funciona; espalhe o retorno nele
 └── NÃO — só aceita value/onChange
 │ (caso comum: Select, DatePicker, Combobox, editor rico,
 │ wrappers que só expõem value/onChange)
 ├── Uso pontual, escrito inline no JSX do form → <Controller>
 └── Vai virar componente reutilizável → useController

Em nenhum caso os dois juntos: campo sob Controller não é registrado
de novo com register. RHF-CORE-04
```

> **Não decida por nome de biblioteca.** A pergunta do ramo é sobre o **componente**, não sobre o pacote de onde ele vem. Bibliotecas grandes são mistas: vários primitivos do Radix encaminham `ref` e renderizam um input nativo oculto justamente para funcionar com formulário, e componentes de wrapper na mesma biblioteca não encaminham. O teste é empírico e leva segundos — espalhe o `register` e veja se o valor chega no submit. Se chegar, `Controller` ali é render controlado que você pagou sem precisar (`RHF-CTRL-08`).

### 5.2 Preciso ler um valor. Como?

A pergunta certa não é "como leio", é **para que**. É aqui que a maior parte do custo de render é criada ou evitada.

```
Para que você vai usar o valor?
├── Só no submit
│ → NÃO LEIA. handleSubmit já entrega o objeto inteiro, validado.
│ Ler para submeter é o desperdício mais comum.
│
├── Numa checagem pontual dentro de um handler, sem afetar a UI
│ → getValues — não assina nada, não re-renderiza
│
├── Para RENDERIZAR algo que depende do valor
│ ├── Num componente pequeno e isolado (o caso normal)
│ │ → useWatch({ control, name }) — o re-render fica no componente
│ └── Precisa do form inteiro no componente raiz E a raiz é pequena
│ → watch. Em formulário grande isso é proibido, não é
│ um trade-off: desça a leitura. RHF-PERF-01
│
├── Para disparar efeito colateral sem UI (autosave, analytics, log)
│ → subscribe({ name, formState, callback })
│ watch(callback) faz isso e está DEPRECADO RHF-PERF-02
│
└── Para ler ESTADO do formulário (errors, isDirty, isSubmitting…)
 ├── No próprio componente que chamou useForm
 │ → destructuring de formState, ANTES do render RHF-CORE-02
 └── Em componente aninhado, ou dentro de FormProvider
 → useFormState({ control }) RHF-STATE-01
```

> **Por que não `useFormContext` para ler `formState`.** A doc oficial de `useFormContext` é explícita: use `useFormState`. O Proxy de assinatura só registra o que foi lido **durante o render daquele componente**; ao pegar `formState` do contexto você recebe o objeto, mas a leitura acontece no componente errado. O resultado é estado que não atualiza — e o sintoma engana, porque o valor *inicial* está certo.

### 5.3 Onde valido?

```
A regra é expressável num schema?
├── SIM → resolver (zodResolver). Fonte única, reutilizável no servidor.
│ └── A regra cruza campos (senha × confirmação, data início × fim)?
│ →.refine /.superRefine no schema, não validate por campo
└── NÃO
 ├── Regra trivial de um campo (required, min) e o projeto não tem schema
 │ → rules do register
 ├── Regra que exige I/O (e-mail já existe, cupom válido)
 │ ├── HÁ resolver no projeto? Então as rules do register NÃO
 │ │ rodam — nem validate, nem deps. RHF-VAL-06
 │ │ →.refine assíncrono no schema, OU só no submit
 │ │ via setError. Prefira o submit se não for
 │ │ implementar debounce e cancelamento. RHF-VAL-10
 │ └── NÃO há resolver → validate assíncrono no register
 │ Depende de outro campo? → deps, para revalidar junto
 └── Regra do formulário inteiro, sem resolver no projeto
 → validate no useForm (v7.72.0)
 NUNCA junto com resolver — são exclusivos. RHF-VAL-01

Qualquer que seja a resposta: o servidor revalida. RHF-CORE-05
```

### 5.4 Quem é dono da submissão?

Esta é a fronteira com [React - Formulários e Actions](react-formularios-e-actions.md). Errar aqui produz formulários com dois donos, em que a ordem de execução deixa de ser sua.

```
Você precisa de validação por campo, erro por campo, array dinâmico
de campos, ou formulário em várias etapas?
├── NÃO → as Actions nativas do React 19 bastam.
│ useActionState + <form action>. Menos dependência, menos código.
│ → [React - Formulários e Actions](react-formularios-e-actions.md). Pare aqui.
└── SIM → React Hook Form é o dono da CAPTURA.
 └── Onde a mutação acontece?
 ├── Server Function / Server Action (Next.js, TanStack Start)
 │ → handleSubmit valida e, DENTRO dele, você chama a action.
 │ Sem <form action>. Sem ponte via useEffect. RHF-BRIDGE-02
 ├── Mutation do TanStack Query (há cache a invalidar)
 │ → handleSubmit chama mutateAsync.
 │ A mutation é dona do otimismo e da invalidação. RHF-BRIDGE-04
 └── Chamada isolada, sem cache e sem RSC
 → handleSubmit chama a função e trata o retorno

NUNCA os dois donos ao mesmo tempo:
 <form action={acaoServidor} onSubmit={handleSubmit(...)}> ❌
Escolha um. RHF-BRIDGE-01
```

> **E o `<Form>` do próprio RHF?** Ele existe, envia a requisição HTTP sozinho e suporta progressive enhancement — mas está marcado como **BETA** desde a v7.44.0. Enquanto isso valer, ele não é o padrão desta doc: use `<form onSubmit={handleSubmit(...)}>`. A exceção legítima é progressive enhancement real (o formulário precisa funcionar antes da hidratação), e aí o custo do beta é uma decisão consciente, registrada no código.

### 5.5 Onde mora o erro?

```
O erro pertence a um campo específico?
├── SIM
│ ├── Veio da validação de cliente
│ │ → o resolver ou as rules já preenchem errors[campo]. Nada a fazer.
│ └── Veio do servidor (409 e-mail em uso, 422 campo inválido)
│ → setError('email', { type: 'server', message }) RHF-ERR-02
│ ATENÇÃO: erro posto num campo que tem validação é apagado
│ na próxima rodada. Se precisa sobreviver → root. RHF-ERR-04
└── NÃO — é do formulário todo
 ├── Esperado (credencial inválida, saldo insuficiente, indisponível)
 │ → setError('root.serverError', { type: String(status), message })
 └── Inesperado (bug, contrato quebrado, exceção não prevista)
 → deixe subir para o Error Boundary. Não capture para exibir.
 →

Em nenhum caso o erro esperado é lançado de dentro do onSubmit:
handleSubmit não engole exceções, e isSubmitSuccessful fica errado.
RHF-ERR-03
```

### 5.6 O formulário tem várias etapas. Um `useForm` ou vários?

A pergunta parece de organização e é de arquitetura: ela decide o schema, o botão "Avançar" e o que acontece ao voltar.

```
As etapas têm regra CRUZADA que precisa avisar antes da última?
(ex.: "cliente PJ exige nota fiscal", com o tipo na etapa 1
 e a nota na etapa 3)
├── NÃO — o caso comum
│ → UM FORMULÁRIO POR ETAPA, com acumulador no wizard.
│ Cada etapa: schema próprio, isValid próprio, handleSubmit
│ como "Avançar". RHF-STEP-01
│ Voltar preenchido = values alimentado pelo acumulador.
│ RHF-STEP-03
└── SIM
 → um useForm só, com trigger(['campos','da','etapa']).
 Custo: isValid é global e não serve para o botão, e a
 fonte NÃO diz se errors fica restrito à etapa.
 Filtre por campo. RHF-STEP-05

Nos dois casos, antes de enviar: safeParse do objeto acumulado
contra o schema COMPLETO. As etapas validaram fragmentos.
 RHF-STEP-04
```

> **Por que a recomendação inverte o instinto.** Um formulário por etapa parece "mais estado para coordenar". É o contrário: o acumulador é um `useState` comum, e em troca somem quatro problemas de uma vez — `isValid` volta a ser útil, erros de etapas futuras não vazam, voltar sem perder dados deixa de depender de o RHF lembrar campo desmontado, e `shouldUnregister` deixa de importar. Detalhe e código em [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) § 7.

### 5.7 O formulário está lento ou re-renderizando demais

Ordem do mais barato ao mais caro. Ela é normativa e está detalhada na seção "Ordem de investigação de re-render" de [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md).

```
0. MEDIU? Profiler do React DevTools. Sem medida, pare aqui.
 (o mesmo REACT-PERF-01 de [React.js](react-js.md) vale aqui)

1. Existe useState espelhando um campo?
 → remova. O valor já está no formulário.

2. Existe watch sem argumento, ou watch em componente grande?
 → troque por useWatch no menor componente que precisa do valor
 RHF-PERF-01

3. formState está sendo lido no topo e passado por prop?
 → cada consumidor assina o que precisa com useFormState RHF-STATE-01

4. Há Controller onde register bastaria?
 → Controller reintroduz render controlado. Só use quando o
 componente não encaminha ref. RHF-CORE-03

5. É lista longa com useFieldArray?
 → o custo é volume de nós, não cálculo. Virtualize ou pagine;
 memoizar a linha não resolve sozinho.

6. Só então: memo na linha/campo, com props estáveis.
```

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `RHF-CORE-01` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

### `RHF-CORE-*` — o núcleo

| ID | Regra |
| --- | --- |
| `RHF-CORE-01` | `defaultValues` **MUST** cobrir todo campo do formulário. `isDirty`, `dirtyFields`, `reset` e componentes controlados dependem dele; campo ausente compara contra `undefined`. |
| `RHF-CORE-02` | Toda propriedade de `formState` de que o render depende **MUST** ser lida incondicionalmente durante o render. O Proxy assina o que foi **lido**: acesso atrás de `&&`/`||`/ternário ou dentro de `if` não assina, e aquela propriedade nunca atualiza. Desestruturar no topo é a forma mais simples de garantir isso — mas o defeito é o acesso condicional, não o fato de guardar o objeto. |
| `RHF-CORE-03` | Componente que não encaminha `ref` **MUST** ser conectado por `Controller`/`useController`, nunca por `register` espalhado. |
| `RHF-CORE-04` | Campo sob `Controller`/`useController` **NEVER** é registrado de novo com `register`. Registro duplo. |
| `RHF-CORE-05` | Validação de cliente **NEVER** é garantia. Toda mutação **MUST** revalidar e autorizar no servidor. Apelido de `REACT-RSC-06`. |
| `RHF-CORE-06` | `field.onChange` **NEVER** recebe `undefined`. Use `null` ou `''` — `undefined` faz o input voltar a ser não controlado. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo.

| ID | Regra | Satélite |
| --- | --- | --- |
| `RHF-REG-01` | Nome de campo **MUST** usar dot notation (`itens.0.nome`), nunca colchetes. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-REG-03` | Valor de `<input type="number">` ou `date` **MUST** ter coerção explícita — o DOM devolve string. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-CTRL-01` | Ao sobrescrever `onChange`/`value` num `Controller`, `field` **MUST** ser espalhado antes — senão `onBlur`, `name` e `ref` se perdem. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-CTRL-09` | Transformação de mão dupla (exibido ≠ guardado: moeda, máscara) **MUST** usar `Controller` com `input`/`output`; `setValueAs` só transforma a entrada. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-A11Y-01` | Campo com erro **MUST** ter `aria-invalid` e a mensagem ligada por `aria-describedby`. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-A11Y-02` | Mensagem de erro **MUST** usar `role="alert"`; confirmação de sucesso, `role="status"`. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-A11Y-03` | Todo campo **MUST** ter `<label htmlFor>` com `id` estável; `placeholder` **NEVER** substitui rótulo. | [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) |
| `RHF-VAL-06` | Com `resolver` ativo, `rules` do `register` — `validate` e `deps` inclusive — **NEVER** rodam. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-ERR-04` | Erro de servidor que precisa sobreviver à revalidação do campo **MUST** ir para `root.*`. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-VAL-01` | `resolver` e `validate` de `useForm` **NEVER** coexistem — são mutuamente exclusivos. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-VAL-02` | Schema com `.transform`/`.default` **MUST** declarar os três generics: `useForm<z.input<S>, unknown, z.output<S>>`. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-VAL-04` | O tipo do formulário **NEVER** é escrito à mão em paralelo ao schema — deriva dele. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-ERR-02` | Erro vindo do servidor **MUST** entrar por `setError`: de campo no campo, global em `root.serverError`. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-ERR-03` | Erro esperado **NEVER** é lançado de dentro do `onSubmit`. Apelido de `REACT-ASYNC-09`. | [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) |
| `RHF-STATE-01` | Dentro de `FormProvider`, estado de formulário **MUST** vir de `useFormState`, não de destructuring de `useFormContext`. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-STATE-02` | `reset` pós-submissão **MUST** rodar em `useEffect` observando `isSubmitSuccessful` **e** um sinal de sucesso real — ver a armadilha abaixo. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-PERF-01` | `watch` sem argumento **NEVER** em componente grande — re-renderiza a raiz. Use `useWatch`. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-PERF-02` | Reação sem UI **MUST** usar `subscribe`; `watch(callback)` está marcado como deprecado na fonte (sem versão declarada). | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-PERF-03` | O retorno de `watch`/`useWatch` **NEVER** entra em array de dependências de `useEffect` — é otimizado para a fase de render. Para reagir fora do render, `subscribe`. Escrever de volta no formulário a partir daí é o caminho padrão para loop de render. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-ARRAY-01` | `key` de `useFieldArray` **MUST** ser `field.id`, nunca o índice. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-STEP-01` | Wizard **MUST** ter um `useForm` por etapa, com schema próprio — salvo regra cruzada que precise avisar antes da última etapa. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-STEP-04` | Antes do envio, o objeto acumulado **MUST** ser validado contra o schema completo; as etapas validaram fragmentos. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-ARRAY-02` | Entradas de `useFieldArray` **MUST** ser objetos, nunca primitivos. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |
| `RHF-ARRAY-04` | `append` **MUST** receber a entrada completa com todos os defaults; `append({})` deixa campos fora do form state. | [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) |

### A armadilha do reset: três regras corretas, um bug

Estas três, seguidas à risca, apagam o trabalho do usuário:

1. `RHF-ERR-03` — erro esperado **não** é lançado do `onSubmit`; vira `setError`.
2. `isSubmitSuccessful` significa "a submissão terminou **sem lançar**" — não "o servidor aceitou".
3. `RHF-STATE-02` — resetar em `useEffect` observando `isSubmitSuccessful`.

Encadeadas: a API devolve 422, você captura, chama `setError`, não lança → `isSubmitSuccessful` fica `true` → o effect reseta → **os campos e os erros que você acabou de exibir desaparecem juntos.**

```tsx
// ERRADO — reseta também quando o servidor recusou
useEffect( => {
 if (isSubmitSuccessful) reset
}, [isSubmitSuccessful, reset])

// CERTO — o sinal de sucesso é seu, não do RHF
const onSubmit = handleSubmit(async (data) => {
 try {
 await mutateAsync(data)
 setSalvouComSucesso(true)
 } catch (e) {
 setError('root.serverError', { message: mensagemDe(e) })
 }
})

useEffect( => {
 if (salvouComSucesso) { reset; setSalvouComSucesso(false) }
}, [salvouComSucesso, reset])
```

| ID | Regra |
| --- | --- |
| `RHF-STATE-09` | `isSubmitSuccessful` **NEVER** é usado sozinho como condição de `reset` quando o `onSubmit` captura erro de servidor — ele indica ausência de exceção, não aceitação pelo servidor. |

> As regras `RHF-BRIDGE-*` são definidas na § 8.3, junto do contexto que as justifica.

### 6.2 IDs canônicos

Dois princípios já existem no corpus de React com outro ID, porque cada doc precisa se sustentar sozinha.

**Regra de citação:** dentro de uma revisão restrita a formulários, o ID `RHF-*` é suficiente e é o que as tabelas dos satélites usam. **Ao citar entre docs** — um review de React que encosta em formulário, ou vice-versa — use o canônico, senão o revisor não acha o texto.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Erro esperado é estado, não exceção para boundary | `REACT-ASYNC-09` ([React - Suspense e Assincronia](react-suspense-e-assincronia.md)) | `RHF-ERR-03`, `REACT-FORM-03`, `REACT-PAT-07` |
| Servidor revalida e autoriza na fronteira | `REACT-RSC-06` ([React - Server Components e Diretivas](react-server-components-e-diretivas.md)) | `RHF-CORE-05`, `REACT-FORM-08`, `REACT-PAT-09` |

**`RHF-BRIDGE-04` é canônico**, sem equivalente no corpus de React: "otimismo sobre cache remoto pertence à mutation" é uma regra de fronteira entre RHF e TanStack Query. O `REACT-FORM-07` trata de outra coisa — que `useOptimistic` não é fonte de verdade — e não deve ser citado no lugar dele.

Mais dois princípios do React que o RHF **não** redefine — cite o ID do React:

| Princípio | Canônico | Onde o RHF o menciona |
| --- | --- | --- |
| Dado remoto nunca vira snapshot local como fonte de verdade | `REACT-PAT-03` | `RHF-BRIDGE-03` é apelido — `defaultValues` estático é exatamente isso |
| Requisição obsoleta precisa de cancelamento | `REACT-EFFECT-06` | `RHF-VAL-10` é apelido — validação assíncrona tem a mesma race condition |
| Valor derivável nunca vira estado próprio | `REACT-PAT-01` | é o **passo 1** da ordem de investigação de re-render ("existe `useState` espelhando um campo?"), que aparece em três notas sem ID. Cite `REACT-PAT-01` |

E os pares internos do próprio RHF, onde a mesma norma aparece em mais de um lugar:

| Princípio | Canônico | Apelido |
| --- | --- | --- |
| `field.onChange` nunca recebe `undefined` | `RHF-CORE-06` | `RHF-CTRL-02` |
| Sob `FormProvider`, estado vem de `useFormState` | `RHF-STATE-01` | `RHF-CTX-01` |
| `shouldUnregister` global é incompatível com `useFieldArray` | `RHF-ARRAY-03` | `RHF-CTRL-06` |
| Erro esperado não sobe como exceção do `onSubmit` | `RHF-ERR-03` | `RHF-ERR-01` — mesma norma, mesma tabela, dois IDs |
| `reset` pós-submissão exige sinal de sucesso real | `RHF-STATE-02` | `RHF-STATE-09` — o predicado já está em `-02` |
| O tipo do formulário deriva do schema | `RHF-VAL-04` | `RHF-STEP-02` |
| O componente encaminha `ref`? decide `register` × `Controller` | `RHF-CORE-03` | `RHF-CTRL-08` é a outra metade do mesmo predicado |

### Famílias completas nos satélites

`RHF-REG-*` · `RHF-CTRL-*` · `RHF-CTX-*` · `RHF-A11Y-*` — [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md)
`RHF-VAL-*` · `RHF-ERR-*` — [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md)
`RHF-STATE-*` · `RHF-PERF-*` · `RHF-ARRAY-*` · `RHF-STEP-*` — [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md)
`RHF-BRIDGE-*` — esta nota, § 8.3

Os apelidos internos do próprio RHF estão na tabela da § 6.2.

**Duas regras moram fora do satélite que a família sugere**, porque o contexto que as justifica está aqui: `RHF-STATE-09` (§ 6.1, a armadilha do reset) e `RHF-BRIDGE-05` (§ 8).

---

## 7. Contrato de skill

Como uma skill de formulários deve consumir esta doc.

### O que carregar

```
SEMPRE: Docs/React Hook Form.md § 2 (modelo mental)
 § 5 (árvores de decisão)
 § 6 + § 6.1 (regras)
 § 8.3 (regras de ponte) ← não omita
 Docs/React.js.md § 6 (REACT-PURE-*, REACT-HOOK-*)

ANTES de decidir usar RHF:
 § 5.4 — pode ser que Actions nativas bastem
 Docs/React - Formulários e Actions.md, se a árvore apontar para lá

AO CONECTAR CAMPOS, com campo formatado (moeda, máscara),
ou ao rotular/associar erro para leitor de tela:
 Docs/React Hook Form - Registro e Controle.md

AO DEFINIR VALIDAÇÃO ou TRATAR ERRO DE SERVIDOR:
 Docs/React Hook Form - Validação e Resolvers.md

AO LER ESTADO, REAGIR A VALORES, LISTAS, FORMULÁRIO EM ETAPAS,
ou INVESTIGAR RE-RENDER:
 Docs/React Hook Form - Estado e Performance.md

NUNCA: abrir um satélite ANTES de saber que precisa dele
```

**Sobre carregar mais de um satélite.** A regra é de sequência, não de teto. Uma tarefa **estreita** — "por que este botão não habilita?" — toca um satélite e para ali. Uma tarefa **larga** — revisar um formulário inteiro, escrever um CRUD do zero — toca os três, porque conectar campos, validar e ler estado são três coisas que todo formulário faz.

O desperdício que a regra combate é carga preventiva: abrir tudo "por precaução" antes de rodar a § 5. O sinal de violação é abrir um satélite sem conseguir dizer qual ramo da § 5 mandou.

> **Por que § 8.3 entra no SEMPRE.** As regras `RHF-BRIDGE-*` decidem quem é dono da submissão, de onde vem o dado remoto e quem é dono do estado de envio. Elas se aplicam **antes** de qualquer satélite e são citadas por todos eles — `RHF-BRIDGE-03` em particular é a causa-raiz do erro mais comum em formulário de edição (`defaultValues` estático recebendo dado de `useQuery`).

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `RHF-PERF-01` — `watch` sem argumento no componente raiz re-renderiza o formulário inteiro a cada tecla. Use `useWatch` no componente que precisa do valor.
> Ver [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md).

### Invariantes que a skill deve fazer valer

1. **Decidir antes de instalar.** A § 5.4 vem antes de qualquer código. RHF é a resposta certa para formulário complexo, não para todo formulário.
2. **Verificar antes de afirmar.** Se uma API não está na § 4, ela não foi verificada nesta doc. Consulte a fonte e atualize a nota — não invente comportamento.
3. **A fonte vence.** Divergência entre esta nota e react-hook-form.com é bug desta nota.
4. **Regra do React antes de regra do RHF.** Uma violação de `REACT-PURE-*` ou `REACT-HOOK-*` tem precedência: RHF não suspende nenhuma delas.
5. **Um dono por submissão.** `RHF-BRIDGE-01` é a regra que mais economiza depuração.
6. **Não otimizar sem medida.** A ordem da § 5.7 é obrigatória, e começa em "mediu?".

### Ao criar uma nova skill

Derive-a de um satélite, não desta nota inteira: uma skill de acessibilidade de formulário carrega [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) + § 2 + § 6, e nada mais. Registre no início da skill qual satélite é sua fonte, para que a atualização da doc propague.

---

## 8. Pontes com o stack

O corpo desta doc é RHF puro, fiel à fonte. No meu stack ([TanStack Router](tanstack-router.md), [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md), TanStack Start, `Tailwindcss`, `TypeScript`) várias práticas cruas mudam de dono.

| Problema | Prática crua | O que usar no stack |
| --- | --- | --- |
| Preencher o form com dado remoto | `defaultValues` estático após fetch | `values` + `resetOptions: { keepDirtyValues: true }` · `RHF-BRIDGE-03` |
| Enviar a mutação | `fetch` dentro do `onSubmit` | `mutateAsync` do TanStack Query dentro do `handleSubmit` |
| Invalidar cache após salvar | manual | `invalidateQueries` na mutation — |
| Update otimista | `useOptimistic` | mutation otimista da Query — |
| Estado de wizard entre rotas | store global | search params tipados do Router — [TanStack Router - Search Params](tanstack-router-search-params.md) |
| Validação de fronteira | `if` manual | o mesmo schema Zod no cliente e no servidor — |
| Erro do servidor na UI | `alert`/toast solto | `setError` no campo ou em `root.serverError` · `RHF-ERR-02` |

### Quem desabilita o botão: `isSubmitting` ou `isPending`?

Os dois existem quando `handleSubmit` chama `mutateAsync`, e **têm durações diferentes**:

| Sinal | De quem | Termina quando |
| --- | --- | --- |
| `formState.isSubmitting` | RHF | a Promise do `onSubmit` resolve |
| `isPending` da mutation | TanStack Query | a mutation resolve **e**, se os callbacks retornam a Promise de invalidação (`TSQ-MUT-02`), depois do refetch |

Escolher `isSubmitting` reabilita o botão enquanto a lista ainda mostra dado velho — que é exatamente o clique duplo que `TSQ-MUT-02` existe para evitar.

**Regra:** quando há mutation com invalidação, **o dono é `isPending`**. `isSubmitting` só é suficiente em formulário sem cache a invalidar. Nunca combine os dois num `||` — isso não é redundância defensiva, é dois donos para o mesmo estado. (O padrão é análogo ao de `REACT-FORM-07`, mas aquela regra é sobre otimismo; não a cite para estado de submissão — ver § 6.2.)

| ID | Regra |
| --- | --- |
| `RHF-BRIDGE-05` | Com mutation que invalida cache, o estado de submissão na UI **MUST** vir do `isPending` da mutation, não de `formState.isSubmitting`. |

### 8.1 RHF × Server Actions

O padrão é o da própria documentação oficial (seção *Advanced Usage*), e o ponto não óbvio é a **ausência** de ponte: nada de `useEffect` observando o estado da action para mexer no formulário.

```tsx
'use client'

import { useActionState, useId } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { criarTopico } from './actions' // 'use server'
import { topicoSchema } from './schema'

export function NovoTopico {
 const [state, dispatch, isPending] = useActionState(criarTopico, null)
 const id = useId
 const { register, handleSubmit, setError, formState: { errors } } = useForm({
 resolver: zodResolver(topicoSchema),
 defaultValues: { titulo: '' },
 })

 // O RHF valida; só então a action é despachada. Um dono só. RHF-BRIDGE-01
 // startTransition é obrigatório: o dispatch sai de fora de <form action>. REACT-FORM-04
 return (
 <form onSubmit={handleSubmit((data) => startTransition( => dispatch(data)))}>
 <label htmlFor={`${id}-titulo`}>Título</label>
 <input
 {...register('titulo')}
 id={`${id}-titulo`}
 aria-invalid={errors.titulo ? true : undefined}
 aria-describedby={errors.titulo ? `${id}-titulo-erro` : undefined}
 />
 {errors.titulo && (
 <p id={`${id}-titulo-erro`} role="alert">{errors.titulo.message}</p>
 )}

 {/* state e isPending são lidos direto no JSX — sem useEffect */}
 {state?.erro && <p role="alert">{state.erro}</p>}
 <button disabled={isPending}>{isPending ? 'Salvando…' : 'Salvar'}</button>
 </form>
 )
}
```

Três decisões do exemplo:

- **`handleSubmit` envolve `dispatch`**, não o contrário. A action só roda depois de a validação de cliente passar — é o que dá sentido a ter RHF ali.
- **`state` e `isPending` são consumidos direto no JSX.** Copiá-los para dentro do formulário via `useEffect` cria um segundo estado que diverge; a doc oficial diz explicitamente que essa ponte não é necessária.
- **Erro de campo vindo do servidor é a única coisa que volta para o RHF**, via `setError` — e isso é sincronização legítima com sistema externo, não derivação de estado.

A Server Function continua sendo endpoint público: valida e autoriza sempre. `REACT-RSC-06`, e.

### 8.2 RHF × TanStack Query

```tsx
const { mutateAsync, isPending } = useMutation({
 mutationFn: salvarPerfil,
 onSuccess: => queryClient.invalidateQueries({ queryKey: ['perfil'] }),
})

const onSubmit = handleSubmit(async (data) => {
 try {
 await mutateAsync(data)
 } catch (e) {
 // erro esperado volta para o formulário; não é lançado. RHF-ERR-03
 setError('root.serverError', { message: mensagemDe(e) })
 }
})
```

**Quem é dono do quê:** o formulário é dono da captura e da validação; a mutation é dona do envio, do cache e do otimismo. Empilhar otimismo no formulário e na mutation produz duas fontes de verdade divergindo — `RHF-BRIDGE-04`, e.

**Preencher com dado do servidor** não é `defaultValues`: dado remoto muda sem você saber. Use `values`, que é reativo, com `keepDirtyValues` para não apagar o que o usuário já digitou enquanto o refetch chegava.

```tsx
const { data } = useQuery({ queryKey: ['perfil'], queryFn: buscarPerfil })

useForm({
 defaultValues: { nome: '', email: '' }, // forma do formulário
 values: data, // conteúdo vindo do servidor
 resetOptions: { keepDirtyValues: true }, // não sobrescreve edição em curso
})
```

Ver e.

### 8.3 Regras da ponte

| ID | Regra |
| --- | --- |
| `RHF-BRIDGE-01` | A submissão **MUST** ter dono único: `handleSubmit` **ou** `<form action>`, nunca os dois no mesmo `<form>`. |
| `RHF-BRIDGE-02` | Com Server Action, o dispatch **MUST** ser chamado de dentro do `handleSubmit`; o estado da action **NEVER** é copiado para o formulário via `useEffect`. |
| `RHF-BRIDGE-03` | Dado remoto **NEVER** vira `defaultValues` estático — use `values` com `resetOptions.keepDirtyValues`. |
| `RHF-BRIDGE-04` | Update otimista sobre cache remoto **NEVER** pertence ao formulário — pertence à mutation. **Canônico** — ver § 6.2; `REACT-FORM-07` trata de outra coisa e não o substitui. |

---

## Relacionados

- [React Hook Form - Registro e Controle](react-hook-form-registro-e-controle.md) — conectar campos
- [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) — o que é válido, e o que fazer com erro
- [React Hook Form - Estado e Performance](react-hook-form-estado-e-performance.md) — ler estado, listas, re-render
- [React.js](react-js.md) — entrada de React; `REACT-PURE-*` e `REACT-HOOK-*` valem aqui
- [React - Formulários e Actions](react-formularios-e-actions.md) — a alternativa nativa; ver § 5.4 antes de escolher
- · · ·
- [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) · [Frontend roadmap](../pages/frontend-roadmap.md)

## Fontes consultadas

Verificadas diretamente em **2026-08-15**:

- [Get Started](https://react-hook-form.com/get-started) · [API index](https://react-hook-form.com/docs)
- [useForm](https://react-hook-form.com/docs/useform) · [register](https://react-hook-form.com/docs/useform/register) · [formState](https://react-hook-form.com/docs/useform/formstate) · [handleSubmit](https://react-hook-form.com/docs/useform/handlesubmit)
- [watch](https://react-hook-form.com/docs/useform/watch) · [subscribe](https://react-hook-form.com/docs/useform/subscribe) · [setValue](https://react-hook-form.com/docs/useform/setvalue) · [reset](https://react-hook-form.com/docs/useform/reset) · [setError](https://react-hook-form.com/docs/useform/seterror) · [trigger](https://react-hook-form.com/docs/useform/trigger) · [getFieldState](https://react-hook-form.com/docs/useform/getfieldstate)
- [Controller](https://react-hook-form.com/docs/usecontroller/controller) · [useController](https://react-hook-form.com/docs/usecontroller) · [useFormContext](https://react-hook-form.com/docs/useformcontext) · [useFormState](https://react-hook-form.com/docs/useformstate) · [useWatch](https://react-hook-form.com/docs/usewatch) · [useFieldArray](https://react-hook-form.com/docs/usefieldarray)
- [`<Form>`](https://react-hook-form.com/docs/useform/form) · [useLens](https://react-hook-form.com/docs/uselens)
- [Advanced Usage](https://react-hook-form.com/advanced-usage) · [TypeScript](https://react-hook-form.com/ts) · [FAQs](https://react-hook-form.com/faqs)
- [@hookform/resolvers](https://github.com/react-hook-form/resolvers)

### Notas de verificação

Pontos em que a fonte contraria o que se assume por hábito:

- **`watch(callback)` está marcado como deprecado, mas a fonte não declara em qual versão.** A página traz o aviso *"Deprecated: consider use or migrate to subscribe"* e, ao lado, o badge `Since v7.0.0`. Os dois não dizem a mesma coisa: nesta documentação `Since vX` marca **quando a API entrou** (`update` traz *Since v7.11.0*, `replace` traz *Since v7.15.0*). E a depreciação não poderia ser da v7.0.0, porque o substituto indicado, `subscribe`, só chegou na **v7.55.0** — 55 versões menores depois. Trate como "deprecado, versão desconhecida" e prefira `subscribe` em código novo.
- **`useLens` não é do core.** Vem de `@hookform/lenses`, pacote separado. Aparece no índice de API da doc oficial ao lado dos hooks do core, o que induz ao erro.
- **`validate` a nível de `useForm` existe** desde a v7.72.0 e é **mutuamente exclusiva com `resolver`** — a fonte diz que ela não roda quando há resolver configurado.
- **`isReady` (v7.56.0)** sinaliza que a assinatura de `formState` está pronta. Componente filho que chama `setValue` no mount precisa aguardá-lo; sem isso a chamada se perde silenciosamente.
- **`<Form>` é BETA** desde a v7.44.0. A doc não o apresenta como padrão, e esta nota também não.
- **`Controller`/`useController` têm `exact` com default `true`** (v7.68.0), enquanto `useWatch` e `useFormState` têm `exact` com default `false`. A inconsistência é real e está na fonte.
- **Chamar `register` de novo no mesmo nome mescla opções, não substitui.** Remover uma regra exige passá-la como `false` explícito; `undefined` ou `{}` não removem.
- **`handleSubmit` não engole exceções** do `onSubmit`, e a promise devolvida resolve com o retorno de `onValid` desde a v7.84.0.
- **A doc oficial tem seção de Server Actions** em *Advanced Usage*, e o padrão dela dispensa `useEffect` como ponte.
- **Nomes reservados de campo:** `type`, `root`, `ref`, `types`, `message`, `form` colidem com a estrutura interna de `FieldError`. Nomes também não podem começar com número.
- **`<Activity />` do React é suportado desde a v7.85.0** — o RHF ressincroniza as assinaturas internas no remount.
- **Um 404 que era erro de URL, não ausência de página.** `createFormControl` mora em `/docs/createFormControl` (camelCase); `setValues` e `resetDefaultValues` têm páginas próprias. As três estão verificadas na § 4.3. Já `/docs/useform/resolver` de fato não existe — o contrato do resolver está em `/docs/useform#resolver`, que é a fonte real do que [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) § 3.2 afirma.
- **`rules` do `register` × `resolver`:** a exclusividade está afirmada na página de `useForm` ("Cannot be used with built-in validators") e é a base de `RHF-VAL-06`. A consequência para `validate` e `deps` é dedução direta dessa frase — a fonte não os nomeia um a um. A alternativa recomendada (`.refine` assíncrono com `mode: 'async'` do resolver) tem suporte declarado no README de `@hookform/resolvers`, mas **o encadeamento Zod async refine + zodResolver não foi testado end-to-end nesta verificação**.

**Sobre revisão.** Esta estrutura passou por teste de leitura com quatro agentes sem contexto (escolha entre RHF e Actions, performance e re-render, erros de servidor com Zod, componente de campo reutilizável) e uma auditoria de consistência de IDs e referências, em 2026-08-15. As correções aplicadas incluíram: reversão da orientação de validação assíncrona na § 3.3 do satélite de Validação (estava mandando usar `validate` do `register` num setup com resolver, onde ele não roda), reescrita de `RHF-STATE-04` que contradizia `RHF-STATE-02`, correção de `RHF-PERF-01` citado como permissão para o que proíbe, desambiguação de "número como chave isolada" contra `itens.0.nome`, e correção dos exemplos que violavam `RHF-A11Y-01`/`-03`. Ao editar esta doc, repetir o teste é mais barato que confiar na releitura.
