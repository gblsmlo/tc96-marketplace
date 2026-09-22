# Exemplo trabalhado — a variante robusta: fronteira de servidor

Mesma feature do exemplo anterior, agora com **escrita**: aprovar uma fatura.
O que muda não é o React — é que existe uma fronteira de confiança no meio.

> Aplica-se a Server Functions (`'use server'`). Numa SPA Vite sem RSC, a fronteira
> é o endpoint HTTP e as mesmas três obrigações valem lá — ver [React.js](../../../../knowledge-base/docs/react-js.md) § 8.

---

## A regra que decide tudo

`REACT-RSC-06` — Server Function **MUST** autenticar, validar e autorizar **na própria
função**. É um endpoint público: qualquer cliente pode chamá-la com qualquer argumento.
Validação no formulário é ergonomia, não segurança.

## O código

```tsx
// aprovar-fatura.ts
'use server';

const Entrada = z.object({ faturaId: z.string.uuid }); // validação de fronteira

export async function aprovarFatura(_estado: EstadoAprovacao, dados: FormData) {
 const sessao = await lerSessao;
 if (!sessao) return { erro: 'Sessão expirada. Entre de novo.' }; // 1. autenticar

 const parsed = Entrada.safeParse({ faturaId: dados.get('faturaId') });// 2. validar
 if (!parsed.success) return { erro: 'Fatura inválida.' };

 const fatura = await repo.buscar(parsed.data.faturaId);
 if (!fatura || fatura.orgId !== sessao.orgId) { // 3. autorizar
 return { erro: 'Fatura não encontrada.' }; // mesma mensagem dos dois casos:
 } // não revele existência a quem não pode ver

 if (fatura.status !== 'pendente') {
 return { erro: 'Esta fatura já foi processada.' }; // conflito é esperado → estado
 }

 await repo.aprovar(fatura.id, sessao.userId);
 return { ok: true };
}
```

```tsx
// BotaoAprovar.tsx — Client Component, o mais baixo que dá
'use client';

export function BotaoAprovar({ faturaId }: { faturaId: string }) {
 const [estado, acao] = useActionState(aprovarFatura, {});

 return (
 <form action={acao}> {/* sem e.preventDefault */}
 <input type="hidden" name="faturaId" value={faturaId} /> {/* name, não estado */}
 <Enviar />
 {estado.erro && <p role="alert">{estado.erro}</p>} {/* erro esperado é UI */}
 </form>
 );
}

function Enviar {
 const { pending } = useFormStatus; // descendente do <form>, nunca o pai
 return <button disabled={pending}>{pending ? 'Aprovando…' : 'Aprovar'}</button>;
}
```

## Por que cada linha está assim

| Decisão | Regra |
| --- | --- |
| `'use server'` valida mesmo com validação no cliente | `REACT-RSC-06` |
| argumentos e retorno serializáveis (`FormData`, objeto simples) | `REACT-RSC-07` |
| erro de sessão, conflito e "não encontrada" **retornam**, não lançam | `REACT-FORM-03` / `REACT-ASYNC-09` |
| `'use client'` no botão, não na página | `REACT-RSC-03` |
| nada de `e.preventDefault` com `<form action>` | `REACT-FORM-01` |
| `name` no campo que a Action lê | `REACT-FORM-02` |
| `useFormStatus` em `<Enviar>`, descendente do `<form>` | `REACT-FORM-05` |

## A pergunta que decide o dono da submissão

Se a aprovação **invalida cache** da [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md), o dono é a mutation da Query, e o
formulário vira `<form>` comum com handler. `useActionState` sozinho basta quando a
submissão é isolada. Empilhar os dois — e ainda `useOptimistic` sobre dado que vive no
cache — produz duas fontes de verdade divergindo (`REACT-FORM-07`). Critério em
[React.js](../../../../knowledge-base/docs/react-js.md) § 8.

## O que um agente escreveria por hábito, e falharia

```tsx
// ERRADO
export async function aprovarFatura(id: string) {
 'use server';
 await repo.aprovar(id); // sem sessão, sem validação, sem checar dono
} // REACT-RSC-06 — qualquer id aprova qualquer fatura

// ERRADO
if (fatura.status !== 'pendente') throw new Error('já processada');
// REACT-ASYNC-09 — erro esperado subindo para o boundary: a tela inteira cai
```
