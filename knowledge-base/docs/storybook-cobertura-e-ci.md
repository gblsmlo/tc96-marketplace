---
titulo: Storybook - Cobertura e CI
Link: https://storybook.js.org/docs/writing-tests/test-coverage
tags:
 - storybook
 - testing
 - coverage
 - ci
 - agent-context
source: "Documentação oficial do Storybook — Test coverage, In CI, Vitest addon"
verificado-em: 2026-08-21
---

# Storybook — Cobertura e CI

> Satélite de [Storybook](storybook.md). Cobre o que acontece **depois** de a story virar teste: onde os testes são disparados na UI, como a cobertura é medida (e o que ela mede de verdade), e como o job de CI se monta.
>
> **Fronteira com o satélite irmão.** [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) cobre *escrever* o teste — `play`, `storybook/test`, a11y, a config do addon-vitest, portable stories. Esta nota cobre *operá-lo*. Se a pergunta é "como assevero isto", é lá; se é "por que a cobertura diz 40%" ou "por que o CI não acha o browser", é aqui.

Verificado em storybook.js.org em **2026-08-21**. Versões no npm na mesma data: `storybook` e `@storybook/addon-vitest` **10.5.10** · `vitest` e `@vitest/browser-playwright` **4.1.11**.

---

## 1. O testing widget

A UI do Storybook tem um painel de teste no rodapé da sidebar. É de lá que saem três coisas que também existem em CLI:

| Controle | Efeito |
| --- | --- |
| **Run tests** | executa os testes das stories |
| **watch mode** (ícone de olho) | reexecuta ao salvar |
| **coverage** (caixa) | liga a medição de cobertura na execução |
| **accessibility** (caixa) | liga a varredura do addon-a11y |

O widget é conveniência, não uma segunda implementação: ele dispara o mesmo `@storybook/addon-vitest`. Mas **ele ignora parte da configuração de cobertura** (§ 2.4), e **watch mode desliga a cobertura** (§ 2.5) — as duas pegadinhas desta nota.

---

## 2. Cobertura

### 2.1 O que ela mede — e é aqui que quase todo mundo se engana

A fonte é explícita nas três limitações, e a primeira reescreve o significado do número:

> 1. *"A cobertura é calculada usando as stories que você escreveu, não a base de código inteira."*
> 2. *"A cobertura só pode ser calculada para todas as stories do projeto, não para uma story individual."*
> 3. *"A cobertura não é calculada enquanto o watch mode está ativado."*

A limitação 1 é a que importa: **isto não é cobertura de projeto.** O denominador é o que as stories alcançam. Um componente sem story nenhuma não aparece como 0% — ele frequentemente não aparece. Ler "82%" como "82% do código testado" é erro de leitura, não de medição (`SB-TEST-11`).

O que o número **de fato** responde é útil e mais estreito: *das stories que existem, quanto do código que elas exercitam foi executado.* Serve para achar ramo de componente que nenhuma story alcança — que é o uso certo de cobertura em qualquer ferramenta ([Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) § 3.3).

### 2.2 Instalar o provider

Não vem embutido. Um dos dois, explicitamente (`SB-TEST-12`):

```bash
npm install --save-dev @vitest/coverage-v8 # v8 é o default
npm install --save-dev @vitest/coverage-istanbul
```

```ts
// vitest.config.ts
coverage: {
 provider: 'istanbul', // 'v8' é o default
}
```

### 2.3 Ligar

| Onde | Como |
| --- | --- |
| widget | marcar a caixa **antes** de rodar |
| CLI, só o project storybook | `npm run test-storybook -- --coverage` |
| CLI, todos os projects | `npx vitest --coverage` |

O relatório sai em dois lugares diferentes, e isso confunde:

| Origem | Onde o relatório fica |
| --- | --- |
| UI do Storybook | servido em `/coverage/index.html` do Storybook rodando |
| CLI | gravado em `./coverage` (configurável) |

### 2.4 As seis opções que a UI ignora

Rodando pela UI do Storybook, estas opções de `coverage` **não têm efeito**:

`enabled` · `clean` · `cleanOnRerun` · `reportOnFailure` · `reporter` · `reportsDirectory`

Isso é decisão da ferramenta, não bug: o widget gerencia o ciclo de vida do relatório para poder servi-lo em `/coverage/index.html`. A consequência prática é que **configurar `reporter` ou `reportsDirectory` para o widget é trabalho jogado fora** — essas opções valem quando o disparo é pela CLI (`SB-TEST-14`).

`watermarks` **funciona** e é o que colore o número na UI:

```ts
coverage: {
 watermarks: {
 statements: [50, 80], // [baixo, alto]
 },
}
```

### 2.5 Watch mode zera a medição

A terceira limitação da § 2.1 merece destaque porque produz um número silenciosamente falso: **com watch mode ligado, a cobertura não é calculada.** Quem deixa o olho aceso, marca a caixa de cobertura e lê o resultado está lendo um valor que não foi medido naquela execução (`SB-TEST-13`).

Para número confiável: watch desligado, ou CLI.

### 2.6 Cobertura não é meta

Vale aqui a mesma regra que vale em qualquer lugar do vault: cobertura mede **execução**, não **verificação** — uma story que renderiza sem `play` cobre linhas e não afirma nada. Ver `TS-CORE-05` em [Teste de Software](teste-de-software.md) e o teste de trinta segundos em [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) § 4.

E como o denominador aqui é "as stories que existem" (§ 2.1), a métrica é ainda mais frágil como meta do que o normal: ela sobe escrevendo story, não escrevendo asserção.

---

## 3. CI

### 3.1 O workflow da fonte

O comando é o mesmo do local — é isso que a fonte recomenda:

```json
{
 "scripts": {
 "test-storybook": "vitest --project=storybook"
 }
}
```

> **Uma divergência interna da fonte, e ela importa.** A página de CI usa `vitest --project=storybook`, sem `run`. A página do addon dá as duas formas e aponta **`vitest run`** como a de CI. Sem `run`, o Vitest entra em watch mode — e num job de CI isso trava até o timeout. Use `vitest run --project=storybook` ([Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 4.3).

O workflow, verbatim da fonte:

```yaml
name: UI Tests

on: [push]

jobs:
 test:
 runs-on: ubuntu-latest
 container:
 image: mcr.microsoft.com/playwright:v1.58.2-noble
 steps:
 - uses: actions/checkout@v4

 - name: Setup Node
 uses: actions/setup-node@v4
 with:
 node-version: 22.12.0

 - name: Install dependencies
 run: npm ci

 - name: Run tests
 run: npm run test-storybook
```

### 3.2 Os binários do Playwright

O addon roda em **browser real**, então o job precisa dos binários. Dois caminhos:

| Caminho | Como |
| --- | --- |
| imagem que já os traz | `container.image: mcr.microsoft.com/playwright:v1.58.2-noble` |
| instalar no job | `npm ci && npx playwright install chromium --with-deps` |

A fonte recomenda o primeiro: *"para a experiência mais rápida, você deve usar uma imagem de máquina que já tenha o Playwright instalado."* (`SB-TEST-15`)

> **Isto fecha uma pendência.** Até 2026-08-19 a estrutura registrava que a fonte citava `mcr.microsoft.com/playwright` **sem tag** ([Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md)). A tag está declarada: **`v1.58.2-noble`**. Note que ela versiona o **Playwright**, não o Storybook — atualizar o Playwright do projeto sem atualizar a imagem é como o job passa a divergir do local.

### 3.3 Em CI não existe Storybook rodando

Esta é a parte que muda o desenho do pipeline. A fonte: *"em CI, não há um Storybook ativo. Em vez disso, você precisa primeiro fazer o build e publicar seu Storybook."*

Consequência: sem Storybook publicado, o teste **roda**, mas a falha vem sem link para a story. Com ele, o status check do PR aponta direto para a story que quebrou.

O caminho é passar a URL por ambiente:

```ts
// vitest.config.ts
storybookTest({
 configDir: path.join(dirname, '.storybook'),
 storybookUrl: process.env.SB_URL,
})
```

(`SB-TEST-16`)

**`storybookScript` × `storybookUrl`** — os dois são do mesmo plugin e resolvem problemas opostos:

| Opção | Serve para | Onde |
| --- | --- | --- |
| `storybookScript` | **subir** um Storybook para o teste usar | local, watch mode |
| `storybookUrl` | **apontar** para um Storybook que já existe | CI |

### 3.4 A armadilha do Bun

A imagem `mcr.microsoft.com/playwright` traz Node, **não Bun**. Num monorepo Bun, o `storybookScript` costuma ser `bun run storybook` — e ele falha nessa imagem.

Três saídas, em ordem de preferência:

1. **Não usar `storybookScript` em CI.** Ele existe para watch mode; em CI use `storybookUrl` apontando para o Storybook publicado (§ 3.3). É a saída que dispensa Bun no container.
2. **Instalar Bun no job**, antes do `install`.
3. **Imagem própria** com Node, Bun e os binários do Playwright.

A opção 1 é a que a própria divisão de responsabilidade da § 3.3 já sugere (`SB-TEST-17`).

### 3.5 O que fica fora do alcance do `--filter` do Bun

Já registrado em [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 4.5 e vale relembrar no contexto de CI: o addon-vitest **exige Vitest** e não roda sob `bun test` (`SB-TEST-05`). O monorepo fica com runners separados por desenho, e o CI precisa invocar cada um — ver `Monorepo com Bun - estrutura e tooling` § 4. Com Playwright na conta, são três ([Playwright](playwright.md) § 8).

---

## 4. Regras — `SB-TEST-11` a `SB-TEST-17`

A família continua a de [Storybook - Testes e Interações](storybook-testes-e-interacoes.md): os IDs `SB-TEST-01` a `SB-TEST-10` **mantêm texto e significado**, e citação antiga em skill ou PR continua válida.

| ID | Regra |
| --- | --- |
| `SB-TEST-11` | O número de cobertura **MUST** ser lido como cobertura **das stories**, não do código do projeto. Tratá-lo como cobertura de base de código **NEVER**. |
| `SB-TEST-12` | O provider de cobertura (`@vitest/coverage-v8` ou `@vitest/coverage-istanbul`) **MUST** ser instalado explicitamente — ele não vem embutido. |
| `SB-TEST-13` | Número de cobertura lido com watch mode ativo **NEVER** é resultado: a fonte declara que a cobertura não é calculada nessa condição. |
| `SB-TEST-14` | `enabled`, `clean`, `cleanOnRerun`, `reportOnFailure`, `reporter` e `reportsDirectory` **NEVER** são usados para configurar a cobertura disparada pela UI — a UI os ignora. |
| `SB-TEST-15` | O job de CI **MUST** ter os binários do Playwright, por imagem que já os traga ou por `playwright install` explícito. |
| `SB-TEST-16` | Em CI, o link de depuração **MUST** vir de `storybookUrl` apontando para um Storybook publicado — em CI não há Storybook ativo. |
| `SB-TEST-17` | `storybookScript` **NEVER** invoca `bun` numa imagem de CI que só tem Node. Em CI, prefira `storybookUrl`. † |

**Marcação de origem:** regra sem marca vem de afirmação explícita da fonte; **†** é decisão desta doc. Mesma convenção do resto da estrutura.

---

## 5. Antipadrões

### 5.1 Reportar cobertura de story como cobertura de projeto

"Temos 82% de cobertura" quando o denominador são as stories existentes. Um componente sem story não puxa o número para baixo — ele fica fora da conta (`SB-TEST-11`).

### 5.2 Ler cobertura com watch ligado

O olho aceso e a caixa marcada. O número exibido não foi medido naquela execução (`SB-TEST-13`).

### 5.3 Configurar `reporter` para o widget

```ts
// ✗ ignorado quando o disparo é pela UI
coverage: { reporter: ['lcov'], reportsDirectory: './cov' }
```

Vale pela CLI, não pelo widget (`SB-TEST-14`).

### 5.4 Meta de cobertura de stories no CI

Pior que meta de cobertura comum: aqui o número sobe **escrevendo story**, não escrevendo asserção. Uma story sem `play` cobre linhas e não afirma nada (`SB-TEST-11`, e `TS-CORE-05` em [Teste de Software](teste-de-software.md)).

### 5.5 `vitest` sem `run` em CI

```yaml
# ✗ entra em watch mode e o job trava até o timeout
- run: npm run test-storybook # onde o script é "vitest --project=storybook"
```

Ver § 3.1 — é divergência da própria fonte.

### 5.6 Imagem sem os binários do Playwright

Job em `node:22` puro. O erro que aparece é de browser não encontrado, e não diz que a causa é a imagem (`SB-TEST-15`).

### 5.7 `storybookScript` com `bun` no container do Playwright

Falha com "command not found: bun", que não sugere a causa (`SB-TEST-17`).

### 5.8 CI sem Storybook publicado

Os testes rodam e o status check aponta uma falha sem link para a story. Funciona, e desperdiça o principal ganho de depuração do addon (`SB-TEST-16`).

### 5.9 Tag da imagem congelada

`mcr.microsoft.com/playwright:v1.58.2-noble` versiona o **Playwright**. Subir o Playwright do projeto sem subir a imagem faz o job divergir do local — e o sintoma é um teste que passa numa ponta e falha na outra.

---

## Relacionados

- [Storybook](storybook.md) — o hub; a § 5 tem as árvores de decisão e a § 6 as regras
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o satélite irmão: escrever o teste, e a config do addon-vitest
- [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md) — `main.ts`, Vite, e o recorte de `apps/storybook`
- [Storybook - Pendências de revisão](storybook-pendencias-de-revisao.md) — o registro do que continua aberto
- [Teste de Software](teste-de-software.md) — por que cobertura não é meta (`TS-CORE-05`)
- [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) — cobertura × mutação, e o teste de trinta segundos
- [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) — o uso legítimo de cobertura
- [Playwright](playwright.md) — o terceiro runner do monorepo, e a mesma exigência de binário em CI
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — o pipeline do lado do E2E
- [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) — o equivalente sob `bun test`, com os dois portões silenciosos
- `Monorepo com Bun - estrutura e tooling` — por que os runners são separados
- `Github Actions` ·

## Fontes consultadas

Verificadas em **2026-08-21**:

- [Test coverage](https://storybook.js.org/docs/writing-tests/test-coverage) — providers, `watermarks`, as seis opções ignoradas na UI, os dois destinos de relatório, as três limitações
- [In CI](https://storybook.js.org/docs/writing-tests/in-ci) — o workflow verbatim, a imagem com tag, Node 22.12.0, `SB_URL`/`storybookUrl`, a exigência de Storybook publicado
- [Vitest addon](https://storybook.js.org/docs/writing-tests/integrations/vitest-addon) — `storybookScript` × `storybookUrl`, requisitos, e `vitest run`
- [Writing tests](https://storybook.js.org/docs/writing-tests) — o testing widget e os cinco tipos de teste
- Versões: `npm view <pacote> version` em 2026-08-21

**Notas de verificação:**

- **A tag da imagem de CI está declarada:** `mcr.microsoft.com/playwright:v1.58.2-noble`. Isso fecha a metade da pendência "CI real" registrada em 2026-08-19; a metade do Bun continua aberta, porque a imagem traz Node e não Bun.
- **A página de CI usa `vitest --project=storybook`, sem `run`; a página do addon aponta `vitest run` como a forma de CI.** É divergência interna da documentação, e a segunda é a correta — sem `run` o job entra em watch mode.
- **Cobertura mede as stories, não a base de código.** É a primeira das três limitações declaradas, e a que mais muda a leitura do número.
- **Cobertura não é calculada em watch mode** — o número aparece e não foi medido.
- **Seis opções de `coverage` são ignoradas quando o disparo é pela UI:** `enabled`, `clean`, `cleanOnRerun`, `reportOnFailure`, `reporter`, `reportsDirectory`.
- **Em CI não há Storybook ativo** — é preciso build e publicação para os links de depuração funcionarem, e a URL entra por `storybookUrl`.
- **O provider de cobertura não vem embutido:** `@vitest/coverage-v8` (default) ou `@vitest/coverage-istanbul`.
- **`storybookScript` e `storybookUrl` são opostos complementares**, e a fonte marca `storybookScript` como relevante só para watch mode.
- **Versão subiu de 10.5.9 para 10.5.10** desde a verificação de 2026-08-19 — patch, sem mudança de superfície observada nas páginas desta nota.
- **O conteúdo de `.storybook/vitest.setup.ts` continua não transcrito pela fonte** — a pendência de 2026-08-19 permanece aberta.
