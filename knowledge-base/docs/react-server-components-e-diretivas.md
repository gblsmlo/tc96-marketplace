---
Link: https://react.dev/reference/rsc/server-components
tags:
 - react
 - rsc
 - server-components
 - agent-context
source: "Documentação oficial do React — RSC, 'use client', 'use server', cache, taint (experimental)"
verificado-em: 2026-08-14
---

# React — Server Components e Diretivas

> Server Components · Server Functions · `'use client'` · `'use server'` · `cache` · taint (experimental)
>
> A fronteira servidor/cliente é a decisão arquitetural mais cara de reverter depois. Este satélite existe para que ela seja tomada de propósito.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

> **Pré-requisito:** RSC exige um framework com suporte (Next.js App Router, TanStack Start com server functions, ou bundler configurado). Numa SPA Vite pura, nada desta nota se aplica — o equivalente arquitetural está em.

---

## 1. Server Components

Renderizam **antes**, em ambiente de servidor separado do app cliente — em build time ou por request. Podem:

- ler filesystem e banco diretamente;
- manter dependências caras fora do bundle do cliente;
- buscar dados sem waterfall, colocando o fetch junto do render;
- usar `async`/`await` **no render** — a única exceção legítima a "não faça I/O no render", porque não há re-render concorrente do lado do servidor.

```tsx
// Server Component — sem diretiva; é o padrão em ambiente RSC
async function Notas {
 const notas = await db.notas.listar // acesso direto ao banco
 return (
 <ul>
 {notas.map((n) => (
 <Expansivel key={n.id}><p>{n.texto}</p></Expansivel>
 ))}
 </ul>
 )
}
```

### O que um Server Component **não** pode

| Não pode | Por quê |
| --- | --- |
| `useState`, `useReducer`, `useEffect` | não há ciclo de vida no cliente |
| handlers de evento (`onClick`, `onChange`) | funções não são serializáveis para o cliente |
| APIs de browser (`window`, `localStorage`) | não existem no servidor |
| `useContext` | contexto é do cliente |
| bibliotecas que dependem de APIs de cliente | mesma razão |

O que chega ao cliente é o **resultado renderizado**, não o componente.

| ID | Regra |
| --- | --- |
| `REACT-RSC-01` | Server Component **NEVER** usa estado, Effects, handlers ou APIs de browser. |
| `REACT-RSC-02` | Dado de servidor **MUST** ser buscado no Server Component, não repassado ao cliente para ele buscar de novo. |

---

## 2. `'use client'`

```tsx
'use client'

import { useState } from 'react'
```

Marca o arquivo **e todas as suas dependências transitivas** como código de cliente.

### Regras de posicionamento (verificadas)

- **No começo do arquivo**, acima de qualquer import. Comentários antes são permitidos.
- Aspas simples ou duplas — **nunca** backticks.

### O ponto que quase todo mundo entende errado

`'use client'` opera sobre a **árvore de módulos**, não sobre a árvore de render. Um componente sem diretiva pode ser Server Component quando importado de um módulo de servidor e Client Component quando importado de um módulo de cliente. A mesma fonte serve aos dois usos.

E, decisivo: **todo o código do subgrafo marcado vai para o cliente** — não só os componentes. Uma diretiva no topo de um módulo que importa uma biblioteca pesada arrasta a biblioteca junto.

### Empurrar a fronteira para baixo

```tsx
// ERRADO — a página inteira e tudo que ela importa viram cliente
'use client'
export default function Pagina {
 const [aberto, setAberto] = useState(false)
 return <><Cabecalho /><ListaEnorme /><Botao onClick={ => setAberto(true)} /></>
}

// CERTO — só o pedaço interativo é cliente
// Pagina.tsx (Server Component)
export default async function Pagina {
 const dados = await carregar
 return <><Cabecalho /><ListaEnorme dados={dados} /><BotaoAbrir /></>
}

// BotaoAbrir.tsx
'use client'
export function BotaoAbrir {
 const [aberto, setAberto] = useState(false)
 return <button onClick={ => setAberto(true)}>Abrir</button>
}
```

| ID | Regra |
| --- | --- |
| `REACT-RSC-03` | `'use client'` **MUST** ficar o mais baixo possível na árvore — nunca no topo da página por conveniência. |

### Composição através da fronteira

Um Client Component **pode** renderizar Server Components — desde que recebidos como `children` ou props, não importados diretamente. O Server Component executa antes e o resultado renderizado é passado adiante.

```tsx
// Server Component compõe: conteúdo de servidor dentro de casca interativa
<Expansivel>
 <ConteudoDeServidor />
</Expansivel>
```

| ID | Regra |
| --- | --- |
| `REACT-RSC-04` | Client Component **NEVER** importa um Server Component diretamente — recebe como `children`/props. |

### Props precisam ser serializáveis

| ✅ Atravessa | ❌ Não atravessa |
| --- | --- |
| primitivos: string, number, bigint, boolean, undefined, null | funções comuns |
| símbolos registrados com `Symbol.for` | instâncias de classe |
| String, Array, Map, Set, TypedArray, ArrayBuffer | objetos com protótipo `null` |
| `Date` | símbolos não registrados globalmente |
| objetos simples com propriedades serializáveis | |
| Server Functions (`'use server'`) | |
| elementos JSX | |
| Promises | |

Promises atravessarem é o que habilita o padrão de iniciar o fetch no servidor e lê-lo no cliente com `use` — ver [React - Suspense e Assincronia](react-suspense-e-assincronia.md) § 3.

| ID | Regra |
| --- | --- |
| `REACT-RSC-05` | Props que cruzam a fronteira **MUST** ser serializáveis — instância de classe e função comum lançam exceção. |

---

## 3. `'use server'`

Marca funções de servidor invocáveis pelo cliente. **Não** é o oposto de `'use client'`: não marca componentes, marca **funções**.

```tsx
'use server'

export async function criarTopico(formData: FormData) {
 const sessao = await autenticar // autenticar
 const dados = topicoSchema.parse({ // validar
 titulo: formData.get('titulo'),
 })
 if (!podeCriar(sessao, dados)) throw new Error('Sem permissão') // autorizar
 return db.topicos.criar({...dados, autorId: sessao.userId })
}
```

**Toda Server Function é um endpoint HTTP público.** O bundler gera uma rota para ela; qualquer cliente pode chamá-la com qualquer payload. Validação no cliente não protege nada.

| ID | Regra |
| --- | --- |
| `REACT-RSC-06` | Toda Server Function **MUST** autenticar, validar e autorizar na própria função — é um endpoint público. |
| `REACT-RSC-07` | Argumentos e retorno **MUST** ser serializáveis. |

Desenvolvido em; validação de schema em. Integração com formulários em [React - Formulários e Actions](react-formularios-e-actions.md).

---

## 4. `cache`

```tsx
import { cache } from 'react'

const getUsuario = cache(async (id: string) => db.usuarios.buscar(id))
```

Memoiza o resultado por argumentos **dentro de um mesmo passe de render de servidor**. Dois componentes que pedem o mesmo usuário resultam em uma consulta — resolve a duplicação sem precisar elevar o fetch e fazer prop drilling.

Não é cache entre requests, nem cache persistente. Só vale em Server Components.

| ID | Regra |
| --- | --- |
| `REACT-RSC-08` | `cache` **NEVER** é usado como cache entre requests — o escopo é um passe de render. |

---

## 5. Taint — **experimental**

Marcação verificada na fonte:

> "This API is experimental and is not available in a stable version of React yet. […] Experimental versions of React may contain bugs. Don't use them in production. This API is only available inside React Server Components."

Os exports são `experimental_taintObjectReference` e `experimental_taintUniqueValue`. Impedem que um objeto ou valor específico cruze para o cliente.

```tsx
import { experimental_taintObjectReference } from 'react'

experimental_taintObjectReference(
 'Do not pass ALL environment variables to the client.',
 process.env,
)
```

E o aviso que define como tratá-los, citado literalmente:

> "Do not rely on just tainting for security. Tainting an object doesn't prevent leaking of every possible derived value. For example, the clone of a tainted object will create a new untainted object. Using data from a tainted object (e.g. `{secret: taintedObj.secret}`) will create a new value or object that is not tainted. Tainting is a layer of protection; a secure app will have multiple layers of protection, well designed APIs, and isolation patterns."

| ID | Regra |
| --- | --- |
| `REACT-RSC-09` | Taint **NEVER** é a defesa primária contra vazamento — é camada extra. A defesa é não montar o objeto sensível para começo de conversa. |
| `REACT-RSC-10` | APIs experimentais **NEVER** entram em produção. |

Na prática: monte um DTO explícito com os campos que o cliente pode ver, em vez de passar a entidade inteira e torcer.

```tsx
// Em vez de <Perfil user={user} /> com hash de senha e tokens dentro:
const perfil = { id: user.id, nome: user.nome, avatarUrl: user.avatarUrl }
<Perfil perfil={perfil} />
```

---

## 6. Checklist de revisão

- [ ] `'use client'` está no ponto mais baixo possível? → `REACT-RSC-03`
- [ ] A diretiva está antes de todos os imports, com aspas normais?
- [ ] Client Component importa Server Component diretamente? → `REACT-RSC-04`
- [ ] Alguma prop atravessando é função comum ou instância de classe? → `REACT-RSC-05`
- [ ] Toda Server Function autentica, valida e autoriza? → `REACT-RSC-06`
- [ ] Alguma entidade inteira cruza a fronteira em vez de um DTO? → `REACT-RSC-09`
- [ ] `useState`/`useEffect` em componente sem `'use client'`? → `REACT-RSC-01`

---

## Relacionados

- [React.js](react-js.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Formulários e Actions](react-formularios-e-actions.md) · [React - Suspense e Assincronia](react-suspense-e-assincronia.md) · [React - Renderização e Entrypoints](react-renderizacao-e-entrypoints.md)
- · · ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [Server Components](https://react.dev/reference/rsc/server-components) · [Directives](https://react.dev/reference/rsc/directives)
- ['use client'](https://react.dev/reference/rsc/use-client) — regras de posicionamento e tabela de serialização
- ['use server'](https://react.dev/reference/rsc/use-server) · [cache](https://react.dev/reference/react/cache)
- [experimental_taintObjectReference](https://react.dev/reference/react/experimental_taintObjectReference) — avisos citados literalmente
