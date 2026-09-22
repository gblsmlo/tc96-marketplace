---
titulo: Teste de Software - Dublês de Teste
Link: https://martinfowler.com/bliki/TestDouble.html
tags:
 - testing
 - test-doubles
 - mocking
 - agent-context
source: "Martin Fowler (TestDouble, Mocks Aren't Stubs), Software Engineering at Google cap. 11, e material próprio do vault"
verificado-em: 2026-08-20
---

# Teste de Software — Dublês de Teste

> Satélite de [Teste de Software](teste-de-software.md). Cobre **o que substituir e por quê**, com o vocabulário correto. A árvore está na § 4.2 do hub.
>
> **A tese em uma linha.** "Mock" virou palavra guarda-chuva para cinco coisas diferentes, e a imprecisão não é estética: ela **apaga a pergunta seguinte**. Quando você chama um servidor de mentira de "mock", não se pergunta se ele honra o contrato real. Quando o chama de **fake**, a pergunta aparece sozinha.

---

## 1. A taxonomia de Fowler

Cinco tipos, nas definições da fonte:

| Tipo | Definição | Uso típico |
| --- | --- | --- |
| **dummy** | *"passado adiante mas nunca usado de verdade; geralmente só preenche lista de parâmetros"* | um argumento obrigatório que este teste não exercita |
| **stub** | *"fornece respostas enlatadas às chamadas feitas durante o teste, geralmente sem responder a nada fora do que foi programado"* | `fetch` que devolve um JSON fixo |
| **fake** | *"tem implementação funcional, mas geralmente com um atalho que o torna inadequado para produção"* | banco em memória, servidor de dev com `store` |
| **spy** | *"stubs que também registram informação sobre como foram chamados"* | verificar que o e-mail foi disparado |
| **mock** | *"pré-programado com expectativas que formam uma especificação das chamadas que ele espera receber"* — pode lançar ao receber chamada inesperada, e é **verificado** no fim | verificar a interação como parte da asserção |

**A confusão que mais custa:** um servidor de mentira que **funciona** — tem estado, responde a `POST` e depois a `GET` — é um **fake**. Não é mock. A distinção não é acadêmica: mock e stub são sobre *o que o teste afirma*; fake é sobre *quanta fidelidade a substituição tem* (`TS-DUB-01`).

### 1.1 Verificação de estado × de comportamento

| | Verifica | Dublê típico |
| --- | --- | --- |
| **estado** | o resultado, depois da ação | stub, fake |
| **comportamento** | as chamadas que aconteceram | mock, spy |

Verificação de estado é preferível por default: ela afirma sobre o **resultado observável**, que é o que interessa, e sobrevive a refactor. Verificação de comportamento acopla o teste à **forma da colaboração** — trocar duas chamadas por uma quebra o teste sem mudar o comportamento (`TS-CORE-07`).

**Quando comportamento é o certo:** quando o efeito **é** a saída e não há estado para observar. "Enviou o e-mail", "publicou o evento", "registrou a auditoria" — não há retorno a inspecionar, e a chamada é o contrato.

---

## 2. A pergunta que decide

Antes de qualquer escolha de dublê:

> **Se a dependência real divergisse do meu dublê, este teste deveria quebrar?**

```
SIM → não substitua. Pegar a divergência é o ponto inteiro do teste
NÃO → substitua, e escolha o tipo pela § 1
```

É a `TS-CORE-03`, e é a regra mais rentável desta estrutura. Mock do contrato que o teste veio verificar é **falsa confiança**: o verde prova que o código concorda com a sua própria imitação, não com o mundo.

### 2.1 O caso do CRUD mockado

O exemplo canônico de teatro de teste, e vale detalhar porque ele passa em revisão:

```
Teste E2E "criar pedido e vê-lo na lista", com a API mockada:
 1. POST /pedidos → mock devolve 201 com um id
 2. GET /pedidos → mock devolve uma lista fixa
 3. asserção: o pedido aparece
```

Isso **passa sempre** e não verifica nada. Pior: passa mesmo se cada arquivo de mock tiver seu próprio estado isolado — o `POST` nunca chega ao `GET`. E mesmo que chegasse, o verde só provaria consistência interna da imitação.

O teste existia para provar *"o back-end aceita o pedido e o devolve na listagem"*. Essa é exatamente a dependência mockada. Não deveria ser.

### 2.2 O que É legítimo substituir, mesmo em E2E

São **bordas**, não o miolo:

| Substituição | Por quê |
| --- | --- |
| **relógio e aleatoriedade** | determinismo, e é barato (`TS-DUB-05`) |
| **terceiro que não possuo** | gateway de pagamento, API externa — não devo chamar no teste |
| **condição de erro difícil de provocar** | fabricar 500/timeout para testar a **reação** da UI |
| **autenticação** | é pré-condição, não o objeto do teste |

Note o padrão da terceira linha: o dublê é da **causa**; a **reação** — que é código próprio — continua real. É a forma correta de testar estado de erro, e a razão de o estado de erro merecer teste próprio.

E o padrão geral: **substitua o que atravessa a fronteira do que você possui.** O que é seu, deixe real.

---

## 3. Fidelidade de fake

Fake é a substituição mais poderosa e a mais perigosa, porque ele *funciona* — e funcionar convence.

A pergunta é sempre: **este fake honra o contrato real?**

| Infidelidade comum | Consequência |
| --- | --- |
| estado isolado por arquivo/processo | round-trip nunca acontece; o teste é teatro |
| shape divergindo do real (*drift*) | verde no fake, quebra em produção |
| validação ausente | o fake aceita entrada que o real rejeita |
| erro não modelado | nenhum teste do caminho de erro |
| ordenação ou paginação simplificadas | teste de lista passa e a lista real vem diferente |

**Fake infiel não serve para verificar contrato** — só como ferramenta de desenvolvimento local e para fabricar reação a erro (`TS-DUB-03`). E essa distinção precisa ser **declarada**, porque um fake sem etiqueta é indistinguível de um confiável.

**Fake fiel existe, e é ótimo:** um Postgres em container é essencialmente o real controlado. O critério não é "fake × real", é **fidelidade** — e um container do banco de verdade tem fidelidade quase total por um custo de tamanho medium.

> **Ponte com o stack.** O padrão preferível para persistência não é fake de repositório: é Postgres local com dado isolado por worker ([Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md)). Fake de repositório substitui exatamente a coisa cujo comportamento — transação, constraint, cascade, tipo de coluna — é a mais fácil de errar.

---

## 4. Onde os dublês moram por nível

| Nível | Substituição típica | Observação |
| --- | --- | --- |
| unidade | stub para a fronteira de processo | é o que mantém o teste *small* |
| integração | dependência real controlada; stub só para terceiros | **é aqui que a maior parte dos mocks pertence** |
| componente | stub de módulo, spy de callback | [Storybook - Mocking](storybook-mocking.md) |
| E2E | só as bordas da § 2.2 | E2E deve tender ao real |

A linha da integração é a mais importante: quando um E2E precisa de mock pesado, ele virou **um teste de integração caro e lento disfarçado**. O sinal de que a asserção deveria descer um nível (`TS-CORE-02`).

E no stack, as ferramentas por nível:

| Ferramenta | Mecanismo | Nota |
| --- | --- | --- |
| `bun test` | `mock`, `spyOn`, `mock.module` | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| Storybook | `sb.mock` no preview, `fn`, MSW | [Storybook - Mocking](storybook-mocking.md) |
| Playwright | `route`, `addInitScript`, `clock` | [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) |

---

## 5. Relógio e aleatoriedade

O único caso em que substituir é **sempre** certo, em qualquer nível.

Sem relógio controlado, todo teste que envolve tempo é ou lento (espera de verdade) ou flaky (assume que a máquina é rápida) — e frequentemente os dois. Substituir é barato e resolve uma classe inteira:

| Assunto | Sem controle | Com controle |
| --- | --- | --- |
| "expira em 30 min" | esperar, ou não testar | avançar o relógio |
| "há 3 dias" | teste quebra amanhã | data fixa |
| debounce de 300 ms | espera arbitrária | avançar timers |
| `id` aleatório | asserção frouxa | semente fixa |

`TS-DUB-05`. As APIs concretas: [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 7 e [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md).

---

## 6. Regras — `TS-DUB-01` a `TS-DUB-08`

| ID | Regra |
| --- | --- |
| `TS-DUB-01` | O dublê **MUST** ser chamado pelo nome correto — dummy, stub, fake, mock ou spy. Chamar tudo de "mock" **NEVER**, porque apaga a pergunta seguinte. |
| `TS-DUB-02` | **NEVER** substituir por dublê aquilo que o teste existe para provar. O critério é: se a dependência real divergisse, este teste deveria quebrar? *(apelido de `TS-CORE-03` — cite o canônico)* |
| `TS-DUB-03` | Fake que substitui um sistema real **MUST** ter a fidelidade de contrato declarada. Fake infiel **NEVER** serve para verificar contrato. |
| `TS-DUB-04` | Verificação de estado **MUST** ser a forma default. Verificação de comportamento só quando o efeito **é** a saída e não há estado observável. † |
| `TS-DUB-05` | Relógio e aleatoriedade **MUST** ser substituídos em qualquer nível, inclusive E2E — determinismo se compra aqui, barato. |
| `TS-DUB-06` | E2E que precisa de dublê pesado **MUST** ser reconhecido como teste de integração no nível errado, e descido. † |
| `TS-DUB-07` | Dublê que reproduz o shape de uma resposta **MUST** derivar do tipo exportado pela fonte. Shape redigitado à mão **NEVER**. † |
| `TS-DUB-08` | Persistência **NEVER** é substituída por fake de repositório quando um banco real controlado é viável: transação, constraint e cascade são justamente o que o fake não tem. † |

---

## 7. Antipadrões

### 7.1 "Mock" para tudo

```
✗ "o mock do servidor" (é um fake)
✗ "mockei o fetch" (é um stub)
✗ "mock do relógio" (é um fake ou stub)
```

Cada nome errado é uma pergunta que não foi feita (`TS-DUB-01`).

### 7.2 Mockar o contrato que o teste vem provar

Ver § 2.1. Passa sempre, prova nada (`TS-DUB-02`).

### 7.3 Fake com estado isolado por processo

O `POST` grava num lugar e o `GET` lê de outro. O round-trip nunca acontece, e o teste que existia para verificar o round-trip fica verde (`TS-DUB-03`).

### 7.4 Verificação de comportamento por default

```ts
// ✗ quebra ao trocar duas chamadas por uma, sem mudar comportamento
expect(repo.save).toHaveBeenCalledTimes(2);
// ✓
expect(await repo.buscar(id)).toEqual({ …, status: 'aprovado' });
```

(`TS-DUB-04`)

### 7.5 Shape redigitado à mão

```ts
// ✗ o servidor manda "quantidade"; o mock diz "qty"
route.fulfill({ json: { id: 1, name: 'Café', qty: 2 } });
```

O mock passa, o real quebra — e o teste que existia para pegar drift de contrato foi o que introduziu o drift (`TS-DUB-07`).

### 7.6 Fake de repositório

Substitui exatamente o que é mais fácil de errar: transação, constraint, cascade, tipo de coluna (`TS-DUB-08`).

### 7.7 Esperar o tempo passar

```ts
// ✗ 61 s de teste, e ainda flaky
await sleep(61_000);
```

(`TS-DUB-05`)

### 7.8 Mock pesado em E2E "por velocidade"

Produz o pior dos dois: o custo de infraestrutura do E2E, com a fidelidade de um teste de integração (`TS-DUB-06`).

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub; a § 4.2 é a árvore de substituição
- [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) — a regra de substituir o que atravessa fronteira de processo
- [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) — determinismo, que o § 5 compra
- [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Storybook - Mocking](storybook-mocking.md) · [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) — as ferramentas por nível
- `Hono - Validação e RPC` · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — de onde o shape deve vir
- — o critério de quando mock não basta
- [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) — por que fake de repositório perde o que importa
- — a fronteira que torna a substituição possível

## Fontes consultadas

Verificadas em **2026-08-20**:

- [Martin Fowler — Test Double](https://martinfowler.com/bliki/TestDouble.html) — as cinco definições, citadas literalmente na § 1
- [Martin Fowler — The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) — solitary × sociable, e onde os dublês pertencem por nível
- [Software Engineering at Google, cap. 11](https://abseil.io/resources/swe-book/html/ch11.html) — dublê e tamanho de teste; teste de escopo amplo pode ser *small* com dublês fora do processo

**Material do próprio vault.** A formulação da § 2 ("se a dependência real divergisse, este teste deveria quebrar?"), a análise do CRUD mockado da § 2.1 e a lista de substituições legítimas em E2E da § 2.2 vêm de material de trabalho existente neste vault — não de uma das fontes externas. Elas estão registradas aqui porque são mais precisas que o que as fontes dizem sobre o assunto, e porque a nota original é transitória. Ver a observação em [Teste de Software](teste-de-software.md) § Fontes.
