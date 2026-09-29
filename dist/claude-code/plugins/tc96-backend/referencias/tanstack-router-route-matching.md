---
titulo: TanStack Router - Route Matching
Link: https://tanstack.com/router/latest/docs/framework/react/routing/route-matching
tags:
  - tanstack-router
  - routing
  - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Route Matching

> **Qual rota ganha** quando mais de uma poderia casar a URL: a ordem de precedência por especificidade, a ordenação automática da árvore e os quatro casos que a documentação percorre passo a passo.
>
> **Não cobre:** o que cada tipo de rota é ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · a topologia da árvore ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · convenções de nome de arquivo ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · o que acontece *depois* do match — `beforeLoad`, `loader`, `<Outlet />` ([TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md)).

Entrada: [TanStack Router](tanstack-router.md) · Base normativa: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: a ordem de declaração não existe

Em roteadores baseados em lista — `react-router` clássico, Express — a ordem em que você escreve as rotas **é** a semântica. `/blog/new` declarado depois de `/blog/:postId` nunca casa, porque o parâmetro engole tudo primeiro. Metade dos bugs de roteamento nesses sistemas é ordem de declaração.

O TanStack Router elimina essa categoria inteira de bug: ele **reordena a árvore por especificidade** antes de tentar casar. A ordem em que as rotas foram escritas, ou em que o sistema de arquivos as devolveu, é irrelevante.

A ordem de precedência, citada da fonte:

1. **Index Route**
2. **Static Routes** (mais específica → menos específica)
3. **Dynamic Routes** (mais longa → mais curta)
4. **Splat / Wildcard Routes**

Uma quinta camada vem da página de conceitos de rota:

> "Routes with optional parameters are ranked lower in priority than exact matches"

Isto é, `{-$param}` perde para o segmento estático correspondente.

| ID | Regra |
| --- | --- |
| `TSR-MATCH-01` | A ordem de declaração das rotas **NEVER** é usada como mecanismo de precedência — o router reordena por especificidade. Código que depende de ordem está errado. |

---

## 2. A ordenação, na prática

Árvore como escrita:

```
Root
  - blog
    - $postId
    - /
    - new
  - /
  - *
  - about
  - about/us
```

Árvore como o router a ordena:

```
Root
  - /
  - about/us
  - about
  - blog
    - /
    - new
    - $postId
  - *
```

Três leituras que valem por toda a tabela:

- `/` sobe ao topo — index tem a maior precedência;
- `about/us` vem antes de `about` — entre estáticas, ganha a mais específica;
- dentro de `blog`, a ordem final é `/` → `new` → `$postId`: a index primeiro, a estática antes da dinâmica, e o splat depois de tudo.

**É por isso que `/blog/new` funciona sem nenhum cuidado especial**, mesmo convivendo com `/blog/$postId`. O caso clássico de "a rota estática foi engolida pelo parâmetro" não acontece aqui.

| ID | Regra |
| --- | --- |
| `TSR-MATCH-02` | Rota estática irmã de uma dinâmica **NEVER** precisa de workaround (prefixo artificial, ordem manual, guard dentro do componente) — a estática já vence por especificidade. |

---

## 3. Os quatro casos da fonte

**`/blog`** — a raiz index falha (a URL não é `/`), as estáticas `about/us` e `about` falham, o router entra no ramo `blog` e casa a **index route** de blog.

**`/blog/my-post`** — mesma descida até `blog`; a index de blog falha (a URL não termina em `blog`), `new` falha, e casa `$postId` com `postId = "my-post"`.

**`/`** — casa a index route da raiz imediatamente, antes de qualquer outra tentativa.

**`/not-a-route`** — todas falham e o **splat** captura como fallback.

O quarto caso é o que define o papel do splat: ele não é "uma rota que pega qualquer coisa", é **a última linha de defesa**, testada depois de todas as outras. Usá-lo cedo na árvore para "capturar" um conjunto de URLs que teria rota estática possível inverte o desenho: você paga o custo de rotear à mão dentro do componente e perde params tipados, loader por rota e code splitting.

| ID | Regra |
| --- | --- |
| `TSR-MATCH-03` | Splat route **NEVER** é usada para rotear manualmente dentro do componente um conjunto de URLs que poderia ter rotas próprias. Ela é fallback, não despachante. |
| `TSR-MATCH-04` | Código **NEVER** conta com `{-$param}` ganhando de um segmento estático — parâmetro opcional é ranqueado abaixo do match exato. |

---

## 4. Tabela de precedência

| Tipo | Exemplo | Prioridade | Desempate interno |
| --- | --- | --- | --- |
| Index | `/` | 1ª | — |
| Estática | `/about/us`, `/blog/new` | 2ª | mais específica primeiro |
| Dinâmica | `/blog/$postId` | 3ª | mais longa primeiro |
| Param opcional | `/posts/{-$category}` | abaixo de match exato | — |
| Splat | `/files/$` | última | — |

> **Não verificado:** a posição exata de `{-$param}` *relativa a* dynamic routes obrigatórias. A fonte afirma apenas que parâmetros opcionais ficam abaixo de correspondências exatas; não encontrei declaração sobre opcional × dinâmico obrigatório nesta verificação. Se o desenho depender disso, teste.

---

## Antipadrões

**Prefixo artificial para "proteger" a rota estática**

```
// ERRADO — resolve um problema que não existe neste router,
// e vaza um detalhe de implementação para a URL
routes/blog._new.tsx      → /blog/_new  (nem é isso que _ faz)

// CERTO — a estática já vence a dinâmica
routes/blog.new.tsx       → /blog/new
routes/blog.$postId.tsx   → /blog/:postId
```

**Splat como despachante**

```tsx
// ERRADO — um único match, um único loader, params sem tipo,
// e todo o code splitting perdido
export const Route = createFileRoute('/admin/$')({
  component: () => {
    const { _splat } = Route.useParams()
    if (_splat === 'users') return <Users />
    if (_splat?.startsWith('reports/')) return <Report />
    return <NotFound />
  },
})

// CERTO — cada URL é uma rota, com loader e tipos próprios
// routes/admin.users.tsx
// routes/admin.reports.$reportId.tsx
// routes/admin.$.tsx        ← só o fallback de verdade
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Reordenar arquivos ou renomear para forçar precedência | A ordem de declaração não é lida | Confiar na especificidade (`TSR-MATCH-01`) |
| `if` dentro do componente da rota dinâmica para tratar um valor especial (`postId === 'new'`) | A rota estática irmã já resolveria isso | Criar `blog.new.tsx` (`TSR-MATCH-02`) |
| Splat na raiz cobrindo uma seção inteira | Um loader, sem params tipados, sem code splitting | Rotas explícitas + splat só como 404 (`TSR-MATCH-03`) |
| `{-$category}` esperando ganhar de `/posts/featured` | Opcional é ranqueado abaixo do match exato | Aceitar a precedência ou não criar a estática (`TSR-MATCH-04`) |

---

## Checklist de revisão

- [ ] Alguma decisão de nome ou de estrutura foi tomada "para garantir a ordem"? → `TSR-MATCH-01`
- [ ] Existe rota dinâmica com `if` interno tratando um valor que mereceria rota estática? → `TSR-MATCH-02`
- [ ] Splat routes são só fallback, e não despachantes de subárvore? → `TSR-MATCH-03`
- [ ] Nenhum código depende de `{-$param}` vencer um segmento estático? → `TSR-MATCH-04`
- [ ] URLs exatas de rotas com filhos têm index route? → `TSR-ROUTE-04`

---

## Relacionados

- [TanStack Router](tanstack-router.md) — entrada
- [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)
- [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) — o que roda depois do match
- [TanStack Router - Navegação](tanstack-router-navegacao.md) · [React.js](react-js.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [Route Matching](https://tanstack.com/router/latest/docs/framework/react/routing/route-matching)
- [Routing Concepts](https://tanstack.com/router/latest/docs/framework/react/routing/routing-concepts) — precedência de parâmetros opcionais
- [Path Params](https://tanstack.com/router/latest/docs/framework/react/guide/path-params)

**Correções aplicadas nesta revisão:**

- **A ordem de precedência e os quatro exemplos conferem com a fonte** — o conteúdo técnico da versão anterior estava correto e foi preservado.
- **Removidas todas as reconstruções do algoritmo interno**: a função `matchRoute`, a `class RouteMatcher` com `sortBySpecificity`, e a `interface RouteConfig`. Nenhuma existe na documentação. Pior do que supérfluas, elas eram **erradas**: o `sortBySpecificity` inventado ordenava estáticas por profundidade decrescente (`bStatic - aStatic`), o que contradiz a própria tabela da nota, e a `matchRoute` retornava uma única rota, apagando o fato de que o resultado de um match é uma **cadeia** de rotas do root à folha.
- **Removida a API inventada** `createRouteTree([rootRoute(...), indexRoute(...), route(...)])`. Não existe nada com essa assinatura.
- **Adicionada a precedência de parâmetros opcionais** (`{-$param}` abaixo do match exato), ausente na versão anterior.
- **Cortado por redundância:** a seção "Camadas de Abstração", que redefinia route tree e tipos de rota (agora só em [TanStack Router - Route Trees](tanstack-router-route-trees.md) e [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)).
