---
titulo: Bun - Package Manager
Link: https://bun.com/docs/pm/cli/install
tags:
  - bun
  - package-manager
  - agent-context
source: "Official documentation — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Package Manager

> `bun install` and what it does differently from npm/pnpm · `bun.lock` and the decision to commit it · `bun ci`, `--frozen-lockfile` and what it does **not** protect · lifecycle scripts and `trustedDependencies` · `configVersion` and the hoisted × isolated linker · the isolation that a migration from pnpm loses in silence · workspaces, catalogs and `--filter` · `overrides`/`resolutions` · `bun patch` · `bun outdated`/`why`/`audit`/`pm` · `bun x` × `bunx`.
>
> **Does not cover:** script execution and runtime flags ([Bun - Runtime and APIs](bun-runtime-and-apis.md)) · `bun build` and bundling ([Bun - Bundler and Build](bun-bundler-and-build.md)) · `bun test` ([Bun - Tests](bun-tests.md)) · image publishing and deploy ([Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)).

Entry: [Bun](bun.md) · Normative base: [Bun](bun.md) § 6

---

## 1. Concept: the lockfile is a reproducibility artifact, and trusting an install script is a security decision

A package manager makes two decisions that the team inherits without discussing, and both turn into incidents when they stay implicit.

**The first is reproducibility.** If the lockfile is not versioned, or if the CI command is `bun install` instead of `bun ci`, then "the version that passed CI" and "the version that went to production" are two things nobody guaranteed to be the same. Bun does not force this: the source says explicitly that *"Bun does not enable `--frozen-lockfile` automatically in CI"*. Whoever comes from `npm ci` assumes the opposite and spends months without noticing.

**The second is executing third-party code on your machine.** `postinstall` is an arbitrary shell script that a transitive package can declare, and it is the vector of a good share of recent supply chain attacks. Here Bun takes a position distinct from its competitors, and it is the most important point of this note:

> "Because running arbitrary code is a security risk, Bun does not execute arbitrary lifecycle scripts by default, unlike other `npm` clients."

The default is safe. What is not safe is the reflex gesture of working around the block when a package "does not work after installing" — because working around means authorizing code execution, and the authorization has a scope gotcha that § 4 details.

The rest of the note is operational. These two paragraphs are what needs to survive a PR review.

---

## 2. `bun install`: what it does, and what it does not

```bash
bun install                      # installs everything
bun add zod                      # dependency
bun add -d @types/bun            # devDependency  (--dev)
bun add --peer react             # peerDependency
bun add --exact zod              # no ^ in the range
bun remove lodash
bun update                       # respecting the ranges in package.json
bun update --latest              # crossing major
```

What `bun install` does, verified in the source:

- Installs `dependencies`, `devDependencies` and `optionalDependencies`. **Installs `peerDependencies` by default** — the same behavior as Yarn, different from npm in old versions.
- Runs the `{pre|post}install` and `{pre|post}prepare` scripts **of your own project**.
- Does **not** execute lifecycle scripts of the installed dependencies (§ 4).
- Writes `bun.lock` at the root.

Two scope flags that get confused:

| Flag | What it does | What it does **not** do |
| --- | --- | --- |
| `--production` | does not install `devDependencies`; **implies `--frozen-lockfile`** | does not remove devDependencies that are already in `node_modules` — for that, `bun prune --production` |
| `--omit dev\|peer\|optional` | excludes the indicated type, including in transitive dependencies | same |

**On the implication, because it appears written twice in a Dockerfile of this vault.** The source describes `production` mode (the flag and the `[install] production` key of `bunfig.toml`) as skipping `devDependencies` **and** freezing the lockfile. So `bun install --production --frozen-lockfile` is **redundant, not contradictory**: the second flag changes nothing. The redundancy in the Dockerfile of [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) is deliberate and worth keeping — it documents the reproducibility intent at the point where it is read, and survives someone swapping `--production` for `--omit dev` (which does **not** freeze the lockfile). If you prefer the short form, `--production` alone is enough.

Non-npm dependencies are declared in `package.json` like any other: `git+https://…`, `git+ssh://…#tag`, `github:owner/repo`, tarball URL, and alias with `npm:@types/bun`.

`bun install --filter` restricts the target in a monorepo (§ 6), and `--cpu`/`--os` force the target platform — the lockfile stores normalized `cpu` and `os`, so **it does not change between platforms** even when the installed packages change.

| ID | Rule |
| --- | --- |
| `BUN-PKG-05` | `--production` is **NEVER** treated as cleanup — it does not remove `devDependencies` already present in `node_modules`; use `bun prune --production`. |

---

## 3. Lockfile: `bun.lock` is text, and the CI command is not `bun install`

**The current state, verified:** the lockfile is called **`bun.lock`** and it is **textual**. It is the default **since Bun 1.2**. The previous binary format, `bun.lockb`, is still read, and the migration is a single command:

```bash
bun install --save-text-lockfile --frozen-lockfile --lockfile-only
rm bun.lockb
```

Third-party documentation and old answers still talk about `bun.lockb` and the ritual of configuring a git differ for it. That is legacy — with `bun.lock`, the diff is readable by default.

**Should it be committed?** The source answers in one word: *"Yes"*.

**Automatic migration.** Running `bun install` in a project without `bun.lock`, Bun converts `yarn.lock` (v1), `package-lock.json` (`lockfileVersion` 2, 3 or 4) and `pnpm-lock.yaml`. It does **not** migrate `package-lock.json` from npm 6 or earlier (`lockfileVersion` 1) — in that case it emits a warning and resolves from `package.json`, which means potentially different versions from the ones that were locked. The original lockfile is preserved.

**CI.** Two equivalent forms, and neither is the default:

```bash
bun ci                              # shortcut
bun install --frozen-lockfile       # identical
```

With `--frozen-lockfile`, Bun installs the exact versions from the lockfile and fails if `package.json` diverges.

**The bridge between the two statements that seem to contradict each other.** `--frozen-lockfile` checks one thing only: **the agreement between `package.json` and `bun.lock`**. It does not check that the lockfile exists. The two sentences below are the two halves of the same rule, and neither retracts the other:

| Situation in the checkout | What `--frozen-lockfile` does |
| --- | --- |
| `bun.lock` present and agreeing with `package.json` | installs the exact versions from the lockfile — the desired case |
| `bun.lock` present and **diverging** from `package.json` | **fails** — that is what the flag exists for |
| **No `bun.lock`** | resolves from `package.json` and installs, **without failing and without writing a lockfile** |

That is: the flag protects against divergence, not against absence. A repository that never committed `bun.lock` passes `bun ci` green, with versions resolved on the spot, and nobody is warned. That is exactly why `BUN-PKG-01` (commit the lockfile) is a separate rule from `BUN-PKG-02` (use `bun ci`): **one does not imply the other, and CI is only reproducible with both.** The CI example below closes the hole with an explicit guard.

Other verified details that matter:

- Works in a pruned monorepo checkout (output of `turbo prune`, partial Docker context): a workspace listed in the lockfile without a `package.json` on disk is skipped with a `note:`. If a remaining workspace depends on a skipped one, the install fails.
- To validate without installing: `bun install --frozen-lockfile --dry-run`.
- **In a full monorepo, `bun ci` installs all workspaces.** It is the behavior of `bun install` at the root — *"installs dependencies for all workspaces in the monorepo, de-duplicating packages if possible"* — and `bun ci` is equivalent to `bun install --frozen-lockfile`. To restrict, `--filter`.

```yaml
# .github/workflows/ci.yml
steps:
  - uses: actions/checkout@v4

  # Pinned Bun version: a doc whose argument is reproducibility cannot
  # install the package manager itself at a floating version. `bun-version` accepts
  # an exact version, "latest" or "canary"; without the input, the action resolves by
  # packageManager/engines.bun from package.json and falls back to "latest" if it finds none.
  - uses: oven-sh/setup-bun@v2
    with:
      bun-version: 1.3.14        # or: bun-version-file: .bun-version

  # Guard: --frozen-lockfile does NOT fail when the lockfile does not exist.
  - name: lockfile present
    run: test -f bun.lock || (echo "bun.lock missing — build is not reproducible" && exit 1)

  - run: bun ci
  - run: bun run build
```

The alternative to pinning the version in the YAML is declaring `"packageManager"` (or `"engines": { "bun": … }`) in `package.json` and using `bun-version-file`: the version then lives next to the code, versioned, and the YAML stops being a second place to update.

| ID | Rule |
| --- | --- |
| `BUN-PKG-01` | `bun.lock` **MUST** be versioned in the repository. |
| `BUN-PKG-02` | Installation in CI **MUST** be `bun ci` or `bun install --frozen-lockfile` — plain `bun install` rewrites the lockfile and does not fail on divergence. |

---

## 4. Lifecycle scripts and `trustedDependencies`: the security point of this note

Bun blocks dependency lifecycle scripts by default. It only runs those of packages on an **allow-list**.

### The three possible configurations, and the gotcha

The source is literal: *"Defining `trustedDependencies` in `package.json` **replaces** the default list rather than extending it."*

| `package.json` | Who may run a lifecycle script |
| --- | --- |
| `trustedDependencies` absent | the packages on Bun's built-in list — **only if installed from npm** |
| `trustedDependencies: ["pkg-a"]` | **only** `pkg-a`. The built-in list is ignored entirely. |
| `trustedDependencies: []` | **no** package — total opt-out without needing `--ignore-scripts` on every install |

The gotcha is the second row. A team that adds a single package to the list silently turns off the scripts of `sharp`, `esbuild` and everything else that **is** on the built-in list — the built-in list keeps existing and keeps being the default; declaring `trustedDependencies` is what discards it for that project. The symptom shows up far from the cause: a native binary that was not downloaded, a build failure with no obvious relation to `package.json`. When declaring the list, re-include whatever is still needed (`bun pm default-trusted` prints the built-in list in force).

The second verified detail: **the default list only applies to packages coming from npm**. `file:`, `link:`, `git:` or `github:` dependencies need an explicit entry in `trustedDependencies` even if the name matches an item on the built-in list — precisely to prevent a malicious package from passing itself off as a trusted one through a local path or git repository.

### The correct flow when a package needs `postinstall`

```bash
bun pm untrusted        # lists what was blocked, with the exact command of each script
```

```txt
./node_modules/@biomejs/biome @1.8.3
 » [postinstall]: node scripts/postinstall.js

These dependencies had their lifecycle scripts blocked during install.
```

Read the script. Then, one of the two:

```bash
bun pm trust @biomejs/biome     # runs now and adds to trustedDependencies
bun pm trust --all              # ← only with the whole list above reviewed
```

`bun pm untrusted` is the only surface that shows **the concrete command** you are authorizing. Approving without going through it is approving blind.

**Why the rule asks for the output pasted into the PR, and not "careful review".** A reviewer cannot distinguish a `trustedDependencies` that went through reading the script from one that went through `bun pm trust --all`: both produce the same `package.json` diff. Pasting the output of `bun pm untrusted` into the PR body turns the mental act into an artifact the reviewer sees and that stays in the history. That is what `BUN-PKG-03` requires, and it is verifiable: either the output is there, or it is not.

**Exit code of `bun pm untrusted`: not verified.** The doc describes the command as "print untrusted dependencies with scripts" and does not declare an exit code. Therefore **do not assume** that `bun pm untrusted` fails the pipeline when something was blocked — nor that it exits zero. If you need a CI gate that rejects an install with a blocked script, the verifiable path is comparing the output with a committed baseline:

```bash
# Fails if a blocked lifecycle script appeared that was not in the baseline.
bun pm untrusted > untrusted.atual.txt
diff -u untrusted.esperado.txt untrusted.atual.txt
```

The `diff` is what gives the exit code, and the baseline becomes a file reviewed in the PR — the same mechanism as the snapshot in [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 9. Confirm the real exit code behavior with `bun pm untrusted; echo $?` on your version before depending on it.

### Turning everything off

```bash
bun install --ignore-scripts
```

```toml
# bunfig.toml
[install]
ignoreScripts = true
```

Also accepted via `.npmrc` (`ignore-scripts=true`).

### The other supply chain control: `minimumReleaseAge`

Bun filters out versions published less than N seconds ago, which neutralizes the window in which a compromised package is published and pulled.

```toml
[install]
minimumReleaseAge = 259200                       # 3 days, in seconds
minimumReleaseAgeExcludes = ["@types/node", "typescript"]
```

Verified behavior: it affects only new resolution (what is already in `bun.lock` does not change), applies to direct and transitive dependencies, and brings a stability check — if several versions came out in quick succession right after the cutoff, Bun skips those and picks a more mature one, searching up to 7 days beyond the limit. An exact version request (`pkg@1.1.1`) respects the age but ignores the stability check.

For integration with a scanning service, there is the [Security Scanner API](https://bun.com/docs/pm/security-scanner-api).

| ID | Rule |
| --- | --- |
| `BUN-PKG-03` | A PR that adds an entry to `trustedDependencies` **MUST** contain, in its body, the output of `bun pm untrusted` showing the authorized command — without that artifact, the PR is rejected. |
| `BUN-PKG-04` | Declaring `trustedDependencies` **MUST** re-include the packages from the default list that are still needed — the declared list **replaces** the default. |

---

## 5. `node_modules` layout: hoisted × isolated

Bun has two linker strategies, and **the default varies** — it is the point that most surprises when creating a new project.

### `configVersion`: the field that decides the default without you knowing

Before the table, the term. `configVersion` is a field of **`bun.lock`**, written by **Bun itself** on the first install (or on migration from another package manager). It is not a setting you declare: you **consult** it, and for that it is enough to open the lockfile — it is text since 1.2:

```bash
grep configVersion bun.lock      # absent ⇒ treat as configVersion 0
```

It does not describe the file format (that is `lockfileVersion`, another field, § 7). It marks **in which generation of defaults the project was born**, and today its main effect is a single one: deciding the linker when you declared none.

| `configVersion` in the lockfile | Has workspaces? | Default linker |
| --- | --- | --- |
| `1` (new project) | yes | **`isolated`** |
| `1` | no | `hoisted` |
| `0` (project predating v1.3.2, or migrated from npm/yarn) | any | `hoisted` |

Migration coming from pnpm enters as `configVersion = 1`; coming from npm or yarn, `configVersion = 0`.

### Coming from pnpm in a single-package project, you lose the isolation and nobody warns you

Put the two previous rows together and out comes a case that bites exactly the most common profile — a single-package React app, migrated from pnpm:

1. The migration from pnpm writes `configVersion = 1`.
2. `configVersion = 1` **without workspaces** is born `hoisted`.
3. A single-package app has no workspaces.
4. Therefore: **the project goes from an isolated layout (pnpm) to a hoisted layout, silently.**

What this gives back to the project is the *phantom dependency*: an `import` of a package that `package.json` never declared starts to resolve, because the package was hoisted as a dependency of something else. Under pnpm that import failed on the spot; now it works — until the day the intermediate dependency bumps its version, swaps a transitive, and the import breaks somewhere unrelated to the change. It is the worst shape of error: whoever introduces it does not feel it, and whoever feels it has no clue.

The fix is one line, and it is the reason `BUN-PKG-10` exists:

```toml
# bunfig.toml — declare the linker; do not inherit the default
[install]
linker = "isolated"
hoist = false          # strict isolation, see the end of this section
```

After declaring, `rm -rf node_modules && bun install` to re-layout. A `bun install` over the old `node_modules` does not reorganize what is already on disk.

```bash
bun install --linker isolated
bun install --linker hoisted
```

**What changes.** The `isolated` mode is pnpm's model: a central store in `node_modules/.bun/<pkg>@<version>/` and symlinks in the top-level `node_modules`. A package only sees what it declared. The `hoisted` mode flattens everything into a shared directory, and with that allows *phantom dependencies* — importing a package you never declared, because it was hoisted as a dependency of something else.

| | Hoisted (npm/Yarn) | Isolated (pnpm model) |
| --- | --- | --- |
| Access to dependencies | anything hoisted | only the declared ones |
| Phantom dependencies | possible | prevented |
| Determinism | lower | higher |
| Compatibility with tools that scan `node_modules` | standard | may break |
| Best for | single project, legacy code | monorepo, library |

**Honest comparison with pnpm**, within what the source allows us to state: `isolated` is *"conceptually similar to pnpm"*, and the declared difference is that Bun uses symlinks inside the project's `node_modules`, while pnpm uses a global store with symlinks. Bun has a global virtual store (`install.globalStore`), but it is **off by default**; with it on, the doc reports a warm install about **7× faster** after `rm -rf node_modules` in a mid-sized project. On install speed in general, the number the source publishes is the Remix monorepo installed in about 500 ms on Linux, *"8x faster than pnpm install"* — the vendor's own benchmark, useful as an order of magnitude and not as a measurement of your project.

**An isolation detail that goes unnoticed.** By default, even in `isolated` mode, Bun creates `node_modules/.bun/node_modules` with a symlink to every installed package. Since that directory is an ancestor of all store entries, a package **can still** resolve something it did not declare. For strict isolation:

```toml
[install]
linker = "isolated"
hoist = false          # equivalent to pnpm's hoist=false
```

The caveat, shared with pnpm and declared in the source: the root `node_modules` is also an ancestor of the store, so your direct dependencies and the workspace packages remain resolvable from anywhere.

| ID | Rule |
| --- | --- |
| `BUN-PKG-10` | A project whose build depends on the `node_modules` layout **MUST** declare `linker` explicitly in `bunfig.toml` — the default varies with `configVersion` and with the presence of workspaces. |

---

## 6. Monorepo: workspaces, catalogs and `--filter`

### Workspaces

```json
{
  "name": "loja",
  "private": true,
  "workspaces": ["packages/**", "!packages/**/template/**"]
}
```

**Two prescriptions from the source about the root, and the reason for each.** The monorepo guide is explicit: the root *"should not contain `dependencies`, `devDependencies`, or other dependency fields"*, and it is convention to declare `"private": true`. They are not style:

- **Each package declares itself** because that is what makes it movable and publishable. A dependency that lives only at the root works in the monorepo — via hoisting, or via the top-level `node_modules` that `isolated` mode keeps visible (§ 5) — and breaks on the day the package is extracted or published. It is a *phantom dependency* through the front door.
- **`private: true` at the root** prevents publishing the whole monorepo by accident. The failure is silent until `bun publish`, and then it is public.

> **Recorded tension.** The prescription is literal and has no caveat in the source, but repository tooling (`typescript`, `@types/bun`, linter) at the root is widespread practice, and this note's CI examples use it. The criterion that reconciles the two: **a dependency that some package's code imports** goes in that package's `package.json`, always; **a tool the repository runs** and no package imports may stay at the root. If it is in an `import`, it is not repository tooling.

Full glob is supported, including negative patterns. References between packages use the `workspace:` protocol:

```json
{ "name": "@loja/api", "dependencies": { "@loja/dominio": "workspace:*" } }
```

On publish, Bun substitutes: `workspace:*` → `1.0.1`, `workspace:^` → `^1.0.1`, `workspace:~` → `~1.0.1`; an explicit version (`workspace:1.0.2`) wins over the one in `package.json`.

**`bun add` inside a workspace writes to the two right places.** Run from inside the package directory, Bun detects the workspace, adds the dependency to **that package's** `package.json`, and updates the **root lockfile** — which is the monorepo's only lockfile (§ 3). No `--filter` and no hand-editing of `package.json` needed:

```bash
cd packages/api
bun add zod                      # goes into packages/api/package.json
```

Where the package is physically installed depends on the linker (§ 5): in `isolated`, which is the default for a new monorepo, it goes to the root's `node_modules/.bun/` store and is *symlinked* in the workspace's own `node_modules`; with `--linker hoisted`, it is hoisted to the root `node_modules`.

### Catalogs: the version declared once

The problem they solve: ten `package.json` repeating `"react": "^19.0.0"`, and one of them falling behind in an update.

```json
{
  "name": "loja",
  "workspaces": {
    "packages": ["packages/*"],
    "catalog":  { "react": "^19.0.0", "react-dom": "^19.0.0" },
    "catalogs": { "testing": { "@testing-library/react": "16.3.0" } }
  }
}
```

```json
{
  "name": "@loja/web",
  "dependencies":    { "react": "catalog:", "react-dom": "catalog:" },
  "devDependencies": { "@testing-library/react": "catalog:testing" }
}
```

Verified points:

- `catalog:` works in `dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies` and as the value of an `overrides` rule at the root. It behaves exactly as if the range were written there.
- `catalog` and `catalogs` also work at the **top level** of `package.json`, not only inside `workspaces` — but the source says this right after instructing to declare them *"in your root-level `package.json`"*, and **does not declare whether the top level works in a member package's `package.json`**. Treat it as: top level of the **root** `package.json`, verified; member, **not verified** — declare at the root and do not count on the opposite. What the source is explicit in restricting is the **reference**: `catalog:` only works in the `package.json` of the root and of the workspaces.
- `catalog:default` is the same as `catalog:`; declaring the same package in `catalog` and in `catalogs.default` is an error.
- `bun add react --catalog` adds to the root catalog and writes `"catalog:"` in the current package. Without the flag, `bun add react` (without a version) already writes `"catalog:"` when the default catalog lists `react`.
- **`catalog:` does not resolve inside a published package.** `bun publish` and `bun pm pack` replace it with the real range; publishing by any other path delivers a broken `package.json` to the consumer.

### `--filter`

```bash
bun install --filter './packages/api'       # installs only one workspace's deps
bun install --filter 'pkg-*' --filter '!pkg-c'
bun run --filter 'ba*' build                # runs the script in several packages
bun run --workspaces test                   # in all of them
```

The pattern accepts a package-name glob, a `./…` path, a `{dir}` directory and a dependency relation (`foo...`).

### What is root-only, what is per-workspace, and what was not verified

Half of the monorepo questions are about **where the field lives**. The source answers some clearly and is silent on others — and the silence is information, because a reader who answers by analogy gets some right and others wrong.

| Field / command | Scope | Status |
| --- | --- | --- |
| `overrides` / `resolutions` | **root only**; declared in a workspace it is ignored without error | verified — `BUN-PKG-08` |
| `catalog` / `catalogs` (declaration) | root, inside `workspaces` or at the top level | verified for the root |
| `catalog:` (reference) | `package.json` of the root and of the workspaces | verified |
| `workspace:` | `dependencies` of any member | verified |
| `bun install` / `bun ci` without `--filter`, at the root | installs **all** workspaces, deduplicating | verified |
| `bun.lock` | a single one, at the root | verified |
| `trustedDependencies` | — | **not verified** |
| `bunfig.toml` in a monorepo | — | **not verified** ([Bun - Runtime and APIs](bun-runtime-and-apis.md) § 9) |

**`trustedDependencies` in a monorepo — not verified, and do not deduce it from `overrides`.** The lifecycle scripts doc describes the field as "an allow-list in `package.json`" and does not say whether, in a monorepo, it is read from the root, from the workspace, or from both. The analogy with `overrides` (root only) is tempting and **is not confirmed**. What to do in the meantime: declare at the root, run `bun pm untrusted` after the install and check that the list is empty — the command is the oracle, and it answers for the whole installation. If a script stays blocked with the entry at the root, it is a sign that the field is read from the workspace; record the finding.

**`tsc --noEmit` in a monorepo — not documented by Bun.** `BUN-CORE-02` requires the type check step because the runtime does not validate a single type, but Bun's source documents a single-project `tsconfig.json` and nothing about workspace layout. What **is** verified is where Bun's piece goes:

```jsonc
// tsconfig.json — the key belongs to compilerOptions, not to a top-level field
{
  "compilerOptions": {
    "types": ["bun"],          // required from TypeScript 6.0 on
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "noEmit": true
  }
}
```

`bun add -d @types/bun` installs the types. In a monorepo, **where** that `compilerOptions` lives (one tsconfig per package? a base at the root with `extends`? project references?) is a TypeScript configuration decision, outside the scope of Bun's `TypeScript` doc. What Bun's doc does **not** offer is a type check command that crosses workspaces: `bun run --filter '*' typecheck`, with a `typecheck` script in each package, is a composition of verified pieces (`--filter` + script), not a feature documented under that name.

| ID | Rule |
| --- | --- |
| `BUN-PKG-06` | A dependency version shared by more than one package of the monorepo **MUST** come from a catalog, not be repeated in each `package.json`. |
| `BUN-PKG-12` | The root `package.json` of a monorepo **MUST** declare `"private": true`, and **NEVER** list a dependency that some package imports — only tooling the repository runs. |
| `BUN-PKG-07` | `catalog:` **NEVER** reaches a published package — publishing **MUST** go through `bun publish` or `bun pm pack`. |

---

## 7. Controlling what you did not declare: `overrides` and `bun patch`

### `overrides` / `resolutions`

They pin the version of a **meta-dependency** — a dependency of a dependency. Both fields exist; `resolutions` is Yarn's form, kept for migration.

```json
{
  "overrides": {
    "semver@<7.5.2": "7.5.2",
    "micromatch>picomatch": "^2.3.2",
    "quux": "npm:@meuorg/quux@^1.0.0",
    "foo": "catalog:"
  }
}
```

Verified, and not obvious:

- **Bun only reads `overrides` from the root `package.json`.** Overrides declared in a workspace are ignored. They also apply to `peerDependencies`.
- The value can be any specifier: `npm:` to swap for a fork, `catalog:` to keep in sync, and `"$name"` to reuse the range you already declared for `name`.
- Parent-scoped forms: npm object with `"."`, pnpm form `parent>child`, and parent with range (`micromatch@^4>picomatch`). **One level only** — `a>b>c` is ignored with a warning.
- A version selector (`"semver@<7.5.2"`) compares against the range the dependent **declares**, not against the resolved version. A dependent that uses a dist-tag, `catalog:`, `workspace:`, git or URL never matches a selector.
- Nested rules or rules with a selector make the lockfile be written as `lockfileVersion` 3, which old Bun versions do not read.

### `bun patch`

Changing a package in `node_modules` without vendoring it.

```bash
bun patch react                     # 1. prepares: real clone, no symlink/hardlink
# edit node_modules/react/…         # 2. test locally
bun patch --commit react            # 3. generates patches/react@19.x.patch + package.json + lockfile
```

Step 1 is not optional and the source's warning is explicit: without it, *"you might end up editing the package globally in the cache"* — the edit leaks to every project on the machine. `bun patch` exists precisely to preserve the integrity of the global cache; the resulting patch lives in `patches/`, is tracked in `"patchedDependencies"` and must be committed.

| ID | Rule |
| --- | --- |
| `BUN-PKG-08` | `overrides`/`resolutions` **MUST** be in the root `package.json` — Bun ignores those declared in a workspace. |
| `BUN-PKG-09` | Editing a package in `node_modules/` **MUST** be preceded by `bun patch <pkg>`; direct editing corrupts the global cache. |

---

## 8. Inspecting: `outdated`, `why`, `audit`, `pm`

```bash
bun outdated                 # table Current | Update | Latest
bun outdated 'eslint*'       # accepts glob
bun why react                # chain that brought the package in
bun audit                    # known vulnerabilities
bun pm ls                    # resolved dependencies
bun pm untrusted             # blocked lifecycle scripts  ← § 4
bun pm cache rm              # clears the global cache
bun pm migrate               # converts another PM's lockfile without installing
```

Two readings that save time:

- In `bun outdated`, **`Update` ≠ `Latest`**. `Update` is the highest that satisfies the `package.json` range; `Latest` is the one published in the registry. A row where the two differ is the one that requires changing the range (major), and it is the only one worth discussing.
- `bun audit` reads the package list **from `bun.lock`**, without needing `node_modules`, and modifies nothing. Filters: `--audit-level=<low|moderate|high|critical>`, `--prod`, `--omit=<dev|optional|peer>`, `--ignore <GHSA-…>`. With `--json`, the output is the raw registry response — `--audit-level` and `--ignore` affect only the exit code, not the JSON. `bun audit fix` applies fixes within the ranges; `bun audit fix --latest` crosses major.

---

## 9. `bun x` / `bunx`: running without installing

`bunx` is an alias of `bun x`, and it is installed together with `bun`. It looks first for the locally installed package and, if it does not find it, installs into the global cache.

```bash
bunx prettier --write .
bunx uglify-js@3.14.0 app.js       # pinned version
bunx -p @angular/cli ng new app    # binary with a name different from the package
bunx --bun vite                    # forces the Bun runtime in the CLI
```

Two things people get wrong:

- **`--bun` comes before the executable name.** After the name, everything is forwarded to the package: `bunx my-cli --bun` passes `--bun` to `my-cli`.
- **Without a pinned version, `bunx <pkg>` resolves the latest compatible one.** In a CI pipeline that is an unlocked dependency running with the runner's permissions. Pin it (`bunx pkg@1.2.3`) or declare it as a devDependency and call it through `bun run`.

| ID | Rule |
| --- | --- |
| `BUN-PKG-11` | A `bunx` invocation in CI or in a versioned script **MUST** pin the package version, or the package **MUST** be a devDependency called through `bun run`. |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `bun install` as the CI command | locks nothing: rewrites `bun.lock` and passes even with a divergent `package.json` | `bun ci` — `BUN-PKG-02` |
| `bun.lock` in `.gitignore` | without a lockfile, `--frozen-lockfile` installs from `package.json` **without failing**; the build silently stops being reproducible | commit it — `BUN-PKG-01` |
| `bun pm trust --all` to "unblock the install" | authorizes execution of an arbitrary shell script from every blocked package, without reading any | `bun pm untrusted`, read, and trust one by one — `BUN-PKG-03` |
| `trustedDependencies: ["meu-pacote"]` and nothing else | replaces the default list; `sharp`, `esbuild` and the like stop running their scripts, with the symptom far from the cause | re-include what is needed (`bun pm default-trusted`) — `BUN-PKG-04` |
| `bun install --production` expecting a lean `node_modules` | does not remove what was already there; the image keeps carrying devDependencies | `bun prune --production`, or install in a clean layer — `BUN-PKG-05` |
| The same React version repeated in eight `package.json` | one update forgets a package and the monorepo ends up with two copies of React | catalog at the root — `BUN-PKG-06` |
| Publishing a workspace package with `"react": "catalog:"` | `catalog:` does not resolve outside the monorepo; the consumer receives an invalid `package.json` | `bun publish` / `bun pm pack` — `BUN-PKG-07` |
| `overrides` in a workspace's `package.json` | Bun only reads those at the root; the rule is ignored without error and the vulnerable package stays installed | move to the root — `BUN-PKG-08` |
| Editing `node_modules/<pkg>` and then running `bun patch --commit` | without the initial `bun patch <pkg>`, the edit may happen in the global cache and contaminate other projects | `bun patch <pkg>` first — `BUN-PKG-09` |
| `bunx <tool>` without a version in a pipeline | runs unlocked code with the runner's permissions; today's build is not yesterday's | pin the version or declare as a devDependency — `BUN-PKG-11` |
| Assuming `bun.lockb` because third-party documentation says so | the textual format is the default since 1.2; old instructions lead to configuring a git differ for a file that no longer exists | `bun.lock`; migrate with `--save-text-lockfile` |
| Migrating from npm 6 and trusting that the versions were preserved | `lockfileVersion` 1 is **not** migrated — Bun warns and resolves from `package.json` | update npm and regenerate the lockfile first, or review `bun outdated` after the migration |
| `bun ci` in CI as the only reproducibility guarantee | without `bun.lock` in the repository, `--frozen-lockfile` resolves from `package.json` and passes green | `test -f bun.lock` before the install — § 3, `BUN-PKG-01` + `BUN-PKG-02` |
| `oven-sh/setup-bun@v2` without `bun-version` in a doc about reproducibility | the action falls back to `latest`; the package manager that locks everything is itself not locked | `bun-version: <exact>` or `bun-version-file` — § 3 |
| Migrating a single-package app from pnpm and not declaring `linker` | `configVersion = 1` **without workspaces** is born `hoisted`; pnpm's isolation disappears and phantom dependency comes back | `[install] linker = "isolated"` + `rm -rf node_modules` — § 5, `BUN-PKG-10` |
| Assuming that `trustedDependencies` at the root covers the workspaces | not declared by the source; the analogy with `overrides` is not confirmed | declare at the root and **check with `bun pm untrusted`** — § 6 |
| Using `bun pm untrusted` as a CI gate counting on the exit code | the source declares no exit code for the command | compare the output with a committed baseline (`diff`) — § 4 |

---

## Review checklist

- [ ] Is `bun.lock` versioned? → `BUN-PKG-01`
- [ ] Is the CI command `bun ci` (or `--frozen-lockfile`)? → `BUN-PKG-02`
- [ ] Does every new entry in `trustedDependencies` have a justification in the PR? → `BUN-PKG-03`
- [ ] Does the declared list re-include the packages from the default list that are still needed? → `BUN-PKG-04`
- [ ] Is `bun pm untrusted` clean, or is what remains a conscious decision?
- [ ] Is the use of `--production` accompanied by `bun prune`, when the goal is reducing the image? → `BUN-PKG-05`
- [ ] Are the monorepo's shared versions in a catalog? → `BUN-PKG-06`
- [ ] Does no `catalog:` escape into a published package? → `BUN-PKG-07`
- [ ] Are `overrides` at the root? → `BUN-PKG-08`
- [ ] Is `patches/` committed and does `"patchedDependencies"` match it? → `BUN-PKG-09`
- [ ] Is `linker` declared when the build depends on the layout? → `BUN-PKG-10`
- [ ] Is `bunx` in CI at a pinned version? → `BUN-PKG-11`
- [ ] Was `minimumReleaseAge` considered as a supply chain defense?
- [ ] Does CI have a guard for the lockfile's **existence**, and not only `bun ci`? → § 3
- [ ] Is the Bun version in CI pinned (`bun-version` or `bun-version-file`)? → § 3
- [ ] Did a project migrated from pnpm declare `linker` explicitly? → § 5, `BUN-PKG-10`
- [ ] Was `bun pm untrusted` run **after** the install in a monorepo, to confirm where `trustedDependencies` was read from? → § 6

---

## Related

- [Bun](bun.md) — hub, API map, decision trees
- [Bun - Runtime and APIs](bun-runtime-and-apis.md) · [Bun - Tests](bun-tests.md) · [Bun - Bundler and Build](bun-bundler-and-build.md) · [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)
- `Node.js` · `TypeScript`
- — the neighboring boundary of secrets in build

## Sources consulted

Verified on **2026-08-15**:

- [Configuring a monorepo using workspaces](https://bun.com/guides/install/workspaces) — guide, with [example project](https://github.com/colinhacks/bun-workspaces)
- [bun install](https://bun.com/docs/pm/cli/install) · [bun add](https://bun.com/docs/pm/cli/add) · [bun update](https://bun.com/docs/pm/cli/update)
- [Lockfile](https://bun.com/docs/pm/lockfile) · [Lifecycle scripts](https://bun.com/docs/pm/lifecycle)
- [Isolated installs](https://bun.com/docs/pm/isolated-installs) · [Global virtual store](https://bun.com/docs/pm/global-store)
- [Workspaces](https://bun.com/docs/pm/workspaces) · [Catalogs](https://bun.com/docs/pm/catalogs) · [bun --filter](https://bun.com/docs/pm/filter)
- [Overrides and resolutions](https://bun.com/docs/pm/overrides) · [bun patch](https://bun.com/docs/pm/cli/patch)
- [bun outdated](https://bun.com/docs/pm/cli/outdated) · [bun why](https://bun.com/docs/pm/cli/why) · [bun audit](https://bun.com/docs/pm/cli/audit) · [bun pm](https://bun.com/docs/pm/cli/pm)
- [bunx](https://bun.com/docs/pm/bunx) · [Security Scanner API](https://bun.com/docs/pm/security-scanner-api)
- [bunfig.toml — `[install]`](https://bun.com/docs/runtime/bunfig) · [TypeScript](https://bun.com/docs/typescript)
- Outside Bun's doc, for the CI action's version input: [oven-sh/setup-bun](https://github.com/oven-sh/setup-bun)

**What verification contradicted:**

- **Textual `bun.lock` is the default since Bun 1.2.** The binary `bun.lockb` is legacy, and a good share of third-party material still teaches configuring a git differ for it.
- **`bun install` does not become `--frozen-lockfile` in CI automatically.** The source says so explicitly and offers `bun ci`. The habit coming from `npm ci` produces the opposite assumption.
- **`--frozen-lockfile` with no lockfile at all does not fail** — it installs from `package.json`. That is, it does not protect against the lockfile's absence, only against divergence.
- **`trustedDependencies` replaces the default list.** Declaring one package turns off the whole built-in allow-list.
- **The default list of trusted packages only applies to npm origin.** `file:`, `link:`, `git:` and `github:` require an explicit entry, to prevent name spoofing.
- **The default linker depends on `configVersion` and on the presence of workspaces**, not on a single setting: a new monorepo is born `isolated`, a single-package project is born `hoisted`.
- **Even in `isolated`, `node_modules/.bun/node_modules` allows undeclared resolution** until `hoist = false` is turned on — and even then the root `node_modules` stays visible, a caveat the source says is shared with pnpm.
- **`overrides` is only read from the root**, and silently ignores those declared in workspaces.
- **npm's `lockfileVersion` 1 is not migrated**: Bun warns and resolves from `package.json`, which can swap versions without anyone asking.
- **Nested overrides or overrides with a version selector raise the lockfile to `lockfileVersion` 3**, unreadable by old Bun versions.
- **`bun install` installs `peerDependencies` by default** — Yarn's behavior, not old npm's.
- **`bun install` at the root installs all workspaces**, deduplicating — and `bun ci`, being equivalent to `bun install --frozen-lockfile`, inherits that. Restricting requires `--filter`.
- **`--production` already freezes the lockfile.** The source describes `production` mode as skipping `devDependencies` **and** freezing the lockfile, so `--production --frozen-lockfile` is redundant, not contradictory.
- **`configVersion` is written by Bun into `bun.lock`**, not declared by you, and it is different from `lockfileVersion`. The combination `configVersion = 1` + absence of workspaces is what makes a project migrated from pnpm fall into `hoisted`.
- **`"types": ["bun"]` goes inside `compilerOptions`**, and becomes required from TypeScript 6.0 on.

**What was not verified (declared, not invented):**

- **`trustedDependencies` in a monorepo**: root, workspace or both. The source does not declare it. Do not deduce it from `overrides`.
- **Exit code of `bun pm untrusted`**: not documented. Do not use it as a CI gate without confirming on your version.
- **`catalog`/`catalogs` at the top level of a member package's `package.json`**: the source states the top level in the context of the root `package.json` and does not extend the statement to members.
- **`bunfig.toml` in a monorepo**: whether there is inheritance or merging between root and workspace. Only the global × project pair is documented.
- **`tsconfig.json` layout in a monorepo**: outside the scope of Bun's doc. `bun run --filter '*' typecheck` is a composition of verified pieces, not a named feature.
