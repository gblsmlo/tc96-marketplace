# Autoverificação antes de entregar

> É a mesma varredura que `playwright-review` aplicaria. Script: `scripts/autoverificar.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-build/scripts/autoverificar.sh e2e/pedidos.spec.ts
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | nenhum `waitForTimeout` | `PW-CORE-05` |
| 2 | toda `expect` sobre `Locator`/`Page` tem `await` | `PW-CORE-04` |
| 3 | nenhuma asserção lê valor antes de afirmar | `PW-EXP-01` |
| 4 | nenhum `.first`/`.nth` calando strict mode | `PW-LOC-02` |
| 5 | nenhum `force: true` sem motivo escrito | `PW-ACT-01` |
| 6 | espera por evento **armada antes** da ação | `PW-ACT-03` |
| 7 | nenhum `waitUntil: 'networkidle'` | `PW-ACT-04` |
| 8 | navegação por caminho relativo, via `baseURL` | `PW-CFG-05` |
| 9 | título descreve o comportamento que deixa de funcionar | `PW-STR-04` |
| 10 | `toPass` tem `timeout` explícito | `PW-EXP-03` |
| 11 | nenhum `test.only` sobrando | `PW-CFG-01` |
| 12 | `skip`/`fixme` com motivo textual | `PW-STR-05` |

O item 2 é o único que **nenhum grep pega bem** — a defesa é
`@typescript-eslint/no-floating-promises` ligada no projeto.

---

## As três verificações que valem mais que as doze

1. **Quebre o código de propósito** e confirme que o teste fica vermelho. Troque um sinal,
 inverta uma condição, remova a chamada. Se nada quebrar, a asserção não existe
 (`TS-TEC-08` em `Docs/Teste de Software - Técnicas de Design de Caso.md`). Trinta segundos, e
 separa teste real de teste decorativo.
2. **`npx playwright test <arquivo> --repeat-each=5`** — cinco execuções verdes valem mais
 que uma.
3. **Rode a suíte inteira.** Um teste novo que suja estado quebra o vizinho, e o sintoma
 aparece em **outro** arquivo.

---

## Fechar

1. **Se o teste precisou de `getByTestId` ou de CSS**, registre a dívida: o achado é sobre o
 componente (`PW-LOC-04`).
2. **Se o teste ficou lento ou frágil**, a pergunta é se ele deveria estar neste nível —
 `teste-design`.
3. **Declare o que não cobriu.** Erro, vazio e carregando são estados distintos e merecem
 caso próprio (`TS-TIPO-02`). "Não coberto" não é "não existe".
