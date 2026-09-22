# Conserto × anestésico, e o formato do achado

---

## Os sete anestésicos

Fazem o vermelho desaparecer sem resolver nada. Se você está propondo um deles, volte à árvore.

| Anestésico | O que esconde | Regra |
| --- | --- | --- |
| `waitForTimeout` | a condição que deveria ser esperada | `PW-CORE-05` |
| `retries` mais alto | um defeito diagnosticável | `PW-RUN-03` |
| `force: true` | um overlay que o usuário também sofre | `PW-ACT-01` |
| `workers: 1` | acoplamento entre testes | § 5.2 do hub |
| `expect.timeout` global maior | regressão de performance | `PW-EXP-04` |
| `test.skip` sem issue | a dívida, agora anônima | `PW-STR-05` |
| remover a asserção que falha | exatamente o que o teste verificava | `PW-AGT-05` |

O último é o mais grave, e é o que um healer automático faz quando não tem a intenção
declarada — [[Playwright - Agents, CLI e MCP]] § 2.5.

---

## Formato do achado

Cinco partes — **a evidência do trace** é o que distingue esta skill de um chute:

```
`ID-DA-REGRA` — arquivo:linha
Sintoma: <como a falha se apresenta, e em que condição>
Evidência: <o que o trace mostra — a aba e a mensagem>
Causa: <uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

```
`PW-ACT-01` — e2e/checkout.spec.ts:52
Sintoma: falha ~1 em 4 execuções em CI, sempre no clique em "Confirmar"; passa local.
Evidência: trace, aba Log da ação click — "element intercepts pointer events";
  Snapshot Before mostra o toast de "item adicionado" ainda na tela, sobre o botão.
Causa: o toast tem 3 s de duração e cobre o botão; em CI o passo anterior termina mais rápido.
Correção: NÃO usar force: true. Aguardar o toast sair antes de clicar —
  await expect(page.getByRole('status')).toBeHidden() — ou corrigir o z-index/posição do toast,
  que é o defeito real: o usuário também não consegue clicar.
Ver [[Playwright - Ações e Auto-waiting]].
```

Regras do formato:

- **ID conferido em `mapa-de-ids.md`**, nunca apelido.
- **Evidência do trace, com a aba.** "Parece timing" não é evidência.
- **Correção que ataca a causa.** Se a causa é defeito de produto, a correção é no produto —
  dizer isso explicitamente é o valor principal desta skill.

---

## Fechar o diagnóstico

1. **Confirme com `--repeat-each=20`.** Vinte verdes; uma não prova nada num flake de 1 em 4.
2. **Se a causa foi defeito de produto**, o teste não muda. Diga isso.
3. **Se foi paridade de ambiente**, o conserto é o pipeline (`PW-SNAP-02`).
4. **Transforme o diagnóstico em portão:** trace ligado (`PW-CFG-02`), flaky não contando como verde, `--repeat-each` no job noturno.
5. **Se o mesmo teste volta a flakear**, a causa raiz não foi encontrada (`TS-PROC-08`).
6. **Declare o que não foi verificado.** "Não verificado" não é "sem achado".
