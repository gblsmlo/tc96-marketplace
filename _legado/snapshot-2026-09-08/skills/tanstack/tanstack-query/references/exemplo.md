# Exemplo trabalhado

Tarefa: *"aprovar uma fatura na tela de detalhe, e a lista precisa refletir"*.

**A árvore que importa é "Escrevi no servidor. E agora?".** Escrita não atualiza a tela — invalidação atualiza. Nenhuma mutation sai desta skill sem responder **o que ela tornou velho**.

**O inventário do que envelheceu**, feito antes de escrever a mutation:

| Query | Envelheceu? | Por quê |
| --- | --- | --- |
| `['faturas','detalhe',id]` | sim | o status mudou |
| `['faturas','lista']` | sim | a fatura sai do filtro "pendentes" |
| `['faturas','resumo']` | sim | o total pendente mudou |
| `['clientes',clienteId]` | **não** | aprovar fatura não altera o cliente |
| `['usuarios']` | não | sem relação |

```ts
const aprovar = useMutation({
  mutationFn: (id: string) => api.faturas.aprovar(id),

  // sincronização de cache mora AQUI, não nos callbacks de mutate — TSQ-MUT-03
  onSuccess: async (_, id) => {
    // retorna a Promise: a mutation segue pending até o refetch terminar — TSQ-MUT-02
    await Promise.all([
      qc.invalidateQueries({ queryKey: ['faturas','detalhe',id] }),
      qc.invalidateQueries({ queryKey: ['faturas','lista'] }),
      qc.invalidateQueries({ queryKey: ['faturas','resumo'] }),
    ]);
  },
});

// navegar e avisar pertencem ao mutate — eles não devem rodar se o componente desmontar
aprovar.mutate(id, {
  onSuccess: () => { toast.success('Fatura aprovada'); navigate({ to: '/faturas' }); },
});
```

**O que cada decisão evitou:**

| Decisão | Sintoma que ela previne | Regra |
| --- | --- | --- |
| `useMutation`, não `useQuery` | POST disparado por render, e de novo no refetch | `TSQ-MUT-01` |
| `await` / `return` no `invalidateQueries` | o botão volta a "Aprovar" com a lista velha, e o usuário clica de novo | `TSQ-MUT-02` |
| invalidação no `useMutation` | fechar o modal cancela a invalidação, e o cache fica sujo | `TSQ-MUT-03` |
| `toast` e `navigate` no `mutate` | toast disparando numa tela que já saiu | `TSQ-MUT-03` |
| `try/catch` se fosse `mutateAsync` | rejeição não tratada | `TSQ-MUT-04` |
| sem `retry` | aprovar duas vezes uma operação não idempotente | `TSQ-MUT-05` |
| `['clientes']` **fora** da lista | refetch de dado que não mudou, em toda aprovação | invariante 3 |

A última linha é a que mais se erra na direção oposta: invalidar `['faturas']` inteiro por segurança refaz também `['faturas','rascunhos']`, que ninguém tocou. Invalidação ampla demais é o mesmo defeito de invalidação faltando — só que o sintoma é lentidão, não tela velha.

---

