# Tailwind skills — setup, build, review

Three skills, one directory each. The split is **configure · write · audit**, and in
Tailwind it is deliberate: most defects live in the **configuration** and show up in the
**markup** — a config nobody loads turns into "arbitrary" colors three files away.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `tailwind-setup` | how does Tailwind enter this project's build, and with which tokens? | [Tailwind CSS - Installation and Detection](docs/tailwindcss-installation-and-detection.md) | 6 references + 2 scripts |
| `tailwind-build` | which classes does this component get, and from where does each value come? | [Tailwind CSS - Utilities and Variants](docs/tailwindcss-utilities-and-variants.md) | 6 references + 1 script |
| `tailwind-review` | does this Tailwind lie — in the config or in the markup? | [Tailwind CSS](docs/tailwindcss.md) | 5 references + 3 scripts |

**The rules are written for line 4.** On a project that stays on 3.x, only the
line-independent IDs apply (`TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*`) —
citing the others is an invalid finding.

## The docs travel with the family

The normative notes — the hub and its five satellites, with the 77 `TW-*` rules — live in
[`docs/`](docs/tailwindcss.md), not in the tc96 `knowledge-base/`. That is what lets
`tc96-tailwind` be enabled in a project that has nothing else from tc96:

| Layout | Where the docs are |
| --- | --- |
| this repository | `skills/tailwind/docs/` — the skills link to `../docs/` |
| the built plugin | `docs/tailwind/` at the plugin root — the build rewrites the links |
| `AGENTS.md` target | `skills/tailwind/docs/`, nested as here |

The docs cite tc96 notes (`Playwright - Locators`, `Storybook - Configuração e Builder`…)
**by name in a code span**, never by link: context when tc96 is installed, never a dependency.

## The script that defines the family

`tailwind-setup/scripts/discover-line.sh` — and the other two call it before any
prescription (`TW-CORE-01`).

It reads the line from `package.json` **and** from the entry stylesheet, and looks for the
contradictions that compile:

| It finds… | The symptom |
| --- | --- |
| a `tailwind.config.*` that no `@config` loads | its values never reach the CSS — no error (`TW-CFG-08`) |
| a `.dark` toggle with no `@custom-variant dark` | `dark:` follows the OS; the toggle does nothing (`TW-THEME-09`) |
| a plain `@theme` mapping to `var(--x)` | the token resolves at `:root`, not at the element (`TW-THEME-05`) |
| `package.json` on 3.x with `@import "tailwindcss"`, or the reverse | a migration stopped halfway (`LINE: MIXED`) |

## The other two scripts

| Script | Gap it closes |
| --- | --- |
| `tailwind-review/scripts/probes.sh` — S1 to S11 | the probes, with the ID each one feeds |
| `tailwind-review/scripts/conflicts.py` | two utilities on one property, the defect no build and no linter in this stack catches — shared by `tailwind-build`'s self-check |
| `tailwind-build/scripts/self-check.sh` | the self-check, run over the file just written |
| `tailwind-review/scripts/rule.sh` | a rule's text, satellite and section by ID — the three skills cite without loading the notes |

## The ID map

`id-map.md` is **generated** and identical across the three, by
`tailwind-setup/scripts/generate-id-map.sh`. It indexes the **77** `TW-*` by satellite and
section, plus § 6.2 of the hub: no aliases, and the four pairs that look like aliases and
remain citable.

```bash
bash skills/tailwind/tailwind-setup/scripts/generate-id-map.sh
```

## Related

- [Skills index](../README.md) · [Tailwind CSS](docs/tailwindcss.md) § 7 — the contract
- `react-developer` · `react-review` — the component around the classes
- `storybook-story` — one story per variant · `playwright-review` — a class is not a selector
