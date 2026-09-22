# Quem é dono do estado de submissão

Com TanStack Query no fluxo há **dois** estados dizendo "está salvando":
`formState.isSubmitting` (RHF) e `isPending` (mutation). Escolha um e use o **mesmo** em
toda a tela — botão, texto, `disabled`, spinner.

| Situação | Dono | Por quê |
| --- | --- | --- |
| `handleSubmit` faz `await mutateAsync(...)` e é o único caminho de escrita | `isSubmitting` | cobre o `await` inteiro, inclusive o refetch se o callback retornar a Promise (`TSQ-MUT-02`) |
| A mesma mutation dispara de outros lugares (retry, outra tela, otimismo) | `isPending` | o estado é da mutation; o form é só um dos gatilhos |
| Server Function com `useActionState` | o `isPending` do `useActionState` | `isSubmitting` não é lido |

**Não faça `disabled={isSubmitting || isPending}`.** Parece defensivo e é o sintoma de que
ninguém decidiu: os dois divergem entre o fim do `await` e o fim da invalidação, e o botão
pisca ou destrava cedo.

O precedente é `REACT-FORM-07` — quando duas camadas descrevem o mesmo estado, uma é a
verdade e a outra é ruído. É o mesmo erro que `RHF-BRIDGE-04` proíbe no **otimismo**,
aplicado ao estado de **espera**; são regras distintas e citáveis separadamente (hub § 6.2).

**Deixe a escolha registrada junto do handler**, em uma linha. A sonda 11 de `sondas.sh`
procura exatamente o `||` que aparece quando ela não foi feita.

---

## Relacionados

- [React Hook Form](../../../../knowledge-base/docs/react-hook-form.md) § 5.4 e § 8 — as árvores de submissão e as pontes
- `tanstack-query` — o que a escrita tornou velho no cache
- `tarefas.md` § 5 — submeter
