# A árvore, e a bissecção

> Passos 3 e 4. A árvore completa é a § 5.2 do hub [[Playwright]] — a mais detalhada do vault.

---

## Percorra sem pular

| # | Verifique | Se sim, a causa é | Regra |
| --- | --- | --- | --- |
| 1 | há `waitForTimeout` no teste? | é a causa, não o sintoma | `PW-CORE-05` |
| 2 | alguma asserção lê valor antes de afirmar? | instante congelado | `PW-EXP-01` |
| 3 | espera armada **depois** da ação? | o evento já passou | `PW-ACT-03` |
| 4 | há `waitUntil: 'networkidle'`? | indeterminístico por natureza | `PW-ACT-04` |
| 5 | depende de dado que outro teste criou? | dependência de ordem | `PW-CORE-06` |
| 6 | falha só em CI? | ver `falha-so-em-ci.md` | — |
| 7 | falha só com paralelismo? | estado compartilhado | `PW-AUTH-03` |
| 8 | nada acima | volte ao trace | `PW-DBG-01` |

**O que nunca é a resposta:** subir `retries` (`PW-RUN-03`). Retry absorve instabilidade
**residual** de uma suíte sã; usá-lo contra um teste que falha 30% das vezes converte um
defeito diagnosticável em custo permanente de CI.

---

## Bissecção

Script: `scripts/isolar.sh <arquivo[:linha]> [repeticoes]`.

```bash
bash ~/.claude/skills/playwright-diagnose/scripts/isolar.sh e2e/checkout.spec.ts:52 20
```

| Comando | Se o comportamento mudar, a causa é |
| --- | --- |
| `--repeat-each=20` | confirma que é intermitente e não determinístico |
| `--workers=1` | **estado compartilhado** entre workers (`PW-AUTH-03`) |
| só o caso (`arquivo:linha`) | **dependência de outro teste** (`PW-CORE-06`) |
| `--project=chromium` | específico de browser |
| `--headed` | dependente de headless — raro, mas existe |
| container com a imagem do CI | **paridade de ambiente** (`PW-SNAP-02`) |

> **`--workers=1` diagnostica; ele não conserta.** Configurar `workers: 1` porque a suíte
> passa em série mantém o acoplamento e deixa a suíte N vezes mais lenta. O mesmo vale para
> prefixar arquivos com `001-`, `002-`: isso **codifica** a dependência, e a próxima
> inserção quebra tudo.

---

## Relacionados

- [[Playwright]] § 5.2 — a árvore completa
- `falha-so-em-ci.md` — a ramificação 6
- `conserto-x-anestesico.md` — o que **não** propor
