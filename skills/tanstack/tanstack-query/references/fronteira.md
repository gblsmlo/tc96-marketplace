# Fronteira com as outras skills

| A pergunta é sobre | Skill |
| --- | --- |
| O dado remoto: key, frescor, invalidação, otimismo, forma da consulta | esta |
| A rota: onde o loader mora, casamento de URL, search params, navegação, code splitting | `tanstack-router` |
| O componente que já existe: pureza, Hooks, estrutura, severidade do achado | `react-review` |
| O componente novo: posse do estado, composição, fronteiras de falha e espera | `react-developer` |

Sobreposições resolvidas:

- **Dado remoto em `useState`** aparece nas quatro. É `REACT-PAT-03` para citar; a correção é desta skill (vira query).
- **`fetch` em `useEffect`** é `REACT-EFFECT-06`; a correção é query, ou loader se o dado pertence à rota — tarefa 6.
- **Update otimista** é fronteira com `react-developer`: a escolha da camada está acima, e `REACT-FORM-07` vale nas duas.
- **Paginação e filtro** são fronteira com `tanstack-router`: o valor pertence à URL (`REACT-PAT-10`), o cache pertence à key (`TSQ-PATTERN-04`). Os dois, não um dos dois.

Ao reportar achado em revisão, use o formato de `react-review` — ID canônico + `arquivo:linha` + correção concreta + link do satélite. Os IDs `TSQ-*` entram nesse formato do mesmo jeito que os `REACT-*`.

**Regra de honestidade:** se a API tocada não aparece em [TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 4 nem nos satélites, ela não foi verificada nesta doc. Declare a limitação, consulte [tanstack.com/query](https://tanstack.com/query/latest/docs/framework/react/overview) e proponha atualizar a nota — não afirme comportamento e não invente ID ([TanStack Query](../../../../knowledge-base/docs/tanstack-query.md) § 7).

---

