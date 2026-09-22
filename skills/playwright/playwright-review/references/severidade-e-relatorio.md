# Severidade, formato e o corte

---

## Classificação

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | asserção que não afirma nada (`PW-CORE-04`, `PW-EXP-01`); `.only` sem `forbidOnly` (`PW-CFG-01`); `storageState` versionado (`PW-AUTH-02`); `trace: 'off'` em CI (`PW-CFG-02`); asserção apagada por healer (`PW-AGT-05`); `no-floating-promises` desligada |
| **Alta** | `waitForTimeout` e `networkidle` (`PW-CORE-05`, `PW-ACT-04`); `force: true` sem motivo (`PW-ACT-01`); conta compartilhada entre workers (`PW-AUTH-03`); regra de negócio em E2E (`TS-CORE-02`); shard sem `fullyParallel` (`PW-RUN-01`); opção de runner em `use` (`PW-CORE-07`) |
| **Média** | `.first` (`PW-LOC-02`); locator CSS estrutural (`PW-LOC-01`); login em `beforeEach` (`PW-AUTH-01`); asserção de negócio em page object (`PW-STR-02`); URL absoluta (`PW-CFG-05`); screenshot onde aria serviria (`PW-SNAP-01`); `skip` sem motivo (`PW-STR-05`) |
| **Baixa** | preferência sem ID — **não é achado** |

Dois critérios decidem a fronteira:

- **Bloqueante × Alta:** *o defeito faz o CI mentir?* Asserção que não afirma, `.only` sem
 portão e healer que apagou asserção produzem **verde falso**.
- **Alta × Média:** *produz flake hoje, ou dívida para depois?* `waitForTimeout` já custa
 tempo em toda execução; `.first` é bomba de efeito retardado.

---

## Formato

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver Satélite correspondente.
```

```
`PW-EXP-01` — e2e/pedidos.spec.ts:41
expect(await page.getByRole('alert').textContent).toBe('Pedido criado') afirma sobre um
instante congelado: se o alerta aparece 40 ms depois, o teste falha sem haver defeito.
Correção: await expect(page.getByRole('alert')).toHaveText('Pedido criado').
Ver Playwright - Assertions.
```

Para sonda, **a evidência é a saída do comando** — cole-a:

```
`PW-CFG-01` — playwright.config.ts (ausência) + e2e/checkout.spec.ts:18
S2: grep encontrou test.only em checkout.spec.ts:18, e o config não declara forbidOnly.
O CI está verde rodando 1 teste de 214.
Correção: forbidOnly: !!process.env.CI no config, e remover o.only.
Ver Playwright - Configuração e Projects.
```

Regras do formato:

- **ID conferido em `mapa-de-ids.md`**, e **nunca apelido**.
- **`arquivo:linha` sempre.**
- **Correção concreta.** Se a suíte já tem o padrão certo em outro arquivo, aponte esse
 arquivo: estender o padrão estabelecido vale mais que introduzir um novo.
- **Um link de satélite.**

---

## O corte: três coisas que **não** são achado

| Não é achado | Por quê |
| --- | --- |
| **ausência de teste** | "esta jornada não tem E2E" é decisão de estratégia — reporte como pergunta, e o ID seria de `teste-review` |
| **`getByTestId` com dívida registrada** | é solução honesta quando o componente não tem semântica e não vai ser corrigido neste PR (`PW-LOC-04`). Achado é o test id **sem** registro |
| **escolha de proporção da suíte** | "tem E2E demais" só é achado com o argumento de nível — e aí o ID é `TS-CORE-02`, não `PW-*` |

Se a varredura encontrar defeito recorrente e real **sem regra correspondente**, o produto
certo é uma **proposta de regra** para [Playwright](../../../../knowledge-base/docs/playwright.md) § 6 — não uma citação falsa.

---

## Fechar a auditoria

1. **Transforme sonda em portão.** S2 vira `forbidOnly`; S3 vira `trace: 'on-first-retry'`; S6 vira a regra de lint no CI; S8 vira a linha no `.gitignore`.
2. **Separe "não protegido" de "quebrado".** Uma suíte pode estar verde, correta e não proteger nada.
3. **Separe "nível errado" de "teste ruim".** Um E2E bem escrito verificando regra de negócio não tem defeito de escrita — a correção é **mover**, não melhorar.
4. **Ordene por severidade**, não por arquivo.
5. **Credencial exposta (S8) vai separada e primeiro.**
6. **Declare o que não foi verificado.** "Não verificado" não é "sem achado".
7. **Se a correção for escrever teste**, a fonte passa a ser `playwright-build`; se for investigar falha concreta, `playwright-diagnose`.
