---
titulo: Pull Request
---

## O que é?
Um Pull Request (PR) é uma solicitação para mesclar alterações de uma branch para outra em um repositório Git. É usado para revisar, discutir e aprobar mudanças antes de integrá-las ao código principal.

## Por que usar?

- **Revisão de código**: Permite que outros desenvolvedores analisem as mudanças antes da integração
- **Controle de qualidade**: Identifica bugs, problemas de estilo e melhorias antes de afetar a base principal
- **Documentação de mudanças**: Cria um registro das alterações com contexto e justificativa
- **Colaboração**: Possibilita que múltiplos desenvolvedores trabalhem em paralelo sem interferir no código alheio
- **Rastreabilidade**: Vincula mudanças a issues/tarefas e permite acompanhar o histórico

## Como fazer?

### 1. Criar uma branch

```bash
git checkout -b minha-feature
```

### 2. Fazer as alterações e commitar

```bash
git add.
git commit -m "Descrição das alterações"
```

### 3. Enviar para o repositório remoto

```bash
git push origin minha-feature
```

### 4. Criar o Pull Request

- No GitHub/GitLab/Bitbucket, clique em "New Pull Request"
- Selecione a branch base (ex: main) e a branch com suas alterações
- Adicione título e descrição explicativa
- Solicite revisores se necessário
- Linkue com issues relacionadas

### 5. Responder feedback

- Faça alterações solicitadas
- Comente no PR quando resolver pendências
- Aguarde aprovação e merge

## Quando usar?

- Ao adicionar novas funcionalidades
- Ao corrigir bugs
- Ao refatorar código
- Antes de integrar qualquer alteração à branch principal
- Em workflows de equipe que seguem Git Flow ou trunk-based development


