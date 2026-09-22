---
aliases:
 - FBA
 - Arquitetura baseada em features
tags:
 - frontend
 - react
 - architecture
---
# Feature-Based Architecture

> Nota filha de [Architecture in React](architecture-in-react.md). Aqui se decide **onde o código mora e quem pode importar quem**.
> A ideia conceitual em uma frase está em;
> esta nota transforma a ideia em estrutura, regras citáveis e verificação automatizada.

Esta nota é **condução**, não resumo. Ela existe para dois leitores: eu, decidindo onde colocar um
arquivo, e um agente, criando ou revisando código. A seção 10 é o contrato que um agente carrega.

---

## 1. O problema: agrupar por papel técnico

A estrutura padrão de quase todo projeto React organiza por **o que o arquivo é**:

```
src/
├── components/
├── hooks/
├── utils/
├── pages/
└── store/
```

Funciona enquanto o app tem uma capacidade. Depois disso, cada mudança de produto vira uma varredura:
alterar "faturas" toca `components/fatura-card.tsx`, `hooks/use-faturas.ts`, `store/faturas-slice.ts`,
`utils/formatar-vencimento.ts` e `pages/faturas.tsx` — cinco pastas, nenhuma delas chamada faturas.

O custo real não é estético. É que **a fronteira do domínio deixa de existir no código**:

- nada impede `components/fatura-card.tsx` de importar `store/usuario-slice.ts`;
- a pasta `utils/` acumula regra de negócio de todos os domínios;
- ninguém sabe o que pode ser deletado quando a capacidade morre;
- onboarding exige entender o app inteiro antes de mudar uma tela.

A causa é um desalinhamento: **arquivos são agrupados por tipo, mas mudam por domínio.** Coisas que
mudam pela mesma razão devem morar juntas — é coesão, aplicada a diretório em vez de classe.
Ver e.

---

## 2. O princípio e as camadas

**Agrupe por domínio, não por papel técnico.** Tudo que pertence a uma capacidade — UI, hooks,
chamadas de API, schemas, estado, tipos — mora em uma fatia vertical só.

A estrutura adotada no vault:

```
src/
├── routes/ # árvore de rotas (TanStack Router, file-based). Compõe, não implementa.
├── features/ # domínios do produto. Cada um é uma fatia vertical fechada.
│ ├── auth/
│ └── faturas/
├── components/ # UI sem domínio
│ ├── ui/ # primitivos: button, input, dialog
│ └── layout/ # header, sidebar, footer
├── hooks/ # hooks genéricos: use-debounce, use-local-storage
│ └── index.ts
├── libs/ # infraestrutura: http-client, formatadores, config
│ └── index.ts
└── types/ # contratos genéricos: ApiResponse, PaginationParams
 └── index.ts
```

Cada camada consumida por alias tem seu próprio barrel — é ele que o alias endereça. Sem
`src/libs/index.ts`, o import `from '@libs'` não resolve. Vale para `@hooks`, `@libs` e `@app-types`;
`@features/*` e `@components/*` endereçam o barrel da subpasta (`@features/faturas`, `@components/ui`).

Aliases correspondentes em `tsconfig.json`:

```json
{
 "compilerOptions": {
 "paths": {
 "@features/*": ["./src/features/*"],
 "@components/*": ["./src/components/*"],
 "@routes/*": ["./src/routes/*"],

 "@hooks": ["./src/hooks"],
 "@libs": ["./src/libs"],
 "@app-types": ["./src/types"]
 }
 }
}
```

> **Sem `baseUrl`.** O TypeScript 7 **removeu** essa opção — `error TS5102: Option 'baseUrl' has been
> removed`. Não é depreciação, é erro de configuração: o projeto não compila. Isso não quebra nada
> aqui, porque um `paths` sem `baseUrl` resolve relativo à própria localização do `tsconfig.json`, e
> as entradas acima já são escritas assim (`./src/...`). Verificado com `tsc` 7.0.2. Se você mantém
> `baseUrl` num projeto antigo, remova; se precisa do comportamento de raiz implícita que ele dava,
> a substituição indicada pela própria mensagem é `"paths": { "*": ["./*"] }`.

> **Por que `@app-types` e não `@types`.** O prefixo `@types/` é o escopo do npm para pacotes de
> declaração (`@types/node`, `@types/react`). `paths` do TypeScript resolve **antes** de
> `node_modules`, então um alias `@types/*` entra em rota de colisão com o ecossistema. Use um
> prefixo que não exista no registro.

> **Por que umas entradas têm `/*` e outras não.** Um mapeamento `"@libs/*"` só casa com
> especificadores que tenham algo depois da barra — `import { httpClient } from '@libs'` **não
> resolve**. Camadas que são consumidas apenas pelo barrel (`@hooks`, `@libs`, `@app-types`) recebem
> a entrada sem curinga; camadas em que o subcaminho é o endereço legítimo (`@features/faturas`,
> `@components/ui`) recebem a entrada com `/*`. Declarar as duas formas para a mesma camada reabre a
> porta do deep import.

Os mesmos aliases precisam existir em `vite.config.ts` e `vitest.config.ts`. Três arquivos que
precisam concordar é uma fonte clássica de "funciona no build, quebra no teste".

### Direção da dependência

Entre camadas, só existe uma direção legal:

```
routes/ → features/ → components/ · hooks/ · libs/ · types/
 ╰─ ─ ─ ─╯
 aresta lateral: feature → feature,
 permitida só pelo barrel (ver § 4)
```

Nunca de volta. `components/ui/button.tsx` não sabe que faturas existem. `libs/http-client.ts` não
sabe que autenticação existe — ele recebe um interceptador, não o importa. E nenhuma feature importa
de `routes/`: a rota conhece a feature, não o contrário.

A aresta lateral entre features é a única exceção, e é deliberada — ver § 4, "Import entre features
irmãs". Ela não inverte a direção; anda de lado dentro da mesma camada.

Essa é a regra que produz todas as outras. Uma seta invertida é um domínio vazando para dentro do
genérico, e o genérico deixa de ser reutilizável no momento em que isso acontece.

---

## 3. Anatomia de uma feature

O vocabulário completo de uma feature **madura** — não o que se cria no dia um:

```
features/faturas/
├── api/ # queryOptions, mutations, cliente HTTP do domínio
├── components/ # UI do domínio, props explícitas
│ ├── fatura-card.tsx
│ └── fatura-card.test.tsx # teste colocalizado, ao lado do que ele testa
├── hooks/ # lógica de interação da feature
├── stores/ # estado de cliente (quando existir); ver nota abaixo
├── types/ # schemas Zod e tipos inferidos
├── utils/ # funções puras do domínio
└── index.ts # ← a API pública. O resto é privado.
```

Nem toda feature precisa das sete pastas. Uma feature nasce com **`index.ts` e mais nada**; cada
subpasta abre no mesmo commit do primeiro arquivo que pertence a ela — `mkdir` e arquivo juntos.
`types/fatura-schema.ts` pode nascer antes de qualquer componente, porque schema não é componente; a
ordem não é fixa, o gatilho é sempre o arquivo.

Criar as sete de uma vez custa duas coisas: pasta vazia anuncia estrutura que não existe, e um
esqueleto pronto empurra quem chega depois a preencher os buracos só porque estão lá. O scaffold do
vault segue essa regra — ver `Prompts/Frontend/scaffold-phase-05-fba-directory-structure.md`.

Teste fica **colocalizado**, ao lado do arquivo que testa, e nunca entra no barrel. Isso mantém a
regra "o que muda junto mora junto" válida também para a verificação.
Ver.

### O barrel é o contrato

`index.ts` não é conveniência de import. É **a declaração de superfície pública** da feature:

```typescript
// src/features/faturas/index.ts
export { FaturasPainel } from './components/faturas-painel'
export { FaturaForm } from './components/fatura-form'
export { faturasQueryOptions } from './api/faturas-queries'
export { useMarcarComoPaga } from './api/faturas-mutations'
export type { Fatura, FaturaFiltros } from './types/fatura-schema'
```

Repare no que **não** está exportado: `FaturaCard`, `faturas-client.ts`, os utilitários. `FaturaCard`
é detalhe de como `FaturasPainel` desenha a lista — se ele vazar, o consumidor passa a depender da
decoração interna da feature e a lista deixa de poder mudar sozinha.

O que não está aqui não existe para o resto do app. Isso dá três coisas que a pasta sozinha não dá:

1. **Refatoração barata** — mover `fatura-card.tsx` para outro subdiretório não quebra consumidor.
2. **Revisão focada** — mudança no barrel é mudança de contrato, e aparece no diff como tal.
3. **Deleção segura** — a superfície é finita e auditável.

O barrel contém **apenas reexports**. Nenhuma lógica, nenhum side effect, nenhuma constante. Um
`console.log` ou uma inicialização no barrel roda para todo mundo que tocar a feature.

### `stores/` e a questão do estado

A maior parte do que projetos chamam de "estado global" é cache de servidor mal nomeado. Antes de
criar `stores/`, verifique se o dado não é remoto — se for, ele pertence a `api/` como
`queryOptions`. Ver e.

Quando `stores/` for de fato necessário — estado de cliente compartilhado entre telas, como filtros
de uma jornada ou passo de um wizard — a escolha da ferramenta não é decidida aqui. Ver. Esta nota decide **onde o arquivo mora**, não com o que ele é
escrito.

---

## 4. Regras normativas (`REACT-ARCH-*`)

IDs citáveis, no mesmo formato de [React - Rules of React](../docs/react-rules-of-react.md). Um achado de revisão cita o ID, o
arquivo e a linha — não parafraseia.

| ID | Regra | Severidade | Verificação |
| --- | --- | --- | --- |
| `REACT-ARCH-01` | Agrupe por domínio, não por papel técnico. | crítica | revisão |
| `REACT-ARCH-02` | Toda feature expõe `index.ts`. Nada fora dele é público. | crítica | revisão |
| `REACT-ARCH-03` | Barrel contém apenas reexports — sem lógica, sem side effect. | crítica | revisão |
| `REACT-ARCH-04` | Dentro da feature, import **relativo**. Nunca o próprio alias, nunca o próprio barrel. | crítica | `noImportCycles` |
| `REACT-ARCH-05` | Entre módulos com barrel — outra feature, `@components/ui`, `@components/layout` — importe pelo **barrel**. Deep import é proibido. | crítica | `noRestrictedImports` |
| `REACT-ARCH-06` | `components/`, `hooks/`, `libs/`, `types/` não conhecem domínio. | crítica | `noRestrictedImports` |
| `REACT-ARCH-07` | Dependência flui `routes → features → genérico`. Nunca de volta. | crítica | `noRestrictedImports` parcial |
| `REACT-ARCH-08` | Extração para o genérico exige o **terceiro consumidor**. | alta | revisão |
| `REACT-ARCH-09` | A rota compõe e carrega. A jornada é da feature. | alta | revisão (ver teste de bancada) |
| `REACT-ARCH-10` | Ciclo de import é erro, não aviso. | alta | `noImportCycles` |
| `REACT-ARCH-11` | Tipos saem do barrel com `export type`. | média | revisão |
| `REACT-ARCH-12` | kebab-case em todo arquivo e diretório. | média | revisão |

### `REACT-ARCH-04` — por que o ciclo detecta

Importar o próprio barrel de dentro da feature parece inofensivo, mas cria um ciclo real:

```
features/faturas/index.ts
 → features/faturas/components/fatura-card.tsx
 → @features/faturas (= features/faturas/index.ts)
```

Por isso a regra não depende de convenção: `noImportCycles` do Biome falha o build. O sintoma em
runtime depende do sistema de módulos — em ESM nativo (o que o Vite serve em dev), usar um `const` ou
`class` antes da inicialização dá `ReferenceError` por temporal dead zone; em CJS ou saída
transpilada, dá um export `undefined` silencioso. Os dois são sensíveis à ordem de avaliação e caros
de diagnosticar. Import relativo dentro da feature elimina a classe inteira de bug.

**Cobertura parcial.** O ciclo só se fecha quando o arquivo que importa o próprio alias é, ele mesmo,
alcançável a partir do barrel. Um arquivo interno que ninguém reexporta pode importar
`@features/faturas` sem formar ciclo — viola `REACT-ARCH-04` e passa no lint. Esse resíduo fica em
revisão; na prática ele é raro, porque arquivo interno que ninguém alcança costuma ser código morto.

### `REACT-ARCH-08` — a regra do terceiro consumidor

Dois consumidores são coincidência; três são um padrão. Extrair no segundo produz abstração com
contrato inventado, que depois precisa de flags para servir aos dois casos. Deixe a duplicação viver
até o terceiro caso revelar a forma real. Esta é a mesma disciplina do Zettel aplicada a extração.

### Import entre features irmãs — a decisão adotada

> **O dono desta regra é `MONO-12`**, em `Monorepo com Bun - estrutura e tooling` § 6: a aresta
> lateral é o mesmo invariante para package e para feature, e é lá que ela tem ID, severidade e
> sonda executável. Esta seção **aplica** o invariante ao caso React. `REACT-ARCH-05` é o *como
> atravessar* uma aresta que existe, e `REACT-ARCH-08` é o *quando extrair* — nenhum dos dois é a
> permissão em si, e citá-los como se fossem foi o defeito que motivou `MONO-12`.

O artigo de referência **proíbe** import irmã ↔ irmã e roteia todo reuso por `features/core/`.
O vault adota a variante **progressiva**:

- irmã pode importar irmã (`MONO-12`), **desde que pelo barrel** (`REACT-ARCH-05`);
- deep import continua proibido;
- quando um terceiro consumidor aparecer (`REACT-ARCH-08`), extraia para `features/core/<capacidade>/`
 e corte as arestas diretas.

**Importar, duplicar e extrair são três movimentos diferentes.** Confundi-los é o erro mais comum ao
ler estas regras juntas:

| Consumidores | Movimento | Regra |
| --- | --- | --- |
| 1 | fica onde está, privado | `REACT-ARCH-02` |
| 2 | a segunda **importa o barrel** da primeira — não duplica, não extrai | `REACT-ARCH-05` |
| 3 | extrai para `features/core/<capacidade>/` e corta as arestas | `REACT-ARCH-08` |

`REACT-ARCH-08` responde *"quando criar um módulo compartilhado"*, não *"posso importar"*. Ele nunca
recomenda copiar código entre features — a duplicação que ele tolera é a que já existe por acidente,
não uma que você cria de propósito para evitar um import.

**Capacidade que nasce compartilhada.** A regra fala em *extrair*, e portanto pressupõe duplicação
já existente. Quando a especificação nomeia três consumidores antes da primeira linha de código —
"a moeda escolhida vale para faturas, contratos e o perfil" —, o terceiro consumidor não é uma
previsão, é um requisito. Crie direto em `features/core/<capacidade>/`. O que `REACT-ARCH-08` proíbe
é **presumir** o terceiro consumidor, não **ler** três na especificação.

**Antes disso, pergunte se é domínio.** Um componente que não conhece vocabulário de nenhuma
capacidade — só recebe `variant` e `children` — nunca entra nessa tabela: ele é `@components/ui`
desde o primeiro consumidor. `features/core/` é para capacidade compartilhada (permissões, status de
assinatura), não para UI genérica. O teste: se o componente precisa saber o que é uma fatura para
renderizar corretamente, é domínio.

A razão: `features/core/` sem consumidores reais vira depósito. O modelo estrito paga o custo de uma
camada extra desde o dia um para prevenir um acoplamento que o barrel já mantém visível e barato de
desfazer. A troca é consciente e tem preço: **um grafo de features irmãs pode virar emaranhado sem
ninguém perceber.** O sinal de alerta é uma feature aparecendo em três ou mais barrels alheios — nesse
ponto `features/core/` deixou de ser opcional.

Esse sinal deixou de ser intenção: a sonda de fan-in lateral de
`Monorepo com Bun - estrutura e tooling` § 7 o conta, e três ou mais é achado de `MONO-12`. Até
que ela existisse, a permissão desta seção era prosa sem portão — `MONO-11` contra esta nota.

### `REACT-ARCH-09` — teste de bancada

"Compor" e "implementar" são vagos o bastante para dois revisores discordarem sem meio de arbitrar.
O critério objetivo para um arquivo em `src/routes/`:

- não declara `useState`, `useReducer` nem `useEffect`;
- não importa nada de `@components/` — quem monta UI é a feature;
- só importa de `@features/*` e do próprio router;
- o corpo cabe em uma tela sem rolagem.

Um arquivo de rota que falha em qualquer um desses pontos absorveu jornada que pertence à feature.

**Exceção: o shell.** A rota raiz (`__root.tsx`) e os layouts persistentes não são rotas de jornada —
são o esqueleto que sobrevive entre navegações. O teste acima não se aplica a eles: o shell **precisa**
importar `@components/layout`, e é o único lugar em `routes/` que pode. O que continua valendo é o
resto: o shell monta, não implementa; nada de estado de domínio nem de lógica de capacidade nele.

### Camada genérica que precisa exibir domínio

O caso concreto: o cabeçalho é genérico (`@components/layout`), mas precisa mostrar um seletor de
moeda, que é domínio. `REACT-ARCH-06` proíbe o cabeçalho de importar a feature — e a proibição está
certa, porque um `Header` que conhece moedas deixa de servir a qualquer outro app.

A saída é **inversão por slot**, e é sempre a mesma:

```tsx
// src/components/layout/header.tsx — genérico, não sabe o que vai receber
export function Header({ acoes }: { acoes?: ReactNode }) {
 return <header><Logo />{acoes}</header>
}

// src/routes/__root.tsx — o shell compõe as duas camadas
import { Header } from '@components/layout'
import { SeletorMoeda } from '@features/core/moedas'

export const Route = createRootRoute({
 component: => <><Header acoes={<SeletorMoeda />} /><Outlet /></>,
})
```

O genérico **recebe** domínio, nunca o busca. E quem tem licença para importar as duas camadas ao
mesmo tempo é o shell — pela exceção acima. Ver.

---

## 5. Exemplos no stack real

Stack: Vite/TanStack Start · TanStack Router · TanStack Query · Zod · React Hook Form · Biome · pnpm.

### 5.1 O contrato nasce do schema

```typescript
// src/features/faturas/types/fatura-schema.ts
import { z } from 'zod'

export const faturaSchema = z.object({
 id: z.string.uuid,
 descricao: z.string.min(1),
 valorCentavos: z.number.int.positive,
 vencimento: z.coerce.date,
 status: z.enum(['aberta', 'paga', 'vencida']),
})

export const faturaListaSchema = z.array(faturaSchema)

export const faturaFiltrosSchema = z.object({
 status: faturaSchema.shape.status.optional,
 busca: z.string.optional,
})

export type Fatura = z.infer<typeof faturaSchema>
export type FaturaFiltros = z.infer<typeof faturaFiltrosSchema>
```

Todo tipo é **derivado** de um schema, não declarado ao lado dele — inclusive `FaturaFiltros`, que é
entrada e não resposta. Um único lugar define forma e validação, então não existe o estado em que o
tipo diz uma coisa e o runtime aceita outra. `faturaSchema.shape.status` reaproveita o enum em vez de
redigitá-lo: se um status novo aparecer, o filtro acompanha sozinho.
Ver e.

### 5.2 A fronteira HTTP valida

```typescript
// src/features/faturas/api/faturas-client.ts
import { httpClient } from '@libs'
import {
 faturaSchema,
 faturaListaSchema,
 faturaFiltrosSchema,
 type FaturaFiltros,
} from '../types/fatura-schema'

export async function listarFaturas(filtros: FaturaFiltros) {
 const resposta = await httpClient.get('/faturas', {
 params: faturaFiltrosSchema.parse(filtros),
 })
 return faturaListaSchema.parse(resposta.data)
}

export async function marcarFaturaComoPaga(id: string) {
 const resposta = await httpClient.post(`/faturas/${id}/pagar`)
 return faturaSchema.parse(resposta.data)
}
```

`httpClient` vem de `@libs` — infraestrutura genérica, sem domínio (`REACT-ARCH-06`). O schema é
importado por caminho relativo, porque é da própria feature (`REACT-ARCH-04`).

### 5.3 Dado remoto é `queryOptions`, não estado

```typescript
// src/features/faturas/api/faturas-queries.ts
import { queryOptions } from '@tanstack/react-query'
import { listarFaturas } from './faturas-client'
import type { FaturaFiltros } from '../types/fatura-schema'

export function faturasQueryOptions(filtros: FaturaFiltros = {}) {
 return queryOptions({
 queryKey: ['faturas', 'lista', filtros],
 queryFn: => listarFaturas(filtros),
 staleTime: 30_000,
 })
}
```

`queryOptions` é o formato que serve rota e componente com a mesma definição — o loader pré-carrega e
o componente consome a mesma chave, sem duplicar a política de frescor.
Ver.

A mutation mora ao lado, e **a invalidação é parte dela**:

```typescript
// src/features/faturas/api/faturas-mutations.ts
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { marcarFaturaComoPaga } from './faturas-client'

export function useMarcarComoPaga {
 const queryClient = useQueryClient

 return useMutation({
 mutationFn: marcarFaturaComoPaga,
 onSuccess: => {
 queryClient.invalidateQueries({ queryKey: ['faturas'] })
 },
 })
}
```

Escrever a mutation sem `onSuccess` é o bug mais comum desta camada: o servidor aceita a mudança e a
tela continua mostrando o valor antigo até um refresh manual. Por isso a chave é hierárquica —
`['faturas', 'lista', filtros]` no query, `['faturas']` na invalidação — e um prefixo derruba todas
as listas de uma vez, com qualquer filtro. Quando a espera pela resposta for perceptível, o passo
seguinte é atualização otimista: ver.

A regra estrutural: **quem invalida é a feature dona da chave.** Uma feature nunca invalida a
`queryKey` de outra — se precisar disso, a operação pertence à outra feature e deve ser exportada
por ela.

### 5.4 A rota compõe, não implementa

```tsx
// src/routes/faturas/index.tsx
import { createFileRoute } from '@tanstack/react-router'
import { FaturasPainel, faturasQueryOptions } from '@features/faturas'

export const Route = createFileRoute('/faturas/')({
 loader: ({ context }) => context.queryClient.ensureQueryData(faturasQueryOptions),
 component: FaturasPainel,
})
```

Quatro linhas. A rota decide **qual** capacidade aparece naquele path e o que pré-carregar; ela não
sabe como uma fatura é renderizada (`REACT-ARCH-09`). Todo import vem do barrel (`REACT-ARCH-05`).

Quando a convenção de arquivo do router colidir com a organização por feature, a saída são rotas
virtuais em vez de desmontar as features — ver [TanStack Router - Virtual File Routes](../docs/tanstack-router-virtual-file-routes.md).

### 5.5 Formulário: captura e validação separadas

```tsx
// src/features/faturas/components/fatura-form.tsx
import { z } from 'zod'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Button, Input } from '@components/ui'
import { faturaSchema } from '../types/fatura-schema'

const novaFaturaSchema = faturaSchema.omit({ id: true, status: true })
type NovaFatura = z.infer<typeof novaFaturaSchema>

export function FaturaForm({ onSalvar }: { onSalvar: (dados: NovaFatura) => void }) {
 const { register, handleSubmit, formState } = useForm<NovaFatura>({
 resolver: zodResolver(novaFaturaSchema),
 })

 return (
 <form onSubmit={handleSubmit(onSalvar)}>
 <Input {...register('descricao')} aria-invalid={!!formState.errors.descricao} />
 <Button type="submit" disabled={formState.isSubmitting}>Salvar</Button>
 </form>
 )
}
```

O schema de criação é **derivado** do schema do domínio com `.omit`, não reescrito. O componente
recebe `onSalvar` por prop em vez de chamar a mutation direto: assim ele é testável sem servidor e a
orquestração fica em quem compõe. Ver e.

### 5.6 Nota sobre Next.js App Router

Em Next, `app/` **é a camada de rota**, não bootstrap — a nomenclatura do artigo original colide.
O mapeamento é direto: `app/` ocupa o lugar de `routes/`, e `src/features/` permanece igual.

Dois cuidados que só existem em Next e que mudam o desenho do barrel:

- **`'use client'` contamina o barrel.** Um `index.ts` que reexporta um componente cliente junto com
 utilitários de servidor arrasta o módulo inteiro para o bundle do cliente. Em features mistas,
 separe as superfícies: `index.ts` (servidor) e `client.ts` (cliente), e importe de cada uma
 conforme o contexto.
- **Barrels grandes custam build.** Um `index.ts` que reexporta muita coisa faz o bundler percorrer
 o grafo inteiro mesmo quando o consumidor usa um símbolo só. A mitigação estrutural é manter o
 barrel pequeno — não existe flag que resolva isso para código local. O
 `experimental.optimizePackageImports` do Next é para **pacotes** de `node_modules` que exportam
 centenas de módulos (a lista padrão é toda de bibliotecas de terceiros), é experimental e a própria
 doc não o recomenda para produção. Não conte com ele para barrel de feature.

Nada disso invalida a estrutura — só significa que a fronteira servidor/cliente é uma segunda
dimensão que atravessa a fatia vertical.

---

## 6. Antipadrões

| Antipadrão | Por que dói | Correção |
| --- | --- | --- |
| `import { X } from '@features/faturas/components/fatura-card'` | Amarra o consumidor à estrutura interna; mover o arquivo quebra o app. | Exporte no barrel e importe `@features/faturas`. |
| `import { useFaturas } from '@features/faturas'` dentro de `features/faturas/` | Ciclo via `index.ts`; export `undefined` em runtime. | Caminho relativo: `../api/faturas-queries`. |
| Lógica no `index.ts` | Roda para todo consumidor; vira import com efeito colateral. | Barrel só reexporta. |
| `libs/formatar-fatura.ts` | Domínio dentro do genérico; `libs/` deixa de ser reutilizável. | Mova para `features/faturas/utils/`. |
| Pasta `features/comum/` genérica | Vira depósito sem dono; ninguém sabe o que pode deletar. | Nomeie pela capacidade: `features/core/permissoes/`. |
| Feature criada para uma tela | Feature é capacidade de produto, não rota. | Mantenha em uma feature existente até haver domínio próprio. |
| Sete subpastas vazias em feature nova | Ruído; sugere estrutura que não existe. | Crie a pasta no segundo arquivo do tipo. |
| `stores/` guardando resposta de API | Reimplementa cache, invalidação e revalidação à mão. | `queryOptions` em `api/`. |

Antipadrões de React (não de arquitetura) ficam em [React - Patterns](../docs/react-patterns.md) § 8.

---

## 7. Enforcement com Biome

> **Fronteira que ninguém verifica é apenas convenção.** Estrutura de pasta não resolve arquitetura;
> o que resolve é disciplina de dependência, e disciplina que depende de memória humana falha em
> escala. As regras abaixo movem parte de `REACT-ARCH-*` de revisão para build.

`biome.json`:

```json
{
 "$schema": "https://biomejs.dev/schemas/latest/schema.json",
 "linter": {
 "rules": {
 "correctness": { "noUnusedImports": "error" },
 "suspicious": { "noImportCycles": "error" },
 "style": {
 "noRestrictedImports": {
 "level": "error",
 "options": {
 "patterns": [
 {
 "group": ["@features/*/*", "@features/*/*/**"],
 "message": "REACT-ARCH-05: deep import em feature. Importe pelo barrel: @features/<feature>."
 },
 {
 "group": ["@components/*/*", "@components/*/*/**"],
 "message": "REACT-ARCH-05: deep import em componente compartilhado. Importe @components/ui ou @components/layout."
 }
 ]
 }
 }
 }
 }
 },
 "overrides": [
 {
 "includes": ["src/features/**"],
 "linter": {
 "rules": {
 "style": {
 "noRestrictedImports": {
 "level": "error",
 "options": {
 "patterns": [
 {
 "group": ["@routes/**"],
 "message": "REACT-ARCH-07: feature não importa rota. A rota conhece a feature, nunca o contrário."
 },
 {
 "group": ["@features/*/*", "@features/*/*/**"],
 "message": "REACT-ARCH-05: deep import em feature. Importe pelo barrel: @features/<feature>."
 }
 ]
 }
 }
 }
 }
 }
 },
 {
 "includes": ["src/components/**", "src/hooks/**", "src/libs/**", "src/types/**"],
 "linter": {
 "rules": {
 "style": {
 "noRestrictedImports": {
 "level": "error",
 "options": {
 "patterns": [
 {
 "group": ["@features/**", "@routes/**"],
 "message": "REACT-ARCH-06: camada genérica não conhece domínio nem rota. Inverta a dependência via prop ou parâmetro."
 }
 ]
 }
 }
 }
 }
 }
 }
 ],
 "assist": {
 "actions": { "source": { "organizeImports": "on" } }
 }
}
```

### O que cada regra cobre

| Regra | Grupo | Disponível desde | Cobre |
| --- | --- | --- | --- |
| `noImportCycles` | `suspicious` | Biome v2.0.0 | `REACT-ARCH-04`, `REACT-ARCH-10` |
| `noRestrictedImports` | `style` | `patterns` desde v2.2.0 | `REACT-ARCH-05`, `REACT-ARCH-06` |
| `noUnusedImports` | `correctness` | — | barrel com export morto |

Nenhuma das três é recomendada por padrão — `noImportCycles` e `noRestrictedImports` precisam ser
ativadas explicitamente. `noImportCycles` ignora imports type-only por padrão (`ignoreTypes`), o que
é o comportamento correto: o compilador os apaga e eles não formam ciclo em runtime.

Escopo por pasta usa `overrides[].includes` com globs estilo gitignore (`**` como componente inteiro,
`!` para exceção). **Só o primeiro override que casar é aplicado** — a doc do Biome é explícita:
*"If a file can match three patterns, only the first one is used."* A ordem do array importa, e os
dois overrides acima não se sobrepõem de propósito. Regras declaradas no nível superior valem para
arquivos que nenhum override capturou; por isso o padrão global de deep import é repetido dentro do
override de `src/features/**`, que sobrescreveria a regra inteira.

### O que o Biome não expressa

Três regras ficam total ou parcialmente em revisão:

- **`REACT-ARCH-06` no sentido inverso completo.** Dá para proibir a camada genérica de importar
 features. Não dá para detectar regra de negócio *escrita* dentro de `libs/`.
- **`REACT-ARCH-08`, o terceiro consumidor.** É julgamento sobre duplicação, não sobre grafo.
- **`REACT-ARCH-04` no caso sem reexportação.** `noImportCycles` só pega o import do próprio alias
 quando ele fecha ciclo — ver a ressalva em § 4. Expressar o caso restante exigiria um override por
 feature, o que não se paga.

Além disso, `REACT-ARCH-09` não tem regra de lint, mas tem o teste de bancada da § 4, que é objetivo
o bastante para uma revisão arbitrar.

Além disso, `noPrivateImports` (grupo `correctness`, v2.0.0) **não serve** para fronteira de feature,
embora pareça servir. A visibilidade `@package` do Biome é relativa à pasta que declara o símbolo:
módulos que só compartilham uma pasta ancestral não podem importar. Isso significa que
`features/faturas/index.ts` **não consegue** reexportar um símbolo `@package` de
`features/faturas/components/` — o padrão de barrel quebra. A regra é útil em granularidade fina
(privar helpers dentro de `api/`, por exemplo), não como fronteira de domínio.

**Verificado.** Esta configuração foi executada contra o Biome **2.5.8** num projeto real: o schema é
aceito sem reclamação, e os dois casos que importam disparam como descrito —
`@features/faturas/api/faturas-client` a partir de outra feature emite `REACT-ARCH-05`, enquanto
`@features/faturas` (o barrel) passa; e um arquivo em `src/libs/` importando `@features/faturas`
emite `REACT-ARCH-06`. Os globs `@features/*/*` fazem o que o texto afirma.

Ainda assim, rode contra o seu projeto ao adotar — a forma dos seus aliases pode diferir:

```bash
pnpm biome check src
```

Use `biome check` **sem** `--write` para verificar. Com `--write` ele corrige e reescreve arquivos,
o que é útil no desenvolvimento e inútil como critério de aceite: um comando que conserta o problema
antes de reportá-lo não prova nada.

---

## 8. Migração gradual

Não reorganize o repositório inteiro em um PR. A ordem abaixo mantém o app verde a cada passo.

1. **Aliases primeiro.** Adicione `paths` no `tsconfig.json` e o `resolve.alias` equivalente no
 `vite.config.ts` e no `vitest.config.ts`. Os três precisam concordar, ou os testes quebram sozinhos.
2. **Extraia o genuinamente genérico.** Mova para `components/ui/`, `hooks/` e `libs/` só o que já
 não tem domínio hoje. Não "generalize" nada nesta etapa.
3. **Migre uma feature pequena e isolada, inteira.** Uma capacidade com poucas dependências, do
 componente ao schema. O objetivo é ter um exemplo vivo no repositório, não cobertura.
4. **Adicione o barrel e conserte os consumidores.** É aqui que a superfície pública fica explícita.
5. **Ligue o `noImportCycles`.** Ele revela acoplamentos que ninguém tinha visto. Trate como erro
 desde o começo — em modo aviso ele é ignorado.
6. **Ligue o `noRestrictedImports` por camada.** Comece pela camada genérica (`overrides` acima) —
 ela tende a acusar menos violações por ter menos arquivos, mas confirme antes com
 `pnpm biome check src` em vez de assumir.
7. **Só então considere `features/core/`.** Quando `REACT-ARCH-08` disparar de verdade.

A cada passo, um PR. Migração de estrutura misturada com mudança de comportamento é irrevisável.

---

## 9. Quando não usar

Esta estrutura cobra disciplina antes de devolver valor. O retorno aparece quando há **múltiplos
domínios e mais de uma pessoa mexendo**. Não vale a pena quando:

- o app tem um domínio só (uma landing, uma calculadora, um formulário);
- o produto ainda está descobrindo qual é o formato — fronteira definida cedo é fronteira definida errada;
- o projeto é majoritariamente design system, onde a organização natural é por componente;
- é protótipo com data de validade.

Nesses casos, `components/` + `hooks/` plano é a resposta certa. `REACT-ARCH-01` vale a partir do
momento em que existe um segundo domínio — não antes.

O custo, quando se adota: mais arquivos, mais indireção, barrels que precisam de manutenção, e a
necessidade real de fazer valer as regras. Sem enforcement, as camadas viram sugestão e o resultado é
pior que a estrutura plana — porque agora existe a **ilusão** de fronteira.

---

## 10. Contrato de skill

Implementa o contrato de [React.js](../docs/react-js.md) § 7. Uma skill de estrutura deriva **desta nota**, não da doc
de React inteira, e registra `fonte: "[Feature-Based Architecture](feature-based-architecture.md)"` no frontmatter.

A skill que implementa este contrato é `react-structure`. Ela roteia por tarefa e não repete nada
do que está aqui — se as duas divergirem, a skill é que está errada.

### Carregamento mínimo

```
SEMPRE: § 2 (camadas e direção) + § 4 (regras REACT-ARCH-*)

AO CRIAR FEATURE: § 3 (anatomia) + § 5 (exemplos no stack)
AO MOVER CÓDIGO: § 8 (migração) + REACT-ARCH-08
AO REVISAR IMPORT: § 6 (antipadrões) + § 7 (o que o lint cobre)
AO CONFIGURAR REPO: § 7 (biome.json e aliases)

TAMBÉM: [React - Patterns](../docs/react-patterns.md) para decisão de componente
 (esta nota decide onde o arquivo mora; ela decide o que há dentro)

NUNCA: inventar camada nova sem registrar aqui
```

### Ordem das decisões ao criar código novo

1. **Isto é um domínio?** Se não tem vocabulário próprio de produto, não é feature — é `components/`
 ou `libs/`.
2. **O domínio já existe?** Prefira crescer uma feature existente a criar a nona. Feature nova exige
 capacidade nova, não tela nova.
3. **O dado é remoto?** Se sim, `api/` com `queryOptions` — não `stores/`.
4. **Isto é público?** Só entra no barrel o que outra camada realmente consome.
5. **Quem vai importar isto?** Se a resposta for outra feature, confirme `REACT-ARCH-05` e registre o
 contador de `REACT-ARCH-08`.

### Como citar um achado

Cite o ID, o arquivo e a linha. Não parafraseie a regra:

> `REACT-ARCH-05` — `src/features/relatorios/components/grafico.tsx:8`
> Deep import: `@features/faturas/api/faturas-queries`.
> Correção: exportar `faturasQueryOptions` no barrel de `faturas` e importar `@features/faturas`.

### Invariantes

1. **A estrutura não substitui a regra.** Mover arquivo não conserta dependência invertida.
2. **Direção antes de estética.** Uma violação de `REACT-ARCH-06` ou `-07` tem precedência sobre
 qualquer preferência de organização.
3. **Não extraia sem o terceiro consumidor** (`REACT-ARCH-08`). Duplicação é mais barata que
 abstração errada.
4. **Verificar antes de afirmar.** Se uma regra do Biome não está na tabela da § 7, ela não foi
 verificada nesta nota — consulte `biomejs.dev` e atualize aqui.
5. **A fonte vence.** Divergência entre esta nota e o comportamento real do Biome ou do TanStack é
 bug desta nota.

### Autoverificação antes de entregar

- [ ] Todo import de outra feature passa pelo barrel (`REACT-ARCH-05`)
- [ ] Nenhum import dentro da feature usa `@features/` (`REACT-ARCH-04`)
- [ ] O barrel só tem reexports (`REACT-ARCH-03`)
- [ ] Nada em `components/`, `hooks/`, `libs/` importa domínio (`REACT-ARCH-06`)
- [ ] Nenhuma feature importa de `@routes/` (`REACT-ARCH-07`)
- [ ] Toda mutation nova invalida a `queryKey` que ela afeta, e só chaves da própria feature
- [ ] Teste colocalizado ao lado do arquivo testado, fora do barrel
- [ ] Tipos exportados com `export type` (`REACT-ARCH-11`)
- [ ] Arquivos e pastas em kebab-case (`REACT-ARCH-12`)
- [ ] `pnpm biome check src` passa

---

## Divergências em relação à fonte

O artigo de `Feature-Based Architecture in React` (dev.to) é a origem do argumento; esta nota é a
fonte de verdade para decisão no vault. Onde divergem, e por quê:

| Eixo | Artigo | Aqui | Motivo |
| --- | --- | --- | --- |
| Camadas | `app/` `pages/` `features/` `shared/` | `routes/` `features/` + `components/` `hooks/` `libs/` `types/` | `app/` colide com Next; o genérico já é plano no scaffold do vault |
| Núcleo de reuso | `features/core/` desde o início | só quando `REACT-ARCH-08` disparar | camada sem consumidor vira depósito |
| Feature ↔ irmã | proibido | permitido via barrel | ver § 4, decisão adotada |
| Subpasta de orquestração | `containers/` | `api/` + composição na rota | `containers/` é vocabulário pré-hooks; TanStack Query ocupa o papel |
| Nomenclatura | `UserAvatar/` PascalCase | kebab-case estrito | consistência com o scaffold e com sistemas de arquivo case-insensitive |
| Alias | `@/features/*` | `@features/*` | convenção do scaffold do vault |
| Enforcement | `eslint-plugin-boundaries` | Biome | Biome é a ferramenta única de lint aqui |

O artigo também se posiciona como simplificação do Feature-Sliced Design. Esta nota não adota FSD:
sem `entities/`/`widgets/`, sem numeração de camadas.

---

## Relacionados

- `Fronteira do BFF - forma, jornada e regra` — nota irmã: esta decide onde o código do frontend
 mora; ela decide o que atravessa a fronteira do servidor e quem é dono de cada decisão
- `Monorepo com Bun - estrutura e tooling` — quando uma camada desta nota vira pacote próprio
- [Architecture in React](architecture-in-react.md) — nota mãe: os eixos de decisão arquitetural
- `react-structure` — a skill que implementa o contrato da § 10
- — a ideia conceitual
-
-
-
- [React - Patterns](../docs/react-patterns.md) — decisão dentro do componente
- [React.js](../docs/react-js.md) — hub de React e § 7, o contrato de skill
- [TanStack Router - Virtual File Routes](../docs/tanstack-router-virtual-file-routes.md) — quando a rota colide com a feature
-
-
- [Frontend roadmap](frontend-roadmap.md) — trilha de estudos

## Fontes consultadas

- `Feature-Based Architecture in React` — artigo de origem (dev.to)
- [Biome — `noImportCycles`](https://biomejs.dev/linter/rules/no-import-cycles/)
- [Biome — `noRestrictedImports`](https://biomejs.dev/linter/rules/no-restricted-imports/)
- [Biome — `noPrivateImports`](https://biomejs.dev/linter/rules/no-private-imports/)
- [Biome — configuração e `overrides`](https://biomejs.dev/reference/configuration/)
- `Prompts/Frontend/scaffold-phase-02-biome.md` e `scaffold-phase-05-fba-directory-structure.md` — convenções do vault
