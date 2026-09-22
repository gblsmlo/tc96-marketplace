---
titulo: Teste de Software
Link: https://www.guru99.com/software-testing.html
tags:
 - testing
 - software-quality
 - qa
 - reference
 - agent-context
source: "guru99.com/software-testing (taxonomia clássica), ISTQB CTFL v4.0, Martin Fowler (test pyramid, test doubles), Kent C. Dodds (testing trophy), Software Engineering at Google cap. 11"
verificado-em: 2026-08-20
---
# Teste de Software — referência conduzida

> **O que esta nota é.** A **camada de conceito** de teste neste vault: o vocabulário, os níveis, as técnicas e a economia da decisão. É o que vem *antes* de escolher ferramenta. Para mim ao decidir o que testar e onde; para agentes de código ao propor, revisar ou justificar um teste.
>
> **O que não é.** Não é documentação de ferramenta. Nenhum exemplo aqui é específico de runner. Quando a pergunta for "como escrevo isso", a resposta está numa das notas de ferramenta da § 3 — e esta nota existe para você chegar lá tendo decidido **o quê** e **em que nível**.
>
> **Por que ela existe.** O vault tinha três estruturas de ferramenta de teste ([Bun - Testes](bun-testes.md), [Storybook - Testes e Interações](storybook-testes-e-interacoes.md), [Playwright](playwright.md)) e nenhuma camada que decidisse entre elas. O resultado previsível é o que a economia da pirâmide descreve: asserção caindo na camada mais cara que a comporta, em vez da mais barata que ainda pega o defeito.

Fontes verificadas em **2026-08-20**. Ver [Fontes consultadas](#fontes-consultadas) — incluindo o que **não** foi possível verificar na fonte primária.

---

## 0. Antes de tudo: três distinções que decidem a conversa

Quase toda discussão improdutiva sobre teste é uma destas três confundidas.

**1. Erro × defeito × falha.** Uma pessoa comete um **erro** (*error*, engano humano), que produz um **defeito** (*defect*/*bug*, o problema no artefato), que *pode* causar uma **falha** (*failure*, o comportamento errado observado em execução). Defeito sem execução não vira falha; falha sem defeito no código pode vir de ambiente ou dado. A cadeia importa porque decide **onde** procurar: revisão de código pega defeito sem execução, teste pega falha.

**2. Verificação × validação.** Verificação pergunta *"construímos certo?"* — conformidade com a especificação. Validação pergunta *"construímos a coisa certa?"* — adequação à necessidade real. Uma suíte 100% verde é verificação perfeita e não diz nada sobre validação. É o sétimo princípio da § 2: **absence-of-errors fallacy**.

**3. QA × QC.** QA age no **processo** (prevenir), QC age no **entregável** (detectar). Teste automatizado é QC; a política que exige teste em todo PR é QA. Isto já está registrado em e vale relembrar aqui porque "melhorar a qualidade" sem dizer qual dos dois é a origem da maior parte das iniciativas que não pegam.

**Consequência prática das três:** "o teste passou" responde uma pergunta estreita. Saber qual é a pergunta estreita é o trabalho.

---

## 1. Como usar esta doc

### Para um humano

Leia a § 2 (modelo mental) e a § 4 (as árvores) uma vez. Elas são o conteúdo real. O resto é vocabulário para consultar quando aparecer um termo — e a § 3 é o mapa para sair daqui em direção à ferramenta.

Se a pergunta é *"quantos testes eu escrevo e de que tipo"*, vá para a § 4.1. Se é *"o que eu mocko"*, § 4.2. Se é *"por que a suíte não me dá confiança"*, § 4.5.

### Para um agente de código

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 0, § 2, § 4, § 6) | Antes de **propor** ou **avaliar** uma estratégia de teste |
| 2 | O satélite do domínio | Quando a decisão exigir vocabulário preciso — use a § 5 |
| 3 | A nota de **ferramenta** da § 3 | Só depois de decidido o nível. É lá que mora o "como" |

**A regra de economia:** esta estrutura decide *o quê*; as notas de ferramenta dizem *como*. Carregar as duas camadas ao mesmo tempo para uma tarefa que é só de escrita de teste desperdiça contexto — se o nível já está decidido, vá direto para a ferramenta.

**E a inversa, que é o erro mais comum de agente:** receber "escreva um teste para isto" e escrever um E2E porque E2E é o que parece mais completo. A § 4.1 existe para essa decisão não ser por default.

### Convenções

Os termos aparecem com o nome em inglês entre parênteses na primeira ocorrência, porque a literatura e as ferramentas usam o inglês e a busca precisa achar. As famílias de regra são `TS-*`.

**Marcação de origem:** regra sem marca vem de afirmação explícita de uma das fontes. Regra marcada **†** é decisão desta doc — coerente com as fontes, mas não ditada por elas. Mesma convenção de [Storybook](storybook.md) e [Playwright](playwright.md).

---

## 2. Modelo mental

Cinco afirmações. Elas são a doc; o resto é vocabulário.

**1. Um teste compra informação a um preço.** O preço tem três moedas: tempo de execução, custo de manutenção e probabilidade de falhar sem motivo (*flakiness*). A informação é: *que classe de defeito este teste pega?* Toda decisão de teste é essa razão. Um teste que não pega nenhum defeito plausível é custo puro, mesmo passando; um que pega uma classe importante barato é o melhor investimento do repositório.

**2. Empurre cada asserção para a camada mais barata que ainda pega o defeito.** É a formulação operacional da pirâmide, e a única regra desta doc que resolve sozinha a maioria dos casos. Corolário direto de Fowler: se um teste de nível alto pega um erro e **nenhum** teste de nível baixo falhou, falta um teste de nível baixo. Corolário inverso, mais esquecido: um teste de nível alto que verifica a mesma condicional que um de nível baixo já verifica não acrescenta confiança — acrescenta manutenção.

**3. Nunca mocke aquilo que o teste existe para provar.** A pergunta decisiva não é "e2e pode ter mock?" e sim: *se a dependência real divergisse, este teste deveria quebrar?* Se sim, não substitua — pegar a divergência é o ponto inteiro. Se não, substitua à vontade. Mock do contrato que o teste veio verificar é **falsa confiança**: o verde prova que o código concorda com a sua própria imitação.

**4. Cobertura mede execução, não verificação.** Uma linha coberta é uma linha que rodou, não uma linha cuja saída foi conferida. Uma suíte com 90% de cobertura e nenhuma asserção significativa tem 90% de cobertura. A métrica que mede o que se queria medir é **mutação** ([Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) § 4) — e a checagem barata que serve no dia a dia é: quebre o código de propósito e veja se algo fica vermelho.

**5. Uma suíte não confiável é pior que nenhuma suíte.** Não é retórica: é aritmética. Com 0,1% de flakiness e 10 000 testes por dia, são 10 investigações diárias sem defeito nenhum. A partir de ~1% de flakiness, a suíte perde valor — as pessoas param de acreditar no vermelho, e o vermelho verdadeiro passa junto com os falsos. É por isso que determinismo não é um refinamento: é pré-requisito.

> **A inversão que importa.** É natural pensar em teste como atividade de **encontrar defeitos**. Isso descreve o teste manual exploratório e descreve mal uma suíte automatizada. A suíte automatizada quase nunca encontra um defeito novo — ela **detecta a reintrodução** de um defeito conhecido e **sustenta mudança**. Quem mede uma suíte por defeitos novos encontrados conclui que ela é inútil; quem a mede por "quanto eu consigo refatorar sem medo" entende o que comprou.
>
> É também o que o **pesticide paradox** diz: um conjunto fixo de casos para de achar defeitos novos com o tempo. Isso não é falha da suíte — é a natureza dela. Achar defeito novo é trabalho de teste exploratório, de revisão e de produção observada.

---

## 3. Onde a ferramenta mora

Esta nota decide o nível. A partir daí, o "como" está aqui — e este mapa é a razão principal de a estrutura existir.

| Nível / propósito | Ferramenta no stack | Nota |
| --- | --- | --- |
| unidade e integração (Node/Bun, backend, funções puras) | `bun test` | [Bun - Testes](bun-testes.md) |
| componente isolado, estados de UI, a11y de componente | Storybook + addon-vitest | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| jornada de usuário atravessando rota, rede e sessão | Playwright | [Playwright](playwright.md) |
| contrato entre cliente tipado e servidor | tipo exportado do servidor | `Hono - Validação e RPC`, [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| validação de entrada em runtime | Zod / TypeBox | `Zod - Validação de Ambiente`, [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| estático (tipo e lint) | TypeScript + Biome | `TypeScript` |
| persistência e migração | Drizzle + Postgres local | [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) |

**A fronteira componente × jornada** é a que mais gera indecisão, e o critério é curto: se o teste precisa de **rota, login ou mais de uma tela**, é Playwright; se ele varia **props de um componente**, é story. A [Playwright](playwright.md) § 8 registra ainda que o component testing do Playwright (não-experimental desde a 1.62) cria uma sobreposição nova com Storybook, e a decisão deste vault é não migrar o que já funciona.

---

## 4. Árvores de decisão

### 4.1 Em que nível este teste vai

```
O que exatamente pode dar errado? (escreva a frase antes de escolher)
│
├─ regra de cálculo, transformação, parse, validação, invariante de domínio
│ → UNIDADE. Barato, rápido, determinístico. É onde a maior parte deveria estar
│
├─ duas ou mais peças minhas conversando (caso de uso + repositório, handler + schema)
│ → INTEGRAÇÃO com dependência real controlada (Postgres local, servidor em memória)
│
├─ o formato do que atravessa a fronteira com um sistema que não é meu
│ → CONTRATO. E se o tipo vem do servidor, o compilador já é metade do teste
│
├─ o estado visual/interativo de um componente (loading, vazio, erro, desabilitado)
│ → COMPONENTE (story). Um estado nomeado por story
│
└─ a jornada crítica funciona de ponta a ponta, no browser, com sessão real
 → E2E. Poucos. Só jornada crítica, nunca regra de negócio

Não sei responder "o que pode dar errado"?
→ o teste ainda não deveria ser escrito. Essa frase É o teste
```

**As proporções de referência**, com a origem — porque elas divergem, e a divergência é informação:

| Modelo | Forma | Fonte |
| --- | --- | --- |
| Pirâmide de testes | muitos unidade, alguns serviço, pouquíssimos UI | Cohn, via Fowler |
| **80 / 15 / 5** | 80% escopo estreito, 15% médio, 5% ponta a ponta | Google (cap. 11) |
| Testing Trophy | estático na base, **maior massa em integração**, pouco E2E | Kent C. Dodds |

Pirâmide e Trophy discordam sobre **onde fica a massa** — unidade ou integração — e a discordância é real, não terminológica. Ela se resolve por contexto: quanto mais a lógica do sistema vive **entre** as peças (BFF, adaptação de dado, orquestração), mais o Trophy descreve o ótimo; quanto mais ela vive **dentro** de funções (cálculo, domínio rico), mais a pirâmide descreve. O que os dois concordam é o que mais importa: **E2E é a menor fatia**, e nenhum dos dois tolera o *ice-cream cone* — a forma invertida, com massa em E2E, que é lenta, frágil e caríssima de manter.

### 4.2 O que substituir por dublê

```
Se a dependência real divergisse do meu dublê, este teste deveria quebrar?
├─ SIM → NÃO substitua. Use a coisa real (ou um ambiente controlado dela).
│ Substituir aqui é falsa confiança (TS-CORE-03)
└─ NÃO → substitua, e escolha o dublê certo:
 ├─ só preciso preencher um parâmetro → dummy
 ├─ preciso de uma resposta pronta → stub
 ├─ preciso de uma implementação que funcione → fake
 ├─ preciso verificar QUE foi chamado → mock ou spy
 └─ é relógio, aleatoriedade, ou terceiro que não possuo → substitua sempre

Legítimo substituir mesmo em E2E (são bordas, não o miolo):
 relógio e aleatoriedade · terceiro que não possuo · condição de erro
 difícil de provocar (500, timeout) · autenticação como andaime
```

A taxonomia completa está em [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md). O ponto de vocabulário que mais confunde: um "mock server" que tem `store` e funciona é um **fake**, não um mock — e chamá-lo pelo nome certo já revela a pergunta seguinte, que é *ele honra o contrato real?*

### 4.3 Que técnica usa para desenhar os casos

```
Tenho a especificação, e não preciso olhar o código?
└─ CAIXA-PRETA (specification-based)
 ├─ entrada tem faixas/classes? → partição de equivalência
 ├─ tem limite numérico ou de tamanho? → análise de valor limite ← o mais rentável
 ├─ a saída depende de combinação de condições? → tabela de decisão
 └─ o comportamento depende do estado anterior? → transição de estado

Preciso garantir que o código foi exercitado?
└─ CAIXA-BRANCA (structure-based)
 → cobertura de instrução, de ramo; complexidade ciclomática como sinal de risco

Tenho experiência no domínio e tempo limitado?
└─ BASEADO EM EXPERIÊNCIA
 → error guessing, teste exploratório, checklist
```

Se for para aprender **uma** técnica: **análise de valor limite**. Defeito se concentra em fronteira, e ela transforma "testei o caminho feliz" em quatro ou cinco casos que pegam a classe de bug mais comum que existe. Detalhe em [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md).

### 4.4 Quando parar de escrever teste

```
As jornadas críticas têm um E2E cada? não → escreva
As regras de negócio têm teste de unidade? não → escreva
As fronteiras (limite, vazio, nulo, erro) têm caso? não → escreva
Todo defeito de produção que voltou tem um teste que o pega? não → escreva ESSE primeiro
Quebrando o código de propósito, algo fica vermelho? não → as asserções são fracas

Tudo acima resolvido, e ainda quero subir cobertura?
→ pare. Cobertura acima do necessário compra pouco e custa manutenção (TS-CORE-05)
```

O gatilho de maior retorno da lista é o quarto: **teste que nasce de defeito real** é o único que tem prova de pegar algo que aconteceu de verdade.

### 4.5 A suíte não me dá confiança — por quê

```
1. Alguma falha é intermitente?
 → flakiness. É o problema nº 1, e ele contamina todo o resto
 (TS-CORE-04 · [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md))

2. Quando falha, dá para saber o motivo em menos de um minuto?
 → não: diagnóstico ruim. Nome de teste, granularidade, ou instrumentação
 (trace, step) — [Playwright - Debug e Trace](playwright-debug-e-trace.md)

3. Quebrando o código de propósito, algo fica vermelho?
 → não: asserção fraca ou dublê no lugar errado (TS-CORE-03)

4. Um refactor sem mudança de comportamento quebra muitos testes?
 → os testes observam implementação, não comportamento

5. A suíte demora tanto que ninguém roda antes de abrir PR?
 → forma invertida (ice-cream cone): massa no nível errado (§ 4.1)

6. Passa tudo e defeito chega em produção?
 → cobertura de CLASSE de risco, não de linha. Que tipo de teste falta? (§ 5)
```

---

## 5. Mapa dos satélites

| Nota | Cobre | Família |
| --- | --- | --- |
| [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) | unidade, integração, sistema, aceitação; componente e contrato; solitary × sociable; tamanho × escopo (Google); a economia da pirâmide × trophy | `TS-NIV-*` |
| [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) | funcional × não funcional; performance, carga, estresse, soak, spike; segurança, usabilidade, acessibilidade, compatibilidade; smoke, sanity, regressão, reteste; alpha/beta/UAT; exploratório | `TS-TIPO-*` |
| [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) | caixa-preta, branca e cinza; partição de equivalência, valor limite, tabela de decisão, transição de estado, caso de uso, pairwise; cobertura estrutural, complexidade ciclomática | `TS-TEC-*` |
| [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) | dummy, stub, fake, mock, spy; verificação de estado × de comportamento; o que nunca substituir; fidelidade de fake | `TS-DUB-*` |
| [Teste de Software - Processo e Artefatos](teste-de-software-processo-e-artefatos.md) | STLC, estratégia × plano, cenário × caso, RTM, critério de entrada/saída, ciclo de vida do defeito, severidade × prioridade, métricas, V-model, shift-left | `TS-PROC-*` |
| [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) | flakiness (causas e aritmética), determinismo, isolamento, cobertura e seus limites, teste de mutação, test smells, manutenção | `TS-SUI-*` |

---

## 6. Regras normativas

Convenção: `MUST`/`NEVER` são normativos. **†** marca decisão desta doc.

### `TS-CORE-*` — os princípios que sobrevivem a qualquer ferramenta

| ID | Regra |
| --- | --- |
| `TS-CORE-01` | Antes de escrever um teste, **MUST** existir a frase "o que pode dar errado aqui". Teste sem essa frase **NEVER** — não há como julgar se ele vale o custo. † |
| `TS-CORE-02` | Cada asserção **MUST** ficar na camada mais barata que ainda pega o defeito. Verificar em E2E uma condicional já verificada em unidade **NEVER**. |
| `TS-CORE-03` | **NEVER** substituir por dublê aquilo que o teste existe para provar. O critério é: se a dependência real divergisse, este teste deveria quebrar? |
| `TS-CORE-04` | Teste intermitente **MUST** ser tratado como defeito da suíte, com a mesma prioridade de um bug. Conviver com flaky **NEVER**. |
| `TS-CORE-05` | Cobertura **NEVER** é meta. Ela é sintoma; a pergunta é se a asserção detecta a quebra. |
| `TS-CORE-06` | Defeito encontrado em produção **MUST** gerar um teste que o pegue, no nível mais barato que o pegue. † |
| `TS-CORE-07` | Teste **MUST** observar comportamento observável, **NEVER** detalhe de implementação — salvo quando o detalhe é o próprio contrato em teste. |
| `TS-CORE-08` | Suíte verde **NEVER** é evidência de adequação ao usuário. Isso é validação, e ela não vem de teste automatizado (absence-of-errors fallacy). |

### 6.1 Regras críticas dos satélites

Reproduzidas **verbatim**; o satélite é canônico.

| ID | Regra | Satélite |
| --- | --- | --- |
| `TS-NIV-02` | E2E **MUST** cobrir jornada crítica. Regra de negócio em E2E **NEVER** — ela pertence à unidade. | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| `TS-NIV-04` | A forma da suíte **NEVER** é *ice-cream cone* (massa em E2E). Pirâmide e trophy discordam sobre onde fica a massa; nenhum tolera a forma invertida. | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| `TS-NIV-06` | Tamanho e escopo de teste **NEVER** são a mesma coisa: escopo é quanto de código se **verifica**, tamanho é quanto de recurso se **consome**. | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| `TS-TIPO-03` | Teste de regressão e reteste **NEVER** são sinônimos: reteste confirma **um** defeito corrigido; regressão verifica que o resto continua funcionando. | [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) |
| `TS-TIPO-05` | Atributo não funcional que é requisito **MUST** ter critério numérico e um teste que o meça. "Deve ser rápido" **NEVER** é requisito. † |
| `TS-TEC-01` | Entrada com faixa ou limite de tamanho **MUST** receber análise de valor limite. Testar só o caminho feliz **NEVER**. |
| `TS-TEC-05` | Cobertura de instrução e de ramo **NEVER** são a mesma coisa: 100% de instrução com um `if` sem o ramo falso é possível. |
| `TS-DUB-01` | O dublê **MUST** ser chamado pelo nome correto — dummy, stub, fake, mock ou spy. Chamar tudo de "mock" **NEVER**, porque apaga a pergunta seguinte. |
| `TS-DUB-03` | Fake que substitui um sistema real **MUST** ter a fidelidade de contrato declarada. Fake infiel **NEVER** serve para verificar contrato. |
| `TS-DUB-05` | Relógio e aleatoriedade **MUST** ser substituídos em qualquer nível, inclusive E2E — determinismo se compra aqui, barato. |
| `TS-PROC-02` | Estratégia de teste e plano de teste **NEVER** são o mesmo artefato: estratégia é política, duradoura e organizacional; plano é de um projeto ou release. |
| `TS-PROC-04` | Severidade e prioridade **NEVER** são a mesma coisa: severidade é impacto técnico (do teste), prioridade é ordem de correção (do negócio). |
| `TS-PROC-06` | Relatório de defeito **MUST** conter passos de reprodução, resultado esperado, resultado obtido e ambiente. Sem isso, **NEVER** é relatório — é aviso. † |
| `TS-SUI-01` | Teste **MUST** ser determinístico: mesma entrada, mesmo resultado, em qualquer ordem e em paralelo. |
| `TS-SUI-03` | Retry **NEVER** é conserto de flakiness. Ele é anestésico, e mascara tanto o falso vermelho quanto o verdadeiro. |
| `TS-SUI-05` | Cada teste **MUST** criar os próprios dados, com identificador único. Depender de dado pré-existente compartilhado **NEVER**. |

### 6.2 IDs canônicos

| Princípio | Canônico | Apelido |
| --- | --- | --- |
| Empurrar a asserção para a camada mais barata | `TS-CORE-02` | `TS-NIV-01` |
| Não mockar o que o teste vem provar | `TS-CORE-03` | `TS-DUB-02` |
| Flaky é defeito, não inconveniente | `TS-CORE-04` | `TS-SUI-02` |

> **Duas que parecem apelido e não são:** `TS-CORE-05` (cobertura não é meta) e `TS-SUI-04` (teste de mutação mede o que cobertura não mede) — a primeira proíbe uma meta, a segunda prescreve a métrica substituta; um projeto pode cumprir uma e violar a outra. E `TS-CORE-07` (observar comportamento) não é `TS-SUI-06` (test smell de acoplamento a implementação): o primeiro é critério de escrita, o segundo é sintoma detectável numa suíte já existente.

### Contagem

**64 regras** em sete famílias. Detalhamento porque numeral escrito à mão erra:

| Família | Regras | Satélite |
| --- | --- | --- |
| `TS-CORE-*` | 8 | — (só neste hub) |
| `TS-NIV-*` | 9 | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| `TS-TIPO-*` | 9 | [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) |
| `TS-TEC-*` | 9 | [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) |
| `TS-DUB-*` | 8 | [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) |
| `TS-PROC-*` | 10 | [Teste de Software - Processo e Artefatos](teste-de-software-processo-e-artefatos.md) |
| `TS-SUI-*` | 11 | [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) |

Caminho mínimo (§ 6 + § 6.1, sem abrir satélite): **24 regras**.

---

## 7. Contrato de skill

### O que carregar

```
SEMPRE, ao decidir ou revisar ESTRATÉGIA de teste:
 Docs/Teste de Software.md § 0, § 2, § 4, § 6

AO DECIDIR o nível de um teste novo:
 § 4.1 (e § 3 para saber qual ferramenta é aquele nível)

AO DECIDIR o que substituir:
 § 4.2 + Docs/Teste de Software - Dublês de Teste.md

AO DIAGNOSTICAR suíte em que ninguém confia:
 § 4.5 + Docs/Teste de Software - Confiabilidade da Suíte.md

DEPOIS de decidido o nível, para o "como":
 a nota de FERRAMENTA da § 3 — Bun - Testes, Storybook, ou Playwright

NUNCA: esta estrutura inteira para uma tarefa de escrever um teste
 cujo nível já está decidido
```

### Como citar

> `TS-CORE-02` — a validação de CPF está sendo verificada por um teste E2E que percorre três telas. A regra é pura e tem teste de unidade possível; o E2E deveria verificar apenas que a tela exibe a mensagem que o validador produziu.
> Ver [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md).

### Invariantes que a skill deve fazer valer

1. **Nível antes de ferramenta.** Nunca propor "escrevo um Playwright" antes de responder à § 4.1. E2E como default é o antipadrão mais caro que uma skill pode produzir.
2. **A frase antes do teste.** Se não é possível dizer o que pode dar errado, o teste não deve ser escrito ainda (`TS-CORE-01`).
3. **Perguntar o que o teste vem provar** antes de sugerir qualquer dublê (`TS-CORE-03`).
4. **Flaky é bug.** Nunca sugerir retry, `sleep` ou `skip` como solução (`TS-CORE-04`, `TS-SUI-03`).
5. **Não pedir cobertura.** Cobertura não é meta; a pergunta é se a asserção detecta a quebra (`TS-CORE-05`).
6. **Vocabulário exato.** "Mock" só quando é mock. A imprecisão apaga a pergunta seguinte (`TS-DUB-01`).
7. **Seguir a ponte.** Quando a § 8 indicar que a decisão pertence a outra nota, seguir em vez de reinventar.

### Recortes para skills novas

| Skill | Carrega | Fonte declarada |
| --- | --- | --- |
| "decidir o nível de um teste novo" | § 2 + § 4.1 + [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| "revisar estratégia de teste de um repositório" | § 4 + § 6 + § 6.1 | este hub |
| "diagnosticar suíte instável" | § 4.5 + [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) | [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) |
| "desenhar casos para uma entrada" | § 4.3 + [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) | [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) |

---

## 8. Pontes com o stack

| Decisão | O que **não** fazer | A ponte |
| --- | --- | --- |
| Verificar regra de negócio | escrever E2E | unidade em [Bun - Testes](bun-testes.md) (`TS-CORE-02`) |
| Verificar estado visual de componente | E2E que navega até a tela | story em [Storybook - Stories e Args](storybook-stories-e-args.md) |
| Verificar jornada crítica | teste de unidade que simula a jornada | [Playwright](playwright.md) |
| Verificar o contrato com o BFF | redigitar o shape no mock | reusar o tipo do servidor — `Hono - Validação e RPC`, [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| Verificar entrada inválida | só o caminho feliz | valor limite + Zod na fronteira — [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) |
| Preparar estado para um teste de UI | criar pela interface | criar por API — [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 5 |
| Isolar dado entre execuções paralelas | um banco compartilhado | schema/banco efêmero por worker — [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) |
| Testar expiração e "há 3 dias" | esperar o tempo passar | relógio controlado (`TS-DUB-05`) — [Playwright - Rede e Mocking](playwright-rede-e-mocking.md) § 7, [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| Testar autorização por papel | um usuário com tudo liberado | um estado por papel — [Playwright - Autenticação e Isolamento](playwright-autenticacao-e-isolamento.md), e o critério de achado em `OWASP - Sessão e Autorização` |
| Garantir contrato de status e cache | afirmar `200` sempre | [HTTP - Status e Redirecionamento](http-status-e-redirecionamento.md), [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| Portão de qualidade no PR | revisão manual como único portão | política + CI — `Github Actions` |
| "melhorar a qualidade" | mais teste, sem dizer qual problema | decidir se é QA (processo) ou QC (entregável) — |
| Achar a causa de defeitos recorrentes | corrigir sintoma | análise de causa — |

**A ponte mais importante deste vault: a suíte é o que permite refatorar.** só é segura na medida em que existe rede, e a rede útil é a que verifica **comportamento** — uma suíte acoplada a implementação transforma todo refactor em reescrita de teste, o que na prática significa que ninguém refatora. É a mesma tese de aplicada a todos os níveis.

**E o portão:** descreve exatamente a aposta — trocar branch longa e QA manual por suíte automatizada. Essa aposta só paga com `TS-CORE-04` cumprida: uma suíte flaky não é portão, é pedágio.

---

## Relacionados

- — o Zettel que é a âncora conceitual desta estrutura
- — a estratégia em camadas, com o caso concreto de provedor externo
- — o princípio que `TS-CORE-07` formaliza
- · — o lado de processo
- — TDD e integração contínua como prática
- — o que a suíte existe para viabilizar
- · ·
- **Ferramentas:** [Bun - Testes](bun-testes.md) · [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) · [Playwright](playwright.md) · `TypeScript`
- `Github Actions` · · `Trunk-based development`
- — causa raiz de defeito recorrente
-

## Fontes consultadas

Verificadas em **2026-08-20**:

**Fonte base (taxonomia clássica):**
- [guru99 — Software Testing (hub)](https://www.guru99.com/software-testing.html) — o mapa de tópicos e a taxonomia por eixos
- [guru99 — Seven Principles](https://www.guru99.com/software-testing-seven-principles.html)
- [guru99 — STLC](https://www.guru99.com/software-testing-life-cycle.html) — as seis fases, com critério de entrada/saída e entregáveis
- [guru99 — Equivalence Partitioning & BVA](https://www.guru99.com/equivalence-partitioning-boundary-value-analysis.html)
- [guru99 — Defect Life Cycle](https://www.guru99.com/defect-life-cycle.html) — os 13 estados
- [guru99 — Severity vs Priority](https://www.guru99.com/defect-severity-in-software-testing.html)

**Complementares (a camada de critério, que a fonte base não dá):**
- [Martin Fowler — The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) (Ham Vocke) — push-down, solitary × sociable, ice-cream cone, contratos
- [Martin Fowler — Test Double](https://martinfowler.com/bliki/TestDouble.html) — a taxonomia de cinco, com as definições citáveis
- [Kent C. Dodds — The Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)
- [Software Engineering at Google, cap. 11 — Testing Overview](https://abseil.io/resources/swe-book/html/ch11.html) — tamanho × escopo, 80/15/5, a aritmética da flakiness, Beyoncé Rule
- [testing.googleblog — Flaky Tests at Google](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html)
- [Mutation testing](https://en.wikipedia.org/wiki/Mutation_testing) — mutante, operador, score, mutantes equivalentes

**Material do próprio vault** que já cobria parte do assunto e foi incorporado em vez de reescrito:.

**E uma nota de trabalho em `_inbox/` que era melhor que as fontes externas em três pontos**, e por isso virou conteúdo desta estrutura em vez de ser resumida:

| Formulação | Onde entrou |
| --- | --- |
| "se a dependência real divergisse, este teste deveria quebrar?" — o critério de substituição | `TS-CORE-03` · [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) § 2 |
| a análise do CRUD mockado como teatro de teste | [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) § 2.1 |
| a lista do que é legítimo substituir mesmo em E2E (borda, não miolo) | [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) § 2.2 |
| "empurre cada asserção para a camada mais barata que ainda pega o bug" | `TS-CORE-02` |

Nenhuma das fontes externas formula o critério de substituição tão bem — Fowler dá a taxonomia, e não o teste de decisão. **Aquela nota é transitória e deveria ser promovida a Zettel**, porque agora há duas notas dependendo de conteúdo que vive em `_inbox/`.

### O que a verificação encontrou

- **A fonte base é um índice de curso, não uma referência de critério.** guru99 cobre a taxonomia com amplitude (60+ "tipos de teste", 11 domínios, ferramentas) e quase não trata **decisão**: quantos testes, em que nível, o que substituir, quando parar. Toda a § 2 e a § 4 desta estrutura vêm das fontes complementares. É por isso que esta doc não é um resumo do guru99.
- **"Tipo de teste" no vocabulário clássico mistura eixos ortogonais.** A mesma lista traz nível (unidade, integração), objetivo (regressão, smoke), atributo de qualidade (performance, segurança), técnica (caixa-preta) e quem executa (alpha, beta, UAT). "60 tipos de teste" não é uma taxonomia — é cinco taxonomias sobrepostas. A § 5 separa os eixos, e é a decisão editorial mais importante desta estrutura.
- **Pirâmide e Testing Trophy discordam de fato, não de nome.** Fowler/Cohn põem a massa em unidade; Dodds põe em integração ("Write tests. Not too many. Mostly integration."). Uma doc que apresenta os dois como "a mesma ideia com nomes diferentes" apaga a única decisão que o leitor precisa tomar. A § 4.1 registra a discordância e dá o critério de contexto.
- **Google separa *tamanho* de *escopo*, e a literatura popular não.** Escopo é quanto de código se **verifica**; tamanho é quanto de recurso se **consome** (small = um processo, sem I/O; medium = `localhost`; large = várias máquinas). São ortogonais: um teste de escopo amplo com dublês pode ser small, e um teste de escopo estreito de componente de UI pode ser medium por precisar de browser. É a distinção que explica por que "teste de unidade lento" não é contradição.
- **A aritmética da flakiness é o argumento mais forte que existe sobre teste, e quase nunca é citado.** Com 0,1% de flakiness e 10 000 testes/dia são 10 investigações inúteis por dia; **a partir de ~1% os testes "começam a perder valor"**. O índice do próprio Google gira em torno de **0,15%**. Isso transforma "conviver com flaky" de escolha pragmática em erro quantificado.
- **A taxonomia de dublês de Fowler tem cinco itens, e o uso corrente colapsa todos em "mock".** O caso que mais importa no dia a dia: um servidor de mentira **que funciona** é um **fake**, não um mock — e nomear certo levanta imediatamente a pergunta que decide tudo, que é se ele honra o contrato real.
- **Os sete princípios são de vocabulário ISTQB, e o sétimo é o que mais falta na prática.** "Absence-of-errors fallacy": um sistema quase sem defeitos pode ser inútil se não atende à necessidade. É o princípio que impede confundir suíte verde com produto certo (`TS-CORE-08`).
- **Cobertura e qualidade de asserção são métricas diferentes,** e teste de mutação é o que mede a segunda: o mutante que **sobrevive** aponta a asserção que não existe. O Zettel já registrava a limitação da cobertura; o que faltava era a métrica substituta.
- **Severidade é do teste, prioridade é do negócio** — e as combinações cruzadas são as interessantes: logo errado no site é severidade baixa e prioridade alta; defeito grave num fluxo raro é severidade alta e prioridade baixa.
- **Reteste e regressão não são sinônimos:** reteste confirma **um** defeito corrigido; regressão verifica que o resto continua funcionando. No vocabulário ISTQB os dois são "change-related testing".

### O que não foi verificado (declarado, não inventado)

- **A fonte primária do ISTQB não foi acessível.** `istqb.org` respondeu **403** e o PDF oficial do CTFL v4.0 no mirror da GASQ falhou na validação de certificado TLS. Em consequência: a **estrutura de seis capítulos** e a categorização de técnicas em três grupos (caixa-preta, caixa-branca, baseada em experiência) vêm de fonte **terciária** (softwaretestpilot) mais busca; o **texto dos sete princípios** vem do guru99, não do syllabus. O vocabulário usado aqui é consistente com o ISTQB, mas **não é citação do syllabus** — antes de citar ISTQB normativamente em auditoria ou certificação, vá ao PDF oficial.
- **Não há dado publicado do Google sobre o custo da flakiness em horas de engenharia** — o próprio post declara que não tinham nada publicável na época. O que é citável é o índice (~0,15%) e o limiar (~1%), que vêm do capítulo 11.
- **Pairwise/combinatorial testing** aparece em [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) como técnica reconhecida, mas sem exemplo trabalhado verificado nas fontes desta rodada.
- **TMM, TaaS e as métricas de maturidade** aparecem no índice do guru99 e **não** foram cobertos aqui: são vocabulário de organização grande de QA, fora do recorte deste vault. Ausência é recorte, não lacuna.
