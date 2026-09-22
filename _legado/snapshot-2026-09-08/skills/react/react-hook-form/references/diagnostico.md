# Diagnóstico — sintoma → causa provável → satélite

> Causa **provável**: a tabela encurta a busca, não fecha o diagnóstico. Confirme no código
> antes de reportar, e cite `arquivo:linha`.

---

## "O formulário re-renderiza demais"

**Passo zero, normativo: mediu?** Profiler antes de trocar qualquer coisa — § 5.6, passo 0,
e `REACT-PERF-01`. A ordem da § 5.6 é obrigatória e **não começa por memoização**.

| Sintoma | Causa provável | Onde | Sonda |
| --- | --- | --- | --- |
| Tela inteira renderiza a cada tecla | `watch()` sem argumento na raiz (`RHF-PERF-01`) | Estado | 1 |
| Render por caractere num campo simples | `useState` espelhando o campo (`REACT-PAT-01`), ou `Controller` onde `register` bastava (`RHF-CORE-03`) | hub § 2 · Registro | 9 |
| Componente que só exibe erro renderiza com o form todo | `formState` lido no topo e passado por prop (`RHF-STATE-01`) | Estado | 4 |
| Autosave, analytics ou log provocando render | `watch(callback)`, deprecado — use `subscribe` (`RHF-PERF-02`) | Estado | 2 |
| Lista lenta mesmo com `memo` na linha | volume de nós, não cálculo (§ 5.6, passo 5) | Estado | — |

---

## "Meu campo não valida / não envia"

| Sintoma | Causa provável | Onde | Sonda |
| --- | --- | --- | --- |
| `errors` não atualiza, mas o valor inicial está certo | `formState` acessado condicionalmente — o Proxy não assinou (`RHF-CORE-02`) | hub § 2 | — |
| Em componente filho, o estado congela após o primeiro render | `formState` de `useFormContext` em vez de `useFormState` (`RHF-STATE-01`) | hub § 5.2 | 4 |
| O campo não chega no submit | não registrado, ou nome com colchetes (`RHF-REG-01`) | Registro | — |
| Campo de UI controlada envia vazio, ou perde `onBlur`/foco | `field` não espalhado (`RHF-CTRL-01`), ou registro duplo (`RHF-CORE-04`) | Registro | 8 |
| Input muda de não controlado para controlado | campo fora do `defaultValues` (`RHF-CORE-01`), ou `onChange` com `undefined` (`RHF-CORE-06`) | hub § 2 | 3 |
| Número chega como string no servidor | falta coerção (`RHF-REG-03`) | Registro | — |
| `validate` do `useForm` nunca roda | há `resolver` — são exclusivos (`RHF-VAL-01`) | Validação | — |
| Submete duas vezes, ou em ordem imprevisível | dois donos: `<form action>` com `onSubmit` (`RHF-BRIDGE-01`) | hub § 5.4 | 5 |
| Erro do servidor aparece e some na tecla seguinte | `setError` sob revalidação — caveats de `RHF-ERR-02` | Validação § 4.2 | — |
| `isSubmitSuccessful` errado, ou o form não reseta | erro esperado lançado no `onSubmit` (`REACT-ASYNC-09`), ou `reset` fora do Effect (`RHF-STATE-02`) | Validação · Estado | 6 |
| `setValue` no mount não faz nada | assinatura ainda não pronta — ver `isReady` (v7.56.0) | nota de verificação do hub | — |

---

## O que **não** é diagnóstico desta skill

| Sintoma | Vá para |
| --- | --- |
| a tela volta ao valor antigo depois de salvar | cache: [[tanstack-query]] |
| o wizard perde a etapa no refresh | a etapa é da URL: [[tanstack-router]] (`REACT-PAT-10`) |
| o componente em volta viola pureza ou Rules of Hooks | [[react-review]] — `REACT-PURE-*` e `REACT-HOOK-*` têm precedência (hub § 7, invariante 4) |
| o formulário nem deveria usar RHF | Passo 0 da skill; se a resposta for Actions nativas, [[react-developer]] |

---

## Relacionados

- `tarefas.md` — a tarefa correspondente a cada causa
- `mapa-de-ids.md` — onde cada `RHF-*` está declarado, e o que é apelido
- [[React Hook Form - Estado e Performance]] — o satélite que fecha a maioria destes casos
