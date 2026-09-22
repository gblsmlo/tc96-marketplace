# As cinco tarefas

> Roteador tarefa → nota. Não contém assinaturas, opções nem o comportamento do Proxy de
> `formState`: isso vive nos satélites, e é lá que se lê e se atualiza.
> Nomes curtos: **Registro**, **Validação**, **Estado**; **hub** é [[React Hook Form]].

---

## 1. Montar um formulário novo

Ordem das **decisões** — não é a ordem de escrever o JSX:

1. **Schema primeiro.** O tipo do form deriva do Zod, nunca o contrário → `RHF-VAL-04`.
2. **`defaultValues` cobrindo todo campo** → `RHF-CORE-01`, inclusive os condicionais.
3. **`mode` / `reValidateMode`** — decisão de UX (hub § 5.3, Validação § 2.1). Ficar no default é legítimo **quando é escolha declarada**.
4. **Campo a campo pela árvore § 5.1** — `register` é a via padrão, `Controller` é a exceção (tarefa 2).
5. **Só então o dono do submit** — § 5.4 e tarefa 5.

**Verificar:**

- `formState` desestruturado antes do render que depende dele → `RHF-CORE-02` (a assinatura é criada por **leitura** — hub § 2)
- Nome em dot notation → `RHF-REG-01`; sem nome reservado nem iniciado por número
- `number` e `date` com coerção explícita — o DOM devolve string → `RHF-REG-03`
- `.transform()`/`.default()` exigem os três generics → `RHF-VAL-02`
- Erro com `aria-invalid` e `aria-describedby` → `RHF-A11Y-01`; mensagem com `role="alert"` → `RHF-A11Y-02`
- Nenhum `useState` por campo, e nenhuma leitura só para submeter: `handleSubmit` já entrega o objeto validado (§ 5.2)

**Não faça:** `watch()` na raiz "para acompanhar o form" → `RHF-PERF-01`. É exatamente o custo que a biblioteca elimina.

---

## 2. Integrar um componente de UI controlado

**Carregar:** Registro § 3 (`Controller`, `useController`, o objeto `field`, as armadilhas); § 3.3 se virar componente de campo reutilizável.

**O critério é técnico, não de biblioteca:** o componente encaminha `ref` e emite `onChange` nativo? Verifique **o componente**, não o pacote. `<Input>` do shadcn é um `<input>` com classes — `register` basta. `Select`, `Checkbox`, `RadioGroup`, `Switch` ou date picker sobre Radix expõem `value`/`onValueChange` e não encaminham ref — `Controller`.

**Verificar:**

- `Controller` só onde `register` não serve → `RHF-CORE-03`; e sem registro duplo → `RHF-CORE-04`
- `field` espalhado **antes** de sobrescrever `onChange`/`value` → `RHF-CTRL-01`
- `field.onChange` nunca recebe `undefined` → `RHF-CORE-06`; escapa no adaptador de "limpar seleção"
- Inline e pontual → `<Controller>`; reutilizável → `useController` (§ 5.1)
- Campo aninhado pega **métodos** de `useFormContext`, mas **estado** de `useFormState` → `RHF-STATE-01`
- `exact` tem default diferente entre `useController` e `useWatch`/`useFormState` — confira na nota de verificação do hub, não de memória

---

## 3. Validar com Zod e mapear erros para os campos

**Carregar:** Validação § 3 (resolver) e § 4 (erros); antes, as árvores § 5.3 e § 5.5 do hub.

Schema é fonte única, do cliente ao servidor — [[React Hook Form e Zod separam captura e validação]], [[Zod como schema de runtime]].

**Verificar:**

- Regra **entre** campos vive em `.refine()`/`.superRefine()`, não em `validate` por campo
- `resolver` e `validate` do `useForm` não coexistem → `RHF-VAL-01`
- Regra com I/O é `validate` assíncrono, com `deps` se depender de outro campo (Validação § 3.3)
- Erro de campo do servidor entra por `setError`; erro global em `root.serverError` → `RHF-ERR-02` — leia as caveats de Validação § 4.2 antes de supor que ele sobrevive à revalidação
- Erro **esperado** é estado, nunca exceção lançada do `onSubmit` → `REACT-ASYNC-09`; o **inesperado** sobe ao Error Boundary da feature → `REACT-PAT-06`
- Validação de cliente é UX, não garantia: o servidor revalida e autoriza → `REACT-RSC-06`

Os dois últimos são os **canônicos** (hub § 6.2). `RHF-ERR-03` e `RHF-CORE-05` são apelidos e não aparecem em revisão que cruze docs.

---

## 4. Campos condicionais e listas dinâmicas

**Carregar:** Estado; antes, a árvore § 5.2 do hub para escolher **como** ler o valor que decide a condição.

**Condicional.** O valor que governa a condição é lido com `useWatch` no menor componente que precisa dele, nunca com `watch()` na raiz → `RHF-PERF-01`. Para campo que desmonta, `shouldUnregister` é decisão consciente (o valor some ou fica?), e `defaultValues` continua tendo que cobri-lo → `RHF-CORE-01`.

**Lista.** `useFieldArray` com `key={field.id}` → `RHF-ARRAY-01`. Índice como `key` é o antipadrão de [[React - Patterns]] § 8 **com um agravante local**: os nomes já são indexados (`itens.0.nome`, `RHF-REG-01`), então índice na `key` e índice no nome se confundem no bug. Se a lista for longa, o custo é volume de nós (§ 5.6, passo 5): virtualize ou pagine.

**Wizard.** A etapa pertence à URL → `REACT-PAT-10` e [[tanstack-router]]. O form guarda valores; a rota guarda **onde o usuário está**.

---

## 5. Submeter

Dono único → `RHF-BRIDGE-01`. `<form action={...} onSubmit={handleSubmit(...)}>` é o bug em que a ordem de execução deixa de ser sua.

**a) Mutation do TanStack Query** (há cache a invalidar) — hub § 8.2:

- `handleSubmit` valida e chama `mutateAsync` **dentro dele**; `mutateAsync` lança, então `try/catch` é obrigatório (`TSQ-MUT-04`) e a falha esperada volta por `setError`
- A mutation é dona do envio, do cache e do **otimismo** → `RHF-BRIDGE-04`, que é canônico e **não** é apelido de `REACT-FORM-07`: aquele trata de `useOptimistic` não ser fonte de verdade, e não substitui este (hub § 6.2). Otimismo no formulário, nunca
- O que a escrita tornou velho é decisão da mutation → [[tanstack-query]]
- Preencher com dado remoto não é `defaultValues` estático: é `values` + `resetOptions.keepDirtyValues` → `RHF-BRIDGE-03` (apelido de `REACT-PAT-03`)

**b) Server Function / Server Action** — hub § 8.1:

- O dispatch sai de dentro do `handleSubmit`; sem `<form action>`, sem ponte por `useEffect` → `RHF-BRIDGE-02`
- `state` e `isPending` do `useActionState` são lidos direto no JSX; copiá-los para o form cria um segundo estado que diverge
- Só o erro **de campo** volta ao form, por `setError` → `RHF-ERR-02`
- A função de servidor é endpoint público: autentica, valida e autoriza → `REACT-RSC-06`, [[Server Actions são fronteiras de confiança]]

**Depois do submit:** `reset` em `useEffect` observando `isSubmitSuccessful`, não dentro do `onSubmit` → `RHF-STATE-02`.

---

## Relacionados

- [[React Hook Form]] — hub: modelo mental, árvores § 5, regras § 6
- [[React Hook Form - Registro e Controle]] · [[React Hook Form - Validação e Resolvers]] · [[React Hook Form - Estado e Performance]] — um por vez
- `dono-da-submissao.md` — quem desabilita o botão
- `diagnostico.md` — sintoma → causa → satélite
