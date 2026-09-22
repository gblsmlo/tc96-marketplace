---
Link: https://www.guru99.com/equivalence-partitioning-boundary-value-analysis.html
tags:
 - testing
 - test-design
 - coverage
 - agent-context
source: "guru99 (EP/BVA, white box, cobertura), ISTQB CTFL v4.0 (as três categorias de técnica), Mutation testing"
verificado-em: 2026-08-20
---

# Teste de Software — Técnicas de Design de Caso

> Satélite de [Teste de Software](teste-de-software.md). Cobre **como derivar os casos** — a parte mais mecanizável e mais ignorada da disciplina. A árvore está na § 4.3 do hub.
>
> **Por que importa mais do que parece.** "Testei" quase sempre significa "testei o caminho feliz com um valor que eu inventei". As técnicas desta nota transformam isso num conjunto pequeno e justificável de casos — e a primeira delas, valor limite, pega a classe de defeito mais comum que existe por um custo quase nulo.

---

## 1. As três categorias

Vocabulário ISTQB:

| Categoria | Deriva os casos de | Precisa ver o código? |
| --- | --- | --- |
| **caixa-preta** (*specification-based*) | especificação, requisito, contrato | não |
| **caixa-branca** (*structure-based*) | estrutura do código | sim |
| **baseada em experiência** | conhecimento de domínio e de falhas típicas | opcional |

**Caixa-cinza** (*grey box*) é a combinação: derivar da especificação, com conhecimento parcial da estrutura para escolher onde apertar. É o que na prática se faz.

**A relação com nível é ortogonal:** técnica de caixa-preta serve em unidade, e cobertura de ramo serve em integração. Escolher a técnica não escolhe o nível.

---

## 2. Caixa-preta

### 2.1 Partição de equivalência

Divide o domínio de entrada em classes cujos membros o sistema **deveria** tratar igual, e testa **um** representante de cada.

Campo de senha que aceita 6 a 10 caracteres:

| Partição | Tamanho | Esperado |
| --- | --- | --- |
| 1 | 0–5 | rejeita |
| 2 | 6–10 | aceita |
| 3 | 11+ | rejeita |

Três casos em vez de onze. O pressuposto — que o sistema trata os membros de uma classe igual — é justamente o que a próxima técnica ataca onde ele mais falha.

**Cubra as classes inválidas.** Partição de equivalência tem valor sobretudo por forçar as classes **inválidas** a aparecerem: é onde o comportamento raramente está especificado, e onde o defeito mora.

### 2.2 Análise de valor limite

Testa as **extremidades** de cada classe. Defeito se concentra em fronteira, porque fronteira é onde `<` e `<=` se confundem.

Quantidade válida de 1 a 10:

| Valor | Esperado | Por quê |
| --- | --- | --- |
| 0 | rejeita | logo abaixo do mínimo |
| 1 | aceita | o mínimo |
| 10 | aceita | o máximo |
| 11 | rejeita | logo acima do máximo |

A forma de cinco pontos (mínimo, logo acima, nominal, logo abaixo do máximo, máximo) é a variante que a fonte apresenta; a de quatro acima é a de duas fronteiras, mais usada.

> **Se for para aprender uma técnica, é esta.** Ela converte "testei com 5" em quatro casos que pegam off-by-one, `>` × `>=`, e a validação que esqueceu de tratar o zero. Custo: minutos (`TS-TEC-01`).

E os limites **não numéricos**, que são os mais esquecidos:

| Fronteira | Casos |
| --- | --- |
| coleção | vazia, um elemento, muitos, o máximo permitido |
| string | vazia, um caractere, o tamanho máximo, acima dele |
| texto | espaço no início/fim, acento, emoji, RTL |
| opcional | ausente, `null`, presente e vazio |
| data | fim de mês, ano bissexto, virada de fuso, horário de verão |
| número | zero, negativo, precisão de ponto flutuante |

**Coleção vazia é a fronteira que mais quebra UI** — e é o estado "vazio" que a `TS-TIPO-02` exige.

### 2.3 Tabela de decisão

Para quando a saída depende da **combinação** de condições.

Frete de um pedido:

| # | É assinante | Valor ≥ 200 | Região atendida | → Frete |
| --- | --- | --- | --- | --- |
| 1 | sim | sim | sim | grátis |
| 2 | sim | não | sim | grátis |
| 3 | não | sim | sim | grátis |
| 4 | não | não | sim | cobrado |
| 5 | — | — | não | indisponível |

O valor da tabela é o que ela **revela ao ser montada**: a linha 5 colapsa oito combinações, e a pergunta "e se não é assinante, valor alto, região não atendida?" costuma não ter resposta na especificação. A tabela encontra o requisito faltando antes de qualquer código.

### 2.4 Transição de estado

Para quando o comportamento depende do que veio antes.

```
rascunho ──enviar──▶ em análise ──aprovar──▶ aprovado ──emitir──▶ emitido
 │
 └──rejeitar──▶ rejeitado ──corrigir──▶ rascunho
```

Cubra: **as transições válidas**, e — o que quase ninguém faz — **as inválidas**: aprovar um rascunho, emitir um rejeitado, enviar duas vezes. Transição inválida que o sistema aceita é uma das classes de defeito mais danosas, porque corrompe estado em vez de dar erro.

### 2.5 Caso de uso e pairwise

**Caso de uso** deriva casos do fluxo do ator — principal, alternativos, exceções. É a técnica natural para E2E, e o que dá o critério de "jornada crítica" da `TS-NIV-02`.

**Pairwise** (*all-pairs*): quando há muitos parâmetros independentes, testar todas as combinações é impossível (segundo princípio: *exhaustive testing is impossible*). Pairwise cobre todos os **pares** de valores, o que empiricamente pega a maior parte dos defeitos de interação com uma fração dos casos. É a técnica para matriz de configuração — browser × SO × locale × tema.

> **Não verificado nesta rodada:** exemplo trabalhado de pairwise. A técnica é reconhecida e a ideia está correta; o dimensionamento exato de um conjunto pairwise depende de ferramenta e não foi conferido nas fontes desta verificação.

---

## 3. Caixa-branca

### 3.1 Cobertura estrutural

| Critério | Exige | Nota |
| --- | --- | --- |
| **instrução** (*statement*) | cada linha executada | o mais fraco |
| **ramo/decisão** (*branch*) | cada decisão avaliada **verdadeira e falsa** | o piso razoável |
| **condição** | cada condição atômica nos dois valores | dentro de `&&`/`\|\|` |
| **caminho** (*path*) | cada caminho possível | explode combinatorialmente |

**Instrução e ramo não são a mesma coisa**, e a diferença é a que mais engana:

```ts
function aplicar(v: number, cupom?: string) {
 let total = v;
 if (cupom) total = total * 0.9;
 return total;
}
```

Um único teste com `aplicar(100, 'X')` executa **todas as linhas** — 100% de cobertura de instrução — e nunca avalia `if (cupom)` como falso. O caso sem cupom, que é o mais comum em produção, não foi verificado (`TS-TEC-05`).

### 3.2 Complexidade ciclomática

Mede o número de caminhos independentes de uma função (McCabe). Serve para duas coisas:

1. **estimar o mínimo de casos** para cobertura de caminho;
2. **sinalizar risco** — complexidade alta concentra defeito e é candidata a refatorar antes de testar.

Uma função com complexidade 15 não precisa de 15 testes: precisa ser quebrada em três funções. É o encontro de teste com e — código difícil de testar é código a melhorar, e a dificuldade de teste é o sinal mais confiável de desenho ruim que existe.

### 3.3 Por que cobertura não é a métrica

Cobertura mede **execução**, não **verificação**. Um teste que chama a função e não afirma nada dá cobertura total.

```ts
// 100% de cobertura, zero verificação
test('calcula', => { calcularFrete(pedido); });
```

Isso não é hipótese: é o resultado direto de tratar cobertura como meta (`TS-CORE-05`). A métrica que mede o que se queria está na § 4.

**O que cobertura serve para:** achar código **não** coberto. Um relatório de cobertura é bom para responder "que ramo ninguém testou?" e péssimo como número de meta. Ver [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) para a operação.

---

## 4. Teste de mutação — a métrica que mede asserção

Modifica o código de propósito e pergunta se a suíte percebe.

| Termo | Significa |
| --- | --- |
| **mutante** | uma versão do programa com uma alteração aplicada |
| **operador de mutação** | a regra da alteração: `+`→`*`, `>`→`>=`, remover instrução |
| **mutante morto** (*killed*) | algum teste falhou — a suíte percebeu |
| **mutante sobrevivente** | todos os testes passaram — **a suíte não percebeu** |
| **mutation score** | mortos ÷ total |
| **mutante equivalente** | alterado mas com comportamento idêntico; é o custo prático da técnica |

**O mutante sobrevivente é o produto útil**: ele aponta, com precisão de linha, a asserção que falta. É a diferença entre "esta linha rodou" e "a saída desta linha foi conferida".

**A versão barata, para o dia a dia:** não é preciso ferramenta. Quebre o código de propósito — troque um sinal, remova uma condição, devolva `null` — e veja se algo fica vermelho. Se nada quebrar, a asserção não existe. É o item 3 da § 4.5 do hub, e cabe em trinta segundos.

---

## 5. Baseada em experiência

| Técnica | O que é |
| --- | --- |
| **error guessing** | derivar casos do conhecimento de onde este tipo de sistema costuma falhar |
| **exploratório** | investigar sem roteiro, projetando e executando ao mesmo tempo |
| **checklist** | lista de verificações acumuladas por experiência |

Elas parecem menos rigorosas e são as que mais acham defeito **novo** — porque as outras derivam da especificação, e a especificação é onde o defeito de requisito já está.

**Checklist é o formato que acumula.** Toda vez que um defeito escapa, a pergunta é "que verificação teria pegado?" — e a resposta entra na checklist. É o mecanismo que faz uma equipe melhorar, e é QA no sentido de: processo, não entregável.

O *pesticide paradox* se aplica aqui também: checklist fixa envelhece. Ela precisa de revisão periódica.

---

## 6. Regras — `TS-TEC-01` a `TS-TEC-09`

| ID | Regra |
| --- | --- |
| `TS-TEC-01` | Entrada com faixa ou limite de tamanho **MUST** receber análise de valor limite. Testar só o caminho feliz **NEVER**. |
| `TS-TEC-02` | Partição de equivalência **MUST** cobrir as classes **inválidas**, não só as válidas. |
| `TS-TEC-03` | Coleção **MUST** ter caso para vazia, um elemento e o máximo permitido. † |
| `TS-TEC-04` | Máquina de estado **MUST** ter caso para transição **inválida**, não só para as válidas. † |
| `TS-TEC-05` | Cobertura de instrução e de ramo **NEVER** são a mesma coisa: 100% de instrução com um `if` sem o ramo falso é possível. |
| `TS-TEC-06` | Complexidade ciclomática alta **MUST** ser tratada como sinal de refatorar antes de testar, não como quantidade de casos a escrever. † |
| `TS-TEC-07` | Cobertura **MUST** ser usada para achar o que **não** está coberto, **NEVER** como número de meta. |
| `TS-TEC-08` | Antes de declarar um conjunto de testes suficiente, o código **MUST** ser quebrado de propósito para confirmar que algo fica vermelho. † |
| `TS-TEC-09` | Combinação de muitos parâmetros independentes **MUST** ser reduzida por critério explícito (pairwise ou risco), **NEVER** por escolha arbitrária de algumas combinações. † |

---

## 7. Antipadrões

### 7.1 Um valor inventado no meio da faixa

```ts
// ✗
expect(validarQuantidade(5)).toBe(true);
```

Não pega off-by-one, nem `>` × `>=`, nem zero. Quatro casos de limite pegam os três (`TS-TEC-01`).

### 7.2 Só as classes válidas

Testar senha de 8 caracteres e nunca a de 3 nem a de 50. As classes inválidas é onde o comportamento não está especificado (`TS-TEC-02`).

### 7.3 Lista sempre com três itens

Nenhum teste com lista vazia. O estado vazio é o que mais quebra UI, e é o mais barato de cobrir (`TS-TEC-03`).

### 7.4 Só transições válidas

Verificar que aprovar um pedido em análise funciona, e nunca que aprovar um rascunho falha. Transição inválida aceita corrompe estado (`TS-TEC-04`).

### 7.5 Meta de cobertura no CI

```
✗ "cobertura mínima de 80%"
```

Produz testes escritos para subir número — chamadas sem asserção, testes de getter. Ele sobe, e a suíte não detecta mais nada do que detectava (`TS-TEC-07`).

### 7.6 100% de instrução como prova

Ver § 3.1. É possível e comum (`TS-TEC-05`).

### 7.7 Escrever 15 testes para uma função de complexidade 15

O sinal era para refatorar (`TS-TEC-06`).

### 7.8 Declarar suficiente sem quebrar nada

Trinta segundos de verificação que separa suíte real de suíte decorativa (`TS-TEC-08`).

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub; a § 4.3 é a árvore de técnica
- [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) — cobertura, mutação e test smells em detalhe
- [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) — os cinco estados de um fluxo
- [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) — técnica e nível são ortogonais
- [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) — a operação de cobertura no stack
- [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) — onde os casos derivados aqui são escritos
- `Zod - Validação de Ambiente` — a fronteira que as classes inválidas atacam
- · · — complexidade como sinal
- — checklist como instrumento de processo

## Fontes consultadas

Verificadas em **2026-08-20**:

- [guru99 — Equivalence Partitioning & Boundary Value Analysis](https://www.guru99.com/equivalence-partitioning-boundary-value-analysis.html) — definições e os exemplos trabalhados (pizza 1–10, senha 6–10)
- [guru99 — Software Testing](https://www.guru99.com/software-testing.html) — tabela de decisão, transição de estado, caso de uso; caixa-branca, McCabe, cobertura, basis path
- [Mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) — mutante, operador, killed/surviving, mutation score, mutantes equivalentes
- As três categorias de técnica (caixa-preta, caixa-branca, baseada em experiência) são vocabulário ISTQB CTFL v4.0 — **verificado por fonte terciária**, ver a ressalva em [Teste de Software](teste-de-software.md) § Fontes

**Não verificado, declarado:** exemplo trabalhado de **pairwise/all-pairs** (§ 2.5). A técnica é reconhecida e a descrição está correta; o dimensionamento de um conjunto pairwise concreto não foi conferido nesta rodada.
