# A ordem da varredura, e o diagnóstico de flaky

1. **Asserção que pode não ter rodado** — `BUN-TEST-06`. É o primeiro porque é o defeito que produz teste verde sem verificação nenhuma: `expect` em `catch`, em callback, dentro de `if`. Procure `catch (` em arquivo de teste e confira se há contagem.
2. **Vazamento de mock e spy** — `BUN-TEST-02`, `BUN-TEST-03`, `BUN-TEST-04`. Todo `spyOn` sem restauração garantida; todo `mock.module` que espera ser desfeito; todo mock que tenta evitar efeito de import fora do preload.
3. **Isolamento e ordem** — `BUN-TEST-09`, `BUN-TEST-10`, `BUN-TEST-23`, `BUN-TEST-24`. Estado entre arquivos, recurso compartilhado sob `--parallel`, concorrência com estado mutável, preload caro.
4. **Espera e tempo** — `await` faltando em `userEvent`, `Bun.sleep`, `useFakeTimers` usado para congelar data (`BUN-TEST-20`), data formatada sem fuso (`BUN-TEST-21`).
5. **Marcas que apagam sinal** — `BUN-TEST-08`, `BUN-TEST-11`. `.only` commitado, `.skip` cobrindo bug conhecido.
6. **Snapshot** — `BUN-TEST-05`, `BUN-TEST-19`. `-u` no CI, `__snapshots__/` ignorado, campo não determinístico sem property matcher.
7. **DOM e componente** — `BUN-TEST-07`, `BUN-TEST-12`, `BUN-TEST-25`, `BUN-TEST-26`. Registro fora do preload, matchers não registrados, preload único, `cleanup` ausente.
8. **Portões de CI** — `BUN-TEST-15`, `BUN-TEST-18`, `BUN-TEST-27`, `BUN-TEST-28`, `BUN-TEST-29`. Versão não pinada, typecheck ausente, limiar decorativo, `junit` sem outfile.
9. **Configuração** — `BUN-TEST-13`, `BUN-TEST-14`, `BUN-TEST-16`, `BUN-TEST-17`, `BUN-TEST-22`. Glob no comando, `seed` sem `randomize`, `retry` com `repeats`, `done`, `onTestFinished` em concorrente.

Se um passo produz achado que invalida o seguinte (o preload não restaura mock; a suíte não passa com `--randomize`), **pare de revisar o interior** e reporte a mudança de forma, não o detalhe.

---

## Passo 3 — Diagnóstico de flaky: sintoma → causa

A árvore completa é a § 5.1 do hub. A leitura das sondas:

| Sintoma | Causa provável | Regra / satélite |
| --- | --- | --- |
| Passa isolado, falha junto, e `--isolate` conserta | estado no global compartilhado: spy, módulo mockado, estado de módulo | `BUN-TEST-02`, `BUN-TEST-03`, `BUN-TEST-09` |
| Falha só com `--parallel` | recurso externo compartilhado entre workers | `BUN-TEST-10` |
| Falha só com `--parallel`, e é setup que sobe algo | hooks de preload envolvem **cada arquivo** | `BUN-TEST-24` |
| Falha dentro do mesmo arquivo, dependendo da ordem | concorrência com estado mutável | `BUN-TEST-23` |
| Componente encontra elemento de outro teste | `document` compartilhado sem limpeza | `BUN-TEST-26` |
| Falha intermitente sem padrão de ordem | `await` faltando, ou timer real | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) § 3 |
| Snapshot falha em toda execução | campo não determinístico | `BUN-TEST-19` |
| Teste "sumiu" do relatório | `.skip`, ou arquivo fora do padrão | `BUN-TEST-11`, `BUN-TEST-01` |
| Todos os testes verdes e exit ≠ 0 | erro não tratado fora de teste | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) § 6 |
| `beforeAll` falhou e o relatório mostra "skip" | erro de hook pula o escopo inteiro | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) § 2 |

**`test.serial` nunca resolve dependência entre arquivos** — ele sequencia dentro do arquivo. Se a correção proposta por alguém (ou por você) for `test.serial` para um teste que depende de outro arquivo, ela está errada: `BUN-TEST-09`.

---

---

## Relacionados

- [Bun - Testes](../../../../knowledge-base/docs/bun-testes.md) § 5.1 — a árvore de flaky completa
- `sondas.md` — o que rodar antes
- `severidade-e-relatorio.md` — classificar e reportar
