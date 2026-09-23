---
gerado-por: skills/react/react-hook-form/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-23
---

# ID map `RHF-*`

> An index, not a copy: it says **where** the rule is declared, never what it says.
> Regenerate with `bash skills/react/react-hook-form/scripts/gerar-mapa-de-ids.sh`.

## Citing across docs

Inside a form review, the `RHF-*` ID is enough. **When citing across docs**
— a React review that touches a form, or the other way round — use the canonical one,
or whoever fixes it will not find the text. The tables below come from § 6.2 of the hub.


**Regra de citação:** dentro de uma revisão restrita a formulários, o ID `RHF-*` é suficiente e é o que as tabelas dos satélites usam. **Ao citar entre docs** — um review de React que encosta em formulário, ou vice-versa — use o canônico, senão o revisor não acha o texto.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Erro esperado é estado, não exceção para boundary | `REACT-ASYNC-09` ([React - Suspense e Assincronia](../../../../knowledge-base/react-suspense-e-assincronia.md)) | `RHF-ERR-03`, `REACT-FORM-03`, `REACT-PAT-07` |
| Servidor revalida e autoriza na fronteira | `REACT-RSC-06` ([React - Server Components e Diretivas](../../../../knowledge-base/react-server-components-e-diretivas.md)) | `RHF-CORE-05`, `REACT-FORM-08`, `REACT-PAT-09` |

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


## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `RHF-A11Y-01` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 5. Acessibilidade |
| `RHF-A11Y-02` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 5. Acessibilidade |
| `RHF-A11Y-03` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 5. Acessibilidade |
| `RHF-A11Y-04` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 5. Acessibilidade |
| `RHF-ARRAY-01` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-02` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-03` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-04` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-05` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-ARRAY-06` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 6. `useFieldArray` |
| `RHF-BRIDGE-01` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 8. Pontes com o stack |
| `RHF-BRIDGE-02` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 8. Pontes com o stack |
| `RHF-BRIDGE-03` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 8. Pontes com o stack |
| `RHF-BRIDGE-04` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 8. Pontes com o stack |
| `RHF-BRIDGE-05` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 8. Pontes com o stack |
| `RHF-CORE-01` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CORE-02` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CORE-03` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CORE-04` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CORE-05` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CORE-06` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-CTRL-01` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-02` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-03` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3.5 Regras — `RHF-CTRL-*` |
| `RHF-CTRL-04` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-05` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-06` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-07` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-08` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-09` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-10` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-11` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-12` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTRL-13` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 3. `Controller` e `useController` |
| `RHF-CTX-01` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 4. `FormProvider` e `useFormContext` |
| `RHF-CTX-02` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 4. `FormProvider` e `useFormContext` |
| `RHF-CTX-03` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 4. `FormProvider` e `useFormContext` |
| `RHF-CTX-04` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 4. `FormProvider` e `useFormContext` |
| `RHF-ERR-01` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-02` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-03` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-04` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-05` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-06` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-ERR-07` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 4. Erros |
| `RHF-PERF-01` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-PERF-02` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-PERF-03` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-PERF-04` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-REG-01` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 2. `register` |
| `RHF-REG-02` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 2. `register` |
| `RHF-REG-03` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 2. `register` |
| `RHF-REG-04` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 2. `register` |
| `RHF-REG-05` | [React Hook Form - Registro e Controle](../../../../knowledge-base/react-hook-form-registro-e-controle.md) | 2. `register` |
| `RHF-STATE-01` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-STATE-02` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-03` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-STATE-04` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-STATE-05` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 3. As cinco formas de ler |
| `RHF-STATE-06` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-07` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-08` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-09` | [React Hook Form](../../../../knowledge-base/react-hook-form.md) | 6. Regras normativas |
| `RHF-STATE-10` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-11` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STATE-12` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 4. Escrever, redefinir e alimentar de fora |
| `RHF-STEP-01` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 7. Formulário em várias etapas |
| `RHF-STEP-02` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 7. Formulário em várias etapas |
| `RHF-STEP-03` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 7. Formulário em várias etapas |
| `RHF-STEP-04` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 7. Formulário em várias etapas |
| `RHF-STEP-05` | [React Hook Form - Estado e Performance](../../../../knowledge-base/react-hook-form-estado-e-performance.md) | 7. Formulário em várias etapas |
| `RHF-VAL-01` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 2. Quando validar |
| `RHF-VAL-02` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
| `RHF-VAL-03` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 2. Quando validar |
| `RHF-VAL-04` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
| `RHF-VAL-05` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
| `RHF-VAL-06` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
| `RHF-VAL-07` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
| `RHF-VAL-08` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 5. Validação nativa do browser |
| `RHF-VAL-09` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 5. Validação nativa do browser |
| `RHF-VAL-10` | [React Hook Form - Validação e Resolvers](../../../../knowledge-base/react-hook-form-validacao-e-resolvers.md) | 3. Resolver com Zod |
