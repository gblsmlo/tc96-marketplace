# Eden, and the three traps

### 6.1 `data` is `null` on any error

`ELYSIA-TYPE-08`: Eden's return **has `error` checked before `data`** — `data` is `null` on **any** status ≥ 300.

```ts
const { data, error } = await api.invoices.get;
if (error) throw error; // without this, data is null and the code carries on
```

### 6.2 Eden does not throw

`ELYSIA-TYPE-09`: a `queryFn`/`mutationFn` that calls Eden **has to throw** on error, or the client uses `throwHttpError: true`.

**This is the most expensive bug on the bridge with TanStack Query.** Without throwing, the query stays in **`success`** with the error inside `data`:

- `isError` stays `false`;
- the retry does not run;
- the Error Boundary does not catch;
- the UI renders the success state with null data.

```ts
// ✓
queryFn: async => {
 const { data, error } = await api.invoices.get;
 if (error) throw error;
 return data;
}
```

### 6.3 `parseDate` breaks structural sharing

`ELYSIA-TYPE-10`: an Eden client feeding a TanStack Query cache uses **`parseDate: false`**. A `Date` is a new object on every parse, so Query's structural sharing fails and **every component re-renders** on each refetch, even with no data change.

Symptom: an unexplained re-render in a list that did not change. See `Docs/TanStack Query - Cache e Frescor.md`.

### 6.4 Parity

`ELYSIA-APP-04` (canonical): `strict: true` and TS ≥ 5.0 on both sides. And `ELYSIA-TYPE-11`, for what is its alone: client and server resolve the **same version of `elysia`**. Different versions produce a type that compiles and does not correspond.

---


---

## Why all three are of the same nature

None of them breaks the build. All of them produce **wrong behavior with the right type**:

| Trap | What TypeScript says | What happens |
| --- | --- | --- |
| `data` without checking `error` | the type of `data` looks correct | `data` is `null` on any status ≥ 300 |
| a `queryFn` that does not throw | it compiles | the query stays in `success` with the error inside `data` |
| `parseDate: true` | it compiles | structural sharing breaks and the whole list re-renders |

The second is the most expensive because it switches off **four** mechanisms at once: `isError`, retry,
Error Boundary and the UI's error state.

## Related

- [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) § 6 — Eden in full
- `tanstack-query` — the cache on the other side of the bridge
- `Docs/TanStack Query - Cache e Frescor.md` — structural sharing
