# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-workspace/scripts/sondas.sh.
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | `bun.lock` is committed | `BUN-PKG-01` |
| 2 | CI uses `bun ci` or `--frozen-lockfile` | `BUN-PKG-02` |
| 3 | if `trustedDependencies` was touched, the needed default list was re-included | `BUN-PKG-04` |
| 4 | the PR carries the output of `bun pm untrusted` | `BUN-PKG-03` |
| 5 | `--production` is not being used as cleanup | `BUN-PKG-05` |
| 6 | a shared version comes from a catalog | `BUN-PKG-06` |
| 7 | no `catalog:` in a package to be published | `BUN-PKG-07` |
| 8 | `overrides` is at the root | `BUN-PKG-08` |
| 9 | edits under `node_modules` went through `bun patch` | `BUN-PKG-09` |
| 10 | `linker` declared if the build depends on the layout | `BUN-PKG-10` |
| 11 | `bunx` in CI has a fixed version | `BUN-PKG-11` |
| 12 | the root is `"private": true` and lists no package dependency | `BUN-PKG-12` |

**The probes:**

```bash
bun pm untrusted # what is blocked, and by which command
bun install --frozen-lockfile # does the lock match package.json?
bun pm ls # is the resolved tree the expected one?
git status --short bun.lock # did the install rewrite the lock?
```

The last one is the most revealing after any change: if `bun.lock` changed and you did not expect it, some `package.json` was diverging.
