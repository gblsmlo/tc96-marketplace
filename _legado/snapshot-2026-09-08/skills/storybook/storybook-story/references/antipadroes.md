# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Story como demo, sem estado nomeado | `SB-CSF-04` | [[Storybook - Stories e Args]] |
| Estado embutido em `render` | `SB-CSF-04` | [[Storybook - Stories e Args]] |
| Uma story por combinação de props | § 7.2 do satélite | [[Storybook - Stories e Args]] |
| `useState` no `render` para simular controle | `SB-CSF-07` | [[Storybook - Stories e Args]] |
| Mutar `Story.args` para compor variação | `SB-CSF-05` | [[Storybook - Stories e Args]] |
| `title` refletindo a árvore de pastas | `SB-CSF-03` | [[Storybook - Stories e Args]] |
| `title` por template string ou valor computado | `SB-CSF-03` | [[Storybook - Stories e Args]] |
| `argTypes` copiando o tipo do componente | `SB-CSF-08` | [[Storybook - Stories e Args]] |
| Anotação `Meta<…>` em vez de `satisfies` | `SB-CSF-02` | [[Storybook - Stories e Args]] |
| Valor não serializável em controle, sem `mapping` | `SB-CSF-06` | [[Storybook - Stories e Args]] |
| Helper exportado do arquivo de stories | `SB-CSF-09` | [[Storybook - Stories e Args]] |
| Efeito colateral no corpo do módulo | `SB-CORE-06` | [[Storybook]] |
| Story que depende de outra | `SB-CORE-05` | [[Storybook]] |
| `Meta`/`StoryObj` do renderer | `SB-CORE-02` | [[Storybook]] |
| Documentar em `argTypes` o que o JSDoc já diz | `SB-DOC-02` | [[Storybook - Docs e Autodocs]] |
| Story que é um artigo de prosa | `SB-DOC-03` | [[Storybook - Docs e Autodocs]] |
| Ligar autodocs arquivo a arquivo | `SB-DOC-01` | [[Storybook - Docs e Autodocs]] |
| Página de docs bonita com controles vazios | `SB-CSF-04` | [[Storybook - Docs e Autodocs]] |
| `subcomponents` usado como pasta | § 6.5 do satélite | [[Storybook - Docs e Autodocs]] |
| `globals` onde o correto era `args` | `SB-CTX-05` | [[Storybook - Decorators e Contexto]] |
| Provider repetido por arquivo de story | `SB-CTX-03` | [[Storybook - Decorators e Contexto]] |
| Componente de `packages/ui` que exige rota | `SB-TS-08` / `SB-RV-06` | a nota do caminho |

