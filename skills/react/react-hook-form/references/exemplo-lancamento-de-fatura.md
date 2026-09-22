# Exemplo trabalhado — lançamento de fatura

Tarefa: *"formulário de lançamento de fatura — valor em moeda, vencimento, e um campo de
justificativa que só aparece quando o valor passa de R$ 10.000"*.

---

## Passo 0 — triagem

Três campos, **validação entre eles**, **campo condicional** e submit que **invalida
cache**. Passa da fronteira de "um campo sem validação": é RHF. Dois dos cinco gatilhos
nomeados — registrar isso em uma frase é o que a invariante 1 do contrato pede.

## A ordem das decisões, que não é a ordem do JSX

**1. Schema primeiro** — o tipo do form deriva do Zod, nunca o contrário (`RHF-VAL-04`).
A regra **entre** campos vive em `.superRefine`, não em `validate` por campo:

```ts
const schema = z.object({
 valor: z.coerce.number.positive, // o DOM devolve string — RHF-REG-03
 vencimento: z.coerce.date,
 justificativa: z.string.optional,
}).superRefine((v, ctx) => {
 if (v.valor > 10_000 && !v.justificativa?.trim)
 ctx.addIssue({ code: 'custom', path: ['justificativa'],
 message: 'Obrigatória acima de R$ 10.000' });
});
```

**2. `defaultValues` cobrindo todo campo**, incluindo o condicional (`RHF-CORE-01`) —
`justificativa: ''`, não ausente.

**3. `mode`** — aqui `onBlur`, porque validar a cada tecla num campo de moeda briga com a
máscara. É decisão declarada, não default por omissão.

**4. Campo a campo pela árvore § 5.1.** `valor` e `vencimento` vão por `register`; o
seletor de moeda é componente controlado de terceiro → `Controller` (a exceção, não a regra).

**5. Só então o dono do submit.** Há cache a invalidar → mutation do TanStack Query
(`RHF-BRIDGE-01`):

```ts
const onSubmit = handleSubmit(async (dados) => {
 try {
 await criarFatura.mutateAsync(dados); // mutateAsync lança — TSQ-MUT-04
 } catch (e) {
 if (isValidationError(e))
 setError('valor', { message: e.campo.valor }); // erro de campo — RHF-ERR-02
 else
 setError('root.serverError', { message: 'Falha ao lançar' });
 }
});
```

E o campo condicional lê o valor no **menor componente que precisa dele**:

```tsx
function Justificativa {
 const valor = useWatch({ name: 'valor' }); // não watch na raiz — RHF-PERF-01
 if (valor <= 10_000) return null;
 return <CampoTexto name="justificativa" />; // defaultValues já cobre — RHF-CORE-01
}
```

## O que as decisões evitaram

| Decisão | Alternativa que dói depois | Regra |
| --- | --- | --- |
| tipo derivado do schema | tipo escrito à mão, divergindo do Zod | `RHF-VAL-04` |
| `z.coerce.number` | `valor` chega string e `> 10_000` compara texto | `RHF-REG-03` |
| `superRefine` para a regra entre campos | `validate` na justificativa, que não vê o valor | Validação § 3 |
| `defaultValues` no condicional | campo passa de uncontrolled a controlled no meio | `RHF-CORE-01` |
| um dono do submit | `<form action>` **e** `onSubmit` juntos — a ordem deixa de ser sua | `RHF-BRIDGE-01` |
| `try/catch` no `mutateAsync` | rejeição não tratada, e o form trava em `isSubmitting` | `TSQ-MUT-04` |
| erro esperado por `setError` | lançar do `onSubmit` para o Error Boundary | `REACT-ASYNC-09` |
| `useWatch` no filho | `watch` na raiz: re-render do form inteiro a cada tecla | `RHF-PERF-01` |
| um único estado de espera | `disabled={isSubmitting \|\| isPending}` | `dono-da-submissao.md` |

## O que fica fora desta skill

- O que a criação da fatura tornou velho no cache é decisão da **mutation** —
 `tanstack-query`.
- O **otimismo**, se houver, é da mutation com snapshot e rollback — `RHF-BRIDGE-04`,
 nunca do formulário.
- A validação de cliente aqui é UX; o servidor revalida e autoriza — `REACT-RSC-06`.
