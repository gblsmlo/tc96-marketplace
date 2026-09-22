# O Eden, e as três armadilhas

### 6.1 `data` é `null` em qualquer erro

`ELYSIA-TYPE-08`: o retorno do Eden **tem `error` verificado antes de `data`** — `data` é `null` em **qualquer** status ≥ 300.

```ts
const { data, error } = await api.faturas.get();
if (error) throw error;      // sem isso, data é null e o código segue
```

### 6.2 O Eden não lança

`ELYSIA-TYPE-09`: `queryFn`/`mutationFn` que chama Eden **precisa lançar** em caso de erro, ou o cliente usa `throwHttpError: true`.

**Este é o bug mais caro da ponte com o TanStack Query.** Sem lançar, a query fica em **`success`** com o erro dentro de `data`:

- `isError` fica `false`;
- o retry não roda;
- o Error Boundary não pega;
- a UI renderiza o estado de sucesso com dado nulo.

```ts
// ✓
queryFn: async () => {
  const { data, error } = await api.faturas.get();
  if (error) throw error;
  return data;
}
```

### 6.3 `parseDate` quebra structural sharing

`ELYSIA-TYPE-10`: cliente Eden que alimenta cache do TanStack Query usa **`parseDate: false`**. `Date` é objeto novo a cada parse, então o structural sharing do Query falha e **todo componente re-renderiza** a cada refetch, mesmo sem mudança de dado.

Sintoma: re-render inexplicável numa lista que não mudou. Ver [[TanStack Query - Cache e Frescor]].

### 6.4 Paridade

`ELYSIA-APP-04` (canônico): `strict: true` e TS ≥ 5.0 nos dois lados. E `ELYSIA-TYPE-11`, pelo que é só dele: cliente e servidor resolvem a **mesma versão de `elysia`**. Versões diferentes produzem tipo que compila e não corresponde.

---


---

## Por que as três são da mesma natureza

Nenhuma quebra o build. Todas produzem **comportamento errado com tipo certo**:

| Armadilha | O que o TypeScript diz | O que acontece |
| --- | --- | --- |
| `data` sem checar `error` | tipo do `data` parece correto | `data` é `null` em qualquer status ≥ 300 |
| `queryFn` que não lança | compila | a query fica em `success` com o erro dentro de `data` |
| `parseDate: true` | compila | structural sharing quebra e a lista re-renderiza inteira |

A segunda é a mais cara porque desliga **quatro** mecanismos de uma vez: `isError`, retry,
Error Boundary e o estado de erro da UI.

## Relacionados

- [[Elysia - Schema e Eden]] § 6 — o Eden completo
- [[tanstack-query]] — o cache do outro lado da ponte
- [[TanStack Query - Cache e Frescor]] — structural sharing
