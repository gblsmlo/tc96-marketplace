# As oito sondas — antes de ler o código

> Numa suíte E2E, os piores defeitos são **invisíveis à leitura**: os arquivos parecem
> certos, o CI está verde, e mesmo assim o trace nunca foi gravado, o portão nunca fechou,
> ou a suíte só passa porque um `test.only` está reduzindo tudo a um caso.

```bash
bash ~/.claude/skills/playwright-review/scripts/sondas.sh e2e
```

| Sonda | O que mede | O que revela |
| --- | --- | --- |
| **S1. Versão e piso de Node** | `node -v`, versões de `@playwright/test` e `playwright` | `PW-CORE-01`, `PW-CORE-03` — Node < 22 não roda 1.62; os dois pacotes fora de lockstep é bug de instalação |
| **S2. `test.only` e o portão** | `.only(` na suíte + `forbidOnly` no config | `PW-CFG-01` — um `.only` esquecido faz o CI verde rodando **um** teste |
| **S3. Trace existe?** | `trace:` no config | `PW-CFG-02`, `PW-DBG-05` — `'off'` em CI torna toda falha adivinhação |
| **S4. Espera por tempo** | `waitForTimeout`, `networkidle` | `PW-CORE-05`, `PW-ACT-04` — as duas causas nº 1 de flake |
| **S5. Asserção que congela o instante** | `expect(await ` | `PW-EXP-01` — o defeito mais comum, e o que nenhum linter pega |
| **S6. Asserção sem `await`** | `no-floating-promises` no lint | `PW-CORE-04` — sem essa regra, asserção sem `await` passa **sempre** e ninguém vê |
| **S7. Shard, `fullyParallel`, blob** | config + workflow | `PW-RUN-01`, `PW-RUN-06` — shard sem `fullyParallel` divide por **arquivo**; sem blob produz N relatórios |
| **S8. `storageState` versionado** | config/suíte + `.gitignore` | `PW-AUTH-02` — credencial de sessão viva no histórico do git |

S1, S2, S3, S6, S7 e S8 rodam em segundos. S4 e S5 são varredura sobre a suíte.

---

## Três paradas obrigatórias

| Se a sonda mostrar… | Pare e reporte antes de continuar |
| --- | --- |
| **S2**: `.only` sem `forbidOnly` | a suíte inteira pode estar decorativa — o CI está verde rodando 1 de N |
| **S8**: `storageState` fora do `.gitignore` | **achado de segurança**, não de teste: prazo e canal diferentes |
| **S3**: `trace: 'off'` | a auditoria de flake **para aqui** — sem trace não há diagnóstico, e o primeiro achado é a configuração |

E uma quarta, que é bloqueante mas não interrompe: **S6 sem `no-floating-promises`** — pode
haver qualquer quantidade de asserção que não afirma nada, e nenhuma aparece como falha.

---

## O que a sonda não pega

| Não detectável por grep | ID | Como achar |
| --- | --- | --- |
| regra de negócio verificada em E2E | `TS-CORE-02` | ler o que cada asserção afirma |
| asserção apagada por um healer | `PW-AGT-05` | comparar o diff do teste com a spec `.md` correspondente |
| page object com asserção de negócio | `PW-STR-02` | ler os page objects |
| conta compartilhada entre workers | `PW-AUTH-03` | ler o setup de autenticação |
| teste que faz tudo (falha por seis motivos) | § 8.1 do satélite | ler o título e contar os passos de negócio |

---

## Relacionados

- `ordem-da-varredura.md` — o que fazer com o que as sondas apontaram
- `severidade-e-relatorio.md` — classificar e escrever
- [[Playwright - Configuração e Projects]] · [[Playwright - Debug e Trace]]
