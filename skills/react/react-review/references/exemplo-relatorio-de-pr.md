# Exemplo trabalhado — revisão de um PR

PR: *"adiciona busca de clientes com filtro e exportação"*. Três arquivos tocados.

---

## Passo 1 — sondas antes de abrir qualquer arquivo

```
$ bash scripts/sondas.sh src

== 0. Ambiente
 "react": "^19.1.0"
 -- React Compiler: (nada)
 -- rede de lint para REACT-HOOK-* e REACT-EFFECT-02/03:
 Biome presente (biome.json), mas o domínio react NÃO está ligado
 NENHUMA rede ativa ← já é achado
 -- <StrictMode>: src/main.tsx
== 1. Fetch dentro de Effect
 src/features/clientes/ListaClientes.tsx:31
== 2. Estado derivado por Effect
 src/features/clientes/ListaClientes.tsx:44
== 6. Memoização — inventário
 src/features/clientes/ListaClientes.tsx:3
== 7. index como key
 src/features/clientes/ListaClientes.tsx:78
== 9. Suspense sem Error Boundary
 src/features/clientes/rota.tsx
== 12. Server Function — validação na fronteira
 sem validação aparente: src/features/clientes/exportar.ts
```

Cinco minutos, e a revisão já sabe **quais** arquivos ler e em que ordem. Nenhum desses
seis é achado ainda — são candidatos.

## Passo 2 — leitura, na ordem da grade

Nível 1 primeiro. A leitura de `ListaClientes.tsx` encontra o que a sonda não vê:

```tsx
export function ListaClientes({ termo }: { termo: string }) {
 const [clientes, setClientes] = useState<Cliente[]>([]);
 if (!termo) return <Vazio />; // ← early return
 const [pagina, setPagina] = useState(1); // ← Hook depois dele
 …
```

Isso muda a ordem do relatório: `REACT-HOOK-01` é bloqueante e vem antes de tudo que a sonda achou.

## Passo 3 — o relatório

```markdown
## Revisão React — PR #482 (busca de clientes)

**Ambiente** (sonda 0): react 19.1.0 · React Compiler ausente ·
rede de lint **AUSENTE** (Biome sem o domínio react) · StrictMode ok

### Bloqueante (1)

`REACT-HOOK-01` — src/features/clientes/ListaClientes.tsx:12
`useState(1)` é chamado depois do early return da linha 10; a ordem dos Hooks muda entre renders.
Correção: mover os dois `useState` para antes do `if (!termo)`.
Ver React - Rules of React.

### Alta (3)

`REACT-EFFECT-06` — src/features/clientes/ListaClientes.tsx:31
`fetch('/api/clientes?q=' + termo)` dentro de `useEffect`, sem cancelamento: duas buscas
em voo retornam fora de ordem e a antiga sobrescreve a nova.
Correção: substituir por `useQuery(clientesQuery(termo))`; remover `clientes`, `carregando` e `erro`.
Ver React - Efeitos e Sincronização.

`REACT-RSC-06` — src/features/clientes/exportar.ts:4
A Server Function `exportarClientes(filtro)` usa `filtro` direto na query, sem sessão nem validação.
Correção: ler a sessão, validar `filtro` com Zod na própria função e filtrar por `orgId` da sessão.
Ver React - Server Components e Diretivas.

`REACT-ASYNC-08` — src/features/clientes/rota.tsx:18
`<Suspense>` na fronteira de dados sem Error Boundary: falha da query vira tela branca.
Correção: envolver com o `<ErrorBoundary>` da feature, com botão de retry.
Ver React - Suspense e Assincronia.

### Média (3)

`REACT-PAT-01` — src/features/clientes/ListaClientes.tsx:44
`totalPaginas` é estado sincronizado por Effect a partir de `clientes.length`.
Correção: `const totalPaginas = Math.ceil(clientes.length / POR_PAGINA)` no render; remover estado e Effect.
Ver React - Patterns.

`REACT-PAT-10` — src/features/clientes/ListaClientes.tsx:13
`pagina` em `useState`: não sobrevive a refresh e não é compartilhável por link.
Correção: mover para search param da rota (`Route.useSearch`).
Ver React - Patterns.

antipadrão de React - Patterns § 8 — src/features/clientes/ListaClientes.tsx:78
`key={i}` numa lista que é reordenada pelo seletor de ordenação.
Correção: `key={cliente.id}`.

### Sugestões (sem regra)

- `ListaClientes.tsx` tem 210 linhas e três responsabilidades. Não há ID para isso;
 a extração só se justifica se cada parte tiver nome de domínio (`REACT-PAT-05` é sobre
 o oposto: extrair sem justificativa).

### Não verificado

- `exportar.ts` usa `after` do runtime do framework — não está em React.js § 4,
 logo não foi verificado nesta doc. Não opinei sobre o comportamento.
- O projeto usa Biome com `recommended`, mas **sem o domínio `react`**: `useHookAtTopLevel` e
 `useExhaustiveDependencies` não rodam, e nada avisa. `REACT-HOOK-*` e parte de
 `REACT-CALL-*` dependem de revisão humana. Ligar `linter.domains.react` é uma linha, e é o
 item de maior retorno deste PR.
```

## O que este exemplo demonstra

| Decisão | Onde está a regra |
| --- | --- |
| o achado de `REACT-HOOK-01` veio da **leitura**, não da sonda | `sondas.md` § *O que as sondas não pegam* |
| a memoização da sonda 6 **não** virou achado — o `useMemo` tinha comentário com medição | `REACT-PERF-01` |
| o tamanho do arquivo foi para "Sugestões", não para achados | `severidade-e-relatorio.md` § *O corte* |
| o `after` desconhecido virou declaração de limitação, não opinião | [React.js](../../../../knowledge-base/docs/react-js.md) § 7, invariante 1 |
| a ausência de lint entrou como fechamento, não como nota de rodapé | `severidade-e-relatorio.md` § *Estrutura do relatório* |
