# As invariantes do binário

| Confira | Regra |
| --- | --- |
| código que usa o global `Bun` roda sob o processo `bun` | `BUN-CORE-01` |
| há `tsc --noEmit` no CI — **o runtime transpila sem checar tipo** | `BUN-CORE-02` |
| módulo com top-level `await` não é carregado por `require` | `BUN-CORE-04` |
| automação usa `bun run <script>`, na forma explícita | `BUN-CORE-06` |
| flag de runtime vem **antes** do subcomando | `BUN-CORE-07` |

**`BUN-CORE-02` é a que mais custa:** Bun transpila TypeScript e **não checa tipos**. Sem `tsc --noEmit` no CI, o projeto tem tipos decorativos — o erro de tipo só aparece quando o valor errado chega em runtime.

**E `BUN-CORE-03`:** adicionar `jest`, `ts-node`, `nodemon` ou `dotenv` exige justificar por que o equivalente embutido não serve. Os quatro já existem no binário.

---

