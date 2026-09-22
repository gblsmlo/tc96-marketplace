---
titulo: Storybook - Pendências de revisão
tags:
 - storybook
 - manutencao
source: "Teste de leitura com cinco agentes sem contexto + auditoria adversarial, 2026-08-19"
verificado-em: 2026-08-19
---

# Storybook — registro de revisão

> O que a estrutura de [Storybook](storybook.md) passou depois de escrita, o que os leitores acharam, o que foi corrigido, e **o que continua aberto**. Quem editar as notas deveria ler a § "Invariantes" antes.

---

## O teste

Cinco leitores sem nenhum contexto da conversa que produziu as notas, cada um recebendo só o diretório e uma tarefa. Todos instruídos a **não preencher lacuna com conhecimento prévio de Storybook** — quando a nota não responde, dizer que não responde. É o que separa "a doc funcionou" de "o leitor já sabia".

| Leitor | Tarefa |
| --- | --- |
| 1 | Configurar Storybook do zero num monorepo Bun (Vite 7), com testes em CI |
| 2 | Escrever as stories de um `DataTable` de design system, com docs e controles |
| 3 | Três estados de rede + teste de interação com mock de módulo |
| 4 | **Está em Vite 6 com `react-vite`**: story de página com `<Link>` e `useParams` |
| 5 | Auditoria adversarial: contradições, exemplo que viola regra própria, IDs, contagens, código que não compila |

---

## O achado que mais mudou a estrutura

**O decorator de router do caminho Vite descartava a story.**

```tsx
decorators: [
 (Story) => { // recebido
 const router = createRouter({ routeTree, history });
 return <RouterProvider router={router} />; // e nunca renderizado
 },
],
```

Três leitores independentes acharam. O componente **aparece na tela** — porque a árvore de rotas o resolve — então nada parece errado. Mas `<Story />` nunca entra: `component`, `args` e o painel de controles ficam inertes. Era o exemplo canônico da nota inteira, e violava `SB-CSF-04`, `SB-DOC-05` e a própria definição de decorator do hub.

A correção não foi só inserir `<Story />`: a nota passou a distinguir **duas montagens** — árvore mínima (a rota é criada para a story, cujo componente é `<Story />`; args vivos) e árvore real (a rota resolve o próprio componente; args mortos, e a story existe para exercitar a resolução). Ver [Storybook - React Vite](storybook-react-vite.md) § 4.1–4.3.

O segundo achado de maior impacto veio do leitor 3: **a doc não tinha query assíncrona**. Só `getBy…` síncrono, em toda a estrutura. Numa story que busca dado pela rede, o botão não está no DOM quando a `play` começa — a `play` roda depois do render, não depois do fetch. Todo teste de interação que a doc induzia era racy. Virou [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 2.3 e a regra `SB-TEST-10`.

---

## O que foi encontrado e corrigido

### Código que não rodava

- Decorator do caminho Vite descartando `<Story />` (acima).
- O mesmo bloco não compilava: `Pagina` usado sem import, sem `export default meta`, `StoryObj` importado e não usado.
- `play` composta desestruturando `context` **e** os campos, enquanto o texto ao lado dizia o oposto; e `play` é opcional em `StoryObj`, então a chamada exigia `?.`.
- Dois blocos com identificador declarado duas vezes no mesmo escopo: `dadosBase` em [Storybook - Stories e Args](storybook-stories-e-args.md) e `meta` em [Storybook - Docs e Autodocs](storybook-docs-e-autodocs.md). Separados em blocos distintos.

### Exemplos que violavam regras da própria doc

- O `argTypes` de exemplo redeclarava `options` de uma union que o docgen já infere (`SB-CSF-08`) e usava `table: { disable: true }` num callback público, quando a nota acabara de explicar que isso apaga a linha da documentação e `control: false` é o correto.
- O `preview.tsx` de a11y passava `config: {}`, o que **sobrescreve o default e reativa a regra `region`** — produzindo exatamente o falso positivo que o parágrafo seguinte dizia que o default existe para evitar.
- `meta` de `packages/ui` sem `title`, contra `SB-CSF-10`, em vários exemplos.

### Regras mal formuladas

- **`SB-CORE-06`** dizia "nada roda no corpo do módulo" e era violada pelos exemplos da própria doc (`gerarLinhas(10_000)`). A justificativa real é não-determinismo, não computação. Reescrita para proibir efeito colateral e não-determinismo, permitindo cálculo puro.
- **`SB-DOC-01`** exigia a tag `autodocs` "no `meta` ou numa story", mas a configuração prescrita liga no `preview` e tags acumulam — ou seja, todo arquivo do catálogo violava a regra. Reescrita para exigir que a tag **alcance** o arquivo.
- **`SB-TEST-03`** falava de "callback observado" sem distinguir prop de import de módulo, e não havia exemplo de asserção sobre módulo mockado em lugar nenhum. Escopada para prop, com o outro caso ganhando [Storybook - Mocking](storybook-mocking.md) § 2.4.1.
- **`SB-CTX-08`** exigia cleanup de "estado fora da story", o que tornava todos os exemplos de `mocked` violadores. Escopada para estado global de ambiente.
- **`SB-CFG-06`** ("herdar a config do Vite") era **impossível de seguir** no layout que a própria doc prescreve: `apps/storybook` é um quarto pacote sem Vite config, e as stories vêm de outros dois. Ganhou a § 3.1 com a saída por config base compartilhada em `packages/config` — marcada como decisão desta doc, não da fonte.

### A § 6.2 do hub estava achatando regras distintas

A tabela de IDs canônicos tratava como apelido quatro regras que não são sinônimo:

- `SB-CTX-05` (globals não é `args`) exprime um achado que `SB-CSF-04` não exprime;
- `SB-TEST-07` carrega a exceção do `fn`, que `SB-CTX-04` não carrega;
- `SB-MOCK-04` é a metade complementar de `SB-MOCK-01`, e vive no mesmo satélite;
- `SB-CTX-06` é condicional ao framework, logo mais ampla que `SB-TS-03`.

Pior: `SB-TS-08`/`SB-RV-06` e `SB-TS-03`/`SB-RV-05` estavam como canônico/apelido, e o hub declara em outra linha que citar `SB-TS-*` num projeto `react-vite` é achado inválido — **o princípio ficava incitável nos dois caminhos**. Viraram uma tabela própria de "pares por caminho".

### Contaminação entre os dois caminhos

O selo de caminho estava nos cabeçalhos dos satélites, mas **as tabelas de decisão do hub não tinham marcação**. O leitor 4 mostrou o custo: a ponte "componente usa `Link` → use `parameters.tanstack.router`" é, no caminho dele, um no-op silencioso; e o diagnóstico da § 5.6 classificava a configuração legítima dele ("react-vite em story que usa `Link`") como *framework errado*. Marcados: § 4.4, § 5.4, § 5.6 e § 8 do hub, mais a § 4.2 de [Storybook - Configuração e Builder](storybook-configuracao-e-builder.md), que é exclusiva do caminho TanStack.

### Inconsistências factuais

- `globals` estava como nível `P S` no hub e `P C S` no satélite — o hub estava errado, e é a nota que o contrato de skill manda carregar sempre.
- Três nomes diferentes para o mesmo script do Storybook em três notas, com o `storybookScript` do addon-vitest apontando para um script inexistente. Unificados em `storybook` / `build-storybook`.
- Duas referências cruzadas de seção erradas (`§ 4` onde era `§ 5`, `§ 3` onde era `§ 2.4`).
- "Quatro princípios" numa tabela de cinco linhas; "quatro testes" quando dois estavam fora do escopo.
- "falso negativo" onde é falso **positivo**, em duas notas.
- `refs` listado como fora do mapa e dentro do mapa, na mesma seção.
- `withThemeByClassName` afirmado no hub e declarado não verificado no satélite.
- Promessas do mapa da API sem conteúdo correspondente (`typescript`, `tags` de `main.ts`, `previewHead`/`previewBody`/`managerHead`, `core`/`build`/`env`/`features`/`logLevel`). Marcadas como existentes e não cobertas.

### Lacunas preenchidas com material verificado na fonte

- Queries assíncronas `findBy…`/`findAllBy…`, com a tabela de quais aguardam.
- `delay` do MSW para produzir estado de carregando.
- `vitest run` (e não `vitest`) como forma de CI, e `playwright install` para os binários.
- `.storybook/vitest.setup.ts`: é gerado pelo comando de setup — o conteúdo não é transcrito pela fonte.
- Sequência de setup passo a passo, que não existia em lugar nenhum.
- `sb.mock` é relativo ao arquivo que chama, isto é, ao `preview`.
- `beforeEach` recebe o contexto da story — é daí que vem o `msw` de `beforeEach({ msw })`.
- Critério explícito de `satisfies` × anotação, e padronização de `Preview`.

---

## O que continua aberto

Nada aqui é preguiça: são pontos onde **a fonte não responde** e inventar seria pior que registrar.

| Pendência | Por que está aberta |
| --- | --- |
| **`mocked` reseta entre stories?** | A fonte garante reset automático só para `fn`. Se o comportamento definido com `mocked` sobre um módulo de `sb.mock` vaza para a story seguinte, não está dito. Enquanto isso, `SB-CTX-08` está escopada para não acusar os exemplos. |
| **`mocked` funciona dentro de `play`?** | Todos os exemplos da fonte usam em `beforeEach`. A § 2.4.1 de [Storybook - Mocking](storybook-mocking.md) compõe as duas coisas e está marcada como composição. |
| **`toHaveBeenCalledWith` sobre automock do `sb.mock`** | A fonte só exemplifica esse matcher sobre `fn`. |
| **Conteúdo de `.storybook/vitest.setup.ts`** | A página do addon referencia o arquivo e não o transcreve. |
| **Opções de `@storybook/react-vite`** (`strictMode`, `reactDocgen`) | A referência de `main.ts` remete à documentação do pacote no repositório. |
| **`initialEntries` aceita query string?** | A doc de history types do TanStack só mostra path puro. A § 4.2 de [Storybook - React Vite](storybook-react-vite.md) depende disso e diz que depende. |
| **`validateSearch` sob `react-vite`** | Não há `routeOverrides` e não há substituto: o schema vive na definição da rota. Na árvore mínima você não o declara; na árvore real, ele manda. |
| **Navegação numa `play` sob `react-vite`** | `SB-RV-03` manda criar o router por render, o que zera o estado de navegação — justamente o que uma `play` que clica num `<Link>` precisaria preservar. As duas pontas se contradizem e a doc não tem saída verificada. |
| **Sintaxe de handlers MSW em nível de `meta` e projeto** | A fonte afirma que é possível e só exemplifica o nível de story. |
| **Extensão `.ts` no specifier de `sb.mock`** | `SB-MOCK-02` exige extensão; num projeto TS isso requer configuração de compilador que a fonte não nomeia. |
| **Componentes genéricos** (`DataTable<T>`) | O padrão `satisfies Meta<typeof C>` + `StoryObj<typeof meta>` não foi verificado contra componente genérico, que é onde ele costuma atritar. |
| **Custo de a11y em story de estresse** | Rodar axe sobre 10.000 linhas com `test: 'error'` não é discutido pela fonte. |
| **A rampa de adoção do `a11y.test: 'error'`** | Ligar num design system existente deixa o CI vermelho no dia 1, e a única válvula (`'todo'`) produz zero saída em CI. As duas pontas estão documentadas e a ponte entre elas não. |
| **`SB-TS-08` perde o detector sob `tanstack-react`** | Sob `react-vite`, o componente de `packages/ui` acoplado a rota **falha**, e a falha é o sinal. Sob `tanstack-react` o framework embrulha tudo e o sinal some. A regra continua válida; o mecanismo de detecção, não. |
| **CI real** — *parcialmente resolvida em 2026-08-21* | A **tag existe**: `mcr.microsoft.com/playwright:v1.58.2-noble`, com Node 22.12.0, e o workflow completo está em [Storybook - Cobertura e CI](storybook-cobertura-e-ci.md) § 3.1. O que **continua aberto** é o Bun: a imagem traz Node, e o `storybookScript` de um monorepo Bun invoca `bun run`. A saída registrada é não usar `storybookScript` em CI e apontar `storybookUrl` para o Storybook publicado (`SB-TEST-17`). |
| **Formas `bunx`/`bun add` dos comandos de setup** | Todos os comandos verificados são `npm`/`npx`. O equivalente Bun é inferência. |

---

## Invariantes que valem para quem editar

1. **O satélite é canônico.** A § 6.1 do hub reproduz o texto do satélite **verbatim**. Conferido por script; parafrasear ali é o defeito que a estrutura de backend já registrou.
2. **Toda contagem escrita à mão precisa ser conferida.** Esta revisão achou duas erradas, e as estruturas anteriores acharam outras duas. Numeral em prosa é a coisa que mais envelhece.
3. **Todo exemplo é testado contra as regras da própria doc.** Três dos achados mais graves foram exemplos violando regras que a mesma nota declara.
4. **Marcação de caminho vale nas tabelas, não só nos cabeçalhos.** Foi ali que a contaminação passou.
5. **Regra marcada com †** é decisão desta doc, não da fonte — e é discutível sem ir à fonte. Sem marca, não.
6. **Reexecutar o teste é mais barato que confiar na releitura.** Cinco leitores acharam, juntos, defeitos que nenhuma revisão minha tinha achado — inclusive um exemplo canônico que não funcionava.

---

## Relacionados

- [Storybook](storybook.md) — o hub da estrutura
- [Storybook - React Vite](storybook-react-vite.md) · [Storybook - TanStack React](storybook-tanstack-react.md) — os dois caminhos
- [Backend - Pendências de revisão](backend-pendencias-de-revisao.md) — o registro equivalente da estrutura de backend
