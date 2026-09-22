---
Link: https://playwright.dev/docs/test-parallel
tags:
 - playwright
 - testing
 - ci
 - parallelism
 - sharding
 - agent-context
source: "Documentação oficial do Playwright — Parallelism, Retries, Sharding, Timeouts, Reporters, Annotations, Command line, Setting up CI"
verificado-em: 2026-08-20
---

# Playwright — Execução, Retries e CI

> Satélite de [Playwright](playwright.md). Cobre como a suíte roda: workers, paralelismo, shard, retry, reporters, anotações e o pipeline. É o satélite que decide se uma suíte de 400 testes leva 4 minutos ou 40.

---

## 1. Workers e paralelismo

### 1.1 O modelo

Cada worker é um **processo do SO** com o seu próprio browser. Um worker que falha é descartado e substituído — é o que garante ambiente limpo depois de uma falha.

O default:

- **arquivos** rodam em paralelo;
- **testes dentro de um arquivo** rodam em ordem, no mesmo worker.

```ts
workers: process.env.CI ? 2 : undefined, // undefined = metade dos núcleos lógicos
```

```bash
npx playwright test --workers=4
npx playwright test -j 50%
```

### 1.2 `fullyParallel`

```ts
fullyParallel: true
```

Passa a paralelizar **também dentro** do arquivo. Duas consequências, e a segunda é a que costuma surpreender:

1. A suíte fica mais rápida.
2. **`--shard` passa a distribuir por teste em vez de por arquivo.** Sem `fullyParallel`, o shard reparte arquivos inteiros, e a fonte avisa que "a quantidade de testes por arquivo pode influenciar muito" a distribuição — um arquivo com 60 testes e outro com 2 produzem shards de duração muito diferente (`PW-RUN-01`).

Por arquivo:

```ts
test.describe.configure({ mode: 'parallel' });
```

### 1.3 Modo serial

```ts
test.describe.configure({ mode: 'serial' });
```

| Modo | Comportamento |
| --- | --- |
| `'parallel'` | testes em workers separados |
| `'serial'` | em ordem; se um falha, os seguintes são **pulados** |
| `'default'` | em ordem, mesmo worker, sem pular |

`'serial'` é a admissão de dependência de ordem. Legítimo quando o custo de recriar o estado é proibitivo (um wizard longo, uma sessão de pagamento). Ilegítimo como conserto de flake — aí ele só esconde o acoplamento (`PW-CORE-06`).

> **`test.describe.serial` e `test.describe.parallel` estão marcados como descontinuados** na referência de API, em favor de `test.describe.configure`. A página-guia de retries ainda os usa em exemplo — é divergência interna da fonte. Use `configure` (`PW-RUN-05`).

### 1.4 Isolar dado entre workers

```ts
test('cria pedido', async ({ page }, testInfo) => {
 const ref = `PED-${testInfo.workerIndex}-${testInfo.testId}`;
 // …
});
```

`testInfo.workerIndex`, `testInfo.parallelIndex`, `testInfo.testId` e `testInfo.outputPath` são as ferramentas. Para conta de usuário, o padrão é `parallelIndex` ([Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 3).

---

## 2. Selecionar o que roda

```bash
npx playwright test tests/pedidos.spec.ts
npx playwright test tests/pedidos.spec.ts:42
npx playwright test --grep @smoke
npx playwright test --grep-invert @lento
npx playwright test --grep "@smoke|@critico"
npx playwright test --grep "(?=.*@smoke)(?=.*@critico)" # AND
npx playwright test --project=chromium --project=firefox
npx playwright test --last-failed
npx playwright test --only-changed=origin/main
npx playwright test --repeat-each=20 --grep @flaky # caçar flake
npx playwright test --list
```

`--last-failed` e `--only-changed` são os dois que mais encurtam o laço local. `--repeat-each` é o instrumento certo para confirmar que um flake foi resolvido — 20 execuções verdes valem mais que uma.

Tags:

```ts
test('login funciona', { tag: '@smoke' }, async ({ page }) => { … });
test.describe('relatórios', { tag: ['@lento', '@relatorio'] }, => { … });
```

---

## 3. Anotações

```ts
test.skip; // não roda
test.skip(browserName === 'webkit', 'bug #1234'); // condicional, com motivo
test.fixme; // não roda; intenção de consertar
test.fail; // RODA, e exige que falhe
test.slow; // triplica o timeout
test.only; // foca (perigoso — ver PW-CFG-01)
```

> **`fail` e `fixme` fazem o oposto do que o nome sugere.** `test.fail` **executa** o teste e o considera bem-sucedido **se ele falhar** — é o marcador de bug conhecido e reproduzível, e ele avisa quando o bug for corrigido. `test.fixme` **não executa**. Trocar um pelo outro produz ou um teste que não roda quando devia, ou um que falha por passar (`PW-RUN-04`).

Anotação customizada:

```ts
test('exporta relatório', {
 annotation: { type: 'issue', description: 'https://github.com/org/repo/issues/42' },
}, async ({ page }) => { … });
```

Em runtime:

```ts
test.info.annotations.push({ type: 'versão do browser', description: browser.version });
```

**`skip` e `fixme` sem motivo textual são dívida anônima** — em seis meses ninguém sabe se ainda se aplica (`PW-STR-05`).

---

## 4. Retries

```ts
retries: process.env.CI ? 2 : 0,
retryStrategy: 'immediate', // ou 'isolated' — novo na 1.62
```

```bash
npx playwright test --retries=3
```

Semântica: o worker e o browser são **descartados**, um novo sobe, e o teste roda do zero.

Classificação no relatório:

| Status | Significa |
| --- | --- |
| **passed** | passou de primeira |
| **flaky** | falhou e passou numa retry |
| **failed** | falhou em todas |

```ts
test('meu teste', async ({ page }, testInfo) => {
 if (testInfo.retry) await limparCacheDoServidor;
});
```

Em modo serial com retries, **o grupo inteiro** é retentado.

**`failOnFlakyTests: true`** é o mecanismo que impede a suíte de apodrecer: sem ele, "flaky" é verde, e uma suíte com 30 flaky passa no CI todos os dias enquanto ninguém conserta nada.

> **Retry não conserta flake** (`PW-RUN-03`). Ele existe para absorver instabilidade residual — uma rede que oscilou, um container que demorou a subir. Usá-lo como resposta a um teste que falha 30% das vezes converte um defeito diagnosticável num custo permanente de CI. A árvore de diagnóstico é a § 5.2 do hub.

---

## 5. Reporters

| Reporter | Para quê |
| --- | --- |
| `list` | default local — uma linha por teste |
| `dot` | default em CI — um caractere por teste |
| `line` | progresso compacto |
| `html` | relatório navegável, com trace anexado |
| `blob` | formato intermediário, para unir shards |
| `json`, `junit` | integração com ferramenta externa |
| `github` | anotações no PR do GitHub Actions |
| `null` | nada |

```ts
reporter: process.env.CI ? [['blob'], ['github']] : `'html', { open: 'never' }`,
```

```bash
npx playwright show-report
npx playwright show-report meu-relatorio
```

Opções do html: `open` (`'always'`/`'never'`/`'on-failure'`), `outputFolder` (default `playwright-report`), `host`, `port` (default 9323), `attachmentsBaseURL`.

Reporter customizado implementa a interface:

```ts
import type { Reporter, TestCase, TestResult } from '@playwright/test/reporter';

class MeuReporter implements Reporter {
 onTestEnd(test: TestCase, result: TestResult) {
 if (result.status === 'failed') enviarParaObservabilidade(test, result);
 }
}
export default MeuReporter;
```

---

## 6. Sharding e CI

### 6.1 Shard

```bash
npx playwright test --shard=1/4
```

Com `blob` + `merge-reports` os shards viram um relatório só:

```bash
npx playwright merge-reports --reporter html./all-blob-reports
```

Os blobs saem em `blob-report`, nomeados `report-<hash>-<n>.zip` — sem colisão entre shards.

### 6.2 GitHub Actions — o workflow base

Este é o arquivo que a fonte gera:

```yaml
name: Playwright Tests
on:
 push:
 branches: [ main, master ]
 pull_request:
 branches: [ main, master ]
jobs:
 test:
 timeout-minutes: 60
 runs-on: ubuntu-latest
 steps:
 - uses: actions/checkout@v6
 - uses: actions/setup-node@v6
 with:
 node-version: lts/*
 - name: Install dependencies
 run: npm ci
 - name: Install Playwright Browsers
 run: npx playwright install --with-deps
 - name: Run Playwright tests
 run: npx playwright test
 - uses: actions/upload-artifact@v4
 if: ${{ !cancelled }}
 with:
 name: playwright-report
 path: playwright-report/
 retention-days: 30
```

Quatro ajustes que ele **não** traz e que valem:

1. **Instalar só o que se usa** — `npx playwright install chromium --with-deps` em vez dos três browsers. É a recomendação da própria página de boas práticas, e economiza minutos por job.
2. **Shard** por matriz, com job de merge.
3. **`fail-fast: false`** na matriz, para que um shard vermelho não cancele os outros e esconda os demais achados.
4. **Não subir `test-results/` inteiro** se o `outputDir` puder conter `storageState` — ver [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) § 2.3.

Com shard:

```yaml
jobs:
 test:
 strategy:
 fail-fast: false
 matrix:
 shard: [1, 2, 3, 4]
 steps:
 # …
 - run: npx playwright test --shard=${{ matrix.shard }}/4
 - uses: actions/upload-artifact@v4
 if: ${{ !cancelled }}
 with:
 name: blob-report-${{ matrix.shard }}
 path: blob-report/
 retention-days: 1

 merge:
 if: ${{ !cancelled }}
 needs: [test]
 runs-on: ubuntu-latest
 steps:
 # … download-artifact com pattern blob-report-* …
 - run: npx playwright merge-reports --reporter html./all-blob-reports
```

### 6.3 A checklist de CI

| Item | Por quê |
| --- | --- |
| `forbidOnly: !!process.env.CI` | um `test.only` esquecido faz o CI verde rodando um teste |
| `trace: 'on-first-retry'` | sem trace, falha de CI é adivinhação |
| Linux como runner | é o mais barato, e é a plataforma da referência de screenshot |
| só os browsers usados | `install chromium --with-deps` |
| `failOnFlakyTests` | impede que flaky seja tratado como verde |
| `blob` + `merge-reports` | um relatório por execução, não N |
| `fail-fast: false` | ver todos os achados de uma vez |
| `@typescript-eslint/no-floating-promises` | a única defesa automática contra asserção sem `await` |

A última é recomendação explícita da página de boas práticas, e é o único mecanismo que pega `PW-CORE-04`.

---

## 7. Timeout da execução

```ts
timeout: 30_000, // por teste
globalTimeout: 3_600_000, // a suíte inteira
maxFailures: process.env.CI ? 10 : 0,
```

`maxFailures` aborta depois de N falhas — útil quando o app está fora do ar e não há sentido em rodar 400 testes para descobrir isso. `globalTimeout` é a rede de segurança contra job travado.

A tabela completa de timeouts está na § 0 de [Playwright](playwright.md), e a árvore de "qual mexer" na § 5.5.

---

## 8. Regras — `PW-RUN-01` a `PW-RUN-07`

| ID | Regra |
| --- | --- |
| `PW-RUN-01` | `fullyParallel: true` **MUST** estar ligado para que `--shard` distribua por teste. Sem ele o shard distribui por **arquivo**, e a divisão fica desigual. |
| `PW-RUN-02` | `retries` > 0 **MUST** vir acompanhado de `trace` que capture a retry (`'on-first-retry'` no mínimo). |
| `PW-RUN-03` | Teste flaky **NEVER** é considerado resolvido por aumento de `retries`. |
| `PW-RUN-04` | `test.fail` e `test.fixme` **NEVER** são sinônimos: `fail` **roda** o teste e exige que ele falhe; `fixme` **não roda**. |
| `PW-RUN-05` | `test.describe.serial` e `test.describe.parallel` **NEVER** em código novo — a fonte os marca como descontinuados em favor de `test.describe.configure`. |
| `PW-RUN-06` | Execução com `--shard` **MUST** publicar `blob` e ser unida por `merge-reports`. † |
| `PW-RUN-07` | `mode: 'serial'` **MUST** ter o motivo escrito — ele declara dependência de ordem, e não é conserto de flake. † |

---

## 9. Antipadrões

### 9.1 Subir `retries` para calar um flake

```ts
// ✗
retries: 5
```

Cinco execuções de um teste ruim custam mais que uma hora consertando (`PW-RUN-03`).

### 9.2 `--shard` sem `fullyParallel`

```yaml
# ✗ shard 1 leva 8 min, shard 4 leva 40 s
- run: npx playwright test --shard=${{ matrix.shard }}/4
```

Ver § 1.2 (`PW-RUN-01`).

### 9.3 `mode: 'serial'` como conserto

```ts
// ✗ esconde o acoplamento em vez de removê-lo
test.describe.configure({ mode: 'serial' });
```

(`PW-RUN-07`)

### 9.4 `test.fail` no lugar de `test.fixme`

```ts
// ✗ o teste roda, passa, e é reportado como falha ("expected to fail")
test.fail;
test('feature que ainda não existe', async ({ page }) => { … });
```

(`PW-RUN-04`)

### 9.5 `skip` sem motivo

```ts
// ✗
test.skip;
```

Dívida anônima. Em seis meses, ninguém remove porque ninguém sabe se ainda vale.

### 9.6 Instalar os três browsers em CI para rodar um

```yaml
# ✗ minutos de download por job
- run: npx playwright install --with-deps
```

Se o config só tem `chromium`, instale `chromium`.

### 9.7 `fail-fast` default na matriz de shard

O primeiro shard vermelho cancela os outros três, e o PR mostra um achado de doze. Ver § 6.2.

### 9.8 Retry sem trace

```ts
// ✗ o teste é retentado e nada é gravado; a falha continua inexplicada
retries: 2,
use: { trace: 'off' },
```

(`PW-RUN-02`)

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.2 diagnostica flake e a § 5.5 decide timeout
- [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) — `workers`, `retries`, `projects`, `webServer`
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — o que fazer com o trace que a retry gravou
- [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) — isolamento de conta por worker
- [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) — por que a referência precisa vir do container do CI
- `Github Actions` · — o pipeline em volta
- — a suíte como portão
- `Monorepo com Bun - estrutura e tooling` — os três runners do monorepo
- `TypeScript` — `no-floating-promises`

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Parallelism](https://playwright.dev/docs/test-parallel) — workers, `fullyParallel`, modos, isolamento por índice
- [Retries](https://playwright.dev/docs/test-retries) — semântica, classificação, `testInfo.retry`, serial
- [Sharding](https://playwright.dev/docs/test-sharding) — `--shard`, blob, `merge-reports`, matriz do GitHub Actions
- [Reporters](https://playwright.dev/docs/test-reporters) — os oito reporters e as opções do html
- [Annotations](https://playwright.dev/docs/test-annotations) — `skip`/`fail`/`fixme`/`slow`, tags, `--grep`
- [Command line](https://playwright.dev/docs/test-cli) — as flags
- [Setting up CI](https://playwright.dev/docs/ci-intro) — o workflow gerado
- [Best Practices](https://playwright.dev/docs/best-practices) — Linux em CI, instalar só o necessário, lint
- [TestConfig (API)](https://playwright.dev/docs/api/class-testconfig) — `retryStrategy`, `failOnFlakyTests`, defaults
- [Test (API)](https://playwright.dev/docs/api/class-test) — a marcação de descontinuado em `describe.serial`/`describe.parallel`
