---
titulo: Architecture in React
aliases:
  - Arquitetura em React
tags:
  - frontend
  - react
  - architecture
---
# Architecture in React

Mapa das decisões arquiteturais de uma aplicação React e da nota que responde cada uma. Esta página
**roteia**; o conteúdo mora nos Zettels e em `docs/`.

React é uma biblioteca de renderização. Ele define como a UI é descrita e reconciliada, e
deliberadamente **não** opina sobre pasta, roteamento, busca de dados, cache ou fronteira de módulo.
"Arquitetura em React" é, quase inteiramente, o conjunto de decisões que o React deixou em aberto — e
que alguém vai tomar de qualquer forma, por omissão se não por escolha.

Por isso a ordem importa: decisões tomadas por omissão viram acoplamento sem dono.

---

## 1. Os cinco eixos de decisão

| Eixo | A pergunta que ele responde |
| --- | --- |
| **Posse de estado** | Quem é dono de cada dado e onde ele mora |
| **Organização física e fronteiras** | Onde o código mora e quem pode importar quem |
| **Fluxo de dados e contratos** | Como o dado atravessa camadas e como isso é verificado |
| **Fronteiras de falha** | O que acontece quando algo quebra, e onde a falha para |
| **Verificação** | O que impede a arquitetura de erodir sem ninguém notar |

Os eixos são independentes. Um projeto pode ter feature folders exemplares e nenhuma política de
cache — e vai sofrer do mesmo jeito.

---

## 2. Mapa: cada eixo e sua nota de entrada

### Posse de estado

| Decisão | Nota de entrada |
| --- | --- |
| Onde colocar cada estado | |
| Não guardar o que dá para calcular | |
| Separar local, remoto e persistido | |
| Dado do servidor não é estado global | |
| Política de frescor e invalidação | |
| Dado no navegador precisa de versão | |
| Referência de API | [React - Estado e Reatividade](../docs/react-estado-e-reatividade.md) |

### Organização física e fronteiras

| Decisão | Nota de entrada |
| --- | --- |
| Agrupar por domínio, não por tipo | |
| **Estrutura completa, regras e enforcement** | **[Feature-Based Architecture](feature-based-architecture.md)** |
| Superfície pública de um módulo | |
| Quando extrair para o compartilhado | |
| Composição em vez de configuração | |
| Fronteira dentro do componente | [React - Patterns](../docs/react-patterns.md) § 6 |
| Coesão e acoplamento, em geral | · |

### Fluxo de dados e contratos

| Decisão | Nota de entrada |
| --- | --- |
| Direção do dado | |
| Contrato verificável entre front e back | |
| **Quem é dono de cada decisão na fronteira do servidor** | **[Fronteira do BFF - forma, jornada e regra](fronteira-do-bff-forma-jornada-e-regra.md)** |
| Quando o código vira pacote, e o que o CI precisa verificar | [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) |
| Onde validar, e quantas vezes | |
| Schema em runtime | |
| Captura separada de validação | |
| Extrair sincronização | |
| Fronteira de confiança no servidor | |
| Rota, loader e busca de dados | [TanStack Router](../docs/tanstack-router.md) |

### Fronteiras de falha

| Decisão | Nota de entrada |
| --- | --- |
| Erro esperado × inesperado | |
| Isolar falha de renderização | |
| Reverter mudança otimista | |
| Assincronia e estados de carregamento | [React - Suspense e Assincronia](../docs/react-suspense-e-assincronia.md) |

### Verificação

| Decisão | Nota de entrada |
| --- | --- |
| Testar comportamento, não implementação | |
| Fronteira verificada por lint | · [Feature-Based Architecture](feature-based-architecture.md) § 7 |
| Regras normativas de React | [React - Rules of React](../docs/react-rules-of-react.md) |
| Pureza como pré-condição | |

---

## 3. Ordem das decisões

Nem toda decisão custa o mesmo para desfazer. Decida cedo o que é caro reverter; adie o resto até
haver evidência.

| Ordem | Decisão | Custo de reverter |
| --- | --- | --- |
| 1 | Direção da dependência entre camadas | **alto** — atravessa todo o código |
| 2 | Onde o dado remoto vive | **alto** — muda todo componente que o consome |
| 3 | Contratos e validação na fronteira | **alto** — sem eles, o erro aparece longe da causa |
| 4 | Organização física em features | médio — mover arquivo é mecânico se o barrel existe |
| 5 | Estrutura interna de cada feature | baixo — local à feature |
| 6 | Extração para o compartilhado | baixo — e deve ser adiada de propósito |

O item 6 é o mais comum de se antecipar e o que mais custa quando antecipado: uma abstração criada no
segundo consumidor tem contrato inventado, e o terceiro caso chega exigindo uma flag.


Um corolário: **estrutura de pasta não é a primeira decisão.** É a quarta. Projetos que começam
desenhando o diretório costumam ter fronteiras bonitas com dependências invertidas atravessando-as.

---

## 4. A decisão adotada para organização física

[Feature-Based Architecture](feature-based-architecture.md) — fatia vertical por domínio, `index.ts` como API pública, direção de
dependência única `routes → features → genérico`, e regras `REACT-ARCH-*` verificadas com Biome.

Essa é a nota filha desta e a **entrada padrão** para escrever ou revisar estrutura de código React
no vault. Ela também define o contrato que uma skill de estrutura carrega (§ 10).

---

## 5. Uso por um agente

Esta página é um **roteador**, não uma fonte. Um agente não deve citá-la como regra — ela não tem
IDs normativos. Ela responde a uma única pergunta: *qual nota abrir para esta decisão*.

```
DECISÃO DE ESTRUTURA / IMPORT / PASTA
  → [Feature-Based Architecture](feature-based-architecture.md) § 4 (regras) e § 10 (contrato)

DECISÃO DENTRO DO COMPONENTE
  → [React - Patterns](../docs/react-patterns.md)

REGRA NORMATIVA DE REACT
  → [React - Rules of React](../docs/react-rules-of-react.md) e [React.js](../docs/react-js.md) § 6

CONSULTA DE API
  → [React.js](../docs/react-js.md) § 4 (mapa da API) → o satélite indicado
```

A hierarquia de fontes do vault, da mais forte para a mais fraca: `docs/` (documentação verificada)
→ Zettels (ideias consolidadas) → `pages/` (mapas). Divergência entre uma página e um Doc é bug da
página. Ver [React.js](../docs/react-js.md) § 7, e `react-build` como exemplo de skill que implementa esse contrato.

**Três exceções, explícitas.** [Feature-Based Architecture](feature-based-architecture.md),
[Fronteira do BFF - forma, jornada e regra](fronteira-do-bff-forma-jornada-e-regra.md) e [Monorepo com Bun - estrutura e tooling](monorepo-com-bun-estrutura-e-tooling.md) moram em
`pages/` mas são **normativas**: têm IDs citáveis (`REACT-ARCH-*`, `BFF-*` e `MONO-*`), invariantes e
contrato de skill. Ela está aqui, e não em `docs/`,
porque não resume documentação externa de uma ferramenta — ela registra uma decisão desta casa, com
convenções que só existem neste vault. Uma página com contrato de skill é citável como regra; esta
página, que só roteia, não é. Quando um Doc contradisser a filha em fato verificável — comportamento
do Biome, API do TanStack — o Doc vence e a filha é corrigida.

---

## Relacionados

- [Feature-Based Architecture](feature-based-architecture.md) — nota filha: organização física do código
- [React.js](../docs/react-js.md) — hub de React: modelo mental, mapa da API, contrato de skill
- [React - Patterns](../docs/react-patterns.md) — decisão estrutural dentro do componente
- [React - Rules of React](../docs/react-rules-of-react.md) — base normativa
- [Frontend roadmap](frontend-roadmap.md) — trilha de estudos e evidência prática
- — arquitetura fora do contexto de frontend
- ·
