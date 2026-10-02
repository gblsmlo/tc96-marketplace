# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-build/scripts/self-check.sh <file-or-dir>
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | no class name built by interpolation | `TW-SRC-01` |
| 2 | no two utilities on the same property — on the element or inside `cn` | `TW-UTIL-01`, `TW-COMP-02` |
| 3 | no line-3 name or syntax | `TW-CORE-02`, `TW-MIG-*` |
| 4 | no arbitrary color — the token | `TW-THEME-04` |
| 5 | no arbitrary property that duplicates a utility | `TW-UTIL-04` |
| 6 | no inline style with a static value | `TW-UTIL-05` |
| 7 | an outline removed has a `focus-visible:` replacement | `TW-A11Y-01` |
| 8 | the focus ring is on `focus-visible:` | `TW-A11Y-02` |
| 9 | animation respects `motion-reduce:`/`motion-safe:` | `TW-A11Y-05` |
| 10 | `className` passed **last** to the merge | `TW-COMP-03` |
| 11 | design-system component uses semantic tokens | `TW-THEME-11` |
| 12 | mobile is the unprefixed style | `TW-VAR-01` — reading |
| 13 | a design variation is a variant | `TW-COMP-06` — reading |
| 14 | icon-only controls have a name; nothing only through `hover:` | `TW-A11Y-03`, `TW-A11Y-08` — reading |

**The three worth most:** 1 (it fails far from the cause), 2 (it fails silently and by stylesheet order) and 7 (it removes the keyboard user's only cue).

**Then render it, light and dark.** The build passing proves nothing (`TW-CORE-04`).
