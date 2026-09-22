# A ordem da varredura

> Por **frequência de defeito** em código E2E, incluindo o gerado por agente. Se um passo
> produz achado que invalida o seguinte — a suíte não tem trace; o `.only` reduz tudo a um
> teste; o nível está errado — **pare de auditar o interior** e reporte a mudança de forma.

| # | O que | IDs |
| --- | --- | --- |
| 1 | **Asserção que não afirma** — produz teste **verde e inútil**, a pior categoria | `PW-CORE-04`, `PW-EXP-01` |
| 2 | **Espera inventada** | `PW-CORE-05`, `PW-ACT-04`, `PW-ACT-03` |
| 3 | **Locator frágil** | `PW-LOC-01`, `PW-LOC-02`, `PW-LOC-03`, `PW-LOC-05`, `PW-LOC-06` |
| 4 | **Ação que desliga verificação** | `PW-ACT-01`, `PW-ACT-06`, `PW-ACT-05` |
| 5 | **Isolamento e sessão** | `PW-AUTH-01`, `PW-AUTH-03`, `PW-AUTH-05`, `PW-CORE-06` |
| 6 | **Nível errado** — regra de negócio em E2E; o de maior custo acumulado | `PW-STR-*` + `TS-CORE-02` |
| 7 | **Estrutura** | `PW-STR-01`, `PW-STR-02`, `PW-FIX-01`, `PW-FIX-03`, `PW-FIX-05`, `PW-STR-04`, `PW-STR-06`, `PW-STR-07` |
| 8 | **Rede e dado** | `PW-NET-02`, `PW-NET-04`, `PW-NET-06`, `PW-NET-03` |
| 9 | **Snapshot** | `PW-SNAP-01`, `PW-SNAP-02`, `PW-SNAP-04`, `PW-SNAP-06` |
| 10 | **Configuração e CI** | `PW-CORE-07`, `PW-CFG-04`, `PW-CFG-05`, `PW-CFG-06`, `PW-RUN-01`, `PW-RUN-02`, `PW-RUN-05`, `PW-RUN-06` |
| 11 | **Estilo** | por último, sempre subordinado ao resto |

---

## Teste produzido por agente — checklist extra

Se a suíte tem testes de planner/generator/healer, aplique **também**:

| # | Verificar | Regra |
| --- | --- | --- |
| 1–6 | tudo da varredura acima | `PW-AGT-04` |
| 7 | **asserção deletada por um healer anterior** | `PW-AGT-05` |
| 8 | `test.skip` novo sem issue associada | `PW-STR-05` |
| 9 | as specs `.md` estão versionadas junto dos testes | `PW-AGT-05` |
| 10 | as definições de `init-agents` foram regeradas após atualizar o Playwright | `PW-AGT-02` |

O item 7 é o risco central: **a forma mais fácil de fazer um teste passar é remover o que
ele afirmava.** Um healer sem a intenção declarada (a spec) "conserta" apagando. Compare o
diff do teste com a spec correspondente.

O item 9 é o que torna o 7 **detectável** — sem spec versionada, não há contra o que comparar.

E se o healer conserta o **mesmo** teste a cada release, o achado é sobre a **aplicação**:
locator instável significa markup sem semântica estável, e a correção é dar papel e nome
acessível ao componente (`PW-LOC-01`).

---

## Relacionados

- `sondas.md` — o que rodar antes
- `antipadroes.md` — a grade completa, com satélite por ID
- [[Playwright - Agents, CLI e MCP]] § 2.5 — specs versionadas
