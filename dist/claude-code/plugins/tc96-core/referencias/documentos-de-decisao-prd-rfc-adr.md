---
titulo: Documentos de Decisão — PRD, RFC e ADR
aliases:
  - PRD, RFC e ADR
  - Documentos de decisão
tags:
  - workflow
  - documentation
  - architecture
  - product
  - reference
source: "Michael Nygard, Documenting Architecture Decisions (2011, formato de ADR: contexto, decisão, status, consequências); IETF, a série RFC como registro de proposta aberta a comentário; Aridane Martín, PRD vs ADR vs RFC: The Documents Every Engineer Should Know (2026-08-09, síntese secundária do encadeamento PRD → RFC → ADR)"
verificado-em: 2026-10-07
---
# Documentos de Decisão — PRD, RFC e ADR

> **O que esta nota é.** A regra de **qual documento registra qual decisão**, quando ele nasce,
> quando congela e onde mora. Ela dá ID citável a três documentos que costumam ser tratados
> como intercambiáveis: PRD, RFC e ADR.
>
> **O que não é.** Não é o fluxo de entrega: o *quando* de cada pilar é
> [Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md), e é ele que diz qual
> pilar grava qual arquivo em `.specs/`. Esta nota diz o que cada documento **é**.
>
> **Por que ela existe.** Decisão que só existe na conversa ou no código é reconstruída de trás
> para frente por quem chega depois, pessoa ou agente. Os três documentos guardam o *porquê*
> em três momentos diferentes: a intenção, a proposta e o registro.

Fontes consultadas em **2026-10-07**. Ver [Fontes consultadas](#fontes-consultadas).

---

## 0. Antes de tudo: três perguntas, três documentos

| Documento | Pergunta | Quem escreve | Quando |
| --- | --- | --- | --- |
| **PRD** | o que vamos construir, e por quê? | `product-manager` | antes de desenho e código |
| **RFC** | como proponho construir, e o que vocês acham? | `software-architect` | antes de se comprometer com um desenho, só com a decisão em aberto |
| **ADR** | o que decidimos, e por quê? | `software-architect` | no momento da decisão, muitas vezes ao fechar um RFC |

Os três formam uma cadeia: o PRD fixa a intenção, um ou mais RFCs propõem o como, e cada
escolha de arquitetura que um RFC resolve vira um ADR. Uma iniciativa grande pode ter um PRD,
alguns RFCs e uma dúzia de ADRs; uma correção de uma linha não tem nenhum (`DOC-CORE-02`).

**Design doc × RFC.** Um desenho técnico sem alternativa real em debate é um *design doc*,
não um RFC. Os dois são legítimos; chamar um de outro não é (`DOC-RFC-03`).

---

## 1. Como usar esta doc

### Para uma pessoa

Antes de escrever, pergunte qual das três perguntas da §0 está em aberto. Se nenhuma está,
não escreva documento: entregue.

### Para um agente de código

Ao gravar a saída de Pesquisa ou Planejamento em `.specs/`, use a §4 para saber em que
arquivo cada decisão mora, e a §3 para saber se o arquivo ainda pode mudar. A skill que
grava é `workflow-spec`; o pilar só pede o arquivo.

### Convenções

`MUST`/`NEVER` são normativos, como em todo o resto da knowledge-base. **†** marca decisão
desta doc, sem paralelo direto numa única fonte externa.

---

## 2. Árvore de decisão: qual documento escrever

```
Falta alinhar O QUE construir e POR QUÊ?
├── sim → PRD
└── não
    Há uma proposta de COMO construir, com alternativa real, ainda sem decisão?
    ├── sim → RFC
    └── não
        Uma decisão técnica já foi tomada e vai durar mais que este incremento?
        ├── sim → ADR
        └── não
            Há desenho técnico a registrar, sem alternativa em debate?
            ├── sim → design doc
            └── não → nenhum documento; entregue
```

RFC aberto para aprovar o que já está construído é teatro: o registro certo é um ADR
(`DOC-RFC-01`).

---

## 3. Ciclo de vida

| Documento | Estados | Muda quando |
| --- | --- | --- |
| PRD | `Draft` → `In review` → `Approved` | livre na descoberta; depois de `Approved`, só por retorno deliberado à Pesquisa, como emenda datada (`DOC-PRD-04`) |
| RFC | `Draft` → `In review` → `Accepted` \| `Rejected` | revisado durante o comentário; fecha na data de decisão, com o dono decidindo (`DOC-RFC-02`) |
| Design doc | `Draft` → `In review` → `Accepted` | revisado até aceito; depois, só por emenda datada |
| ADR | `Proposed` → `Accepted` → `Superseded by ADR-NNNN` | livre em `Proposed`; depois de `Accepted`, nunca; a decisão nova é outro ADR (`DOC-ADR-02`) |

O debate registrado num RFC vale tanto quanto o resultado: é ele que responde, um ano depois,
por que a alternativa óbvia foi descartada.

Quem move o status é o dono, com resposta explícita na conversa; o agente que escreveu nunca
aprova o próprio documento (`WF-SPEC-06`, em
[Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) §5).

---

## 4. Onde cada documento mora em `.specs/`

| Documento | Arquivo | Template |
| --- | --- | --- |
| PRD | `.specs/<capability>/requirements.md` | `workflow-spec/references/template-requirements.md` |
| RFC ou design doc | `.specs/<capability>/design.md` | `workflow-spec/references/template-design.md` |
| ADR | `.specs/adr/NNNN-<slug>.md` | `workflow-spec/references/template-adr.md` |

A pasta é da capability, não da entrega: PRD e design doc acompanham a capability enquanto
ela existe e mudam por emenda (`WF-SPEC-08`, em
[Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) §5). O ADR fica fora
dela porque uma decisão de arquitetura costuma valer para mais de uma capability, e a numeração
é uma só para o repositório (`DOC-ADR-03`). `user-experience.md` e o plano em `tasks/` não são documentos de
decisão desta nota; o dono e o momento deles estão em
[Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) §5.

---

## 5. Regras normativas

Convenção: `MUST`/`NEVER` são normativos. **†** marca decisão desta doc.

### `DOC-CORE-*` — o que vale para os três

| ID | Regra |
| --- | --- |
| `DOC-CORE-01` | Cada documento **MUST** responder uma única pergunta da §0; um documento que responde duas **NEVER** fica assim, ele é dois documentos. |
| `DOC-CORE-02` | O número de documentos **MUST** ser proporcional ao custo de errar a decisão; abrir documento para mudança sem trade-off real **NEVER**. |

### `DOC-PRD-*` — PRD

| ID | Regra |
| --- | --- |
| `DOC-PRD-01` | O PRD **MUST** declarar não-objetivos explícitos; não-objetivo vago **NEVER**, ele é a porta do aumento de escopo. |
| `DOC-PRD-02` | Todo requisito **MUST** ter uma métrica ou um cenário verificável; requisito sem medida **NEVER** é requisito, é desejo. |
| `DOC-PRD-03` | O PRD **NEVER** contém desenho técnico (schema, contrato de API, fronteira de serviço); isso **MUST** ir para RFC, design doc ou ADR. |
| `DOC-PRD-04` | PRD `Approved` **MUST** estar congelado; mudança depois disso volta à Pesquisa e entra como emenda datada no fim do arquivo, aprovada pelo dono; reescrever o texto aprovado, ou editar em silêncio, **NEVER**. |

### `DOC-RFC-*` — RFC

| ID | Regra |
| --- | --- |
| `DOC-RFC-01` | RFC **MUST** abrir só para decisão ainda não tomada; RFC para aprovar o que já está construído **NEVER**, o registro é um ADR. |
| `DOC-RFC-02` | RFC **MUST** ter um dono que decide e uma data de decisão; RFC sem prazo **NEVER**, ele trava o trabalho que espera por ele. |
| `DOC-RFC-03` | Alternativa num RFC **MUST** ser real, com o motivo do descarte; alternativa de espantalho **NEVER**. Sem alternativa real, o documento **MUST** se declarar design doc. |
| `DOC-RFC-04` | RFC resolvido **MUST** registrar a decisão e listar os ADRs que produziu. † |

### `DOC-ADR-*` — ADR

| ID | Regra |
| --- | --- |
| `DOC-ADR-01` | Um ADR **MUST** registrar uma única decisão; três escolhas são três ADRs. |
| `DOC-ADR-02` | ADR `Accepted` **NEVER** é editado; decisão que muda **MUST** virar ADR novo, e o antigo recebe só `Superseded by ADR-NNNN` no status. |
| `DOC-ADR-03` | ADR **MUST** morar no repositório do código, em `.specs/adr/NNNN-<slug>.md`, numerado em sequência com quatro dígitos; ADR em wiki **NEVER**. † |
| `DOC-ADR-04` | ADR **MUST** registrar as consequências, custo incluído, e as alternativas descartadas; registrar só o ganho **NEVER**. |

### Contagem

**14 regras** em quatro famílias.

| Família | Regras |
| --- | --- |
| `DOC-CORE-*` | 2 |
| `DOC-PRD-*` | 4 |
| `DOC-RFC-*` | 4 |
| `DOC-ADR-*` | 4 |

---

## 6. Contrato de skill

### O que carregar

```
AO ESCREVER requirements.md:      § 0, § 3 + DOC-CORE-*, DOC-PRD-*
AO ESCREVER design.md:            § 0, § 2, § 3 + DOC-CORE-*, DOC-RFC-*
AO ESCREVER ou SUBSTITUIR um ADR: § 3, § 4 + DOC-ADR-*
NUNCA:                            esta nota para uma tarefa de detalhe de implementação
                                  (ela não abre documento de decisão, DOC-CORE-02)
```

### Como citar

> `DOC-ADR-02` — o ADR 0007 escolheu PostgreSQL e a equipe quer trocar por SQLite no
> ambiente de teste. Editar o 0007 apaga o porquê da escolha original; o certo é o ADR 0012,
> e o 0007 recebe `Superseded by ADR-0012`.
> Ver [Documentos de Decisão — PRD, RFC e ADR](documentos-de-decisao-prd-rfc-adr.md) § 3.

---

## 7. Pontes com o stack

| Decisão | O que **não** fazer | A ponte |
| --- | --- | --- |
| Quando cada arquivo de `.specs/` é escrito, e por qual pilar | decidir aqui | [Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) §5, `WF-SPEC-*` |
| O formato da decisão de arquitetura | inventar outro | `software-architect`, "Output format": o ADR herda eixo, invariantes e custo |
| O formato da decisão de produto | inventar outro | `product-manager`, "Writing a spec / PRD" |
| Cenário de aceite de um requisito | escrever prosa | `workflow-spec/references/template-story.md` |

---

## Fontes consultadas

- Michael Nygard, *Documenting Architecture Decisions* (2011) — o formato de ADR com contexto,
  decisão, status e consequências, e a regra de nunca reescrever um ADR aceito.
- IETF, a série RFC — a origem do nome e do modelo de proposta aberta a comentário.
- Aridane Martín, *PRD vs ADR vs RFC: The Documents Every Engineer Should Know* (2026-08-09) —
  fonte **secundária**: a cadeia PRD → RFC → ADR, os anti-padrões e a ordem de adoção.

**O que não foi possível verificar por fonte primária nesta versão:** os textos de Nygard e da
IETF não foram relidos nesta data; as regras `DOC-*` são síntese própria. A fonte secundária
tem duas inconsistências internas, resolvidas aqui: o estado `Superseded` falta no template de
RFC dela (aqui o RFC fecha em `Accepted` ou `Rejected`, e quem é substituído é o ADR), e o
template de ADR dela não tem seção de alternativas (aqui tem, `DOC-ADR-04`).

---

## Relacionados

- [Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) — §5, onde os
  arquivos de `.specs/` entram no fluxo
- `skills/workflow/workflow-spec/` — a skill que grava cada documento desta nota, com seus templates
- `agents/software-architect.md` — escreve `design.md` e os ADRs
- `agents/product-manager.md` — escreve `requirements.md`
