# Exemplo trabalhado

Tarefa: *"a listagem de faturas precisa filtrar por status, e o filtro tem que sobreviver a refresh e ao botão voltar"*.

Esta skill roteia; ela **não** escreve o código. O exemplo abaixo é do uso dela — que notas carregar, em que ordem, e o que conferir antes de dar a tarefa por concluída.

**1. Identificar a tarefa.** "Filtro que sobrevive a refresh e ao voltar" é estado que pertence à URL, não ao componente. Na tabela de "Como usar", isso é **lidar com search params** — e, porque a listagem também busca dado, **carregar dados de rota**. Duas tarefas, nesta ordem.

**2. Carregar, na ordem da tabela:**

| Ordem | Nota | Para responder |
| --- | --- | --- |
| 1 | [[TanStack Router - Search Params]] | como declarar e validar o `status` |
| 2 | [[TanStack Router - Navegação]] | como trocar o filtro sem empilhar histórico a cada tecla |
| 3 | [[TanStack Router - Carregamento de Dados]] | se o loader participa, ou se o dado é do cache |

Não carregue [[TanStack Router - Routing Concepts]] nem [[TanStack Router - File-Based Routing]]: a rota já existe. É a regra de economia de contexto.

**3. Percorrer o "Verificar" de cada tarefa.** O que essa passagem produz de decisão real:

- o `status` é **validado** na rota, não lido como string solta — é o que dá o tipo ao resto;
- trocar o filtro **substitui** o histórico em vez de empilhar, senão o botão voltar percorre cada letra digitada;
- o dado remoto continua sendo do [[TanStack Query]]; a rota é dona do **filtro**, não das faturas — a fronteira está em [[TanStack Router - Carregamento de Dados]], e a decisão loader × Query é dela;
- o componente **não** guarda o filtro em `useState` (`REACT-PAT-10`) — se guardasse, teria dois donos do mesmo dado divergindo.

**4. A regra de honestidade, em ação.** Se [[TanStack Router - Search Params]] estiver ausente ou incompleta no momento da leitura — o que o Aviso acima admite ser possível — **declare a limitação** e vá à documentação oficial do TanStack Router. Depois registre o verificado na nota. O que não se faz é preencher a lacuna de memória e apresentar a suposição como fato.

**A fronteira que este exemplo demarca:** três skills tocam esta tela e nenhuma invade a outra — esta decide que o filtro é da URL, [[tanstack-query]] decide o cache das faturas, e [[react-developer]] escreve o componente que consome as duas.

---
