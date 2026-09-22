# Exemplo trabalhado — painel de faturas

Tarefa: *"um painel de faturas com filtro por status e o total do que está selecionado"*.

O ponto deste exemplo: a versão intuitiva desta tela tem **quatro** `useState` e **dois**
`useEffect`. Nenhum deles sobrevive ao Passo 1 — e nenhum era necessário.

---

## Passo 1 — as três perguntas, por escrito

| Pergunta | Resposta | Consequência |
| --- | --- | --- |
| De quem é este dado? | as **faturas** são do servidor; o **filtro** pertence à URL; a **seleção** é do painel | três donos, três mecanismos |
| Quem fornece o conteúdo variável? | a linha da fatura varia por contexto → `children`, não prop booleana | a assinatura não cresce |
| Onde uma falha ou espera deve parar? | na fronteira da feature, não na raiz | Error Boundary + `<Suspense>` em `features/faturas` |

A pergunta 1, sozinha, já eliminou dois `useState` que o hábito criaria.

## Passo 2 — as árvores, um dono de cada vez

| Dono | Percurso em [React.js](../../../../knowledge-base/docs/react-js.md) § 5 | Saída | Regra |
| --- | --- | --- | --- |
| faturas | "o dado vem do servidor?" → sim | [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md), não `useState` + `useEffect` | `REACT-PAT-03`, `REACT-EFFECT-06` |
| filtro | sobrevive a refresh, é compartilhável por link, respeita o voltar | search params do [TanStack Router](../../../../knowledge-base/docs/tanstack-router.md) | `REACT-PAT-10` |
| seleção | efêmera, morre ao sair da tela | `useState` no ancestral comum **mais próximo** — o painel, não a raiz | `REACT-PAT-02` |
| total | derivável de faturas + seleção | calculado no render, sem estado nem Effect | `REACT-PAT-01` |

Três das quatro saídas não têm Hook. É o resultado esperado.

## Passo 3 — o código

```tsx
export function PainelFaturas({ children }: { children: ReactNode }) {
 const { status } = Route.useSearch; // filtro: URL
 const { data: faturas } = useSuspenseQuery(faturasQuery({ status })); // remoto: cache
 const [selecionadas, setSelecionadas] = useState<Set<string>>(new Set);

 const total = faturas // derivado, no render
.filter((f) => selecionadas.has(f.id))
.reduce((soma, f) => soma + f.valor, 0);

 function alternar(id: string) {
 setSelecionadas((atual) => { // updater: o anterior importa
 const proximo = new Set(atual);
 proximo.has(id) ? proximo.delete(id) : proximo.add(id);
 return proximo; // novo Set, não mutação do estado
 });
 }

 return (
 <section>
 <Total valor={total} />
 <ul>
 {faturas.map((f) => (
 <LinhaFatura
 key={f.id} // id do domínio, nunca o índice
 fatura={f}
 selecionada={selecionadas.has(f.id)}
 onAlternar={ => alternar(f.id)}
 />
 ))}
 </ul>
 {children}
 </section>
 );
}
```

E a fronteira, um nível acima — boundary de espera **e** de erro, no nível da feature:

```tsx
<ErrorBoundary fallback={<FalhaFaturas onRetry={reset} />}> {/* REACT-ASYNC-08, ASYNC-11 */}
 <Suspense fallback={<EsqueletoPainel />}> {/* mesma área do conteúdo */}
 <PainelFaturas>
 <AcoesEmLote /> {/* composição, não prop booleana */}
 </PainelFaturas>
 </Suspense>
</ErrorBoundary>
```

## Passo 4 — o que a tabela de hábitos evitou

| Hábito que não aconteceu | Regra |
| --- | --- |
| `useEffect` + `fetch` para carregar faturas | `REACT-EFFECT-06`, `REACT-ASYNC-03` |
| `useState` + `useEffect` para o total | `REACT-PAT-01` |
| `useState` para o filtro | `REACT-PAT-10` |
| estado elevado à raiz "por precaução" | `REACT-PAT-02` |
| `setSelecionadas(new Set(selecionadas))` sem updater | `REACT-STATE-01` |
| `showTotal` / `hideActions` em vez de `children` | `REACT-PAT-04` |
| `useMemo` no `total` sem medição | `REACT-PERF-01` |
| `key={i}` na lista | antipadrão de [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 |
| Error Boundary só na raiz | `REACT-PAT-06` |

## Passo 5 — autoverificação

- Passada 1: nenhum Hook condicional, nenhum side effect no render, nenhuma mutação —
 o `Set` novo dentro do updater é construção, não mutação do estado anterior.
- Passada 2: as seções 1–3 de `habitos-de-ia.md` estão limpas; 5–7 não se aplicam.
- Passada 3: o único `useState` é efêmero e local; não há `useEffect`; não há memoização,
 logo não há memoização sem medida.
