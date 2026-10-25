# Tailwind skills: setup, migrate, build, split variants, review

Five skills, one directory each. Most Tailwind defects live in the **configuration** and show up in the **markup**: a config nobody loads turns into "arbitrary" colors three files away.

| Skill | Question it answers | Owns the docs |
| --- | --- | --- |
| `tailwind-setup` | how does Tailwind enter this build, with which tokens and dark mode? | [Installation and Detection](tailwind-setup/docs/tailwindcss-installation-and-detection.md), [Theme and Tokens](tailwind-setup/docs/tailwindcss-theme-and-tokens.md) |
| `tailwind-migrate` | how does this project move from line 3 to 4 without silent visual changes? | [Migration v3 to v4](tailwind-migrate/docs/tailwindcss-migration-v3-to-v4.md) |
| `tailwind-build` | which classes does this component get, and where does each value come from? | [Utilities and Variants](tailwind-build/docs/tailwindcss-utilities-and-variants.md), [Components and Composition](tailwind-build/docs/tailwindcss-components-and-composition.md) |
| `tailwind-split-variants` | in a project that keeps styles apart, how do this component's `cva`/`tv` variants move to `<name>.variants.ts`? | none: a pure move, rules from `rules.md` |
| `tailwind-review` | does this Tailwind lie, in the config or in the markup? | [Tailwind CSS](tailwind-review/docs/tailwindcss.md) (hub, `TW-CORE-*`) |

The rules are written for line 4. On a project that stays on 3.x only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*` apply.

## Layout

- **Docs live inside the skill that owns them** (`<skill>/docs/`), not in the tc96 `knowledge-base/`. A link between notes owned by different skills is a name in a code span, so every skill packages alone.
- **`references/rules.md`** in every skill holds all 77 `TW-*` rules, one table row each, with the note and section that owns it. Skills grep it by ID instead of loading notes. It is generated:

  ```bash
  bash skills/tailwind/tailwind-setup/scripts/generate-id-map.sh
  ```

- **Context7 is a fallback**, not a first step: the docs were verified on 2026-10-02 against `tailwindcss` 4.3.3, and a skill queries Context7 only for a newer version or a fact the docs lack.

## Scripts

| Script | Used by | What it does |
| --- | --- | --- |
| `tailwind-setup/scripts/discover-line.sh` | setup, migrate, build, review | line (3, 4, MIXED), integration, entry stylesheet, and the contradictions that compile (`TW-CFG-08`, `TW-THEME-05/09`) |
| `tailwind-review/scripts/probes.sh` | review, migrate | probes S1 to S11, each hit with its ID |
| `tailwind-review/scripts/conflicts.py` | review, build, split-variants | two utilities on one property, which no build or linter in this stack catches |
| `tailwind-build/scripts/self-check.sh` | build | the self-check over the file just written |
| `tailwind-split-variants/scripts/split-variants.py` | split-variants | detects the convention, moves `cva`/`tv` and their types to the sibling file (dry run unless `--write`), checks the result |
| `tailwind-setup/scripts/generate-id-map.sh` | authoring | regenerates `references/rules.md` |

## Evals

Each skill has `evals/` in the `claude plugin eval` layout. The build does not ship them.

## Related

- [Skills index](../README.md)
- `react-developer` · `react-review`: the component around the classes
- `storybook-story`: one story per variant · `playwright-review`: a class is not a selector
