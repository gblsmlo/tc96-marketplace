---
nome: react-structure
descricao: Decidir onde o código React mora e quem pode importar quem numa arquitetura feature-based, citando IDs `REACT-ARCH-*`, com oito sondas executáveis de import, varredura na ordem que falha mais e migração por etapas — use quando a tarefa for criar uma feature, colocar um arquivo novo, revisar os imports de um PR, extrair código para o compartilhado, ou configurar e migrar a estrutura de um repositório. Não use para o interior do componente — escrever é react-developer, revisar é react-review — e num PR o achado de estrutura vem primeiro, porque mover um arquivo pode apagar o achado de interior.
tipo: skill
familia: react
fonte: "[Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md)"
docs:
  - /reactjs/react.dev
tags:
  - skill
  - react
  - architecture
---

# react-structure

> **Fonte desta skill:** [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) (estrutura, regras e enforcement), com [Architecture in React](../../../knowledge-base/pages/architecture-in-react.md) como roteador dos demais eixos de decisão.
> Esta skill **não contém** o texto das regras nem a configuração do Biome — ela diz o que carregar, em que ordem decidir e como reportar. Regra reescrita aqui viraria cópia desatualizada.
>
> **Resolvendo os links:** a nota-fonte é `Pages/Feature-Based Architecture.md`. Não a confunda com `Weblink/Feature-Based Architecture in React.md`, que é o artigo externo de origem e **não** é normativo aqui.
> **Superfície de API:** resolva pelo Context7 — `/reactjs/react.dev`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10, que por sua vez implementa [React.js](../../../knowledge-base/docs/react-js.md) § 7.

---

## Quando usar

Quando a pergunta for **onde o código mora ou quem importa quem**: criar feature, colocar arquivo novo, revisar imports de um PR, extrair código compartilhado, configurar ou migrar a estrutura de um repositório.

| A pergunta é… | Vá para |
| --- | --- |
| onde este arquivo mora? quem pode importar isto? | **esta skill** |
| como escrever este componente ou Hook? | `react-developer` |
| este código React existente está correto? | `react-review` |
| formulário com validação, campo condicional, arrays | `react-hook-form` |
| como definir esta rota, navegar, carregar dados? | `tanstack-router` |

As skills se compõem, quase sempre em par:

- **criar feature** — esta decide a estrutura, `react-developer` escreve cada componente dentro dela;
- **extrair para o compartilhado** — esta decide o destino (`REACT-ARCH-08`), `react-developer` escreve o módulo em `features/core/`;
- **revisar um PR** — esta cobre a fronteira (imports, camadas, barrel), `react-review` cobre o interior. Um relatório completo roda as duas, e **o achado de estrutura vem primeiro**: mover um arquivo pode apagar o achado de interior.

---

## Carregamento mínimo

Adaptado de [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10 — a linha `SOB DEMANDA` é acréscimo desta skill:

```
SEMPRE: § 2 (camadas e direção de dependência)
 § 4 (regras REACT-ARCH-* e severidade)

AO CRIAR FEATURE: § 3 (anatomia) + § 5 (exemplos no stack)
AO MOVER CÓDIGO: § 8 (migração) + REACT-ARCH-08
AO REVISAR IMPORT: § 6 (antipadrões) + § 7 (o que o lint cobre)
AO CONFIGURAR REPO: § 7 (biome.json, aliases) + § 8

SOB DEMANDA: Architecture in React § 2, quando a decisão não for
 de estrutura física e precisar de outro eixo

NUNCA: inventar camada nova sem registrar na nota-fonte
```

Referências desta skill — abra só a que o passo pedir:

| Arquivo | Para quê |
| --- | --- |
| `references/arvore-de-colocacao.md` | as cinco perguntas, a árvore, e importar × duplicar × extrair |
| `references/varredura-de-imports.md` | a ordem da varredura, o que a sonda não pega, formato e corte |
| `references/mapa-de-ids.md` | ID → severidade → **quem faz valer** (lint ou revisão) → seção |
| `references/exemplo-revisao-de-estrutura.md` | revisão inteira de um PR, das sondas ao fechamento |
| `scripts/sondas-imports.sh` | oito sondas de fronteira, na ordem que falha mais |
| `scripts/gerar-mapa-de-ids.sh` | regenera `mapa-de-ids.md` a partir da nota-fonte |

Antes de decidir que algo é overkill, confira § 9 ("Quando não usar"). App de domínio único não precisa desta estrutura, e impor a fatia vertical nele é o antipadrão desta skill.

---

## Roteamento por tarefa

| Tarefa | Passos |
| --- | --- |
| Criar feature nova | 1 → 2 → 5 |
| Colocar um arquivo novo | 2 → 5 |
| Revisar estrutura e imports (PR, pasta, repo) | 3 → 4 |
| Extrair código compartilhado | 2 → 5 |
| Configurar repo do zero, ou migrar | 6 |

Achado de **colocação** ("isto não deveria estar aqui") sai na varredura do Passo 3 — não é preciso rodar o Passo 2 para auditar. O Passo 2 decide onde colocar; não audita o que já está colocado.

---

## Passo 1 — As cinco perguntas antes de criar uma feature

Ordem normativa ([Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10). Responda **por escrito**, uma frase cada, antes do primeiro `mkdir`: é um domínio? o domínio já existe? o dado é remoto? isto é público? quem vai importar isto?

Tabela completa, com o que fazer quando cada resposta trava, e a exceção da "capacidade que nasce compartilhada": `references/arvore-de-colocacao.md`.

Se a pergunta 1 não tiver resposta clara, **pare**: o problema não é de estrutura, é que a capacidade ainda não foi definida. Estruturar antes disso produz a fronteira errada (§ 9).

---

## Passo 2 — Árvore de colocação

Percorra `references/arvore-de-colocacao.md`. Duas perguntas decidem tudo: **conhece vocabulário de produto?** e, se sim, **quantas capacidades consomem?**

O erro mais comum não é de árvore, é de vocabulário: `REACT-ARCH-08` responde *quando criar módulo compartilhado*, **não** *se posso importar*. Importar, duplicar e extrair são três movimentos diferentes, e a tabela de § 4 desempata.

---

## Passo 3 — Varrer imports, na ordem que falha mais

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-structure/scripts/sondas-imports.sh src
```

A **sonda 0 é de enforcement e roda primeiro**: sem `biome.json` e sem as regras de § 7, todo achado abaixo se repete no próximo PR — e isso é o **primeiro achado do relatório**, não uma nota de rodapé.

Depois, na ordem: direção invertida (`REACT-ARCH-06`, `-07`) → deep import (`-05`) → alias próprio (`-04`) → barrel (`-02`, `-03`) → rota inchada (`-09`) → colocação (`-01`, `-08`) → convenção (`-11`, `-12`). Detalhe, falsos positivos e o que a sonda **não** pega: `references/varredura-de-imports.md`.

Pare de detalhar um arquivo quando um achado invalidar o seguinte: se a camada está errada, não revise o import dela.

---

## Passo 4 — Reportar

Severidade sai de `references/mapa-de-ids.md` — coluna normativa de § 4, **não reclassifique**. Direção de dependência ganha de estética, sempre (§ 10, invariante 2).

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver Feature-Based Architecture § <seção>.
```

**Achado sem ID é opinião.** Existe ID em § 4 → achado. É antipadrão de § 6 sem ID → cite a seção. Nem uma coisa nem outra → "Sugestões (sem regra)", separado. **Nunca invente** um `REACT-ARCH-*`.

Ao fechar, **declare o que o lint já cobriria**. A coluna *Faz valer* do mapa diz quais IDs dependem de revisão humana: são esses que voltam no PR seguinte.

---

## Passo 5 — Autoverificar antes de entregar

Rode a checklist de [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) § 10 na íntegra: barrel, direção de dependência, invalidação de `queryKey`, teste colocalizado, convenção de nome. **Ela não verifica alias** — isso é do Passo 6; se você mexeu em `paths`, confira os três arquivos à mão.

Três perguntas de fechamento:

1. Alguma feature nova nasceu de uma **tela** em vez de uma **capacidade**?
2. Algo foi extraído para o compartilhado com menos de três consumidores?
3. Alguma regra que reportei é verificável pelo lint e simplesmente não estava ligada?

Se a 3 for "sim", o achado real é a configuração ausente, não a violação individual.

`pnpm biome check src` passa ou o trabalho não terminou. **Se o projeto não tiver `biome.json` ou dependências instaladas**, o comando não é executável — declare isso, e trate a configuração ausente como o primeiro achado. Item não verificável é reportado como não verificado, nunca como aprovado.

---

## Passo 6 — Configurar ou migrar um repositório

Não reorganize tudo num PR. A ordem de § 8 mantém o app verde a cada passo: aliases → extrair o genuinamente genérico → migrar uma feature inteira → barrels → `noImportCycles` → `noRestrictedImports` por camada → `features/core/` só quando `REACT-ARCH-08` disparar.

Três pontos em que a migração costuma quebrar (§ 2 e § 7):

- os aliases precisam existir nos **três** arquivos — `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`. Divergência aparece como "funciona no build, quebra no teste" (a sonda 0 mede isso);
- camada endereçada pelo barrel precisa da entrada **sem** curinga no `paths`, senão o import nu não resolve;
- `overrides` do Biome é **first-match-wins**: regra de nível superior não se soma ao override — é substituída.

Um PR por passo. Se uma regra do Biome não está na tabela de § 7, ela não foi verificada: consulte `biomejs.dev` e atualize a **nota-fonte**, não esta skill (§ 10, invariantes 4 e 5).

---

## Vizinhas — quando a decisão sai da estrutura

| A camada é… | Skill |
| --- | --- |
| interior do componente: escrever · revisar | `react-developer` · `react-review` |
| formulário | `react-hook-form` |
| rota, navegação, search params, loader | `tanstack-router` |
| dado remoto, `queryKey`, invalidação | `tanstack-query` |
| story e teste de componente | `storybook-story` · `storybook-test` |
| **nível** do teste (unidade × integração × e2e) | `test-design` |
| unidade e integração em `bun test` · e2e | `bun-test-build` · `playwright-build` |
| rota e schema de API · persistência · contrato HTTP | `elysia-build` · `drizzle-review` · `http-contract` |
| workspace, alias de monorepo, lockfile | `bun-workspace` |

Onde a `queryKey` mora e como se invalida é fronteira compartilhada com `tanstack-query`: a **colocação** do arquivo `api/` é desta skill; a **política de frescor** é de lá.

---

## Exemplo

PR que extrai formatação para `libs/` e cria uma feature "cobranças". As sondas apontam seis candidatos; a **leitura** mostra que a feature nasceu de uma tela, não de uma capacidade (`REACT-ARCH-01`) — e isso apaga dois achados internos que seriam trabalho jogado fora. O mesmo arquivo sai com `REACT-ARCH-06` **e** `REACT-ARCH-08`, que são defeitos diferentes. A ausência de `biome.json` fecha o relatório como item de maior retorno.

Relatório completo: `references/exemplo-revisao-de-estrutura.md`.

---

## Relacionados

- [Feature-Based Architecture](../../../knowledge-base/pages/feature-based-architecture.md) — fonte desta skill: estrutura, regras `REACT-ARCH-*`, enforcement
- [Architecture in React](../../../knowledge-base/pages/architecture-in-react.md) — roteador dos demais eixos de decisão arquitetural
- `react-developer` — escrever o componente que mora na estrutura decidida aqui
- `react-review` — revisar o interior; esta skill revisa a fronteira
- [React.js](../../../knowledge-base/docs/react-js.md) § 7 — o contrato de skill original
