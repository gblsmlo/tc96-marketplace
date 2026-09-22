# What to replace with a double

> Step 5. The tree is § 4.2 of [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md); the body is
> [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md).

---

## The single question, before any choice

> **If the real dependency diverged from my double, should this test break?**

```
YES → do not replace it. Catching the divergence is the whole point (TS-CORE-03)
NO → replace it, and pick the right kind:
 just filling a parameter → dummy
 a canned response → stub
 an implementation that runs → fake (and declare the fidelity — TS-DUB-03)
 verifying THAT it was called → mock or spy
```

---

## Two rules that hold at any level

- **Clock and randomness: always replace them** (`TS-DUB-05`). That is where determinism is
 bought cheaply, and it is the antidote to every wait on real time.
- **Server state: do not mock it — create it for real** through the API when there is an endpoint
 (`TS-CORE-03`, and `PW-NET-06` in `Docs/Playwright - Rede e Mocking.md`).

---

## The vocabulary decides the next question

A fake server **that works** is a **fake**, not a mock (`TS-DUB-01`). Naming it correctly makes
the question that decides everything appear on its own — *does it honor the real contract?*

A repository fake in place of a controlled database is `TS-DUB-08`: the fake passes, and the real
SQL breaks in production.

---

## Related

- [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) — the source
- [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) § 4.2 — the tree
- `arvore-de-nivel.md` — the level that came before
