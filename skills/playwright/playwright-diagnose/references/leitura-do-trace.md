# Obter e ler o trace

> Passos 1 e 2. **Ler o trace vem antes de tocar no código** (`PW-DBG-01`) — é o que
> distingue esta skill de tentativa e erro.

---

## Obter

| Situação | Comando |
| --- | --- |
| falhou em CI | baixe o artefato `playwright-report`, então `npx playwright show-report <pasta>` |
| tem o `.zip` | `npx playwright show-trace test-results/…/trace.zip` |
| quer reproduzir local | `npx playwright test <arquivo>:<linha> --trace on` |
| não há trace nenhum | **este é o primeiro achado** — `PW-CFG-02`, `PW-DBG-05` |

Sem trace configurado, toda falha de CI é adivinhação. Se `trace` está `'off'`, o conserto é
a **configuração**, não o teste — e o diagnóstico só começa na próxima execução.

> **Nunca** use `--debug` para decidir se é flake: ele força `timeout=0` e `workers=1`, então
> **sempre passa** (`PW-DBG-02`). Concluir "sob debug passa, então não é flake" é inválido.

---

## Ler, em quatro passos

| # | Aba | Responde |
| --- | --- | --- |
| 1 | **Errors** | qual ação falhou |
| 2 | **Log** daquela ação | **em qual checagem** ela travou |
| 3 | **Snapshot Before** | o que estava na tela naquele instante |
| 4 | **Network** | qual requisição falhou ou não voltou |

O passo 2 é o que nenhum `console.log` dá, e é onde a causa aparece:

| Mensagem no Log | Causa | Regra |
| --- | --- | --- |
| `waiting for element to be visible` | o alvo nunca apareceu: locator errado, ou a tela é outra | `PW-LOC-01` |
| `element is not stable` | animação em curso | § 1 do satélite de ações |
| `element intercepts pointer events` | **overlay roubando o clique** — é defeito de produto | `PW-ACT-01` |
| `element is not enabled` | botão desabilitado: hidratação, ou pré-condição não cumprida | § 7.2 do satélite de ações |
| `strict mode violation` | locator ambíguo | `PW-LOC-02` |

O passo 3 costuma encerrar o caso: no snapshot aparece o modal aberto, o spinner girando, a
tela de erro, ou **a página de login que ninguém esperava** — que é setup de autenticação
falhando (`PW-AUTH-06`).

---

## Relacionados

- [[Playwright - Debug e Trace]] § 3 — a fonte desta leitura
- `arvore-de-hipoteses.md` — o que fazer quando o trace não encerra o caso
