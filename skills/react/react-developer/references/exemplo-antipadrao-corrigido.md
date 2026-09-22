# Exemplo trabalhado — antipadrão e correção

O componente abaixo é o que sai por default quando se pula o Passo 1. Ele **funciona**
em desenvolvimento, com poucos dados e sem reordenação. Falha nas quatro situações que
importam: conexão lenta, refresh, navegação para trás, e lista reordenada.

---

## Antes

```tsx
function Busca({ termo }: { termo: string }) {
 const [query, setQuery] = useState(termo); // 1
 const [resultados, setResultados] = useState<Item[]>([]);
 const [carregando, setCarregando] = useState(false);
 const [erro, setErro] = useState<string | null>(null);
 const [contagem, setContagem] = useState(0);

 useEffect( => { setQuery(termo) }, [termo]); // 2

 useEffect( => { // 3
 setCarregando(true);
 fetch(`/api/busca?q=${query}`)
.then((r) => r.json)
.then((d) => { setResultados(d); setCarregando(false) })
.catch( => { setErro('falhou'); setCarregando(false) });
 }, [query]);

 useEffect( => { setContagem(resultados.length) }, [resultados]); // 4

 const ordenados = useMemo( => resultados.sort((a, b) => a.nome.localeCompare(b.nome)), [resultados]); // 5

 if (carregando) return <Spinner />;
 return <ul>{ordenados.map((r, i) => <li key={i}>{r.nome}</li>)}</ul>; // 6
}
```

## Os seis defeitos

| # | Defeito | Consequência concreta | Regra |
| --- | --- | --- | --- |
| 1 | `query` espelha a prop `termo` em estado | dois donos do mesmo valor | `REACT-PAT-01` |
| 2 | Effect só para ressincronizar a prop | um render a mais, e a janela em que os dois divergem | `REACT-PAT-01` |
| 3 | `fetch` em Effect | sem cancelamento: duas buscas em voo retornam fora de ordem e a antiga sobrescreve a nova | `REACT-EFFECT-06` |
| 3 | `carregando`/`erro` manuais | estados que admitem combinação impossível (`carregando && erro`) | `REACT-STATE-06` |
| 4 | `contagem` derivada por Effect | é `resultados.length` | `REACT-PAT-01` |
| 5 | `.sort` sobre o array do estado | `sort` **muta** — o array veio do estado e já foi para o JSX | `REACT-PURE-03`, `REACT-PURE-05` |
| 5 | `useMemo` sem medição | custo sem benefício comprovado | `REACT-PERF-01` |
| 6 | `key={i}` | ao reordenar, o estado interno da linha vai para o item errado | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 |

O defeito 3 é o que mais custa e o que menos aparece: a race condition só se manifesta
com latência variável, exatamente onde não há observação.

## Depois

```tsx
function Busca({ termo }: { termo: string }) {
 const { data: resultados } = useSuspenseQuery(buscaQuery(termo)); // 3 → cache

 const ordenados = [...resultados].sort((a, b) => // 5 → cópia, no render
 a.nome.localeCompare(b.nome)
 );

 return (
 <>
 <p>{resultados.length} resultados</p> {/* 4 → derivado */}
 <ul>
 {ordenados.map((r) => <li key={r.id}>{r.nome}</li>)} {/* 6 → id do domínio */}
 </ul>
 </>
 );
}
```

E a espera e a falha saem do componente, para a fronteira da feature:

```tsx
<ErrorBoundary fallback={<FalhaBusca onRetry={reset} />}> {/* REACT-ASYNC-08 */}
 <Suspense fallback={<EsqueletoLista />}> {/* REACT-ASYNC-02 */}
 <Busca termo={termo} />
 </Suspense>
</ErrorBoundary>
```

## O placar

| | Antes | Depois |
| --- | --- | --- |
| `useState` | 5 | 0 |
| `useEffect` | 3 | 0 |
| memoização | 1 sem medida | 0 |
| race condition | não tratada | resolvida pelo cache |
| refresh preserva a busca | não | sim, se `termo` vier da URL (`REACT-PAT-10`) |

Nenhuma linha foi removida por gosto: cada uma saiu por uma regra com ID.
