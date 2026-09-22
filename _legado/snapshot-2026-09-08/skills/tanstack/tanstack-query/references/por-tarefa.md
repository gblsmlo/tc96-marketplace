# As sete tarefas

> Roteador tarefa → nota. O conteúdo do satélite não é repetido aqui — é citado.

| Tarefa | Carregar (nesta ordem) |
| --- | --- |
| 1. Ler dado remoto pela primeira vez | [[TanStack Query - O que um Dev Frontend Precisa Saber]] → [[TanStack Query - Cache e Frescor]] |
| 2. Decidir política de frescor | [[TanStack Query - Cache e Frescor]] |
| 3. Escrever no servidor e invalidar | [[TanStack Query - Mutations e Invalidação]] |
| 4. Update otimista com rollback | [[TanStack Query - Mutations e Invalidação]] → [[React - Formulários e Actions]] § 5 |
| 5. Lista paginada ou infinita | [[TanStack Query - Padrões de Consulta]] → [[TanStack Query - Cache e Frescor]] |
| 6. Integrar com o loader de rota | [[TanStack Router - Carregamento de Dados]] § 8 → [[TanStack Query - O que um Dev Frontend Precisa Saber]] § 7 |
| 7. Diagnosticar cache | ver a seção **Diagnóstico** — o satélite sai do sintoma |

Suspense, SSR/hidratação, cancelamento e network mode ficam em [[TanStack Query - Suspense e SSR]] e aparecem como ramo de outras tarefas, não como tarefa de entrada.

---


### 1. Ler dado remoto pela primeira vez

**Carregar:** [[TanStack Query - O que um Dev Frontend Precisa Saber]] (§ 3 keys, § 4 query functions, § 5 `status` × `fetchStatus`, § 7 `queryOptions`); [[TanStack Query - Cache e Frescor]] só quando chegar na política de frescor — que é a tarefa 2 e **não é opcional**.

**Verificar:**

- O `QueryClient` está fora do corpo do render? → `TSQ-BASE-01`
- A key é array, serializável e única para aquele dado? → `TSQ-BASE-02`
- **Toda** variável lida pela `queryFn` está na key? É a causa raiz da maioria dos bugs de dado velho ([[TanStack Query]] § 2, ponto 3) → `TSQ-BASE-03`
- Ausência de dado resolve `null`, nunca `undefined`? → `TSQ-BASE-04`
- Erro HTTP é lançado explicitamente — `fetch` não rejeita em 4xx/5xx? → `TSQ-BASE-05`
- A resposta passa por schema antes de virar `data`? A fronteira HTTP valida ([[TanStack Query]] § 7, invariante 5; [[Zod como schema de runtime]]) → `TSQ-BASE-06`
- O estado de carregamento distingue os dois eixos: query que pode estar desabilitada usa `isLoading`, não `isPending` → `TSQ-BASE-07`; e `fetchStatus: 'paused'` tem tratamento próprio → `TSQ-BASE-08`
- Se a query tem mais de um consumidor, key e função estão co-locadas em um `queryOptions` exportado? → `TSQ-BASE-09`
- A versão do pacote está travada em patch exato? → `TSQ-BASE-10`

**Não faça:** guardar o resultado em `useState`, nem "salvar a resposta" em qualquer lugar. Isso cria a segunda fonte de verdade que diverge na primeira revalidação — `REACT-PAT-03` em [[React - Patterns]], e invariante 1 do contrato. Se o código atual busca em `useEffect`, o achado é `REACT-EFFECT-06` ([[React - Efeitos e Sincronização]]), e a correção é a query, não um Effect melhor.

### 2. Decidir política de frescor (`staleTime` / `gcTime`)

**Carregar:** [[TanStack Query - Cache e Frescor]] (§ 2 ciclo de vida, § 3 `staleTime`, § 4 gatilhos de refetch).

Percorra a árvore "Qual `staleTime`?" de [[TanStack Query]] § 5 antes de escrever o número. A calibração se faz pela **volatilidade do dado**, não pela tela.

**Verificar:**

- Existe `staleTime` explícito na query ou nos `defaultOptions`? Aceitar o default `0` por omissão é o antipadrão; aceitá-lo por decisão é legítimo → `TSQ-CACHE-01`, e invariante 4 do contrato
- Algum `staleTime: 'static'` cobre dado que uma mutation altera? É o bug que não aparece em teste: a invalidação roda, não falha e não faz nada → `TSQ-CACHE-02`
- `staleTime` e `gcTime` governam fases diferentes (ativa × inativa) e foram decididos separadamente? A combinação alto/baixo é a pior possível — ver [[TanStack Query - Cache e Frescor]] § 2
- Nenhum gatilho de refetch foi desligado antes de calibrar `staleTime`? → `TSQ-CACHE-03`
- A `queryFn` devolve só valores compatíveis com JSON (`Date`, `Map`, `Set` e instâncias de classe quebram structural sharing)? → `TSQ-CACHE-04`
- Nenhum `const { data, ...rest } = useQuery(...)`? O rest desliga tracked properties → `TSQ-CACHE-05`
- Se há `initialData`: é dado real e completo → `TSQ-CACHE-06`, e traz `initialDataUpdatedAt` quando vem de outro cache → `TSQ-CACHE-07`
- Se há `placeholderData`: `isPlaceholderData` bloqueia ação ou decisão baseada no provisório? → `TSQ-CACHE-08`

Raciocínio de fundo: [[Cache de servidor exige uma política de frescor]].

### 3. Escrever no servidor e decidir o que invalidar

**Carregar:** [[TanStack Query - Mutations e Invalidação]] (§ 2 `useMutation`, § 3 `invalidateQueries`, § 4 `setQueryData`).

Percorra a árvore "Escrevi no servidor. E agora?" de [[TanStack Query]] § 5. **Escrita não atualiza a tela — invalidação atualiza** ([[TanStack Query]] § 2, ponto 5). Nenhuma mutation sai desta skill sem responder o que ela tornou velho, ou justificar por que nada ficou velho (invariante 3).

**Verificar:**

- Toda escrita passa por `useMutation` — `useQuery` nunca dispara POST/PUT/PATCH/DELETE → `TSQ-MUT-01`
- Callback que invalida ou refaz **retorna** a Promise, para a mutation seguir `pending` até o refetch terminar? Sem isso o botão volta a "Salvar" com a lista ainda velha, e o usuário clica de novo → `TSQ-MUT-02`
- Sincronização de cache, invalidação e rollback estão no `useMutation`, não nos callbacks de `mutate` — que não rodam se o componente desmontar? Navegar, fechar modal e toast é que pertencem ao `mutate` → `TSQ-MUT-03`
- Todo `mutateAsync` tem `catch` ou `try/catch`? Ele lança; `onError` trata o efeito, não a Promise → `TSQ-MUT-04`
- Nenhum `retry` em mutation não idempotente? → `TSQ-MUT-05`, [[Idempotência torna retries seguros]]
- Mutations concorrentes sobre o mesmo recurso declaram `scope: { id }`? → `TSQ-MUT-06`
- A invalidação usa o **prefixo mais específico** que cobre o efeito da escrita, nunca `invalidateQueries()` sem filtro? Se você não sabe o que a mutation afeta, o problema é a hierarquia de keys → `TSQ-MUT-07`
- Se grava direto no cache: é imutável → `TSQ-MUT-08`, e o updater devolve `undefined` quando recebe `undefined`, para não criar entrada a partir de uma escrita → `TSQ-MUT-09`
- Falha esperada (409, validação, sem permissão) vira estado da UI; falha inesperada vai para o boundary → `REACT-ASYNC-09` em [[React - Suspense e Assincronia]], [[Tratamento de erros esperados e inesperados]]
- **A assinatura dos callbacks está na forma atual da v5** — ver a seção seguinte. Confira sempre, não por memória.

**Calibre a dose:** invalidar de menos deixa tela velha; invalidar de mais transforma cada escrita numa cascata de requests. O `refetchType` (default `'active'`) é o que quase ninguém configura e o que decide o tamanho da rajada — [[TanStack Query - Mutations e Invalidação]] § 3.

### 4. Update otimista com rollback

**Carregar:** [[TanStack Query - Mutations e Invalidação]] § 5 (ciclo completo e a alternativa por `variables`); [[React - Formulários e Actions]] § 5 **antes de escolher a camada**.

**Primeiro decida a camada — não são duas opções que se combinam.** Ver a seção "Otimismo tem duas camadas" abaixo.

Se o otimismo for no cache da Query, verifique:

- O ciclo tem os cinco passos: `cancelQueries` → snapshot → `setQueryData` → rollback em `onError` → invalidação em `onSettled` → `TSQ-MUT-10`
- Sem `cancelQueries`, um refetch em voo chega depois e reverte o otimismo — bug intermitente, quase impossível de reproduzir sob demanda
- O snapshot trafega **pelo retorno de `onMutate`**, nunca por `useRef`, variável de módulo ou estado de componente: com mutations concorrentes, o segundo snapshot sobrescreve o primeiro e o rollback restaura estado errado → `TSQ-MUT-11`
- A invalidação final está em `onSettled`, não só em `onSuccess` — em erro, o rollback restaurou valor local que também precisa ser confirmado contra a fonte → `TSQ-MUT-12`
- O `onSettled` tem `return`, para `isPending` durar até o refetch terminar → `TSQ-MUT-02`
- **A assinatura de `onError`/`onSuccess`/`onSettled` foi conferida na doc**, não escrita de cabeça — ver a seção seguinte.

Raciocínio de fundo: [[Atualizações otimistas exigem snapshot e rollback]].

### 5. Lista paginada ou infinita

**Carregar:** [[TanStack Query - Padrões de Consulta]] (§ 3 paginadas, § 4 infinitas); [[TanStack Query - Cache e Frescor]] § 6 para `placeholderData` × `initialData`.

Antes: a página/cursor pertence à URL? Se o usuário precisa compartilhar link ou usar o botão voltar, é search param — `REACT-PAT-10`, e a rota entra pela [[tanstack-router]]. Modelo de paginação em [[Paginação por offset e cursor]].

**Verificar (paginada):**

- A página está na `queryKey` e a query usa `placeholderData: keepPreviousData`? Sem isso a tabela some a cada troca de página → `TSQ-PATTERN-04`
- Os controles de navegação ficam desabilitados enquanto `isPlaceholderData` for `true` — senão decidem sobre a página anterior e pulam ou ultrapassam → `TSQ-PATTERN-05`

**Verificar (infinita):**

- `initialPageParam` e `getNextPageParam` estão declarados → `TSQ-PATTERN-06`
- `fetchNextPage` é guardado por `isFetchingNextPage`; só há um fetch em voo por infinite query → `TSQ-PATTERN-07`
- Lista sem teto natural declara `maxPages` — o refetch refaz **todas** as páginas em série → `TSQ-PATTERN-08`

**Se a tela também tem queries dependentes, paralelas, lazy, prefetch ou `select`,** a mesma nota cobre: `TSQ-PATTERN-01` (justificar o waterfall de `enabled`), `TSQ-PATTERN-02` (número variável usa `useQueries`, Hook nunca em loop — `REACT-HOOK-01`), `TSQ-PATTERN-03` (paralelas sob Suspense usam `useSuspenseQueries`), `TSQ-PATTERN-09` (disparo manual é `enabled: false`, não `skipToken`), `TSQ-PATTERN-10` (query desabilitada ignora `invalidateQueries` — não guarde nela dado que uma mutation precisa manter fresco), `TSQ-PATTERN-11` e `TSQ-PATTERN-12` (prefetch), `TSQ-PATTERN-13` e `TSQ-PATTERN-14` (`select` não valida e é estável).

### 6. Integrar com o loader de rota

**Carregar:** [[TanStack Router - Carregamento de Dados]] § 8 ("External data loading"), que traz o critério e o padrão; depois [[TanStack Query - O que um Dev Frontend Precisa Saber]] § 7 para o `queryOptions` compartilhado. [[TanStack Router - Route Context e Code Splitting]] § 2 quando o `queryClient` precisar chegar ao loader por contexto.

Esta é a fronteira com [[tanstack-router]]: **a rota é dela, o cache é desta skill.** Se a pergunta é onde o loader mora, como a rota casa ou o que ela herda, delegue.

**Verificar:**

- **Quem é o dono do dado?** Loader nativo quando o dado pertence a uma rota e é consumido só ali; TanStack Query quando é consumido por várias rotas, ou precisa de mutação com invalidação seletiva, refetch em foco, paginação ou update otimista. Não é "ou um ou outro": o padrão oficial usa os dois — o loader aquece o cache, o componente lê do cache. Critério em [[TanStack Router - Carregamento de Dados]] § 8
- Loader e componente compartilham o **mesmo objeto** `queryOptions`, nunca duas construções paralelas → `TSR-LOAD-15` (é o mesmo motivo de `TSQ-BASE-09` e `TSQ-PATTERN-12`)
- O aquecimento no loader usa `ensureQueryData`, que respeita o cache — não `fetchQuery`, que busca sempre → `TSR-LOAD-16`
- O router foi criado com `defaultPreloadStaleTime: 0` → `TSR-LOAD-14`. **Este é o item que mais escapa:** sem ele o router considera o preload fresco por 30 s, não chama o loader, e o `staleTime` do Query nunca é consultado. O sintoma é dado velho depois de uma mutação, com o Query "certo" e o router segurando
- Nada de `fetch` em `useEffect` dentro da rota: `REACT-EFFECT-06` continua valendo lá dentro
- Onde a espera e a falha param: `<Suspense>`/pending e Error Boundary no nível certo, nunca só na raiz → `REACT-ASYNC-08`, `REACT-PAT-06`

Se a tela usa `useSuspenseQuery`, SSR ou hidratação, aí sim abra [[TanStack Query - Suspense e SSR]] — em especial `TSQ-SSR-04` (`QueryClient` por requisição no servidor, ou o cache vaza dado entre usuários), `TSQ-SSR-05` (`staleTime` > 0 no cliente, ou a hidratação descarta o que o servidor buscou) e `TSQ-SSR-07` (`<HydrationBoundary>`).

### 7. Diagnosticar

Ver a seção **Diagnóstico** — o satélite a abrir sai do sintoma, e carregar o satélite errado aqui custa mais do que ler a tabela.

---

