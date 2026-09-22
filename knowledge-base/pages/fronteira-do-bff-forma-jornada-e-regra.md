---
titulo: Fronteira do BFF - forma, jornada e regra
aliases:
  - Fronteira do BFF
  - BFF forma jornada regra
tags:
  - architecture
  - backend-for-frontend
  - frontend
  - agent-context
verificado-em: 2026-08-15
---

# Fronteira do BFF — forma, jornada e regra

> Nota irmã de [Feature-Based Architecture](feature-based-architecture.md). Aquela decide **onde o código do frontend mora e quem
> importa quem**; esta decide **o que atravessa a fronteira do servidor e quem é dono de cada
> decisão**. A ideia conceitual em uma frase está em
>; esta nota transforma a ideia em corte,
> regras citáveis e testes decidíveis.

Como a nota irmã, esta mora em `pages/` mas é **normativa**: tem IDs (`BFF-*`), invariantes e
contrato de skill. Ela está aqui, e não em `docs/`, porque não resume documentação de uma ferramenta
— registra uma decisão desta casa. Ver a exceção explicada em [Architecture in React](architecture-in-react.md) § 5.

---

## 1. O problema: a fronteira desenhada por acidente

Um BFF quase nunca nasce como decisão. Ele nasce como proxy — um lugar para guardar o token fora do
browser — e depois recebe uma rota de cada vez, sempre pelo mesmo motivo: *"o proxy não deu conta
desse caso"*.

O resultado é um híbrido real com uma regra implícita: **escreve endpoint quando o proxy falha.**
Isso faz a fronteira ser desenhada por acidente, uma exceção por vez, e produz três sintomas que
aparecem juntos:

- ninguém sabe dizer qual capacidade está de que lado, então não dá para medir nada;
- regra de negócio escorre para o browser, onde ela não é regra — é sugestão, e um `curl` fura;
- forma de transporte escorre para a tela, e o vocabulário do backend vira vocabulário de produto.

A causa é uma palavra usada para duas coisas. "Lógica de negócio" significa, ao mesmo tempo, *a regra
que precisa ser verdade* e *a jornada que o usuário percorre*. São coisas diferentes, com donos
diferentes, e confundi-las é o que faz o corte se desfazer na primeira sexta-feira apertada.

---

## 2. O corte: três camadas

**O backend é dono da regra. O BFF é dono da forma. A feature é dona da jornada.**

| Camada | Dona de | Exemplos |
| --- | --- | --- |
| **backend** (serviços de domínio) | regra de negócio, autorização, invariantes, persistência, atomicidade | quem pode desativar um agente, limite do plano, transição de estado válida |
| **BFF** | **forma**: tradução de DTO, agregação de leitura, validação de entrada, nome do erro, versão do upstream | `temProxima`, snake_case → domínio, `agente_inexistente` × `gateway_indisponivel`, `/agents/v1` → `/api/agentes` |
| **feature** (frontend) | **jornada**: ordem dos passos, estado de UI, URL, cache, otimismo | confirmar antes de desativar, filtro na URL, `queryKey` e invalidação, 404 como estado da tela |

O corte não é sobre times nem repositórios. BFF e feature podem ser do mesmo time e do mesmo repo —
e é justamente por isso que ele precisa de teste, não de princípio: quando a mesma pessoa pode
escrever nos dois lados, o código vai parar onde for mais rápido digitar.

---

## 3. Os três testes decidíveis

Princípio sem teste vira preferência. Estes três resolvem quase todos os casos e são aplicáveis em
revisão de PR, sem discussão de gosto.

```
1. "O curl fura?"
   Alguém chamando a API direto, sem passar pela tela, quebra a regra?
   SIM → é regra de negócio → backend

2. "Outro cliente refaria?"
   Um app mobile consumindo a mesma API teria que reimplementar isto?
   SIM → é forma → BFF

3. "Muda se o design mudar?"
   Um redesenho da tela altera esta coisa?
   SIM → é jornada → feature
```

Aplicados em ordem, os três são mutuamente exclusivos na prática. Se dois derem "sim", o item está
fazendo mais de uma coisa e precisa ser dividido antes de ser colocado em algum lugar.

**O teste 2 é o que separa BFF de feature**, e é o mais esquecido. `temProxima`, mapeamento de DTO e
nome de erro falham nele quando ficam no browser — um segundo cliente precisaria reescrever cada um.

---

## 4. Validação nas três camadas não é duplicação

Este é o mal-entendido mais caro do corte, e o que mais leva alguém a "simplificar" removendo a
camada errada.

As três validam, com **propósitos diferentes**:

| Camada | Valida para | Se remover |
| --- | --- | --- |
| feature | dar **feedback imediato** — o campo fica vermelho antes do submit | UX piora: o usuário descobre o erro depois da viagem |
| BFF | **recusar entrada malformada na fronteira** — é contrato, não gentileza | o handler passa a receber `unknown` e a rota vira território de `any` |
| backend | garantir a **invariante** — é a única que é verdade | o dado inválido entra no banco, e nenhuma tela conserta isso |

Nenhuma delas substitui a outra, porque nenhuma responde a mesma pergunta. Remover qualquer uma
piora algo diferente, e a que parece mais redundante — a do BFF — é a que impede a rota de tratar
dado não validado como se fosse validado.

**O que é duplicação de verdade** é a mesma *regra de negócio* escrita em duas camadas: se "só admin
desativa agente" existe no backend e no browser, uma das duas vai divergir, e a do browser nunca foi
executável mesmo.

O critério para distinguir: pergunte *o que acontece se as duas discordarem*. Validações de
propósito diferente discordando produz uma UX ruim mas um sistema correto. Regra de negócio
discordando produz um sistema incorreto.

---

## 5. A autocrítica: validação de fronteira nunca é a única

Uma checagem no BFF é defesa **na fronteira**, não a defesa. O erro é fácil de cometer e difícil de
ver, porque o código parece certo.

Caso concreto, do lab: a rota de upload usa `t.File({ type, maxSize })`, que confere o **magic
number** do arquivo — não o `content-type`, que é declarado pelo cliente e forjável. Isso está no
lugar certo: é forma, e é a fronteira. **Mas não pode ser a única checagem**, porque o BFF não é o
único caminho até o serviço de storage. Se ele for, a validação virou regra de negócio disfarçada de
forma, e o teste 1 acusa: um `curl` direto no storage fura.

A generalização, e é ela que vira regra:

> Toda checagem no BFF que, se ausente, permitiria um estado inválido no sistema — e não apenas uma
> tela feia — é sinal de que a mesma checagem precisa existir no backend. A do BFF continua valendo:
> ela falha rápido, perto do cliente, com erro tipado. Ela só não pode ser a última linha.

O sintoma que denuncia: o time discute "onde colocar a validação" em vez de "quantas vezes ela
precisa existir".

---

## 6. A feature não fica com as sobras

A objeção previsível ao corte é que o BFF esvazia o frontend. Ele não esvazia — ele tira da feature
o que nunca foi dela. O que **permanece** na fatia vertical:

- as `queryKey` e a política de frescor — o cliente tipado não sabe nem deve saber disso;
- **a invalidação**: qual mutation derruba qual lista. É decisão de domínio do cliente;
- o schema dos search params, porque filtro e paginação moram na URL e são estado da aplicação;
- a decisão de tratar 404 como **estado** da tela em vez de erro genérico;
- estados efêmeros de UI: progresso de upload, transmissão em curso, rascunho de campo;
- toda a composição de componentes e a jornada.

O que sai é só o que não era jornada: os mappers de DTO e os tipos escritos à mão. A feature fica
**mais** coesa — o `api/` dela vira `queryOptions` + invalidação, que é exatamente o que
[Feature-Based Architecture](feature-based-architecture.md) § 3 descreve como anatomia saudável.

---

## 7. O BFF orquestrador: onde ele para

O risco simétrico ao proxy é o BFF que vira orquestrador de negócio. Ele é atraente porque resolve
um problema real (a tela precisa de três chamadas) com uma solução errada (um endpoint que faz três
escritas).

A linha:

- **Agregação de leitura: à vontade.** Compor N respostas do upstream numa view é exatamente o papel
  do BFF, e é o único jeito de matar o *leque* — várias queries paralelas disparadas pelo mesmo id
  só para montar uma tela.
- **Escrita composta: não.** Um endpoint que cria, anexa e ativa é uma saga, e o BFF **não pode
  garantir atomicidade**: se o terceiro passo falha, ele fica com um estado meio-feito que ninguém
  consegue reverter. Orquestração transacional pertence ao backend, que é dono da persistência.

A pergunta que decide, e ela é sobre falha, não sobre conveniência: *se o passo N falhar, quem
desfaz os N-1 anteriores?* Se a resposta não for "o serviço que é dono dos dados", o endpoint está
na camada errada.

Caso de uso legítimo, do lab: `GET /api/painel-de-agentes` busca agentes, contagens e status de
conexão em paralelo, e devolve uma view. Três leituras, nenhuma escrita, nada a desfazer.

Caso ilegítimo: `POST /api/agentes/completo` que cria o agente, sobe os arquivos e ativa. Três
escritas em serviços diferentes, sem transação. Isso é backend.

---

## 8. A regra de migração

O corte só vale se houver um critério para mover uma capacidade de um lado para o outro. Sem ele, a
fronteira volta a ser resíduo.

```
capacidade nova?
├── SIM → nasce com contrato (endpoint tipado no BFF)
└── NÃO → a tela precisa de agregação, tradução ou erro próprio?
          ├── SIM → migra para contrato
          └── NÃO → fica no proxy (leitura 1:1)
```

Duas propriedades desse critério importam mais que o critério em si:

1. **É registrável.** Toda capacidade está de um lado declarado, então dá para contar — e medir
   antes/depois só faz sentido se você sabe o que mudou de lado;
2. **É assimétrico de propósito.** Novo nasce com contrato porque o custo de nascer certo é baixo;
   existente só migra sob demanda porque migração sem motivo é risco sem retorno.

O que **não** justifica migrar: "para ficar consistente". Consistência não é sintoma. Agregação,
tradução e erro próprio são.

---

## 9. Regras normativas (`BFF-*`)

IDs citáveis, no mesmo formato de [Feature-Based Architecture](feature-based-architecture.md) § 4. Um achado de revisão cita o ID,
o arquivo e a linha — não parafraseia.

| ID | Regra | Severidade | Verificação |
| --- | --- | --- | --- |
| `BFF-01` | Regra de negócio e autorização **MUST** morar no backend. Se o `curl` fura, está na camada errada. | crítica | revisão |
| `BFF-02` | Tradução de DTO, agregação de leitura e nome de erro **MUST** morar no BFF, nunca no browser. | crítica | revisão |
| `BFF-03` | Jornada — ordem de passos, estado de UI, URL, cache, invalidação — **MUST** morar na feature. | crítica | revisão |
| `BFF-04` | Escrita composta em mais de um serviço **NEVER** é orquestrada pelo BFF — não há como garantir atomicidade. | crítica | revisão |
| `BFF-05` | Validação existe nas três camadas com propósitos diferentes; remover uma **MUST** ser justificado pelo propósito que se abre mão. | alta | revisão |
| `BFF-06` | Checagem no BFF que previne estado inválido **MUST** existir também no backend — a do BFF nunca é a última linha. | crítica | revisão |
| `BFF-07` | Tipo de payload no cliente **MUST** derivar do contrato do servidor — **NEVER** ser reescrito à mão. | crítica | build (typecheck) |
| `BFF-08` | Rota que devolve mais de um status **MUST** declarar o mapa de `response` por status, ou o erro chega ao cliente como `unknown`. | crítica | revisão |
| `BFF-09` | Versão e prefixo do upstream **NEVER** aparecem em código de browser. | alta | revisão |
| `BFF-10` | Capacidade nova **MUST** nascer com contrato; existente migra só sob agregação, tradução ou erro próprio. | alta | revisão |
| `BFF-11` | Toda capacidade **MUST** estar declaradamente de um lado da fronteira — proxy ou contrato. Indefinido é dívida. | média | revisão |

### `BFF-07` — o teste do raio de explosão

`BFF-07` é a única regra desta nota verificável por build, e o modo de verificar é um experimento
barato: **renomeie um campo do schema no servidor e conte os erros de typecheck.**

- contrato tipado ponta a ponta: o compilador lista os consumidores exatos, e a lista é completa;
- tipo escrito à mão no cliente: **zero erros** — o build passa e a quebra chega em produção.

Medido no lab em 2026-08-15: renomear um campo produziu 4 erros, nos 4 consumidores reais. O número
é a métrica; o zero é o diagnóstico.

Um dos quatro é indireto — o schema da view do painel embute o schema do agente, e o compilador
atravessa a composição até quem consome. **Um `grep` pelo nome do schema não encontraria esse
arquivo.** É a diferença entre buscar texto e perguntar ao compilador.

> **Sobre citar número medido.** A primeira versão desta nota dizia 3, porque foi medida antes de o
> quarto consumidor existir, e depois foi copiada sem ser refeita. Número medido tem data de
> validade: ao citar, remeça. Vale para esta nota tanto quanto para o código que ela descreve.

---

## 10. Como medir o corte

O erro comum é tentar A/B testar arquitetura. Não dá. O que funciona é **migração pareada de uma
fatia**: escolher um domínio, medir, migrar só ele, medir de novo, com o resto do app como controle.

Indicadores antecedentes, todos contáveis por `grep`:

| Métrica | O que denuncia |
| --- | --- |
| asserções de tipo não verificadas (`as T`) | contrato prometido e não conferido |
| ocorrências de `snake_case` em código de UI | transporte vazando para a tela |
| arquivos de mapper DTO→domínio no cliente | tradução na camada errada (`BFF-02`) |
| requisições por tela | leque não resolvido — candidato a agregação |
| queries encadeadas (`enabled` que depende de `data` de outra query) | waterfall que só o BFF ou o backend resolvem |

Desfechos, que os indicadores só antecipam: arquivos tocados por PR de feature, lead time de
"endpoint disponível" → "tela em QA", e retrabalho causado por drift de contrato. **Se o retrabalho
por drift for zero, metade do argumento desta nota cai** — e isso precisa ser checado antes de
adotar, não depois.

Cuidado que invalida medição de performance: **não meça em localhost.** O BFF fica perto do upstream
e longe do browser; agregação só mostra ganho com RTT real.

---

## 11. Antipadrões

| Antipadrão | Por que dói | Correção |
| --- | --- | --- |
| Regra de permissão no componente | não é regra, é sugestão: o `curl` fura | backend (`BFF-01`) |
| `interface Agente` escrita no browser | segunda fonte de verdade; diverge sem avisar | derivar do contrato (`BFF-07`) |
| Mapper de DTO em `features/*/model/` | todo cliente refaz o mesmo trabalho | mapper no BFF (`BFF-02`) |
| Endpoint que cria + anexa + ativa | saga sem transação; falha no meio deixa estado órfão | backend (`BFF-04`) |
| Remover a validação do BFF "porque o backend já valida" | o handler passa a tratar dado não validado como validado | manter as três (`BFF-05`) |
| Magic number só no BFF | outro caminho até o storage fura | duplicar no serviço dono (`BFF-06`) |
| `/agents/v1` no código de tela | bump de versão do backend vira release de frontend | prefixo morre no BFF (`BFF-09`) |
| Migrar "para ficar consistente" | risco sem sintoma | migrar sob agregação, tradução ou erro (`BFF-10`) |
| Endpoint no BFF para uma tela só, com regra dentro | vira segundo backend sem dono | é jornada: volta para a feature (`BFF-03`) |

---

## 12. Contrato de skill

```
SEMPRE:        § 2 (o corte) + § 3 (os três testes) + § 9 (regras BFF-*)

AO CRIAR ROTA NO BFF:        § 7 (limite da orquestração) + § 4 (validação)
AO MOVER CÓDIGO DE CAMADA:   § 8 (regra de migração) + § 3
AO REVISAR PR:               § 11 (antipadrões) + § 9
AO JUSTIFICAR A ADOÇÃO:      § 10 (como medir)

TAMBÉM:  [Feature-Based Architecture](feature-based-architecture.md) para o lado do frontend
         (esta nota decide o que atravessa; ela decide onde o código mora)

NUNCA:   decidir camada por conveniência de digitação
```

### Invariantes

1. **Teste antes de princípio.** "O BFF é fino" não decide nada às seis da tarde; os três testes da
   § 3 decidem.
2. **Regra que o `curl` fura não é regra.** Vale independentemente de quão bem escrito esteja o
   componente.
3. **Validação repetida com propósitos diferentes não é duplicação** (§ 4). Regra de negócio
   repetida é.
4. **Nenhuma checagem de fronteira é a última linha** (§ 5).
5. **Agregação de leitura sim, escrita composta não** (§ 7). O critério é quem desfaz a falha.
6. **A fronteira precisa ser declarada para ser medida** (`BFF-11`).

### Autoverificação antes de entregar

- [ ] Nenhuma regra que o `curl` fura mora fora do backend (`BFF-01`)
- [ ] Nenhum mapper de DTO no cliente (`BFF-02`)
- [ ] Nenhum endpoint compõe escrita em mais de um serviço (`BFF-04`)
- [ ] Toda checagem preventiva do BFF existe também no backend (`BFF-06`)
- [ ] Nenhum tipo de payload escrito à mão no cliente (`BFF-07`)
- [ ] Toda rota com múltiplos status declara o mapa de `response` (`BFF-08`)
- [ ] Nenhum prefixo de versão do upstream em código de browser (`BFF-09`)
- [ ] A capacidade tocada está declaradamente de um lado (`BFF-11`)

---

## Relacionados

- [Feature-Based Architecture](feature-based-architecture.md) — nota irmã: onde o código do frontend mora
- [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) — nota irmã: o que vira pacote, e o que o CI verifica
- — a ideia conceitual
- — o corte em uma frase
- — § 4 destilada
- [Architecture in React](architecture-in-react.md) — o roteador das decisões arquiteturais
- ·
- — a camada de fora
- ·
- [Elysia](../docs/elysia.md) · [Elysia - Schema e Eden](../docs/elysia-schema-e-eden.md) — a ferramenta que torna `BFF-07` verificável
- [TanStack Query - Padrões de Consulta](../docs/tanstack-query-padroes-de-consulta.md) — leque e waterfall pelo lado do cliente

## Procedência

Esta nota foi destilada de uma investigação sobre `bai-web` em 2026-08-15, com estrutura de
referência executável em `elysia-bff-lab` (34 testes, CI verde). Os números citados na § 9 e
na § 10 foram medidos naquele momento, não estimados. As afirmações sobre comportamento de
ferramenta foram verificadas rodando — quando divergirem de `docs/`, o Doc vence.
