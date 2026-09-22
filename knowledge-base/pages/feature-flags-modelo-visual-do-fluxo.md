---
titulo: Feature Flags — modelo visual do fluxo
type: Page
tags:
  - feature-flags
  - visual
  - mermaid
  - devops
  - expansao-habilidades
  - ci-cd
source: "`Feature Flags - Expansão de Habilidades - Rocketseat`"
---

# Feature Flags — modelo visual do fluxo

> Modelo visual derivado do módulo **Feature Flags** (Rocketseat — Expansão de Habilidades). Os diagramas estão em Mermaid e renderizam nativamente no Obsidian. Eles cobrem o fluxo end-to-end: abordagens de integração, definição/avaliação do flag, A/B testing e estratégias de release.

## Fluxo principal

```mermaid
flowchart TB
    A["Aplicação<br/>(UI ou lógica backend)"]
    C["Contexto<br/>userId · groupId · atributos"]
    GATE{"Qual abordagem de integração?"}
    D["Direta — SDK do fornecedor<br/>(Unleash)"]
    OF["Desacoplada — OpenFeature<br/>API padrão → Provider (FlagD)"]
    CFG["Definição do flag<br/>dashboard do Unleash / JSON do FlagD"]
    TGT["Targeting<br/>constraints · grupos · % de tráfego"]
    VAR["Variants · pesos"]
    EV{"Avaliação"}
    ENABLED["true → feature ligada"]
    DISABLED["false → feature desligada"]
    VARIANT["getVariant → variante atribuída"]
    USE["Controle de visibilidade / lógica<br/>(vira um ramo de `if`)"]
    SAFE["Toggle dinâmico · kill-switch · métricas"]
    REL["Estratégias de release<br/>Canary · Blue-Green · Rolling"]
    K8S["Argo Rollouts · Kubernetes"]

    A --> C
    C --> GATE
    GATE -->|"acoplado ao vendor"| D
    GATE -->|"desacoplado"| OF
    D -->|"get / isEnabled"| CFG
    OF --> CFG
    CFG --> TGT
    TGT --> VAR
    VAR --> EV
    EV -->|"habilita"| ENABLED
    EV -->|"desabilita"| DISABLED
    EV --> VARIANT
    ENABLED --> USE
    DISABLED --> USE
    VARIANT --> USE
    USE --> SAFE
    SAFE -. "gatilho reverso (off)" .-> USE
    CFG -.-> REL
    REL --> K8S
```

## Distribuição de variantes (detalhe)

Como o *global enablement* atua como portão antes dos *weights* das variants:

```mermaid
flowchart TB
    U["100% dos usuários (tráfego)"]
    G{"Flag globalmente ativo?"}
    NO["Não → todos caem no caminho 'false'<br/>(variants nunca são avaliadas)"]
    POOL["Sim → flag habilita 50% do tráfego"]
    NONE["50% → feature inativa para esses usuários"]
    SPLIT["Dos 50% ativos, variants 50/50"]
    VA["25% → Variant A"]
    VB["25% → Variant B"]
    U --> G
    G -->|"desligado"| NO
    G -->|"ligado"| POOL
    POOL --> NONE
    POOL --> SPLIT
    SPLIT --> VA
    SPLIT --> VB
```

> Pontos do módulo: o split dos variants incide **sobre o pool ativo**, não sobre os 100% — por isso 50% de flag ativo + variants 50/50 resultam em 25%/25% (e 50% fora). O `isEnabled`/`getBooleanValue` retorna `true|false`; `getVariant` devolve qual variante o usuário recebeu (essencial para log e comparação A/B).

## A/B testing com targeting e sticky sessions

```mermaid
flowchart LR
    USER["Usuário"]
    REQ["Requisição chega"]
    CTX["Contexto enviado<br/>userId · atributos · properties (ex.: groupId)"]
    TGT{"Targeting resolve?"}
    FA["Flow A (original)<br/>Email · botão 'Logar'"]
    FB["Flow B (teste)<br/>Username · botão 'Como entrar'"]
    STICKY["Sticky session<br/>fixa o usuário no fluxo atribuído"]
    METRIC["Métricas<br/>conversão · cliques · usuários por flow"]

    USER --> REQ --> CTX --> TGT
    TGT -->|"atende constraints / variante A"| FA
    TGT -->|"outro segmento / variante B"| FB
    FA --> STICKY
    FB --> STICKY
    STICKY --> METRIC
```

> No módulo: para um resultado de teste confiável, o usuário não pode "teleportar" de Flow A para Flow B num refresh — daí a necessidade de *sticky sessions*, que o fornecedor (ex.: Unleash) gerencia automaticamente.

## Notas de implementação (resumo do fluxo)

- **Unleash (vendor direto):** a aplicação chama o SDK com um contexto; o serviço aplica constraints + `%` e devolve `true|false` (ou a variante). Apache-style/Open Source roda local via Docker (`docker network create unleash`); o **Open Source é self-hosted**, com custo operacional, enquanto o **Unleash Cloud** tem trial de 14 dias.
- **OpenFeature/FlagD (desacoplado):** a aplicação depende só da **interface OpenFeature**; o **provider** (Ex. FlagD) conversa com o serviço. FlagD é **code-first** — usa arquivos de definição JSON/YAML (schema) como fonte de verdade, sem dashboard, com playground em `flagd.dev` para validar targeting. Conexão gRPC; usar *wait-for* no startup para evitar *race condition*.
- **Deploy gradual (K8s):** com **Argo Rollouts** (CRD no cluster + controlador), a migração é de `Deployment` → `Rollout`, permitindo **Canary** em passos (ex.: 8 passos com `%` de tráfego e waits) e **Blue-Green**, com `preview services`, revisões e rollback via UI.

## Relacionados

- `Feature Flags - Expansão de Habilidades - Rocketseat`
- [Trunk-based development](trunk-based-development.md)