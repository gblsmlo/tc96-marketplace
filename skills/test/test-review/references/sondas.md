# As nove sondas — medir a forma antes de julgar

> A forma de uma suíte é **invisível** lendo arquivos: cada teste parece razoável, e o
> conjunto está desequilibrado. Estas nove medem o conjunto.

Script: `scripts/sondas-suite.sh [raiz]` — roda S1, S3–S9 e prepara S2.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-review/scripts/sondas-suite.sh.
```

---

| Sonda | O que mede | O que revela |
| --- | --- | --- |
| **S1. Forma da suíte** | casos por nível (`test(`/`it(` por diretório) | `TS-NIV-04` — massa em E2E é *ice-cream cone*; nenhum E2E é outra coisa |
| **S2. Duração** | tempo de cada nível, separadamente | `TS-SUI-*` — suíte que ninguém roda antes do PR deixou de ser portão |
| **S3. Camada estática** | `strict`, `noUncheckedIndexedAccess`, `no-floating-promises` | `TS-TIPO-08` — a camada mais barata, e frequentemente desligada |
| **S4. O portão fecha?** | `continue-on-error`, `\|\| true`, `exit 0` no workflow | `TS-PROC-03` — passo que roda e não reprova é decorativo |
| **S5. Meta de cobertura** | `coverageThreshold`, `codecov`, `--coverage` | `TS-CORE-05` — meta de cobertura é **achado**, não virtude |
| **S6. Classes de risco** | ocorrência dos cinco estados nos testes | `TS-TIPO-02` — o estado de **erro** é o mais ausente |
| **S7. Atributo não funcional** | `p95`, `k6`, `lighthouse`, `axe` | `TS-TIPO-05` — requisito sem número não é verificado |
| **S8. Escape** | commits de correção × testes adicionados junto | `TS-CORE-06` — defeito de produção sem teste volta |
| **S9. `skip` e dívida** | `.skip(`, `.todo(`, `fixme` | `TS-SUI-11` — `skip` sem motivo é dívida anônima |

S1, S3, S5, S6, S7 e S9 são leitura mecânica. **S2 exige rodar**; **S4 exige ler o CI**;
**S8 exige histórico de git**.

---

## Três paradas obrigatórias

| Se a sonda mostrar… | Pare e reporte antes de continuar |
| --- | --- |
| **S1 com forma invertida** | criticar teste individual vira ruído: a correção é mover asserções para baixo, e ela reescreve boa parte da suíte |
| **S4 com portão que não reprova** | um CI que sai `0` de qualquer forma torna toda discussão de cobertura decorativa — é o achado que mais explica "temos testes e mesmo assim quebra" |
| **S3 com `no-floating-promises` desligada** num projeto com Playwright | **bloqueante**: pode haver qualquer quantidade de asserção que não afirma nada, e nenhuma aparece como falha (`Docs/Playwright.md` `PW-CORE-04`) |

---

## O que a sonda não mede

| Não detectável | Regra | Como achar |
| --- | --- | --- |
| regra de negócio verificada em E2E | `TS-NIV-02` | amostrar 10 arquivos de E2E e ler o que cada asserção afirma |
| mesma lógica em três níveis | `TS-CORE-02` | procurar o mesmo nome de domínio em níveis diferentes |
| mock do que o teste vem provar | `TS-CORE-03` | ler os dublês dos testes de integração |
| fake sem fidelidade declarada | `TS-DUB-03` | ler o fake e perguntar se ele honra o contrato real |
| asserção que não detecta quebra | `TS-SUI-04` | o teste de trinta segundos — é de `test-diagnose` |

**Cobertura não substitui nenhuma dessas.** Um teste que chama a função e não afirma nada
dá cobertura total (`TS-CORE-05`).

---

## Relacionados

- `ordem-da-varredura.md` — o que fazer com o que as sondas apontaram
- `severidade-e-relatorio.md` — como classificar e escrever
- [Teste de Software - Processo e Artefatos](../../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) — os portões
