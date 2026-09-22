---
Link: https://martinfowler.com/articles/practical-test-pyramid.html
tags:
 - testing
 - software-quality
 - test-levels
 - agent-context
source: "Martin Fowler (Practical Test Pyramid), Kent C. Dodds (Testing Trophy), Software Engineering at Google cap. 11, guru99 (níveis clássicos)"
verificado-em: 2026-08-20
---

# Teste de Software — Níveis e Escopo

> Satélite de [Teste de Software](teste-de-software.md). Cobre a pergunta que decide o custo da suíte: **em que nível este teste vai**. A árvore está na § 4.1 do hub.
>
> **A tese.** "Nível de teste" tem três definições circulando ao mesmo tempo — a clássica (unidade/integração/sistema/aceitação, que é sobre *fase do projeto*), a da pirâmide (que é sobre *quantidade*) e a do Google (que separa *escopo* de *tamanho*). Elas não são substituíveis, e a maior parte da confusão sobre "isto é unidade ou integração?" é a colisão dessas três.

---

## 1. Os quatro níveis clássicos

Vocabulário do ISTQB e do V-model, ainda o mais usado em contexto corporativo:

| Nível | Verifica | Quem costuma escrever |
| --- | --- | --- |
| **unidade** (*component testing*) | um componente isolado — função, classe, módulo | quem desenvolve |
| **integração** | a interação entre componentes, ou entre sistemas | quem desenvolve, ou QA |
| **sistema** | o sistema completo contra os requisitos | QA |
| **aceitação** | adequação ao uso, prontidão para entrega | negócio, usuário, cliente |

O nível de aceitação subdivide em **UAT** (o usuário valida), **alpha** (interno, no ambiente de quem desenvolve), **beta** (externo, no ambiente do usuário) e **aceitação operacional/regulatória**.

**Por que este vocabulário é insuficiente para decidir:** ele descreve *fase* e *responsável*, não *custo* nem *o que se aprende*. Ele responde "quando no projeto" e não responde "escrevo este ou aquele agora". Daí as seções seguintes.

### 1.1 Dois níveis que a lista clássica não nomeia bem

**Teste de componente (UI).** No vocabulário clássico "component testing" *é* unidade. No frontend moderno, "componente" é uma coisa concreta e diferente: uma peça de UI renderizada, com estados nomeados, verificada num browser. Ele não é unidade (renderiza, precisa de DOM) nem integração (não atravessa rede nem rota). É o nível de [Storybook - Stories e Args](storybook-stories-e-args.md), e ignorá-lo empurra teste de estado visual para E2E, que é o erro mais caro da § 4.1 do hub.

**Teste de contrato.** Verifica o **formato** do que atravessa a fronteira entre dois sistemas, sem exercitar a lógica de nenhum. Na variante *consumer-driven* (Fowler), quem consome escreve testes que expressam suas expectativas, e quem provê os verifica contra a implementação — é o que permite equipes autônomas sem quebrar integração.

> **No stack deste vault, boa parte do teste de contrato é feita pelo compilador.** Quando o cliente importa o tipo exportado do servidor (`Hono - Validação e RPC`, [Elysia - Schema e Eden](elysia-schema-e-eden.md)), uma mudança de shape quebra o build em vez de quebrar em runtime. Isso é teste de contrato estático, e é a forma mais barata que existe.
>
> **Mas ele não cobre tudo, e o limite é preciso:** o tipo garante o formato, não o **comportamento** — e não garante nada se a resposta real divergir do tipo declarado. É o mesmo achado das notas de backend: nem `hc` nem Eden lançam em status de erro, então o tipo diz "isto é um `Pedido`" enquanto o corpo carrega um erro.

---

## 2. Escopo × tamanho — a distinção do Google

A contribuição conceitual mais útil desta seção, e a que dissolve a maior parte das discussões de nomenclatura.

**Escopo** = quanto de código o teste **verifica**:

| Escopo | Verifica |
| --- | --- |
| **estreito** (*narrow*) | uma parte pequena e focada — uma classe, um método |
| **médio** | a interação entre um número pequeno de componentes |
| **amplo** (*large*) | a interação de várias partes distintas do sistema |

**Tamanho** = quanto de recurso o teste **consome**:

| Tamanho | Restrições |
| --- | --- |
| **small** | um único processo (e frequentemente uma única thread); **não pode** dormir, fazer I/O, nem chamada bloqueante — sem rede, sem disco |
| **medium** | pode usar vários processos e threads, e fazer chamada de rede **para `localhost`**; não sai da máquina |
| **large** | sem a restrição de `localhost`; pode atravessar várias máquinas |

**São ortogonais**, e é aí que está o valor:

- um teste de **escopo amplo** com dublês para as dependências fora do processo pode ser **small**;
- um teste de **escopo estreito** de um componente de UI pode ser **medium**, porque precisa de um browser real.

Duas consequências práticas:

1. **"Teste de unidade lento" não é contradição** — é escopo estreito com tamanho medium. Uma story do Storybook rodando em browser real via addon-vitest é exatamente isso ([Storybook - Testes e Interações](storybook-testes-e-interacoes.md)).
2. **Determinismo é função do tamanho, não do escopo.** É a restrição de I/O que faz um teste ser confiável, não o quanto de código ele cobre. Por isso a `TS-SUI-01` é sobre recurso, não sobre nível.

---

## 3. Solitary × sociable

Duas escolas de teste de unidade, ambas legítimas:

| | Colaboradores | Vantagem | Custo |
| --- | --- | --- | --- |
| **solitary** | todos substituídos por dublê | isolamento perfeito; falha aponta uma unidade | acopla o teste à estrutura de colaboração; muito dublê |
| **sociable** | reais quando conveniente | testa comportamento de verdade; sobrevive a refactor | falha pode vir de um colaborador |

Fowler não prescreve nenhuma das duas — o que importa é escrever os testes. O critério prático:

- **colaborador que é detalhe interno** (um helper, um value object) → deixe real. Substituí-lo acopla o teste à decisão de extrair aquele helper, e o teste passa a quebrar em refactor sem mudança de comportamento (`TS-CORE-07`).
- **colaborador que é fronteira** (rede, banco, relógio, sistema de arquivos) → substitua. É o que mantém o teste small.

Regra de bolso: **substitua o que atravessa fronteira de processo; deixe real o que é código seu no mesmo processo.** Ela produz testes sociable por default e resolve `TS-CORE-03` na maioria dos casos.

---

## 4. A economia — pirâmide, trophy, 80/15/5

### 4.1 As três formas

| Modelo | Massa em | Maxim |
| --- | --- | --- |
| **Pirâmide** (Cohn/Fowler) | unidade | "muitos testes pequenos e rápidos; alguns mais grosseiros; pouquíssimos ponta a ponta" |
| **80/15/5** (Google) | escopo estreito | 80% estreito · 15% médio · 5% ponta a ponta |
| **Testing Trophy** (Dodds) | **integração** | "Write tests. Not too many. Mostly integration." |

O Trophy tem quatro camadas — **estático** (tipo e lint) na base, unidade, **integração** (a maior), E2E no topo. Incluir o estático é a contribuição própria dele, e é acertada: no stack deste vault, TypeScript + Biome pegam uma classe de defeito inteira antes de qualquer teste rodar (`TypeScript`).

### 4.2 A discordância é real

Pirâmide e Trophy **não** são o mesmo desenho com nomes diferentes: um põe a massa em unidade, o outro em integração. Apresentá-los como equivalentes apaga a única decisão que o leitor tem de tomar.

O critério para escolher é **onde a lógica do sistema vive**:

```
A complexidade está DENTRO de funções?
 (cálculo, domínio rico, regra de negócio densa, parsing)
 → pirâmide. Teste de unidade paga muito, porque é onde o defeito nasce

A complexidade está ENTRE as peças?
 (BFF, adaptação de dado, orquestração, mapeamento de contrato, wiring)
 → trophy. Teste de unidade de cada peça passa e a integração quebra,
 porque o defeito está na junta, e a junta é o que unidade não vê
```

**Para o stack deste vault a resposta costuma ser trophy** — um frontend React com BFF tem mais junta que cálculo. Mas a resposta é por módulo, não por repositório: o pacote que calcula imposto é pirâmide, e a rota que orquestra três chamadas é trophy.

### 4.3 O que os três concordam

Duas coisas, e são as que valem como regra:

1. **E2E é a menor fatia.** Nenhum dos modelos tolera o contrário.
2. **A forma invertida é o antipadrão.** O *ice-cream cone* — massa em E2E e pouco embaixo — é lento, frágil e caro de manter, e o custo cresce mais rápido que a suíte (`TS-NIV-04`).

### 4.4 Push-down e a proibição de duplicar

Duas regras de Fowler, e a segunda é a mais esquecida:

**Push down.** *"Se um teste de nível mais alto pega um erro e nenhum teste de nível mais baixo falhou, você precisa escrever um teste de nível mais baixo."* O teste alto detectou; o baixo é que deveria diagnosticar.

**Não duplique.** *"Empurre seus testes o mais para baixo na pirâmide que conseguir."* Um teste de nível alto que verifica a mesma condicional que um de nível baixo já verifica **não acrescenta confiança** — acrescenta manutenção. Quando a regra muda, os dois quebram, e o de cima quebra mais devagar e diagnostica pior.

A leitura combinada: teste de nível alto verifica **integração e caminho**, não **lógica**. Um E2E de checkout verifica que as telas se conectam e o pedido persiste; ele **não** verifica que o desconto de 15% foi calculado certo — isso é unidade (`TS-NIV-02`).

---

## 5. Como isto vira decisão no stack

| O que pode dar errado | Nível | Ferramenta |
| --- | --- | --- |
| cálculo, parse, validação, invariante | unidade (small, estreito) | [Bun - Testes](bun-testes.md) |
| caso de uso + repositório real | integração (medium) | [Bun - Testes](bun-testes.md) + Postgres local |
| shape que atravessa a fronteira | contrato — em boa parte estático | `Hono - Validação e RPC`, [Elysia - Schema e Eden](elysia-schema-e-eden.md) |
| estado visual de um componente | componente (estreito, medium) | [Storybook - Stories e Args](storybook-stories-e-args.md) |
| jornada crítica com sessão e rota | E2E (amplo, large) | [Playwright](playwright.md) |
| tipo e uso incorreto de API | estático | `TypeScript` |

---

## 6. Regras — `TS-NIV-01` a `TS-NIV-09`

| ID | Regra |
| --- | --- |
| `TS-NIV-01` | Cada asserção **MUST** ficar na camada mais barata que ainda pega o defeito. Verificar em E2E uma condicional já verificada em unidade **NEVER**. *(apelido de `TS-CORE-02` — cite o canônico)* |
| `TS-NIV-02` | E2E **MUST** cobrir jornada crítica. Regra de negócio em E2E **NEVER** — ela pertence à unidade. |
| `TS-NIV-03` | Defeito pego por teste de nível alto **MUST** gerar um teste de nível mais baixo que o diagnostique. |
| `TS-NIV-04` | A forma da suíte **NEVER** é *ice-cream cone* (massa em E2E). Pirâmide e trophy discordam sobre onde fica a massa; nenhum tolera a forma invertida. |
| `TS-NIV-05` | Colaborador que atravessa fronteira de processo (rede, disco, relógio, banco) **MUST** ser substituído em teste small. Colaborador que é código próprio no mesmo processo **MUST** ficar real, salvo justificativa. † |
| `TS-NIV-06` | Tamanho e escopo de teste **NEVER** são a mesma coisa: escopo é quanto de código se **verifica**, tamanho é quanto de recurso se **consome**. |
| `TS-NIV-07` | Estado visual de componente **MUST** ser verificado no nível de componente, **NEVER** por E2E que navega até a tela. † |
| `TS-NIV-08` | O modelo de proporção (pirâmide × trophy) **MUST** ser escolhido por onde a complexidade vive — dentro das funções, ou entre as peças — e a escolha vale por módulo, não por repositório. † |
| `TS-NIV-09` | Contrato garantido por tipo compartilhado **NEVER** dispensa verificar comportamento em erro: o tipo garante formato, não que a resposta real o respeite. † |

---

## 7. Antipadrões

### 7.1 E2E como default

Receber "escreva um teste" e escrever E2E porque parece mais completo. É o antipadrão de maior custo desta doc: o teste mais lento, mais frágil e com pior diagnóstico, verificando algo que unidade pegaria em milissegundos (`TS-NIV-01`).

### 7.2 Regra de negócio em E2E

```
✗ 40 testes E2E cobrindo as faixas de desconto
✓ 40 testes de unidade sobre a função de desconto
 + 1 E2E que confirma que a tela exibe o valor calculado
```

(`TS-NIV-02`)

### 7.3 Ice-cream cone

Suíte com 200 E2E e 30 unidades. Ela demora, falha por motivo alheio, e ninguém roda antes do PR. O sintoma é o item 5 da § 4.5 do hub (`TS-NIV-04`).

### 7.4 Mesma lógica verificada em três níveis

Unidade, integração e E2E todos verificando a mesma condicional. Quando a regra muda, três suítes quebram — e as duas de cima diagnosticam pior que a de baixo. Ver § 4.4.

### 7.5 Substituir colaborador interno

```
✗ dublê para cada helper que a função usa
```

O teste passa a conhecer a estrutura interna, e todo refactor sem mudança de comportamento fica vermelho (`TS-NIV-05`, `TS-CORE-07`).

### 7.6 Confiar só no tipo compartilhado

Assumir que porque cliente e servidor compartilham o tipo, o contrato está testado. O tipo não sabe que a resposta de erro tem outro shape, e o cliente tipado não lança nesse caso (`TS-NIV-09`).

### 7.7 Não nomear o nível de componente

Sem esse nível na cabeça, todo teste de estado visual vira E2E (`TS-NIV-07`).

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub; a § 4.1 é a árvore de nível
- [Teste de Software - Dublês de Teste](teste-de-software-dubles-de-teste.md) — o que substituir, decidido na § 3
- [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) — por que tamanho decide determinismo
- [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) — o eixo ortogonal ao nível
- [Bun - Testes](bun-testes.md) · [Storybook - Stories e Args](storybook-stories-e-args.md) · [Playwright](playwright.md) · `TypeScript`
- `Hono - Validação e RPC` · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — contrato como tipo
- — a mesma decisão, com caso concreto
- — por que a junta é onde o defeito mora

## Fontes consultadas

Verificadas em **2026-08-20**:

- [The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) — push-down, não-duplicação, solitary × sociable, ice-cream cone, contratos consumer-driven
- [The Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications) — as quatro camadas e o argumento de confiança por custo
- [Software Engineering at Google, cap. 11](https://abseil.io/resources/swe-book/html/ch11.html) — tamanho × escopo com as restrições exatas, e 80/15/5
- [guru99 — Software Testing](https://www.guru99.com/software-testing.html) — os níveis clássicos e a subdivisão de aceitação
