---
titulo: Playwright - Autenticação e Isolamento
Link: https://playwright.dev/docs/auth
tags:
  - playwright
  - testing
  - authentication
  - isolation
  - agent-context
source: "Documentação oficial do Playwright — Authentication, Isolation, API testing"
verificado-em: 2026-08-20
---

# Playwright — Autenticação e Isolamento

> Satélite de [Playwright](playwright.md). Cobre por que cada teste começa limpo, e como fazer um teste começar **logado** sem pagar o login toda vez. As duas coisas são o mesmo assunto: isolamento é o default, e autenticação é a exceção deliberada a ele.
>
> **A conta que motiva a nota.** Login por UI custa de 1 a 3 s. Numa suíte de 200 testes isso é entre 3 e 10 minutos de CI gastos reencenando um fluxo que tem teste próprio. O padrão desta nota reduz isso a uma execução.

---

## 1. Isolamento — o default

Um `BrowserContext` é um perfil isolado, equivalente a uma janela anônima: cookies, `localStorage`, cache e permissões próprios. A fonte: eles são *"rápidos e baratos de criar, e completamente isolados"*.

**Cada teste recebe um contexto novo e uma página nova.** Não é otimização — é o que sustenta três coisas:

| Consequência | Por quê |
| --- | --- |
| falha não propaga | um teste quebrado não contamina o próximo |
| depuração é possível | rodar um teste sozinho reproduz o mesmo estado |
| paralelismo e shard funcionam | a ordem deixa de importar |

Vários contextos num teste — para testar interação entre usuários:

```ts
test('admin vê a mensagem do usuário', async ({ browser }) => {
  const ctxAdmin = await browser.newContext({ storageState: 'playwright/.auth/admin.json' });
  const ctxUser  = await browser.newContext({ storageState: 'playwright/.auth/user.json' });

  const admin = await ctxAdmin.newPage();
  const user  = await ctxUser.newPage();

  await user.goto('/chat');
  await user.getByRole('textbox').fill('preciso de ajuda');
  await user.getByRole('button', { name: 'Enviar' }).click();

  await admin.goto('/chat/atendimento');
  await expect(admin.getByText('preciso de ajuda')).toBeVisible();

  await ctxAdmin.close();
  await ctxUser.close();
});
```

Dois papéis no mesmo teste exigem **dois contextos**. `test.use({ storageState })` aplica-se ao arquivo inteiro e só admite um estado — não há como ter dois papéis por essa via (`PW-AUTH-04`).

---

## 2. O padrão base — logar uma vez, reusar `storageState`

### 2.1 O setup

```ts
// tests/auth.setup.ts
import { test as setup, expect } from '@playwright/test';
import path from 'node:path';

const authFile = path.join(__dirname, '../playwright/.auth/user.json');

setup('autenticar', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('E-mail').fill(process.env.TEST_USER!);
  await page.getByLabel('Senha').fill(process.env.TEST_PASSWORD!);
  await page.getByRole('button', { name: 'Entrar' }).click();

  // ancorar num estado observável, não numa URL qualquer
  await expect(page.getByRole('heading', { name: 'Painel' })).toBeVisible();

  await page.context().storageState({ path: authFile });
});
```

A asserção antes de salvar não é decorativa: sem ela, um login que falhou grava um `storageState` vazio, e **todos** os testes falham depois com mensagens sobre a tela de login — a causa fica a um arquivo de distância do sintoma.

### 2.2 O config

```ts
projects: [
  { name: 'setup', testMatch: /.*\.setup\.ts/ },
  {
    name: 'chromium',
    use: { ...devices['Desktop Chrome'], storageState: 'playwright/.auth/user.json' },
    dependencies: ['setup'],
  },
],
```

Agora todo teste do project `chromium` começa autenticado, sem uma linha de login.

### 2.3 O `.gitignore` — não opcional

```gitignore
playwright/.auth
```

A fonte é explícita: o arquivo *"pode conter cookies e headers sensíveis que poderiam ser usados para se passar por você ou pela sua conta de teste"*. É credencial de sessão viva em texto (`PW-AUTH-02`).

Duas consequências que costumam passar:

- **Em CI, o arquivo é gerado a cada execução** pelo setup project — não é artefato a versionar nem a cachear.
- **`upload-artifact` do relatório HTML não deve alcançá-lo.** O `playwright-report` não o inclui, mas um upload de `test-results/` inteiro com `outputDir` mal escolhido pode. Ver [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) § 6.

### 2.4 A pegadinha do UI mode

**Setup project não roda automaticamente em `--ui`**, por velocidade. A suíte abre deslogada na primeira vez, e isso parece defeito de autenticação. O procedimento da fonte: habilitar o filtro do project de setup, rodar `auth.setup.ts` pelo triângulo, desabilitar o filtro de novo.

---

## 3. Uma conta por worker — quando o teste muda estado do servidor

O padrão da § 2 pressupõe testes que **leem**. Se os testes escrevem — criam pedido, mudam configuração, consomem saldo — uma conta compartilhada entre workers paralelos produz interferência, e a falha depende de qual worker chegou primeiro.

```ts
// playwright/fixtures.ts
import { test as base } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

export const test = base.extend<{}, { workerStorageState: string }>({
  // sobrescreve a opção storageState com o valor calculado por worker
  storageState: ({ workerStorageState }, use) => use(workerStorageState),

  workerStorageState: [async ({ browser }, use) => {
    const id = test.info().parallelIndex;
    const arquivo = path.resolve(test.info().project.outputDir, `.auth/${id}.json`);

    if (fs.existsSync(arquivo)) {
      await use(arquivo);
      return;
    }

    const page = await browser.newPage({ storageState: undefined });
    const conta = await alocarConta(id);

    await page.goto('/login');
    await page.getByLabel('E-mail').fill(conta.email);
    await page.getByLabel('Senha').fill(conta.senha);
    await page.getByRole('button', { name: 'Entrar' }).click();
    await page.waitForURL('/painel');

    await page.context().storageState({ path: arquivo });
    await page.close();
    await use(arquivo);
  }, { scope: 'worker' }],
});

export { expect } from '@playwright/test';
```

Três detalhes que fazem isso funcionar:

- **`parallelIndex`, não `workerIndex`.** `workerIndex` cresce indefinidamente conforme workers são substituídos após falha; `parallelIndex` fica no intervalo `[0, workers)`. Usar o primeiro cria uma conta nova a cada retry.
- **`newPage({ storageState: undefined })`** — sem isso a fixture herdaria o estado que ela mesma está tentando produzir.
- **O cache por arquivo** faz o login acontecer uma vez por worker, não uma vez por teste.

(`PW-AUTH-03`)

---

## 4. Autenticar por API

Quando a aplicação permite login por HTTP, isto é mais rápido e mais estável que qualquer fluxo de UI:

```ts
setup('autenticar', async ({ request }) => {
  await request.post('/api/sessao', {
    data: { email: process.env.TEST_USER, senha: process.env.TEST_PASSWORD },
  });
  await request.storageState({ path: authFile });
});
```

**`storageState` é interoperável entre `APIRequestContext` e `BrowserContext`** — o estado gravado por uma chamada HTTP serve para abrir o browser logado, e vice-versa.

A ressalva: isso pula o fluxo de login, então o fluxo de login precisa de teste próprio. É a divisão certa — **um** teste exercita o login, os outros 199 o pressupõem.

---

## 5. Vários papéis

```ts
// tests/auth.setup.ts
const adminFile = 'playwright/.auth/admin.json';
setup('autenticar como admin', async ({ page }) => {
  // … login …
  await page.context().storageState({ path: adminFile });
});

const userFile = 'playwright/.auth/user.json';
setup('autenticar como operador', async ({ page }) => {
  // … login …
  await page.context().storageState({ path: userFile });
});
```

Por arquivo de teste:

```ts
test.use({ storageState: 'playwright/.auth/admin.json' });

test('admin acessa configurações', async ({ page }) => { … });
```

Por project — melhor quando a **mesma** suíte deve rodar sob papéis diferentes:

```ts
projects: [
  { name: 'admin',    use: { storageState: 'playwright/.auth/admin.json' }, dependencies: ['setup'] },
  { name: 'operador', use: { storageState: 'playwright/.auth/user.json' },  dependencies: ['setup'] },
],
```

Por fixture — quando o teste precisa dos dois ao mesmo tempo:

```ts
export const test = base.extend<{ adminPage: Page; userPage: Page }>({
  adminPage: async ({ browser }, use) => {
    const ctx = await browser.newContext({ storageState: 'playwright/.auth/admin.json' });
    await use(await ctx.newPage());
    await ctx.close();
  },
  userPage: async ({ browser }, use) => {
    const ctx = await browser.newContext({ storageState: 'playwright/.auth/user.json' });
    await use(await ctx.newPage());
    await ctx.close();
  },
});
```

> **Ponte de autorização.** Testar que o operador **não** acessa a tela do admin é teste de autorização, e o critério do que verificar (403 × 404, vazamento por resposta, escalonamento horizontal) é de [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) e [NIST RBAC - ANSI INCITS 359](nist-rbac-ansi-incits-359.md). O Playwright é o instrumento; o que constitui um achado é lá.

---

## 6. Testar sem autenticação

```ts
test.use({ storageState: { cookies: [], origins: [] } });

test('visitante é redirecionado para o login', async ({ page }) => {
  await page.goto('/painel');
  await expect(page).toHaveURL(/\/login/);
});
```

Zerar explicitamente é necessário porque o `storageState` do project continua valendo. Um teste "de visitante" num project autenticado, sem esta linha, verifica o contrário do que pretende (`PW-AUTH-05`).

---

## 7. `sessionStorage`

`storageState` cobre cookies e `localStorage`, **não** `sessionStorage`. Se a aplicação guarda algo essencial ali:

```ts
// salvar
const session = await page.evaluate(() => JSON.stringify(sessionStorage));
fs.writeFileSync('playwright/.auth/session.json', session, 'utf-8');

// restaurar
const session = JSON.parse(fs.readFileSync('playwright/.auth/session.json', 'utf-8'));
await context.addInitScript(storage => {
  if (window.location.hostname === 'exemplo.com')
    for (const [k, v] of Object.entries(storage))
      window.sessionStorage.setItem(k, v as string);
}, session);
```

> **Nota de verificação.** As notas de release da 1.61 anunciam `page.localStorage` / `page.sessionStorage`, mas esses acessores **não constam** da referência de API de `Page`. Esta doc segue a referência, e o caminho acima — `addInitScript` + `evaluate` — é o verificado. Ver as notas de verificação de [Playwright](playwright.md).
>
> E vale dizer: se o token de sessão está em `sessionStorage`, isso é uma decisão de segurança discutível antes de ser um problema de teste — ver [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) e [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md).

---

## 8. Regras — `PW-AUTH-01` a `PW-AUTH-06`

| ID | Regra |
| --- | --- |
| `PW-AUTH-01` | Login **MUST** acontecer uma vez em setup project e ser reusado por `storageState`. Login por UI em `beforeEach` **NEVER**. |
| `PW-AUTH-02` | O diretório de `storageState` **MUST** estar no `.gitignore`. Ele contém credencial de sessão viva. |
| `PW-AUTH-03` | Teste que altera estado de servidor **MUST** usar uma conta por worker, via fixture worker-scoped indexada por `parallelIndex`. |
| `PW-AUTH-04` | Dois papéis no mesmo teste **MUST** usar dois `BrowserContext`. Dois `test.use({ storageState })` **NEVER** — só o último vale. |
| `PW-AUTH-05` | Teste de estado não autenticado **MUST** zerar o estado com `test.use({ storageState: { cookies: [], origins: [] } })`. |
| `PW-AUTH-06` | O setup de autenticação **MUST** afirmar o sucesso do login antes de gravar o `storageState`. † |

---

## 9. Antipadrões

### 9.1 Login em `beforeEach`

```ts
// ✗ paga 2 s por teste, e reencena um fluxo que já tem teste próprio
test.beforeEach(async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('E-mail').fill('a@b.com');
  await page.getByLabel('Senha').fill('123');
  await page.getByRole('button', { name: 'Entrar' }).click();
});
```

(`PW-AUTH-01`)

### 9.2 `storageState` versionado

```gitignore
# ✗ ausência de playwright/.auth no .gitignore
```

Cookie de sessão no histórico do git, recuperável por qualquer pessoa com acesso ao repositório — inclusive depois de "apagado" (`PW-AUTH-02`).

### 9.3 Credencial hardcoded no setup

```ts
// ✗
await page.getByLabel('Senha').fill('Senha123!');
```

Use variável de ambiente validada — [Zod - Validação de Ambiente](zod-validacao-de-ambiente.md).

### 9.4 Uma conta para todos os workers em suíte que escreve

```ts
// ✗ dois workers alterando a mesma configuração
projects: [{ name: 'chromium', use: { storageState: 'playwright/.auth/user.json' } }]
```

Falha dependente de ordem, que aparece só sob paralelismo e desaparece com `--workers=1` — o flake mais caro de diagnosticar (`PW-AUTH-03`).

### 9.5 `workerIndex` no lugar de `parallelIndex`

```ts
// ✗ cria conta nova a cada worker substituído após falha
const id = test.info().workerIndex;
```

Ver § 3.

### 9.6 Setup que grava estado sem verificar o login

```ts
// ✗
await page.getByRole('button', { name: 'Entrar' }).click();
await page.context().storageState({ path: authFile });   // grava mesmo se falhou
```

Toda a suíte falha depois, apontando para a tela de login em vez do setup (`PW-AUTH-06`).

### 9.7 Teste de visitante em project autenticado

```ts
// ✗ o storageState do project continua valendo
test('visitante vai para o login', async ({ page }) => {
  await page.goto('/painel');
  await expect(page).toHaveURL(/\/login/);      // falha: está logado
});
```

(`PW-AUTH-05`)

---

## Relacionados

- [Playwright](playwright.md) — o hub; a § 5.3 decide entre fixture e setup project
- [Playwright - Fixtures](playwright-fixtures.md) — o mecanismo de escopo de worker e de sobrescrita de opção
- [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) — `dependencies`, `teardown`, e a pegadinha do UI mode
- [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — `APIRequestContext` e a diferença de cookies
- [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) · [NIST RBAC - ANSI INCITS 359](nist-rbac-ansi-incits-359.md) — o que constitui achado num teste de papel
- [RFC 6265 - Cookies HTTP](rfc-6265-cookies-http.md) — `SameSite`, `Domain`, prefixos, e por que a sessão não persiste
- [OAuth 2.0 for Browser-Based Applications](oauth-2-0-for-browser-based-applications.md) · [RFC 9700 - OAuth 2.0 Security BCP](rfc-9700-oauth-2-0-security-bcp.md) — onde o token deveria estar
- [WorkOS - AuthKit](workos-authkit.md) · [WorkOS - RBAC](workos-rbac.md) — a implementação concreta no stack
- · [Zod - Validação de Ambiente](zod-validacao-de-ambiente.md)

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Authentication](https://playwright.dev/docs/auth) — os três padrões, `parallelIndex`, papéis, `sessionStorage`, o aviso de segurança e a nota de UI mode
- [Isolation](https://playwright.dev/docs/browser-contexts) — o que é contexto e por que o isolamento importa
- [API testing](https://playwright.dev/docs/api-testing) — interoperabilidade de `storageState`
- [Page (API)](https://playwright.dev/docs/api/class-page) — a checagem que refuta `page.sessionStorage`
