# As sete tarefas

> Roteador tarefa → nota, com o que verificar em cada uma.

| Tarefa | Carregar (nesta ordem) |
| --- | --- |
| Definir uma rota nova | [[TanStack Router - Routing Concepts]] → [[TanStack Router - File-Based Routing]] → [[TanStack Router - Route Trees]] |
| Entender por que uma URL casa (ou não) com uma rota | [[TanStack Router - Route Matching]] → [[TanStack Router - Route Trees]] |
| Navegar entre rotas | [[TanStack Router - Navegação]] → [[TanStack Router - Routing Concepts]] |
| Lidar com search params | [[TanStack Router - Search Params]] → [[TanStack Router - Navegação]] |
| Carregar dados de rota | [[TanStack Router - Carregamento de Dados]] → [[TanStack Router - Route Context e Code Splitting]] |
| Dividir bundle | [[TanStack Router - Route Context e Code Splitting]] → [[TanStack Router - File-Based Routing]] |
| Árvore de rotas fora da convenção de arquivos | [[TanStack Router - Virtual File Routes]] → [[TanStack Router - Route Trees]] |

---

### 1. Definir uma rota nova

**Carregar:** [[TanStack Router - Routing Concepts]], depois [[TanStack Router - File-Based Routing]]; [[TanStack Router - Route Trees]] se a rota entra numa hierarquia já existente.

**Verificar:**

- O projeto usa file-based routing ou rotas em código? A convenção do projeto decide onde o arquivo vai — confirme antes de criar ([[TanStack Router - File-Based Routing]] × [[TanStack Router - Virtual File Routes]]).
- O nome do arquivo produz o path pretendido, segundo a convenção documentada — não segundo intuição.
- A rota é de qual tipo (raiz, layout, aninhada, dinâmica, curinga)? Confira a taxonomia em [[TanStack Router - Routing Concepts]] antes de escolher.
- Onde a rota se encaixa na árvore, e o que ela herda do pai (layout, contexto, loader).
- A árvore gerada foi atualizada, se o projeto depende de geração.
- Os tipos batem: type-safety é o ponto do roteador; erro de tipo aqui é sinal de path ou params mal declarados.

### 2. Navegar

**Carregar:** [[TanStack Router - Navegação]]; [[TanStack Router - Routing Concepts]] se a rota de destino for aninhada ou dinâmica.

**Verificar:**

- Navegação declarativa (link) ou imperativa (em handler/efeito)? Prefira a declarativa quando o destino é conhecido no render — é o que dá semântica de link ao usuário e ao browser.
- Params e search params do destino estão completos e tipados.
- Navegação relativa × absoluta: confirme o comportamento documentado antes de assumir.
- Substituir histórico ou empilhar? A escolha errada quebra o botão voltar.
- O destino existe na árvore de rotas — não navegue para path montado por concatenação de string sem checagem de tipo.

### 3. Search params

**Carregar:** [[TanStack Router - Search Params]]; [[TanStack Router - Navegação]] para escrever de volta na URL.

**Verificar:**

- Este estado **pertence** à URL? Critério em [[React - Patterns]] § 2: precisa sobreviver a refresh, ser compartilhável por link ou responder ao botão voltar (`REACT-PAT-10`). Filtro, aba, paginação, ordenação e faixa de datas quase sempre pertencem; menu aberto, hover e foco não.
- Se pertence à URL, a fonte de verdade é a rota — **não** `useState` espelhando o param.
- Os params são validados na leitura, com schema ([[Zod como schema de runtime]]): a URL é entrada não confiável.
- Valores padrão e params ausentes têm comportamento definido.
- A escrita preserva os demais params em vez de sobrescrever a query inteira.
- Tipos derivam do schema, não de `any` nem de cast manual.

### 4. Carregar dados de rota

**Carregar:** [[TanStack Router - Carregamento de Dados]]; [[TanStack Router - Route Context e Code Splitting]] quando o loader depende de contexto injetado.

**Verificar:**

- Quem é o dono do dado: o loader da rota, o cache do [[TanStack Query - O que um Dev Frontend Precisa Saber|TanStack Query]], ou os dois integrados? Escolha **um dono** e documente — duas fontes de verdade divergem.
- Nada de `fetch` em `useEffect` para o que o loader deveria carregar: `REACT-EFFECT-06` continua valendo dentro de uma rota.
- Dependências do loader (params, search params, contexto) estão declaradas, para que a recarga aconteça quando elas mudam.
- Onde a espera para: fronteira de `<Suspense>`/pending no nível certo da árvore, não na raiz por padrão.
- Onde a falha para: todo ponto de carregamento precisa de fronteira de erro — `REACT-ASYNC-08` e `REACT-PAT-06` ([[React - Patterns]] § 6).
- Erro esperado (404 de negócio, sem permissão) é estado/rota de erro, não exceção jogada para o boundary — `REACT-ASYNC-09`.
- Prefetch em hover/intent está considerado, se a doc do satélite o suportar.

### 5. Dividir bundle

**Carregar:** [[TanStack Router - Route Context e Code Splitting]]; [[TanStack Router - File-Based Routing]] para a convenção de arquivos que o suporta.

**Verificar:**

- Existe medida do problema antes da divisão? Mesma disciplina de `REACT-PERF-01`: otimização sem medida não entra.
- O que é dividido é o **componente/código da rota**, não o loader crítico — dividir o carregamento de dados atrasa a rota em vez de acelerá-la.
- A divisão respeita a convenção documentada no satélite; divisão manual com `lazy` por fora pode duplicar o que o roteador já faz.
- Há fronteira de espera para o chunk, e ela não é a raiz.
- Rotas críticas de entrada não ficaram atrás de um chunk desnecessário.

---

