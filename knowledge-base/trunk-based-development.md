---
titulo: Trunk-based development
type: Page
tags:
  - devops
  - version-control
  - git
  - ci-cd
  - trunk-based-development
source: "Atlassian — Trunk-based Development (Kev Zettler)"
---
# Trunk-based development

> Síntese baseada no artigo **"Trunk-based Development"** do guia *Continuous Delivery Topics* da Atlassian, de Kev Zettler. Este guia apresenta o que é a prática, por que times DevOps a adotam, seus benefícios e as boas práticas que a documentação recomenda. Os conceitos atômicos derivados estão como e.

> ⚖️ Para o contraponto — especialmente em times com dificuldade de planejamento e comunicação —, veja ****.

## O que é

**Trunk-based development** é uma prática de controle de versão na qual os desenvolvedores mesclam **atualizações pequenas e frequentes** em um "trunk" (a branch `main`). Ao simplificar as fases de *merge* e integração, a prática ajuda a alcançar **CI/CD** e aumenta a velocidade de entrega e a performance organizacional.

É um modelo mais simples se comparado ao **Gitflow**:

- No **Gitflow**, feature branches longas e múltiplas branches primárias (desenvolvimento, hotfix, features, releases) tornam o merge mais complexo, com maior risco de divergência, conflitos e necessidade de sessões de planejamento e revisão extras.
- No **trunk-based development**, todos os desenvolvedores têm acesso à main, que é assumida como **sempre estável e pronta para deploy**. O foco está no trunk como fonte única de correções e releases.

> A principal é: quanto mais longa a feature branch, maior o risco de ela divergir do trunk e gerar conflitos ao integrar.

## Por que times DevOps adotam

O artigo lista quatro benefícios principais:

1. **Reduz o atrito da integração de código** — assim que o trabalho termina, o código é mesclado à main; conflitos crescem conforme o time e a base de código escalam, e o modelo reduz esses conflitos.
2. **Permite integração contínua de código** — um fluxo constante de commits entra na main; com suíte de testes automatizados e monitoramento de cobertura, a CI valida cada merge.
3. **Garante code review contínuo** — commits pequenos tornam a revisão mais rápida e eficiente que revisar páginas de código de uma feature branch longa.
4. **Habilita releases consecutivas em produção** — merges diários mantêm o trunk "verde" (pronto para deploy a qualquer commit), permitindo releases diárias.

## Trunk-based development e CI/CD

A prática é descrita como um **requisito da integração contínua**. Se os desenvolvedores trabalham em feature branches longas e isoladas, integradas raramente, a integração contínua não cumpre seu potencial. Com trunk-based development, os desenvolvedores integram à main em conjunto com testes automatizados que rodam **após cada commit**, garantindo que o projeto funcione o tempo todo.

## O que entender antes de começar (pré-requisitos)

O artigo não apresenta uma lista formal de pré-requisitos, mas as condições para o modelo funcionar emergem diretamente de suas seções sobre CI/CD e boas práticas. São os entendimentos que precisam estar maduros para que merges frequentes não virem quebras em produção:

1. **Aceitar que a `main` é sempre deployável.** A branch principal é a fonte única de correções e releases, assumida como estável e pronta para deploy a qualquer commit. Isso é uma mudança de mentalidade em relação ao Gitflow (onde apenas alguns aprovam mudanças na main).
2. **Ter integração contínua de verdade.** <mark style="background: #ABF7F7A6;">O valor do modelo depende de builds e testes automatizados que rodam a cada merge.</mark> *"Se build e teste são automatizados, mas os devs trabalham em branches longas integradas com pouca frequência, a integração contínua não cumpre seu potencial."*
3. <mark style="background: #ABF7F7A6;">**Testes automatizados abrangentes.** Unitários e de integração curtos no desenvolvimento/merge; testes end-to-end mais longos nas fases finais contra staging/produção. Sem isso, a suíte não consegue "aprovar ou negar" os commits rapidamente.</mark>
4. **Deploy automatizado e one-click.** Para o trunk "verde" se transformar em release diário de fato, a publicação em produção precisa ser automatizada.
5. **Build e testes rápidos.** Com cachês e stubs para serviços de terceiros, para sustentar a cadência diária (se a CI demora horas, o ritmo diário não sobrevive).
6. **Disciplina de processo coletiva.** Lotes pequenos, poucas branches ativas, merge diário e code review imediato são hábitos do time inteiro — não ferramentas opcionais.
7. **Controlar a exposição de código incompleto.** são o mecanismo que permite comitar na main antes de a capacidade estar pronta, sem precisar de branches longas para "esconder" trabalho — e, por isso, exigem também o hábito de remover flags legadas depois da ativação.

> Resumo prático: **main sempre deployável + CI com testes + deploy automatizado + lotes pequenos e merges diários + feature flags**. Sem esse conjunto, o trunk-based vira apenas "commitar direto na main", com risco alto.

## Boas práticas recomendadas

1. **Desenvolver em pequenos lotes** — o artigo usa a metáfora do *staccato*: notas curtas em sucessão rápida. Commits e branches pequenos reduzem a carga cognitiva e aceleram o ritmo de merges e deploys.
2. **Usar feature flags** — permitem comitar código novo direto na main dentro de um caminho inativo, ativando a capacidade depois — sem precisar de uma branch de feature.
3. **Implementar testes automatizados abrangentes** — testes unitários e de integração curtos durante o desenvolvimento e no merge; testes end-to-end mais longos nas fases finais, contra staging/produção. A suíte aprova ou nega automaticamente cada commit.
4. **Fazer code review contínuo e imediato** — os testes automatizados são uma primeira camada de revisão; o revisor pode verificar que os testes passaram e a cobertura aumentou antes de focar em otimizações. *(O título da seção no artigo é "asynchronous code reviews", mas o texto defende revisão imediata, não adiada.)*
5. **Manter poucas branches ativas** — a documentação recomenda **três ou menos** branches ativas e **excluir a branch após o merge**, evitando branches obsoletas que poluem repositórios e interfaces de Git.
6. **Mesclar ao trunk pelo menos uma vez por dia** — times de alta performance fecham branches prontas diariamente e marcam o `main` como commit de release ao fim do dia, gerando incrementos ágeis diários.
7. **Reduzir code freezes e fases de integração** — equipes de CI/CD não deveriam precisar de pausas planejadas; o "contínuo" implica fluxo constante.
8. **Build rápida e execução imediata** — otimizar tempos de build/teste, usar camadas de cache e stubs para serviços de terceiros.

## Conclusão

Trunk-based development é descrito como o **padrão atual para times de engenharia de alta performance**, por estabelecer uma cadência de release com uma estratégia de branching Git simplificada e por dar mais flexibilidade e controle sobre como o software chega ao usuário final.

## Relacionados


## Fonte

Atlassian — *Trunk-based development*, por Kev Zettler. Disponível em: 
https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development

