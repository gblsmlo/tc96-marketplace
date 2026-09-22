# Fronteira com React

O roteador resolve o que o React puro não resolve. Ao decidir entre uma primitiva do React e o roteador, use [React.js](../../../../knowledge-base/docs/react-js.md) § 8 (pontes com o stack):

| Problema | Não use | Use |
| --- | --- | --- |
| Filtro, aba, paginação, ordenação | `useState` | search params da rota (`REACT-PAT-10`) |
| Navegação e histórico | `useState` + history | API de navegação do roteador |
| Dado remoto de uma tela | `useEffect` + `useState` | loader da rota e/ou TanStack Query (`REACT-EFFECT-06`, `REACT-PAT-03`) |

Ao revisar código de rota, os IDs `REACT-*` continuam citáveis com o formato de `react-review`: ID canônico + arquivo:linha + correção concreta + link do satélite.

---

