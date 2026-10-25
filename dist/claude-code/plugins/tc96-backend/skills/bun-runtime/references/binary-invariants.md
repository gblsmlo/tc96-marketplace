# The invariants of the binary

| Check | Rule |
| --- | --- |
| code using the `Bun` global runs under the `bun` process | `BUN-CORE-01` |
| there is `tsc --noEmit` in CI — **the runtime transpiles without type-checking** | `BUN-CORE-02` |
| a module with top-level `await` is not loaded by `require` | `BUN-CORE-04` |
| automation uses `bun run <script>`, in the explicit form | `BUN-CORE-06` |
| a runtime flag comes **before** the subcommand | `BUN-CORE-07` |

**`BUN-CORE-02` is the one that costs most:** Bun transpiles TypeScript and **does not type-check**. Without `tsc --noEmit` in CI, the project has decorative types — the type error only shows up when the wrong value arrives at runtime.

**And `BUN-CORE-03`:** adding `jest`, `ts-node`, `nodemon` or `dotenv` requires justifying why the built-in equivalent does not do the job. All four already exist in the binary.
