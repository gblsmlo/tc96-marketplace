---
titulo: React - Performance e Concorrência
Link: https://react.dev/reference/react/memo
tags:
 - react
 - performance
 - concurrency
 - agent-context
source: "Documentação oficial do React — memo, useMemo, useCallback, useTransition, useDeferredValue, Activity, Profiler, React Compiler"
verificado-em: 2026-08-14
---

# React — Performance e Concorrência

> `memo` · `useMemo` · `useCallback` · `useTransition` · `startTransition` · `useDeferredValue` · `<Activity>` · `<Profiler>` · React Compiler
>
> Duas famílias distintas que costumam ser confundidas: **memoização** evita trabalho repetido; **concorrência** reordena o trabalho por prioridade. Elas resolvem problemas diferentes.

Entrada: [React.js](react-js.md) · Base normativa: [React - Rules of React](react-rules-of-react.md)

---

## 1. A regra que precede todas

Otimização sem medição é ruído: adiciona custo de comparação, complexidade de leitura e superfície de bug, tipicamente sem ganho.

| ID | Regra |
| --- | --- |
| `REACT-PERF-01` | `memo`, `useMemo` e `useCallback` **MUST** ter justificativa medida — Profiler, gravação de DevTools ou lentidão reproduzível. |

**Exceção a `REACT-PERF-01`:** estabilizar o `value` de um Context (`REACT-STATE-07`) não exige medição. Ali `useMemo` não é otimização — é o que impede que todo consumidor re-renderize a cada render do provider, um custo estrutural e previsível, não hipotético. A exigência de medida vale para memoização **especulativa**.
| `REACT-PERF-02` | Antes de memoizar manualmente, **MUST** verificar se o React Compiler está ativo no projeto (§ 6). |

Ordem correta de ataque, do mais barato ao mais caro:

1. Não criar estado desnecessário →
2. Colocar o estado no lugar certo → [React - Patterns](react-patterns.md) § 2
3. Composição para reduzir o alcance do re-render
4. **Reduzir o volume renderizado** (§ 5) — quando o gargalo é quantidade de nós
5. Concorrência (§ 4) — muda a *percepção*, não o custo
6. Memoização (§ 3) — só com medida

O passo 3 é o mais subestimado: mover estado para um componente menor, ou passar children como prop, elimina re-renders sem nenhuma memoização.

### Diagnóstico: cálculo ou volume?

Antes de escolher a ferramenta, descubra onde o tempo é gasto — são problemas diferentes com soluções que não se substituem.

| Sintoma no Profiler / DevTools | Gargalo | Vai para |
| --- | --- | --- |
| Poucos componentes, `actualDuration` alto em um deles | **cálculo** | `useMemo`, `useDeferredValue` |
| Milhares de componentes, cada um rápido, soma alta | **volume** | § 5 — virtualização/paginação |
| Muitos filhos re-renderizando sem que suas props mudem | **re-render desnecessário** | passos 2-3, depois `memo` |
| Render rápido, mas o browser trava depois | **DOM/paint** | § 5 — menos nós |

O erro que essa tabela evita: tratar volume com memoização. `memo` em 5000 linhas ainda monta 5000 componentes na primeira renderização — ele só evita re-render, nunca o custo inicial.

---

## 2. `<Profiler>`

Medir antes de otimizar. `<Profiler>` mede programaticamente uma subárvore.

```tsx
<Profiler id="Lista" onRender={(id, phase, actualDuration) => {
 console.log(id, phase, actualDuration)
}}>
 <Lista items={items} />
</Profiler>
```

`phase` é `"mount"`, `"update"` ou `"nested-update"`; `actualDuration` é o tempo de render da subárvore. Adiciona overhead — é ferramenta de investigação, não instrumentação permanente. Para uso interativo, o profiler do React DevTools costuma bastar.

---

## 3. Memoização

### `memo`

```tsx
const Row = memo(function Row({ item }: { item: Item }) { /*... */ })
```

Pula o re-render quando as props são **rasamente iguais** às anteriores. Só funciona se as props forem estáveis — daí a dependência de `useCallback`/`useMemo` no pai.

```tsx
// memo INÚTIL: onSelect é nova a cada render do pai
<Row item={item} onSelect={ => select(item.id)} />

// memo efetivo
const onSelect = useCallback((id: string) => select(id), [select])
<Row item={item} onSelect={onSelect} />
```

**Uma prop instável anula o `memo` inteiro.** Por isso memoizar um componente sem estabilizar suas props costuma ser custo puro.

### `useMemo` × `useCallback`

```tsx
const value = useMemo( => computeExpensive(a, b), [a, b]) // cacheia o RESULTADO
const handler = useCallback((x: string) => doSomething(x, a), [a]) // cacheia a FUNÇÃO
```

`useCallback(fn, deps)` é equivalente a `useMemo( => fn, deps)`.

Casos legítimos:

| Caso | Hook |
| --- | --- |
| Cálculo comprovadamente caro | `useMemo` |
| Valor que é dependência de outro Hook | `useMemo` |
| `value` de Context com consumidores custosos | `useMemo` |
| Função passada a filho `memo` | `useCallback` |
| Função que é dependência de um Effect | `useCallback` |

Fora disso, é ruído. `useMemo` **não** garante que o valor será preservado — o React pode descartar o cache.

| ID | Regra |
| --- | --- |
| `REACT-PERF-03` | `memo` sem estabilização das props **NEVER** é aplicado — não produz efeito e adiciona custo. |
| `REACT-PERF-04` | Cálculo dentro de `useMemo`/`useCallback` **MUST** ser puro (`REACT-PURE-01`). |
| `REACT-PERF-05` | `useMemo` **NEVER** é usado para garantir identidade semanticamente necessária — o cache pode ser descartado. Se a identidade é obrigatória, use `useRef`. |

---

## 4. Concorrência

Concorrência não deixa o trabalho mais rápido — deixa a UI **responsiva** durante o trabalho, permitindo que atualizações urgentes (digitar, clicar) interrompam as não urgentes.

### `useTransition`

```tsx
const [isPending, startTransition] = useTransition

function selectTab(tab: Tab) {
 startTransition( => setTab(tab)) // não urgente: pode ser interrompida
}

return (
 <>
 <TabBar onSelect={selectTab} />
 <div style={{ opacity: isPending ? 0.6 : 1 }}>
 <TabPanel tab={tab} />
 </div>
 </>
)
```

O input continua responsivo enquanto o painel pesado renderiza. `isPending` permite indicar a espera sem esconder a UI atual.

### `startTransition`

Mesma marcação, sem a flag de pendência, e chamável **fora** de um componente — útil em stores e utilitários.

A função passada a `startTransition` **pode ser `async`** — os `await` dentro dela fazem parte da Transition. O que não é automático é o que vem **depois** do `await`:

```tsx
// ERRADO — o setState após o await não é tratado como Transition
startTransition(async => {
 await salvar
 setPagina('/pronto')
})

// CERTO
startTransition(async => {
 await salvar
 startTransition( => setPagina('/pronto'))
})
```

A própria documentação chama isso de limitação conhecida a ser corrigida. Outras caveats que mudam decisões: uma Transition **é interrompida** por atualizações posteriores, e **não serve para controlar campos de texto**.

| ID | Regra |
| --- | --- |
| `REACT-PERF-06` | Todo `setState` após um `await` dentro de `startTransition` **MUST** ser envolvido em novo `startTransition`. |
| `REACT-PERF-10` | Transição **NEVER** é usada para controlar o valor de um campo de texto. |

### `useDeferredValue`

```tsx
const deferredQuery = useDeferredValue(query)
const results = useMemo( => search(deferredQuery), [deferredQuery])
```

Quando você **não controla** o `setState` — só recebe o valor. O React renderiza primeiro com o valor antigo e depois com o novo, em background.

| Você controla o `setState`? | Use |
| --- | --- |
| Sim, e quer flag de pendência | `useTransition` |
| Sim, mas está fora de um componente | `startTransition` |
| Não — só tem o valor | `useDeferredValue` |

---

## 5. Reduzir o volume renderizado

Quando o gargalo é **quantidade de nós**, nenhuma API desta nota resolve — nem memoização, nem concorrência. `<Suspense>`, `useTransition` e `useDeferredValue` melhoram a *percepção*; o navegador ainda precisa construir e pintar cada nó.

A única saída é renderizar menos.

| Estratégia | Quando | Custo |
| --- | --- | --- |
| **Virtualização** (windowing) | lista/tabela longa e rolável, todos os itens do mesmo tipo | altura das linhas, acessibilidade, Ctrl+F deixam de funcionar de graça |
| **Paginação** | o usuário não precisa rolar tudo | navegação extra |
| **Busca/filtro no servidor** | o dataset é grande na origem | round-trip |
| **Colapsar por padrão** | árvores, agrupamentos | um clique a mais |

Virtualização renderiza apenas as linhas visíveis (mais uma margem), mantendo o número de nós constante independentemente do tamanho do dataset. É a resposta padrão para listas na casa dos milhares.

> **Ponte:** o React não traz virtualização embutida — é biblioteca. No ecossistema TanStack, TanStack Virtual cobre listas e grids, e combina com TanStack Table. Avalie a versão e a API na documentação da biblioteca; esta nota não a verificou.

**Ordem de escolha:** se o usuário não precisa ver tudo, pagine — é mais simples e preserva acessibilidade. Virtualize quando a rolagem contínua for requisito.

| ID | Regra |
| --- | --- |
| `REACT-PERF-09` | Lista com milhares de itens **NEVER** é tratada com memoização ou concorrência isoladamente — o gargalo é volume; reduza os nós renderizados. |

---

## 6. `<Activity>`

Alternativa a montar/desmontar condicionalmente, **preservando estado**.

```tsx
<Activity mode={isShowingSidebar ? 'visible' : 'hidden'}>
 <Sidebar />
</Activity>
```

Comportamento verificado na fonte:

| `mode` | Efeito |
| --- | --- |
| `'visible'` | renderiza normalmente; Effects ativos |
| `'hidden'` | oculta com `display: none`; **estado preservado**; **Effects limpos**; filhos ainda re-renderizam com prioridade baixa; DOM preservado |

A combinação que importa: **estado sobrevive, Effects não**. Uma subscription é encerrada ao ocultar e recriada ao mostrar, enquanto o scroll, o texto digitado e a seleção permanecem.

Caveats citados da fonte:

> "A *hidden* Activity that just renders text will not render anything rather than rendering hidden text, because there's no corresponding DOM element to apply visibility changes to."

> "Only data read from a source that activates a Suspense boundary, such as a Promise read with `use`, is fetched during pre-rendering. Activity does not detect data fetched inside an Effect."

O segundo é a armadilha: pré-renderização de conteúdo oculto só funciona com dados lidos via Suspense — dados buscados em Effect não são pré-carregados. Mais um argumento contra fetch em Effect (`REACT-EFFECT-06`).

| ID | Regra |
| --- | --- |
| `REACT-PERF-07` | `<Activity mode="hidden">` **NEVER** é usado supondo Effects ativos — eles são limpos. |

---

## 7. React Compiler

O compilador memoiza automaticamente componentes e Hooks, tornando a maior parte de `memo`/`useMemo`/`useCallback` escrita à mão desnecessária.

**A condição de funcionamento é o contrato desta doc inteira:** o compilador só pode otimizar código que segue as [Rules of React](https://react.dev/reference/rules). Código impuro é pulado ou quebra a build, conforme `panicThreshold`. Ver [React - Rules of React](react-rules-of-react.md).

Opções principais de configuração, conforme a referência:

| Opção | Função |
| --- | --- |
| `compilationMode` | o que compilar: tudo, só anotado, ou detecção automática |
| `target` | versão do React alvo (17, 18 ou 19) |
| `panicThreshold` | falhar a build ou pular componentes problemáticos |
| `logger` | log customizado de eventos de compilação |
| `gating` | feature flag de runtime para rollout gradual |

Diretivas por função:

```tsx
function Heavy {
 'use memo' // opta por compilar — útil em compilationMode: 'annotation'
 //...
}

function Legacy {
 'use no memo' // opta por NÃO compilar — depuração ou código incompatível
 //...
}
```

**Status:** React Compiler chegou a **1.0 estável em 07/10/2025** ([anúncio](https://react.dev/blog/2025/10/07/react-compiler-1)). É compatível com React 17 em diante, e Vite, Next.js e Expo têm integração. Ou seja: `REACT-PERF-02` não é hipotético — verificar se o compilador está ativo é passo real antes de memoizar à mão.

| ID | Regra |
| --- | --- |
| `REACT-PERF-08` | `'use no memo'` **MUST** ser temporário e comentado com o motivo; é marcador de dívida, não solução. |

---

## 8. Antipadrões

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| `useCallback`/`useMemo` em tudo | custo de comparação sem ganho | medir primeiro · `REACT-PERF-01` |
| `memo` com prop de callback inline | comparação sempre falha | estabilizar props · `REACT-PERF-03` |
| `useMemo` para efeito colateral | viola pureza | Effect ou handler · `REACT-PERF-04` |
| `useTransition` para esconder lentidão de rede | não é problema de render | cache/Suspense |
| `useDeferredValue` sem `memo` no consumidor | o trabalho caro roda igual | memoizar o cálculo derivado |
| Memoização manual com Compiler ativo | redundante e ruidoso | remover · `REACT-PERF-02` |
| `<Activity>` esperando Effects vivos | Effects são limpos ao ocultar | `REACT-PERF-07` |

---

## Relacionados

- [React.js](react-js.md) · [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md)
- [React - Suspense e Assincronia](react-suspense-e-assincronia.md) — transições e Suspense se combinam
- ·

## Fontes consultadas

Verificadas em 2026-08-14:

- [memo](https://react.dev/reference/react/memo) · [useMemo](https://react.dev/reference/react/useMemo) · [useCallback](https://react.dev/reference/react/useCallback)
- [useTransition](https://react.dev/reference/react/useTransition) · [startTransition](https://react.dev/reference/react/startTransition) · [useDeferredValue](https://react.dev/reference/react/useDeferredValue)
- [Activity](https://react.dev/reference/react/Activity) — caveats citados literalmente
- [Profiler](https://react.dev/reference/react/Profiler)
- [React Compiler — Configuration](https://react.dev/reference/react-compiler/configuration) · [Directives](https://react.dev/reference/react-compiler/directives)
