# A story antes do teste, e a `play`

Uma `play` boa sobre uma story mal argumentada não salva o arquivo. Confira primeiro:

| Confira | Regra |
| --- | --- |
| o que distingue esta story de outra é `args`, não código em `render` | `SB-CSF-04` |
| `meta` com `satisfies Meta<typeof Componente>`, story por `StoryObj<typeof meta>` | `SB-CSF-02` |
| `Meta` e `StoryObj` importados do **pacote do framework**, não do renderer | `SB-CORE-02` |
| `title` literal estático | `SB-CSF-03` |
| nada no corpo do módulo além de declaração pura | `SB-CORE-06` |
| a story não depende de outra ter rodado antes | `SB-CORE-05` |

**`SB-CSF-04` é a que mais importa aqui**, e é pré-requisito do teste: estado embutido em `render` não é controlável por `args`, então o runner não consegue variá-lo e a tabela de docs não consegue documentá-lo. O teste fica preso a um caso.

---

## Passo 2 — Escrever a `play`

### 2.1 O contexto

```ts
play: async ({ args, canvas, userEvent, step, mount }) => { … }
```

`canvas` já vem com as queries do Testing Library escopadas na raiz da story — não é preciso `within(canvasElement)`. `userEvent` vem do contexto (e também existe em `storybook/test`).

### 2.2 As quatro regras que decidem quase tudo

| Regra | O que exige |
| --- | --- |
| `SB-TEST-01` | **todo** `expect` é `await` — sem isso a asserção não afirma nada e passa sempre |
| `SB-TEST-10` | se a story depende de assíncrono, a **primeira** query é `findBy…`, nunca `getBy…` |
| `SB-TEST-03` | callback de prop é `fn()` em `args`, e a asserção lê `args.onX` |
| `SB-TEST-08` | interação é `userEvent`, não disparo de evento na mão |

A `SB-TEST-10` é a que produz o flake clássico: `play` roda depois do **render**, não depois da **rede**. Numa story com MSW, `useQuery` ou `loader`, o instante em que a `play` começa é o de carregando — `getByRole` é síncrono e falha ali. Passa na máquina rápida, falha em CI.

### 2.3 `mount`, quando é obrigatório

Se há código a rodar **antes** do render — fixar o relógio, semear dado, montar com props próprias — é obrigatório desestruturar `mount` e chamá-lo (`SB-TEST-02`). Sem isso, o Storybook já começou a renderizar e o setup chega tarde.

### 2.4 `step` e o que asseverar

`step` agrupa interações sob rótulo e é o que torna o painel de Interactions legível.

E o corte: **`play` assevera o que o usuário observa, nunca implementação interna** (`SB-TEST-09`). Contagem de render, estado de hook, chamada de função interna — nada disso. Query por papel ou rótulo acessível quando existir (`SB-TEST-06`).

---

