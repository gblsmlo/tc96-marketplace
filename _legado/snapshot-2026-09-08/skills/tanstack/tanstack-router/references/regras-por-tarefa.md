# As famílias `TSR-*`, por tarefa

> **O que mudou.** A versão anterior desta skill trazia um "aviso de estado da doc" dizendo
> que os satélites estavam **em construção** e, por isso, **não citava ID nenhum** — ela
> emprestava `REACT-*`. Os dez satélites hoje existem e somam **102 regras `TSR-*`**
> declaradas. O aviso saiu, e cada tarefa passa a ter família citável.

| Tarefa | Família | Onde |
| --- | --- | --- |
| definir rota, hierarquia, layout | `TSR-ROUTE-*` | [[TanStack Router - Routing Concepts]] |
| convenção de arquivo e geração da árvore | `TSR-FILE-*` | [[TanStack Router - File-Based Routing]] |
| montagem e organização da árvore | `TSR-TREE-*` | [[TanStack Router - Route Trees]] |
| por que uma URL casa (ou não) | `TSR-MATCH-*` | [[TanStack Router - Route Matching]] |
| árvore fora da convenção de arquivos | `TSR-VIRTUAL-*` | [[TanStack Router - Virtual File Routes]] |
| navegar, `<Link>`, `useNavigate`, preload | `TSR-NAV-*` | [[TanStack Router - Navegação]] |
| search params tipados e validados | `TSR-SEARCH-*` | [[TanStack Router - Search Params]] |
| loader, `beforeLoad`, integração com cache | `TSR-LOAD-*` | [[TanStack Router - Carregamento de Dados]] |
| contexto de rota (injeção de dependência tipada) | `TSR-CTX-*` | [[TanStack Router - Route Context e Code Splitting]] |
| code splitting por rota | `TSR-SPLIT-*` | [[TanStack Router - Route Context e Code Splitting]] |

Índice completo, por seção: `mapa-de-ids.md`.

---

## As regras que decidem a maior parte dos casos

**Navegação**

| Regra | O que exige |
| --- | --- |
| `TSR-NAV-01` | `to` **nunca** recebe string interpolada — path param vai em `params`, query em `search`, fragmento em `hash` |
| `TSR-NAV-02` | destino conhecido no render é **`<Link>`**; `useNavigate` em `onClick` não |
| `TSR-NAV-03` | `to` relativo (`.`, `..`) **exige** `from` — sem ele a origem é `/`, não a rota atual |
| `TSR-NAV-04` | `from` vem de `Route.fullPath`, nunca de string literal repetida no JSX |
| `TSR-NAV-09` | navegação que **consome** a rota atual (pós-login, pós-submit) usa `replace: true` |

**Search params**

| Regra | O que exige |
| --- | --- |
| `TSR-SEARCH-01` | rota que lê search **declara `validateSearch`** — sem schema não há tipo, default nem garantia de forma |
| `TSR-SEARCH-02` | a fonte é `useSearch` — nunca `window.location.search`, `URLSearchParams` ou hook de outra biblioteca |
| `TSR-SEARCH-03` | toda chave define comportamento para **ausente** e para **inválido**; schema só do caso feliz não valida nada |
| `TSR-SEARCH-05` | Zod v3 com `.catch()` **precisa** de `fallback()` do adapter, senão o tipo colapsa para `unknown` |
| `TSR-SEARCH-07` | atualizar **uma** chave usa a forma funcional com spread — objeto literal substitui o search inteiro |

**Carregamento**

| Regra | O que exige |
| --- | --- |
| `TSR-LOAD-01` | dado da primeira renderização vem do `loader`, **nunca** de `fetch` em `useEffect` (apelido de `REACT-EFFECT-06`) |
| `TSR-LOAD-03` · `TSR-LOAD-04` | `loaderDeps` devolve **só** os search params que o loader lê — e o loader não lê o search da `location` |
| `TSR-LOAD-05` | `beforeLoad` é contexto, guarda e redirect; buscar dado de tela ali é **serial** e bloqueia os loaders paralelos |
| `TSR-LOAD-06` | guarda de acesso é `throw redirect(...)` em `beforeLoad`, não `navigate()` em efeito |
| `TSR-LOAD-09` | rota com `loader` tem `errorComponent` própria ou `defaultErrorComponent` no router |
| `TSR-LOAD-14` | loader que usa Query exige `defaultPreloadStaleTime: 0` — **um** cache decide o frescor. `TSR-NAV-08` é apelido; cite o canônico |

---

## Relacionados

- `por-tarefa.md` — o que carregar e verificar em cada tarefa
- `mapa-de-ids.md` — os 102 `TSR-*` por satélite e seção
- [[tanstack-query]] — o outro cache, e a regra `TSR-LOAD-14` que os concilia
