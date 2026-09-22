# Três coisas que não se assumem de memória

> Contrariam o hábito trazido de Jest e Vitest, e são a fonte da maioria dos erros em código gerado.


Estas contrariam o hábito trazido de Jest e Vitest, e são a fonte da maioria dos erros em código gerado.

**1. Sem flag, todos os arquivos compartilham um `globalThis`.** Não há isolamento por arquivo. "Vazou" não significa "afetou o próximo teste": significa "afetou o resto da suíte". Escreva como se o próximo arquivo fosse ler tudo que você deixou — porque ele vai.

**2. `mock.restore()` não desfaz `mock.module()`.** As três limpezas fazem coisas diferentes, e a tabela está em [[Bun - Testes - Mocks e Tempo]] § 3. `clearAllMocks` preserva a implementação; `resetAllMocks` a remove mas não restaura o original do spy; só `restore` restaura — e nenhuma das três toca mock de módulo.

**3. Concorrência dentro do arquivo compartilha estado.** `test.concurrent` (e a suíte sob `--concurrent`) não isola nada: quem depende de ordem ou de estado mutável precisa ser `test.serial` — `BUN-TEST-23`. E `onTestFinished` não funciona em teste concorrente — `BUN-TEST-22`.

---


---

## Por que estas três, e não outras

As três descrevem **o mesmo tipo de falha**: o teste fica verde e a verificação não aconteceu,
ou aconteceu em outro lugar. Nenhuma delas produz erro, aviso ou tipo errado — por isso não
há como descobri-las lendo o código sem saber que existem.

| A memória de Jest/Vitest diz | No Bun |
| --- | --- |
| cada arquivo tem seu ambiente | um `globalThis` compartilhado por todos, sem flag |
| `restoreAllMocks` desfaz tudo | `mock.restore()` não toca mock de **módulo** (`BUN-TEST-03`) |
| `test.concurrent` isola | não isola nada; estado mutável exige `test.serial` (`BUN-TEST-23`) |
| `useFakeTimers` congela `Date` | não troca o construtor; data é `setSystemTime` (`BUN-TEST-20`) |

## Relacionados

- [[Bun - Testes]] § 2 — o modelo de execução
- [[Bun - Testes - Mocks e Tempo]] § 3 — a tabela das três limpezas
- [[Bun - Testes - Ciclo de Vida e Isolamento]] — escopo, preload, `--isolate`
