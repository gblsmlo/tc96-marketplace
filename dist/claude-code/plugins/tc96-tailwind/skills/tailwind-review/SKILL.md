---
name: tailwind-review
description: Audit existing Tailwind CSS usage — configuration and markup — with eleven executable probes before reading code, a scan in the order that fails most, severity classification and findings with `TW-*` IDs and file:line — use when the task is reviewing a PR, component, screen or whole repository that uses Tailwind, hunting for a class built by interpolation, two utilities fighting on one element, a v3 name that compiles to another value, a `tailwind.config` nobody loads, a token missing in dark mode, raw palette colors in the design system, `cn` hiding an internal conflict, an outline removed with no focus style, or a utility class used as a test selector. Do not use to write new classes, which is tailwind-build, nor to install, configure or migrate, which is tailwind-setup.
fonte: "[Tailwind CSS](../../docs/tailwind/tailwindcss.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /websites/v3_tailwindcss
  - /dcastil/tailwind-merge
tags:
  - skill
  - tailwindcss
  - frontend
  - code-review
---

# tailwind-review

> **Source of this skill:** [Tailwind CSS](../../docs/tailwind/tailwindcss.md) — § 6 (`TW-CORE-*`), § 6.1 with the satellites' critical rules, and § 6.2 with the pairs that look like aliases. The body of each family lives in the satellite that owns the ID.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan, how to classify and how to report.
> **API surface:** resolve it through Context7 — `/tailwindlabs/tailwindcss.com` (or `/websites/v3_tailwindcss` on line 3). Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Tailwind CSS](../../docs/tailwind/tailwindcss.md) § 7.

---

## When to use

Auditing Tailwind that **already exists**: a PR's diff, a component, a directory, the whole repository.

| Situation | Go to |
| --- | --- |
| writing or rewriting the classes | `tailwind-build` |
| the fix is configuration or migration | `tailwind-setup` |
| the React inside the component (state, Effects, Hooks) | `react-review` |
| a Playwright locator tied to a class | `playwright-review` — the finding is `PW-LOC-01` |

---

## API lookups — Context7 first

**Context7 first.** Any API fact this skill needs — whether a utility exists, a directive's options, what changed in a version — comes from a Context7 query, not from memory and not from a docs URL. The knowledge base gives the **rule and the ID**; Context7 gives the **signature for the installed version**. If they disagree, the source wins and the note is a bug to report.

**Every finding that says "does not exist", "was renamed" or "behaves differently in this version" MUST be confirmed with a Context7 query** for the project's line before it is reported. Memory is how a v3 habit becomes a false finding.

**When Context7 is not available**, the knowledge base is the fallback, not a reason to drop the finding: its rules were verified against the official docs on the date in each note's `verificado-em:`. Report the finding with its normal severity, and say once, in "not verified", that the version facts come from the knowledge base dated that day. Only a claim that is in **neither** — your own memory — stays out of the findings.

| Question | Context7 library | Topic to query |
| --- | --- | --- |
| is this class valid in the installed version? | `/tailwindlabs/tailwindcss.com` (line 4) · `/websites/v3_tailwindcss` (line 3) | the utility's name |
| was it removed or renamed, and which default changed? | `/tailwindlabs/tailwindcss.com` | `upgrade guide` |
| how does the merge resolve this pair? | `/dcastil/tailwind-merge` | `features` · `limitations` |
| what does shadcn/ui expect in `components.json` or the theme? | `/shadcn-ui/ui` | `components.json` · `tailwind v4` |

---

## Minimum loading

**Cite without loading.** The probes already print the ID next to each hit. To confirm a rule's exact text, its satellite and its section, run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/rule.sh TW-SRC-01 TW-UTIL-01   # or a family: TW-A11Y
```

That is enough to write a finding. Open a satellite **section** — never the whole note — only when a finding needs the reasoning behind the rule, not just its text.

| Order | Load | When |
| --- | --- | --- |
| 1 | the probe output and `rule.sh` | always — this is the whole citation layer |
| 2 | [Tailwind CSS](../../docs/tailwind/tailwindcss.md) § 6.2 | only if a finding sits on one of the four pairs that look like aliases |
| 3 | the one satellite section `rule.sh` names | only for a finding whose **why** you cannot state from the rule line |

**Never load the hub whole, the ID map, or a satellite whole.** The ID map stays as the index for humans; `rule.sh` reads the rule straight from the satellite that owns it.

References in this skill:

| File | What for |
| --- | --- |
| `references/probes.md` | the eleven probes, the three mandatory stops, and what they do not catch |
| `references/scan-order.md` | the nine levels, in the order that fails most |
| `references/severity-and-report.md` | classification, the finding format, the cut, the closing |
| `references/antipatterns.md` | the grid, with ID and satellite |
| `references/id-map.md` | the 77 `TW-*` by satellite and section |
| `references/example-audit.md` | a whole audit, from the probe to the "not verified" |
| `scripts/probes.sh` | runs the eleven probes |
| `scripts/conflicts.py` | the conflict detector S4 uses (`TW-UTIL-01`, `TW-COMP-02`) |
| `scripts/rule.sh` | prints a rule's text, satellite and section by ID — cite without loading the note |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/probes.sh src .
```

**Three mandatory stops:**

| Probe | If it shows… | Why |
| --- | --- | --- |
| S1 | `LINE: 3` | from here on, **only** the line-independent IDs are findings; the rest goes to a separate migration recommendation |
| S1 | `LINE: MIXED` | a migration stopped halfway — that is the first finding, and it explains the others |
| S1 | a `tailwind.config` **nothing loads** | every value in it is absent from the CSS: the classes that depend on it are dead (`TW-CFG-08`) |

And two that hide best — report them first among the markup findings: **S2** (class built by interpolation, `TW-SRC-01`) and **S4** (conflicting utilities, `TW-UTIL-01` / `TW-COMP-02`).

---

## Step 2 — Scan in the order that fails most

`references/scan-order.md`: the line and the stylesheet → what the scanner cannot see → conflicts → line-3 leftovers → accessibility → tokens and dark mode → composition and merge → arbitrary values → style.

**Then read what no probe reads:** icon-only controls (`TW-A11Y-03`), `sm:` used to mean "mobile" (`TW-VAR-01`), information reachable only through `hover:` (`TW-A11Y-08`), a design variation passed through `className` (`TW-COMP-06`).

---

## Step 3 — Classify and report

`references/severity-and-report.md`. **Blocking** is what makes the CSS lie — a class that is never generated, a config nobody loads, a toggle that does nothing. **High** is what users with a keyboard, a screen reader or the dark theme hit today. **Medium** is debt that breaks on the next change.

For a probe, **the evidence is the command's output** — paste the line, not the whole block.

**Keep the report compact:** the full block only for Blocking and High; Medium and Low are **one line each**. The reader acts on the first two; the rest is a list.

**Three things are not findings:** class **order** (`TW-TOOL-02`), an arbitrary value used once for a pixel adjustment, and a line-4 rule cited against a project that stays on line 3.

---

## Step 4 — Closing

1. **Turn a probe into a gate** where it can be one — the IntelliSense lints, a CI grep for `-\$\{`, the discovery script in the PR template.
2. **Separate "configuration" from "markup"** — the first is fixed once in `tailwind-setup`, the second file by file.
3. **Order by severity**, not by file.
4. **Declare what was not verified** — always: the rendered result, light and dark (`TW-CORE-04`).
5. **If the fix is writing classes**, the source becomes `tailwind-build`.

---

## Example

A PR adding an order card: CI green, screenshots attached. The probes find a `Badge` with `` `bg-${tone}-100` `` (it only "works" because the color appears in another file), `cn('p-4', compact && 'p-2')`, `focus:outline-none` with no replacement and a `--warning` token missing in `.dark`. One blocking, two high, one medium; "the class order is messy" is not reported.

Full audit: `references/example-audit.md`.

---

## Related

- [Tailwind CSS](../../docs/tailwind/tailwindcss.md) — source of this skill: § 6, § 6.1, § 6.2, § 7
- `tailwind-build` · `tailwind-setup` — the sibling skills
- `react-review` — the component around the classes · `playwright-review` — class as selector
