---
titulo: NIST RBAC - ANSI INCITS 359
title: NIST RBAC — ANSI/INCITS 359
aliases: [INCITS 359, ANSI RBAC, NIST RBAC, RBAC padrão]
tags: [rbac, authz, padrao, nist, incits, bondingai]
status: verificado
verificado-em: 2026-08-12
fonte: https://csrc.nist.gov/projects/role-based-access-control
---

> [!info] Identificação
> Modelo NIST proposto em 2000 por **Sandhu, Ferraiolo e Kuhn**; adotado como padrão
> **ANSI/INCITS 359-2004**. Revisado entre 2007 e 2012; a versão corrente é
> **INCITS 359-2012** (29/05/2012). Composto por duas partes: **RBAC Reference Model** e
> **RBAC System and Administrative Functional Specification**.

> [!warning] O padrão é pago
> O texto normativo é vendido pelo INCITS. O conteúdo conceitual, porém, está em documentos
> públicos do NIST — que é o que interessa para vocabulário:
> - Sandhu, Ferraiolo, Kuhn (2000), *The NIST Model for Role-Based Access Control: Towards a
>   Unified Standard* — [PDF no NIST](https://tsapps.nist.gov/publication/get_pdf.cfm?pub_id=916402)
> - Ferraiolo, Sandhu, Gavrila, Kuhn, Chandramouli, *A Proposed Standard for Role-Based Access
>   Control* — [PDF no CSRC](https://csrc.nist.gov/csrc/media/projects/role-based-access-control/documents/rbac-std-draft.pdf)
>
> Ler o padrão comprado só se faz falta em contexto de conformidade formal.

---

## Quando vale o investimento

**Vale** se o catálogo de permissões está sendo desenhado agora. O ganho não é técnico — é de vocabulário. Sem ele, a equipe inventa semântica própria para "role que herda de outro role" e para "essas duas permissões não podem estar na mesma pessoa", e depois descobre que as palavras significavam coisas diferentes para cada um.

**É opcional** se o modelo já está fechado e funcionando. Nesse caso, leia só a seção de hierarquia e SoD abaixo e siga em frente.

---

## Componentes do modelo de referência

### Core RBAC

Os elementos: **usuários, roles, objetos, operações** e **permissões** — sendo permissão um par operação × objeto. Duas relações de atribuição:

```
Usuário ──UA──► Role ──PA──► Permissão (operação × objeto)
```

- **UA** (user assignment) e **PA** (permission assignment) são ambas muitos-para-muitos. Um usuário tem N roles; um role tem N permissões; uma permissão está em N roles.
- **Sessão** é elemento de primeira classe do modelo: o usuário ativa um subconjunto dos seus roles numa sessão. É esse conceito que dá suporte a *least privilege* na prática — ter um role não obriga a exercê-lo o tempo todo.

> [!note] A parte do modelo que a maioria das implementações ignora
> Quase nenhum produto de mercado implementa **ativação de role por sessão** — role atribuído é
> role ativo. Sabendo disso, você lê a lacuna como decisão do produto, não como bug seu.

### Hierarchical RBAC

Herança entre roles: um role sênior herda as permissões dos juniores.

- **Hierarquia geral**: herança múltipla, um role pode herdar de vários.
- **Hierarquia limitada**: restrita a estruturas em árvore/árvore invertida.

O ponto prático: hierarquia é **conveniência de administração**, não expressividade nova. Tudo que ela faz pode ser feito com atribuição direta; ela evita a duplicação e o drift entre catálogos. Se a ferramenta de identidade não suporta hierarquia (caso comum — ver [WorkOS - RBAC](workos-rbac.md)), a alternativa é gerar o catálogo plano a partir de uma definição hierárquica no código, mantendo a hierarquia como fonte e a lista plana como artefato.

### Constrained RBAC — separação de responsabilidades

| Tipo | Restringe | Quando é violada |
|---|---|---|
| **SSD** — Static Separation of Duty | a relação **UA**: certos roles não podem ser atribuídos ao mesmo usuário | na atribuição |
| **DSD** — Dynamic Separation of Duty | os roles **ativados numa mesma sessão** | na ativação |

A diferença importa: SSD é regra de governança ("ninguém acumula aprovar-pagamento e emitir-pagamento"); DSD permite acumular, mas não exercer ao mesmo tempo ("pode ser ambos, não na mesma sessão").

Ambas são expressas com **cardinalidade**: o conjunto de roles e o número máximo que um usuário pode ter dele.

### System and Administrative Functional Specification

A segunda parte especifica as funções que um sistema RBAC deve oferecer, em três grupos: **comandos administrativos** (criar role, atribuir usuário…), **funções de sistema de suporte** (criar sessão, ativar role, checar acesso) e **funções de revisão** (quais usuários têm este role, quais permissões tem este usuário).

As **funções de revisão** são a parte mais subestimada: "quem pode fazer X?" e "o que este usuário pode fazer?" são as perguntas de auditoria, e um catálogo que só sabe responder na direção do enforcement não sobrevive à primeira revisão de acesso.

---

## O que levar para o desenho do catálogo

1. **Permissão = operação × objeto.** A convenção `recurso:ação` já adotada ([WorkOS - RBAC](workos-rbac.md) §3) é exatamente isso — bom sinal, e agora com nome padronizado.
2. **Decida cedo se haverá hierarquia** e onde ela mora (na ferramenta ou no código que gera o catálogo).
3. **Procure os pares de SoD antes de precisar deles.** Se existir qualquer par do tipo "quem solicita não aprova", escreva-o agora e decida se é SSD ou DSD — retrofitar isso depois de 40 permissões é caro.
4. **Planeje as funções de revisão.** Poder listar usuários por permissão é requisito, não extra.
5. **Use os termos do padrão** em ADR e código: *user assignment*, *permission assignment*, *role hierarchy*, *SSD*, *DSD*. Evita a discussão sobre o que "grupo" significa nesta empresa.

## Limite do modelo

RBAC decide sobre **tipos** de recurso, não sobre **instâncias**. Não há no padrão nada sobre ownership, compartilhamento ou hierarquia de pastas — ver [WorkOS - RBAC](workos-rbac.md) §7. O cheat sheet de autorização do OWASP chega a recomendar ABAC/ReBAC no lugar de RBAC por isso ([OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md)). A leitura equilibrada: RBAC continua adequado para permissão **funcional**; permissão sobre instância é outro mecanismo, e misturá-los é o erro.

## Relacionados

- [WorkOS - RBAC](workos-rbac.md) — a implementação concreta e onde ela diverge do padrão
- [OWASP - Sessão e Autorização](owasp-sessao-e-autorizacao.md) — checklist de autorização
