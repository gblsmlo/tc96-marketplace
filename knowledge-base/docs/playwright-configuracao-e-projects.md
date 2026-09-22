---
Link: https://playwright.dev/docs/test-configuration
tags:
 - playwright
 - testing
 - configuration
 - projects
 - emulation
 - agent-context
source: "Documentação oficial do Playwright — Configuration, Projects, Web server, Emulation, TestConfig/TestOptions"
verificado-em: 2026-08-20
---

# Playwright — Configuração e Projects

> Satélite de [Playwright](playwright.md). Cobre `playwright.config.ts` de ponta a ponta: a separação entre opção de runner e opção de fixture, projects como mecanismo de matriz e de dependência, `webServer`, e emulação.
>
> **A confusão estrutural que esta nota resolve:** o config tem dois andares. Opções de **runner** ficam no topo; opções de **fixture/browser** ficam em `use`. Trocar de andar não dá erro de tipo em vários casos — a opção simplesmente é ignorada (`PW-CORE-07`).

---

## 1. Os dois andares

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
 // ── andar do RUNNER ──────────────────────────────
 testDir: 'e2e',
 fullyParallel: true,
 forbidOnly: !!process.env.CI,
 retries: process.env.CI ? 2 : 0,
 workers: process.env.CI ? 2 : undefined,
 reporter: process.env.CI ? [['blob'], ['github']] : 'html',
 timeout: 30_000,
 expect: { timeout: 5_000 },

 // ── andar da FIXTURE / BROWSER ───────────────────
 use: {
 baseURL: 'http://localhost:3000',
 trace: 'on-first-retry',
 screenshot: 'only-on-failure',
 testIdAttribute: 'data-testid',
 },

 projects: [
 { name: 'chromium', use: {...devices['Desktop Chrome'] } },
 ],

 webServer: {
 command: 'bun run dev',
 url: 'http://localhost:3000',
 reuseExistingServer: !process.env.CI,
 },
});
```

A fonte é explícita: *"test runner options are top-level, do not put them into the `use` section"*.

**O checklist mínimo de um config sério**, e o motivo de cada linha:

| Linha | Por quê |
| --- | --- |
| `forbidOnly: !!process.env.CI` | um `test.only` esquecido faz o CI verde rodando um teste (`PW-CFG-01`) |
| `trace: 'on-first-retry'` | sem trace, toda falha de CI é adivinhação (`PW-CFG-02`) |
| `reuseExistingServer: !process.env.CI` | local reaproveita o dev server; em CI exige o próprio (`PW-CFG-04`) |
| `baseURL` | navegação relativa, e um só lugar para trocar de ambiente (`PW-CFG-05`) |
| `retries` só em CI | retry local esconde flake de quem poderia consertá-lo agora |

---

## 2. `baseURL`

```ts
use: { baseURL: 'http://localhost:3000' }
```

```ts
await page.goto('/login'); // → http://localhost:3000/login
await page.goto('./config'); // relativo à URL atual
await expect(page).toHaveURL('/dashboard'); // também respeita baseURL
```

Afeta `page.goto`, `page.waitForURL`, `expect(page).toHaveURL` e o `request` fixture. Trocar de ambiente passa a ser uma variável:

```ts
use: { baseURL: process.env.BASE_URL ?? 'http://localhost:3000' }
```

URL absoluta espalhada pelos testes é o antipadrão correspondente (`PW-CFG-05`): ela impede rodar a mesma suíte contra staging, e é a razão mais comum de "a suíte só roda na minha máquina".

---

## 3. Projects

Um project é *um grupo lógico de testes com a mesma configuração*. Ele serve para três coisas diferentes, e é útil saber qual está em jogo.

### 3.1 Matriz de browser e device

```ts
projects: [
 { name: 'chromium', use: {...devices['Desktop Chrome'] } },
 { name: 'firefox', use: {...devices['Desktop Firefox'] } },
 { name: 'webkit', use: {...devices['Desktop Safari'] } },
 { name: 'mobile-chrome', use: {...devices['Pixel 5'] } },
 { name: 'mobile-safari', use: {...devices['iPhone 12'] } },
],
```

`npx playwright test --project=firefox` roda um só.

**O spread vem primeiro** (`PW-CFG-06`): `devices[...]` traz `viewport`, `userAgent`, `deviceScaleFactor`, `isMobile`, `hasTouch` num pacote, e o que vier depois sobrescreve. Invertida, a ordem faz o device apagar a opção própria em silêncio:

```ts
// ✗ devices sobrescreve o locale
use: { locale: 'pt-BR',...devices['iPhone 12'] }
// ✓
use: {...devices['iPhone 12'], locale: 'pt-BR' }
```

### 3.2 Dependência — setup e teardown

```ts
projects: [
 {
 name: 'setup',
 testMatch: /.*\.setup\.ts/,
 teardown: 'cleanup',
 },
 { name: 'cleanup', testMatch: /.*\.teardown\.ts/ },
 {
 name: 'chromium',
 use: {...devices['Desktop Chrome'], storageState: 'playwright/.auth/user.json' },
 dependencies: ['setup'],
 },
],
```

Semântica:

- `setup` roda primeiro, inteiro.
- Se `setup` passar, os dependentes rodam — **em paralelo entre si**.
- Se `setup` falhar, os dependentes **não rodam**.
- `cleanup` roda depois de todos os dependentes terminarem.
- Setup aparece no relatório como project próprio e **tem trace** — é a vantagem central sobre `globalSetup` (`PW-CFG-03`).

`--no-deps` roda só os projects selecionados, pulando as dependências. Útil quando o estado já existe, e perigoso quando não.

> **A pegadinha do UI mode:** setup project **não roda automaticamente** em UI mode, por velocidade. A fonte descreve o procedimento manual (habilitar o filtro do project de setup, rodar `auth.setup.ts`, desabilitar de novo). Efeito prático: a suíte abre "deslogada" na primeira vez que se usa `--ui`, e isso parece um bug de autenticação.

### 3.3 Filtro e política por grupo

```ts
projects: [
 { name: 'smoke', testMatch: /.*smoke\.spec\.ts/, retries: 0 },
 { name: 'default', testIgnore: /.*smoke\.spec\.ts/, retries: 2 },
],
```

`retries`, `timeout` e `use` podem ser definidos por project — é o mecanismo para "smoke não tem direito a retry".

---

## 4. `webServer`

```ts
webServer: {
 command: 'bun run dev',
 url: 'http://localhost:3000',
 reuseExistingServer: !process.env.CI,
 timeout: 120_000,
 stdout: 'ignore',
 stderr: 'pipe',
},
```

| Campo | Nota |
| --- | --- |
| `command` | comando de shell que sobe o app |
| `url` | o runner espera até ela responder 2xx, 3xx, 400, 401, 402 ou 403 |
| `port` | **deprecado** — use `url` |
| `reuseExistingServer` | `!process.env.CI` é a forma canônica |
| `timeout` | default 60 000 ms |
| `cwd`, `env` | diretório e variáveis; `env` herda `process.env` e adiciona `PLAYWRIGHT_TEST=1` |
| `stdout` | `'pipe'` ou `'ignore'` — default **`'ignore'`** |
| `stderr` | `'pipe'` ou `'ignore'` — default **`'pipe'`** |
| `gracefulShutdown` | ex.: `{ signal: 'SIGTERM', timeout: 500 }` |
| `name` | prefixo nos logs |
| `ignoreHTTPSErrors` | default `false` |

**`url` aceita 401 e 403 como "está no ar"** — isso é deliberado, e importa: um app que responde 401 na raiz não impede a suíte de começar.

**`PLAYWRIGHT_TEST=1` é injetado no ambiente do servidor.** É o gancho para o app se comportar diferente sob teste — desligar analytics, encurtar debounce, semear dado. Usar isso para desligar validação é o abuso previsível.

Vários servidores:

```ts
webServer: [
 { command: 'bun run dev', url: 'http://localhost:3000', name: 'Frontend', reuseExistingServer: !process.env.CI },
 { command: 'bun run server', url: 'http://localhost:3333', name: 'BFF', reuseExistingServer: !process.env.CI },
],
```

No stack deste vault isso é o caso normal: `apps/web` e `apps/server` sobem juntos (`Monorepo com Bun - estrutura e tooling`). O `name` é o que torna o log legível quando os dois falham.

---

## 5. Emulação

Todas as opções abaixo valem em `use` top-level, em `projects[].use` e em `test.use`.

### 5.1 Viewport e device

```ts
use: {
 viewport: { width: 1280, height: 720 },
 deviceScaleFactor: 2,
 isMobile: true,
 hasTouch: true,
}
```

`devices['iPhone 12']` empacota tudo isso. `page.setViewportSize` muda em runtime.

### 5.2 Locale, timezone, geolocalização

```ts
use: {
 locale: 'pt-BR',
 timezoneId: 'America/Sao_Paulo',
 geolocation: { latitude: -23.5505, longitude: -46.6333 },
 permissions: ['geolocation'],
}
```

**`geolocation` sem `permissions: ['geolocation']` não funciona** — o browser pede permissão e o teste não a concede.

`locale` e `timezoneId` são a forma correta de estabilizar teste que formata data e moeda. A alternativa ruim é o teste aceitar qualquer formato via regex, o que deixa de verificar o formato — que era o ponto.

### 5.3 Aparência e mídia

```ts
use: { colorScheme: 'dark' }
```

```ts
await page.emulateMedia({ colorScheme: 'dark', media: 'print' });
```

Combina com project para cobrir tema claro e escuro na mesma execução:

```ts
projects: [
 { name: 'claro', use: {...devices['Desktop Chrome'], colorScheme: 'light' } },
 { name: 'escuro', use: {...devices['Desktop Chrome'], colorScheme: 'dark' } },
],
```

### 5.4 Permissões e rede

```ts
use: {
 permissions: ['notifications'],
 offline: true,
 javaScriptEnabled: false,
 userAgent: 'meu-agente/1.0',
}
```

```ts
await context.grantPermissions(['notifications'], { origin: 'https://exemplo.com' });
await context.clearPermissions;
await context.setGeolocation({ latitude: -23.55, longitude: -46.63 });
```

As opções de rede (`extraHTTPHeaders`, `httpCredentials`, `proxy`, `ignoreHTTPSErrors`, `serviceWorkers`) estão em [Playwright - Rede e Mocking](playwright-rede-e-mocking.md).

---

## 6. Descoberta e filtro

```ts
testDir: 'e2e',
testMatch: '**/*.spec.ts',
testIgnore: '**/fixtures/**',
```

Os globs de `testMatch`/`testIgnore` também existem por project (§ 3.3). O filtro por linha de comando é outro mecanismo, e cumulativo — ver [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) § 2.

---

## 7. Regras — `PW-CFG-01` a `PW-CFG-07`

| ID | Regra |
| --- | --- |
| `PW-CFG-01` | `forbidOnly: !!process.env.CI` **MUST** estar no config. |
| `PW-CFG-02` | `trace` **MUST** ser no mínimo `'on-first-retry'`. `'off'` em CI **NEVER**. |
| `PW-CFG-03` | Setup que precisa de fixture, trace ou visibilidade no relatório **MUST** ser setup project com `dependencies`, **NEVER** `globalSetup`. |
| `PW-CFG-04` | `webServer.reuseExistingServer` **MUST** ser `!process.env.CI`. |
| `PW-CFG-05` | `baseURL` **MUST** ser configurado, e as navegações **MUST** usar caminho relativo. URL absoluta de ambiente dentro do teste **NEVER**. † |
| `PW-CFG-06` | `...devices[...]` **MUST** vir antes das opções próprias do project — o spread sobrescreve o que estiver acima dele. |
| `PW-CFG-07` | Opção de emulação que depende de permissão (`geolocation`) **MUST** vir acompanhada de `permissions`. |

---

## 8. Antipadrões

### 8.1 Opção de runner dentro de `use`

```ts
// ✗ ignorado em silêncio
use: { retries: 2, timeout: 60_000, workers: 4 }
```

Ver § 1 (`PW-CORE-07`).

### 8.2 URL absoluta no teste

```ts
// ✗
await page.goto('http://localhost:3000/login');
```

Impede rodar contra staging, e duplica a informação de ambiente em cada arquivo (`PW-CFG-05`).

### 8.3 `devices` depois da opção própria

```ts
// ✗ o locale é apagado
use: { locale: 'pt-BR',...devices['iPhone 12'] }
```

Ver § 3.1 (`PW-CFG-06`).

### 8.4 `reuseExistingServer: true` em CI

```ts
// ✗
webServer: { command: 'bun run dev', url: '…', reuseExistingServer: true }
```

Em CI não há servidor para reaproveitar; e se houver — de um job vizinho — a suíte testa a build errada (`PW-CFG-04`).

### 8.5 `retries` alto no config local

```ts
// ✗
retries: 3
```

Retry local esconde o flake de quem estava em posição de consertá-lo, e o transfere para o CI de outra pessoa (`PW-RUN-03`).

### 8.6 Um project por ambiente

```ts
// ✗
projects: [
 { name: 'staging', use: { baseURL: 'https://staging…' } },
 { name: 'prod', use: { baseURL: 'https://prod…' } },
],
```

Project é matriz de **configuração**, não de ambiente: isso põe um alvo de produção a um `--project` de distância do comando errado. Ambiente é variável (`BASE_URL`), e a separação é do pipeline. †

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 0 tem a tabela de timeouts e a § 5.3 a de setup
- [Playwright - Fixtures](playwright-fixtures.md) — option fixtures, consumidas por `projects[].use`
- [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md) — o setup project canônico
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — `workers`, `fullyParallel`, shard, reporters
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — as opções de rede de `use`
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — os valores completos de `trace`, `video` e `screenshot`
- `Monorepo com Bun - estrutura e tooling` — dois `webServer` e onde a suíte vive
- · `Zod - Validação de Ambiente` — como `BASE_URL` deveria chegar

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Configuration](https://playwright.dev/docs/test-configuration) — os dois andares e o config recomendado
- [TestConfig (API)](https://playwright.dev/docs/api/class-testconfig) — defaults exatos de cada campo
- [TestOptions (API)](https://playwright.dev/docs/api/class-testoptions) — o que vive em `use`
- [Projects](https://playwright.dev/docs/test-projects) — matriz, `dependencies`, `teardown`, `--no-deps`
- [Web server](https://playwright.dev/docs/test-webserver) — todos os campos e defaults
- [Emulation](https://playwright.dev/docs/emulation) — devices, viewport, locale, permissões, mídia
