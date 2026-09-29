---
titulo: Teste de Software - Confiabilidade da Suíte
Link: https://abseil.io/resources/swe-book/html/ch11.html
tags:
  - testing
  - flaky-tests
  - coverage
  - maintenance
  - agent-context
source: "Software Engineering at Google cap. 11, testing.googleblog (flaky tests), Mutation testing, Martin Fowler"
verificado-em: 2026-08-20
---

# Teste de Software — Confiabilidade da Suíte

> Satélite de [Teste de Software](teste-de-software.md). Cobre a propriedade sem a qual todo o resto é decorativo: **dá para acreditar no vermelho?** A árvore de diagnóstico está na § 4.5 do hub.
>
> **A afirmação central.** Uma suíte não confiável é pior que nenhuma suíte, e isso é aritmética, não retórica. Com nenhuma suíte, ninguém tem falsa confiança e ninguém gasta tempo investigando nada. Com uma suíte flaky, as pessoas gastam tempo em falso vermelho e — o custo real — **aprendem a ignorar o vermelho**, o que faz o vermelho verdadeiro passar junto.

---

## 1. A aritmética da flakiness

Os números são do Google, e são o argumento mais forte que existe sobre teste:

> Com **0,1%** de chance de um teste falhar quando não deveria, e **10 000** testes por dia, são **10 investigações inúteis por dia**.

> *"Ao se aproximar de 1% de flakiness, os testes começam a perder valor."*

> O índice do próprio Google *"gira em torno de 0,15%, o que implica milhares de falhas espúrias por dia"*.

Três coisas que isso estabelece:

1. **Existe um limiar quantificado.** Não é "flaky é ruim"; é ~1%, e acima dele a suíte deixa de pagar.
2. **O custo escala com o tamanho.** 0,1% é tolerável em 200 testes e insuportável em 10 000. Uma suíte que cresce sem atacar flakiness piora de forma não linear.
3. **Mesmo os melhores não chegam a zero.** 0,15% com investimento enorme. A meta não é zero — é ficar uma ordem de magnitude abaixo do limiar, e tratar cada caso como defeito (`TS-CORE-04`).

---

## 2. Determinismo, e de onde a flakiness vem

**Determinístico** = mesma entrada, mesmo resultado, em qualquer ordem, em paralelo, em qualquer máquina (`TS-SUI-01`).

As causas, em ordem de frequência:

| Causa | Sintoma típico | Correção |
| --- | --- | --- |
| **espera por tempo fixo** | passa na máquina rápida, falha no CI | esperar pela **condição** |
| **estado compartilhado** | falha só em paralelo; passa com um worker | dado próprio por teste |
| **dependência de ordem** | passa sozinho, falha na suíte | isolar; nunca "arrumar" a ordem |
| **relógio real** | falha à meia-noite, na virada do mês, no horário de verão | relógio controlado |
| **aleatoriedade** | falha 1 em 50, sem padrão | semente fixa |
| **rede externa** | falha quando o terceiro oscila | substituir a borda |
| **animação / render** | clique cai no lugar errado | esperar estabilidade |
| **vazamento entre testes** | o segundo teste vê o estado do primeiro | teardown de verdade |
| **paralelismo do runner** | porta, arquivo ou banco em disputa | recurso por worker |
| **ordem de coleção não garantida** | asserção de lista falha às vezes | ordenar, ou asserção sem ordem |

**A causa nº 1 é sempre a mesma, em qualquer ferramenta:** esperar tempo em vez de esperar condição. `sleep`, `waitForTimeout`, `setTimeout` no teste. Ela é simultaneamente lenta quando a máquina está rápida e insuficiente quando está lenta — o pior de dois mundos, por construção.

As formas concretas por ferramenta: [Playwright](playwright.md) § 5.2 (a árvore mais detalhada do vault sobre isto) e [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md).

---

## 3. Isolamento

O que garante que a ordem não importa.

| Recurso | Como isolar |
| --- | --- |
| dado de banco | schema ou banco por worker; ou identificador único por teste |
| arquivo | diretório de saída por teste |
| porta | porta por worker, ou porta zero |
| sessão / usuário | uma conta por worker |
| estado em memória | reset no teardown, nunca no setup do seguinte |
| cache | desligado, ou chave por teste |

**Cada teste cria os próprios dados, com identificador único** (`TS-SUI-05`). Depender de dado pré-existente ("o usuário 42 existe no banco de dev") produz suíte que funciona até alguém rodar uma migração.

**Reset no teardown, não no setup do seguinte.** Parece equivalente e não é: teardown roda mesmo quando o teste falha, e mantém a limpeza como responsabilidade de quem sujou. Limpeza no setup do próximo acopla os dois testes e vaza quando alguém roda um só.

> **Ponte com o stack.** Em [Playwright](playwright.md) o isolamento é por `BrowserContext` e vem de graça; em `bun test` ele é responsabilidade de quem escreve ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md)). A diferença explica por que suíte de unidade costuma ter *mais* problema de isolamento que suíte E2E, o que é contraintuitivo.

---

## 4. Cobertura e mutação

### 4.1 O que cobertura é

Percentual de código **executado** pela suíte. É útil para uma coisa: **achar o que não foi executado**.

Não é útil como meta (`TS-CORE-05`), porque não distingue:

```ts
// cobre a função por completo, e não verifica nada
test('calcula', () => { calcularFrete(pedido); });

// mesma cobertura, e verifica
test('frete grátis acima de 200', () => {
  expect(calcularFrete({ valor: 250 })).toBe(0);
});
```

E os critérios de cobertura não são equivalentes: **100% de instrução com um `if` cujo ramo falso nunca roda é possível** ([Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) § 3.1). Cobertura de ramo é o piso razoável.

**O que meta de cobertura produz na prática:** testes escritos para o número — chamadas sem asserção, testes de getter, testes de construtor. O número sobe, a capacidade de detecção não muda, e agora existe manutenção nova.

### 4.2 O que mutação é

Modifica o código de propósito e pergunta se a suíte percebe. O **mutante sobrevivente** aponta a asserção que falta, com precisão de linha.

| | Cobertura | Mutação |
| --- | --- | --- |
| Mede | linha executada | quebra detectada |
| Responde | "que código ninguém chamou?" | "que quebra ninguém pega?" |
| Custo | baixo | alto (roda a suíte por mutante) |
| Falso positivo | linha coberta sem asserção | mutante equivalente |

`TS-SUI-04`. Mutação é caro para rodar sempre — o uso realista é pontual, no módulo crítico, para calibrar.

**A versão de trinta segundos, que serve todo dia:** quebre o código de propósito e veja se algo fica vermelho. Troque um sinal, inverta uma condição, devolva `null`. Se nada quebrar, a asserção não existe. Isso não precisa de ferramenta e é o único teste da suíte que realmente importa (`TS-TEC-08`).

---

## 5. Test smells

Sintomas de suíte que vai doer, e o que cada um indica:

| Smell | Indica |
| --- | --- |
| teste quebra em refactor sem mudança de comportamento | acoplado a implementação (`TS-SUI-06`) |
| asserção sobre número de chamadas de um método interno | verificação de comportamento onde estado bastava |
| setup de 40 linhas | falta fixture, ou a unidade sob teste faz demais |
| nome `test('funciona')` | ninguém saberá o que quebrou |
| `if` dentro do teste | são dois testes |
| teste que testa o mock | o dublê virou o objeto sob teste |
| comentário explicando por que está `skip` | dívida sem prazo |
| um teste que verifica dez coisas | falha diz "algo em algum lugar" |
| duplicata da mesma lógica em três níveis | violação de `TS-CORE-02` |
| `try/catch` para "garantir" que passa | o teste foi desativado sem dizer |

**O primeiro é o mais grave.** Uma suíte que quebra a cada refactor transforma refatoração em reescrita de teste, e o efeito prático é que ninguém refatora — o que anula exatamente o benefício pelo qual a suíte foi escrita.

**O último é o mais insidioso**, porque é invisível em revisão:

```ts
// ✗ nunca falha
test('processa o pedido', async () => {
  try { await processar(pedido); } catch { /* … */ }
});
```

---

## 6. Manutenção

Uma suíte é código, e envelhece.

| Prática | Por quê |
| --- | --- |
| apagar teste que não paga | duplicata, feature removida, verificação de detalhe morto |
| revisar `skip` periodicamente | `skip` sem prazo é dívida anônima |
| revisar a checklist | *pesticide paradox*: conjunto fixo para de achar coisa nova |
| medir tempo da suíte | se ninguém roda antes do PR, ela deixou de ser portão |
| tratar flaky com prioridade de bug | `TS-CORE-04` |
| acompanhar taxa de escape | mede o que a suíte deixou passar — [Teste de Software - Processo e Artefatos](teste-de-software-processo-e-artefatos.md) § 6 |

**Apagar teste é trabalho legítimo**, e raramente feito. Um teste que não pode falhar por nenhum defeito plausível é custo puro: ele roda, é mantido, e não informa. Os candidatos: duplicatas de nível (`TS-CORE-02`), testes de getter e construtor, testes escritos para meta de cobertura.

**Retry merece parágrafo próprio.** Ele é anestésico: mascara o falso vermelho e, junto, o verdadeiro. Um teste que passa "às vezes na segunda tentativa" tem um defeito — no teste ou no produto — e o retry esconde qual (`TS-SUI-03`). O uso legítimo é absorver instabilidade **residual** de uma suíte já sã, e com trace da tentativa gravado ([Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) § 4).

---

## 7. Regras — `TS-SUI-01` a `TS-SUI-11`

| ID | Regra |
| --- | --- |
| `TS-SUI-01` | Teste **MUST** ser determinístico: mesma entrada, mesmo resultado, em qualquer ordem e em paralelo. |
| `TS-SUI-02` | Teste intermitente **MUST** ser tratado como defeito da suíte, com a mesma prioridade de um bug. Conviver com flaky **NEVER**. *(apelido de `TS-CORE-04` — cite o canônico)* |
| `TS-SUI-03` | Retry **NEVER** é conserto de flakiness. Ele é anestésico, e mascara tanto o falso vermelho quanto o verdadeiro. |
| `TS-SUI-04` | Qualidade de asserção **MUST** ser medida por detecção de quebra (mutação, ou quebra manual deliberada), **NEVER** por cobertura. |
| `TS-SUI-05` | Cada teste **MUST** criar os próprios dados, com identificador único. Depender de dado pré-existente compartilhado **NEVER**. |
| `TS-SUI-06` | Teste que quebra em refactor sem mudança de comportamento **MUST** ser tratado como defeito do teste, não do refactor. |
| `TS-SUI-07` | Espera **MUST** ser por condição observável, **NEVER** por tempo fixo. |
| `TS-SUI-08` | Limpeza de estado **MUST** acontecer no teardown do teste que sujou, **NEVER** no setup do seguinte. † |
| `TS-SUI-09` | Recurso disputado sob paralelismo (porta, arquivo, banco, conta) **MUST** ser alocado por worker. |
| `TS-SUI-10` | Teste que não pode falhar por nenhum defeito plausível **MUST** ser apagado. † |
| `TS-SUI-11` | `skip` e `fixme` **MUST** carregar motivo e prazo ou issue. † |

---

## 8. Antipadrões

### 8.1 `sleep` para "estabilizar"

Lento quando a máquina está rápida, insuficiente quando está lenta (`TS-SUI-07`).

### 8.2 Retry para calar

```
✗ retries: 5
```

Cinco execuções de um teste ruim custam mais que uma hora consertando, e o defeito continua (`TS-SUI-03`).

### 8.3 `--workers=1` como solução

Descobrir que a suíte passa em série e configurar série. O acoplamento continua, e a suíte agora é N vezes mais lenta (`TS-SUI-09`).

### 8.4 Ordenar os arquivos para a suíte passar

`001-`, `002-` como prefixo para forçar ordem. Codifica a dependência em vez de removê-la, e a próxima inserção quebra tudo (`TS-CORE-06` do hub de nível: um teste nunca depende de outro).

### 8.5 Meta de cobertura

Produz teste escrito para o número (`TS-SUI-04`, `TS-CORE-05`).

### 8.6 Depender de dado semeado no ambiente

"O usuário 42 existe no banco de dev." Funciona até a próxima migração, e quebra para todo mundo ao mesmo tempo (`TS-SUI-05`).

### 8.7 `try/catch` no corpo do teste

```ts
// ✗ desativa o teste sem dizer
test('processa', async () => {
  try { await processar(p); } catch {}
});
```

Nunca falha, e passa em revisão (§ 5).

### 8.8 Culpar o refactor

O teste quebrou num refactor sem mudança de comportamento, e a conclusão é que o refactor foi arriscado. Era o teste que observava implementação (`TS-SUI-06`).

### 8.9 `skip` permanente

Teste pulado há oito meses, sem motivo escrito. Ninguém remove porque ninguém sabe se ainda vale (`TS-SUI-11`).

### 8.10 Suíte que ninguém roda

40 minutos de execução local. Ela existe, e deixou de ser portão — o feedback chegou tarde demais para mudar comportamento. O problema é a forma da suíte (`TS-NIV-04`).

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub; a § 4.5 é a árvore de "não confio na suíte"
- [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) — tamanho de teste decide determinismo
- [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) — relógio e aleatoriedade, onde o determinismo se compra
- [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) — cobertura estrutural e mutação em detalhe
- [Teste de Software - Processo e Artefatos](teste-de-software-processo-e-artefatos.md) — taxa de escape e taxa de flakiness
- [Playwright](playwright.md) § 5.2 — a árvore de flake mais detalhada do vault
- [Playwright - Execução, Retries e CI](playwright-execucao-retries-e-ci.md) — retry com trace, e por que retry não conserta
- [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) — isolamento onde ele não vem de graça
- — o que a suíte acoplada a implementação impede
- — a origem de `TS-SUI-06`
- — dado único e limpeza transacional
- — a aposta que só paga com suíte confiável

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Software Engineering at Google, cap. 11](https://abseil.io/resources/swe-book/html/ch11.html) — a aritmética (0,1% × 10 000 = 10/dia), o limiar de ~1%, o índice de ~0,15%, e tamanho de teste como base do determinismo
- [testing.googleblog — Flaky Tests at Google](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html) — detecção por rerun e histórico; **sem** dado publicado de custo em horas
- [Mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) — mutante sobrevivente como apontador de asserção faltante; mutation score; mutantes equivalentes
- [The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) — duplicação entre níveis como custo de manutenção
- [guru99 — Software Testing](https://www.guru99.com/software-testing.html) — *pesticide paradox* e métricas

**Decisões desta doc, não das fontes:** a tabela de causas de flakiness em ordem de frequência (§ 2), a tabela de test smells (§ 5), a regra de limpeza no teardown (`TS-SUI-08`), e a prescrição de apagar teste que não paga (`TS-SUI-10`).
