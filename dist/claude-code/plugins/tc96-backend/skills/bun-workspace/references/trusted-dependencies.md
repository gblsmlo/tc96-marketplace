# The rule that breaks the whole build

> **`trustedDependencies` REPLACES the default list. It does not extend it.**

Declaring one package there **turns off the install scripts of everything else** — `sharp`, `esbuild`, `better-sqlite3`, all of it. The symptom is not an install error: it is a binary that was never compiled, and the failure shows up at runtime, far from the cause.

```jsonc
// ✗ you just turned off the scripts for sharp, esbuild and the whole default list
"trustedDependencies": ["my-internal-package"]

// ✓ re-include what is still needed
"trustedDependencies": ["my-internal-package", "sharp", "esbuild"]
```

`BUN-PKG-04`. And `BUN-PKG-03` completes it: a PR that adds an entry there **must** carry the output of `bun pm untrusted` in its body, which shows which command will be executed. Allowing an install script is a security decision — the script runs with the permissions of whoever installs.

```bash
bun pm untrusted # what is blocked, and each one's command
```
