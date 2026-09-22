# Exemplo trabalhado — auditoria de uma suíte E2E

Suíte de 214 testes, CI verde, time relata que "às vezes falha".

---

## Passo 1 — as sondas

```
$ bash scripts/sondas.sh e2e

== S1. Versão e piso de Node
   node v20.11.0
   package.json:31:  "@playwright/test": "^1.62.1"
   package.json:32:  "playwright": "^1.58.0"          ← fora de lockstep
== S2. test.only sobrando, e o portão
   e2e/checkout.spec.ts:18:  test.only('finaliza compra', ...)
   -- forbidOnly no config: AUSENTE
== S3. Trace existe?
   playwright.config.ts:14:  trace: 'off'
== S4. Espera por tempo
   e2e/checkout.spec.ts:22,31,44   waitForTimeout
   e2e/login.spec.ts:9             waitUntil: 'networkidle'
== S6. Asserção sem await
   AUSENTE — bloqueante
== S8. storageState versionado
   playwright.config.ts:22: storageState: '.auth/user.json'
   -- .gitignore cobre o arquivo de sessão? NÃO
```

**Três paradas dispararam**: S2 (`.only` sem portão), S3 (`trace: 'off'`) e S8 (sessão
versionada). E S1 mostra Node 20 com Playwright 1.62 — que **não roda**.

## Passo 2 — o relatório

```markdown
## Auditoria de suíte E2E — loja

### Segurança (1) — prazo diferente do resto

`PW-AUTH-02` — playwright.config.ts:22 + .gitignore
S8: storageState grava .auth/user.json, que não está no .gitignore. Se já foi commitado,
há credencial de sessão viva no histórico do git.
Correção: adicionar .auth/ ao .gitignore, rotacionar a sessão, e reescrever o histórico se
  o arquivo já entrou. O teste não muda.
Ver [[Playwright - Autenticação e Isolamento]].

### Bloqueante (3)

`PW-CFG-01` — playwright.config.ts (ausência) + e2e/checkout.spec.ts:18
S2: test.only em checkout.spec.ts:18 e forbidOnly ausente. O CI está verde rodando
  1 teste de 214.
Correção: forbidOnly: !!process.env.CI no config, e remover o .only.
Ver [[Playwright - Configuração e Projects]].

`PW-CFG-02` — playwright.config.ts:14
S3: trace: 'off'. Toda falha de CI é adivinhação, e a auditoria de flake não pode começar.
Correção: trace: 'on-first-retry'.
Ver [[Playwright - Debug e Trace]].

`PW-CORE-03` — package.json:31-32
S1: @playwright/test 1.62.1 com playwright 1.58.0, sob Node 20. Os dois pacotes precisam
  estar em lockstep, e 1.62 exige Node ≥ 22.
Correção: alinhar as duas versões e subir o Node do CI.
Ver [[Playwright]] § 0.

### Alta (2)

`PW-CORE-05` — e2e/checkout.spec.ts:22,31,44
S4: três waitForTimeout. É a causa nº 1 de flake, e custa tempo em toda execução.
Correção: trocar por asserção web-first, que reespera. O arquivo login.spec.ts:14 já usa
  o padrão certo — estenda-o.
Ver [[Playwright - Ações e Auto-waiting]].

`PW-ACT-04` — e2e/login.spec.ts:9
S4: waitUntil: 'networkidle' é indeterminístico por natureza.
Correção: esperar a condição da UI que a navegação produz.
Ver [[Playwright - Ações e Auto-waiting]].

### Não é achado (registrado)

- e2e/relatorios.spec.ts usa getByTestId com comentário registrando a dívida: é solução
  honesta (PW-LOC-04), não achado.
- "A suíte tem E2E demais": só vira achado com argumento de nível — e o ID seria TS-CORE-02,
  numa auditoria de estratégia ([[teste-review]]).

### Não verificado

- S5 (expect(await …)): a varredura rodou, mas 6 arquivos usam helper próprio que envolve
  expect; a checagem por grep não os cobre. Ficou aberta.
- S7: o workflow de CI não está neste repositório.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| a credencial saiu **primeiro e separada** | `severidade-e-relatorio.md` § *Fechar*, item 5 |
| três paradas dispararam e vieram antes do interior | `sondas.md` § *Três paradas obrigatórias* |
| a correção aponta o arquivo que já tem o padrão certo | `severidade-e-relatorio.md` § *Formato* |
| `getByTestId` com dívida **não** virou achado | `severidade-e-relatorio.md` § *O corte* |
| "tem E2E demais" foi devolvido para a skill de estratégia | `TS-CORE-02` |
| o que o grep não cobriu foi declarado | § *Fechar*, item 6 |
