---
name: playwright-review
description: Auditar uma suíte Playwright existente com oito sondas executáveis antes de ler código, varredura em onze níveis por frequência de defeito, checklist extra para teste gerado por agente, e achados com ID `PW-*` — use quando a tarefa for revisar a suíte E2E de um repositório ou de um PR, caçar asserção que não afirma nada, espera por tempo, locator frágil, sessão versionada, `test.only` sem portão, trace desligado ou shard mal configurado. Não use para escrever teste novo, que é playwright-build, para diagnosticar uma falha concreta, que é playwright-diagnose, nem para auditar a forma da suíte entre níveis, que é teste-review.
tags:
  - skill
  - playwright
  - testing
  - code-review
fonte: "[[Playwright]]"
---

# playwright-review

> **Fonte desta skill:** [[Playwright]] — a § 6 normativa (85 regras), a § 6.1 com as críticas dos satélites, e a § 6.2 com os IDs canônicos. O corpo de cada família vive no satélite dono do ID.
> Esta skill **não contém** o texto das regras — ela diz o que executar, em que ordem varrer, como classificar e como reportar.

Contrato que esta skill implementa: [[Playwright]] § 7 ("Contrato de skill").

---

## Quando usar

Auditar uma suíte E2E que **já existe**: o repositório inteiro, um diretório, ou os testes de um PR.

| Situação | Vá para |
| --- | --- |
| escrever ou reescrever teste | [[playwright-build]] |
| uma falha concreta, ou flake com trace disponível | [[playwright-diagnose]] |
| a **forma** da suíte entre níveis (E2E × unidade × componente) | [[teste-review]] |
| suíte instável como sistema, taxa de flakiness | [[teste-diagnose]] |
| revisar teste sob `bun test` | [[bun-test-review]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Playwright]] § 0 | piso de Node e a tabela de timeouts |
| 2 | [[Playwright]] § 6 e § 6.1 | as regras invioláveis e as críticas |
| 3 | `references/mapa-de-ids.md` | **obrigatório antes de citar** — dois IDs são apelidos |
| 4 | o satélite do achado | via § 4 do hub |

**Nunca carregue os doze satélites.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as oito sondas, as três paradas obrigatórias, e o que elas não pegam |
| `references/ordem-da-varredura.md` | os 11 níveis, e a checklist extra de teste gerado por agente |
| `references/severidade-e-relatorio.md` | classificação, formato com evidência de sonda, o corte, o fechamento |
| `references/antipadroes.md` | ~70 antipadrões com ID e satélite |
| `references/mapa-de-ids.md` | os 85 `PW-*` por satélite e seção |
| `references/exemplo-auditoria.md` | auditoria inteira, da sonda ao "não verificado" |
| `scripts/sondas.sh` | roda as oito sondas |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas três skills de Playwright |

---

## Passo 1 — Sondar antes de ler

```bash
bash ~/.claude/skills/playwright-review/scripts/sondas.sh e2e
```

**Três paradas obrigatórias:**

| Sonda | Se mostrar… | Por quê |
| --- | --- | --- |
| S2 | `.only` sem `forbidOnly` | o CI pode estar verde rodando **1 de N** |
| S8 | `storageState` fora do `.gitignore` | **achado de segurança**, reporte separado e primeiro |
| S3 | `trace: 'off'` | a auditoria de flake **para aqui**: o primeiro achado é a configuração |

E uma quarta, bloqueante sem interromper: **S6 sem `no-floating-promises`** — asserção sem `await` passa sempre e ninguém vê.

---

## Passo 2 — Varrer na ordem que falha mais

`references/ordem-da-varredura.md`: asserção que não afirma → espera inventada → locator frágil → ação que desliga verificação → isolamento e sessão → **nível errado** → estrutura → rede e dado → snapshot → configuração e CI → estilo.

Se a suíte tem testes de agente, aplique **também** a checklist extra — o item central é **asserção deletada por um healer**: a forma mais fácil de fazer um teste passar é remover o que ele afirmava (`PW-AGT-05`).

---

## Passo 3 — Classificar e reportar

`references/severidade-e-relatorio.md`. Bloqueante é o que **faz o CI mentir**; Alta é o que produz flake hoje; Média é dívida.

Para sonda, **a evidência é a saída do comando** — cole-a, incluindo o exit code quando ele for o achado.

**Três coisas não são achado:** ausência de teste, `getByTestId` com dívida registrada, e escolha de proporção da suíte (essa é `TS-CORE-02`, em [[teste-review]]).

---

## Passo 4 — Fechar

1. **Transforme sonda em portão** — `forbidOnly`, `trace`, lint, `.gitignore`.
2. **Separe "não protegido" de "quebrado"**, e **"nível errado" de "teste ruim"**: o segundo se corrige movendo, não melhorando.
3. **Ordene por severidade**, não por arquivo.
4. **Credencial exposta vai separada e primeiro.**
5. **Declare o que não foi verificado.**
6. **Se a correção for escrever teste**, a fonte passa a ser [[playwright-build]].

---

## Exemplo

Suíte de 214 testes, CI verde. As sondas encontram `.only` sem `forbidOnly`, `trace: 'off'`, `storageState` fora do `.gitignore` e as versões dos dois pacotes fora de lockstep sob Node 20. **Três paradas disparam.** A credencial sai primeiro e separada; "tem E2E demais" é devolvido para a skill de estratégia; o que o grep não cobriu é declarado.

Auditoria completa: `references/exemplo-auditoria.md`.

---

## Relacionados

- [[Playwright]] — fonte desta skill: § 6, § 6.1, § 6.2, § 7
- [[playwright-build]] · [[playwright-diagnose]] — as skills irmãs
- [[teste-review]] — audita a **forma** entre níveis; esta audita os **testes**
- [[bun-test-review]] — a auditoria equivalente sob Bun
- [[react-review]] · [[drizzle-review]] — de onde vem o formato de achado
