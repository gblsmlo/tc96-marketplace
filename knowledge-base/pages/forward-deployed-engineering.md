---
titulo: Forward Deployed Engineering
type: Page
tags:
 - engineering
 - product
 - ai
 - careers
 - forward-deployed-engineering
source: "Pragmatic Engineer — What are Forward Deployed Engineers, and why are they so in demand?; FDE Academy — How Palantir Invented the Forward Deployed Engineer Model"
---

# Forward Deployed Engineering

> Síntese sobre **Forward Deployed Engineering (FDE)**: o modelo criado pela Palantir em que engenheiros se embarcam no cliente para resolver problemas reais no campo — e devolvem o aprendizado ao produto. Baseada em duas fontes: o deep-dive da Pragmatic Engineer (Gergely Orosz, ago/2025) e a análise de origem da FDE Academy (mar/2026). A ideia atômica central derivada está em.

## O que é

**Forward Deployed Engineer (FDE)** é um engenheiro de software que alterna entre estar **embarcado no time do cliente** e nos **times de engenharia do produto** — misturando, na prática, engenharia de software, vendas e engenharia de plataforma. O papel foi apelidado de "o trabalho mais quente da tecnologia" pela firma de venture capital a16z.

A definição da própria Palantir resume o escopo: as responsabilidades de um FDE "parecem as de um CTO de startup — você trabalha em times pequenos e é dono da execução de ponta a ponta de projetos de alto risco".

## Origem

O papel **"Forward Deployed Software Engineer"** foi criado na Palantir no **início dos anos 2010**, com o nome interno de **"Delta"**. A origem é uma necessidade, não um desenho de produto:

- A Palantir (fundada em 2003) atende agências de inteligência, órgãos de segurança e empresas privadas, com dados sensíveis e proprietários.
- Esses clientes **não conseguiam especificar o que precisavam**: não podiam compartilhar dados abertamente, não havia requisitos claros nem feedback loops convencionais.
- Em vez de perguntar o que o cliente queria, a Palantir **colocou engenheiros dentro do ambiente do cliente**, aprendendo por observação, experimentação e construção em tempo real.

Até **cerca de 2016**, a Palantir tinha **mais FDEs do que engenheiros de software tradicionais**. Com o lançamento do **Foundry** (2016), a plataforma integrada para o setor comercial e civil, muitos FDEs migraram de volta para a engenharia de produto — levando o aprendizado do campo para o núcleo.

## O modelo Echo/Delta

A Palantir não dependia de engenheiros trabalhando sozinhos, e sim de uma estrutura em dois times:

- **Echo** — especialistas de domínio, muitas vezes vindos do próprio setor do cliente (militar, saúde, finanças). Identificam os problemas reais e servem de ponte entre cliente e engenharia.
- **Delta** — engenheiros focados em execução, que constroem soluções rápido, priorizando velocidade e impacto sobre design perfeito, confortáveis com dados incompletos e requisitos mutáveis.

Juntos, funcionam como uma **mini-startup dentro de cada cliente**. A Palantir resume a divisão de foco assim: o foco de um **Dev** é *uma capacidade, muitos clientes*; o foco de um **Delta** é *um cliente, muitas capacidades*.

## O ciclo campo → produto (gravel road → paved highway)

O mecanismo que distingue o FDE de uma consultoria comum é o **feedback loop entre trabalho de campo e produto**:

1. O FDE constrói no cliente uma solução **"estrada de cascalho"** (gravel road): rápida, pragmática, para aquele cliente específico.
2. O time de produto estuda essas soluções, identifica os **padrões que se repetem entre clientes** e transforma os comuns em features padrão — as **"estradas pavimentadas"** (paved highways).

Assim, trabalho customizado vira capacidade de produto. A ideia está desenvolvida em.

## FDE vs papéis vizinhos

| Papel | Diferença central |
| --- | --- |
| **Consultor** | Faz recomendações pontuais (one-off) e segue em frente; o FDE trabalha com o cliente **a longo prazo** e contribui com o produto. |
| **Solutions Architect (SA)** | Papel mais consultivo: raramente escreve código na infraestrutura do cliente; constrói MVPs/PoCs com dados anonimizados ou offline. |
| **Sales Engineer / Agent Engineer / Technical Delivery Engineer** | Chegam perto, mas o FDE se distingue por **trabalhar com o cliente e, ao mesmo tempo, contribuir com o produto** que a empresa vende. |

A presença no cliente é parte do papel: a Palantir espera cerca de **25% do tempo** onsite; startups como a Commure estimam até **50%**. Ambientes incomuns são comuns — linha de montagem (Airbus), chão de fábrica, ambientes *airgapped*.

## Por que está em alta agora

O ressurgimento do papel em **2025+** é puxado pela **integração de LLMs e produtos de IA**: LLMs são complicados de colocar para funcionar em ambientes reais, e as empresas descobriram que precisam de engenheiros *hands-on* dentro do cliente. OpenAI (liderada por Colin Jarvis, Head of FDE), Ramp, Anthropic e Stripe adotaram versões do modelo.

Na OpenAI, o trabalho de FDE se divide em três fases — **scoping** (dias no cliente mapeando processos e áreas de valor), **validação** (construir *evals* e provar o valor antes de entregar) e **entrega** (construir no cliente a "menor unidade possível" que gere valor de ponta a ponta). O time de FDE também contribui com o roadmap de produto (ex.: o **Agents SDK**).

## Relacionados

-
-
-
-
-
-
-
-
-

## Fonte

- Gergely Orosz — *What are Forward Deployed Engineers, and why are they so in demand?* (Pragmatic Engineer, 12 ago 2025): https://newsletter.pragmaticengineer.com/p/forward-deployed-engineers
- FDE Academy — *How Palantir Invented the Forward Deployed Engineer Model and Why AI Startups Are Adopting It* (25 mar 2026): https://fde.academy/blog/how-palantir-invented-the-forward-deployed-engineer-model
