---
name: tailwind-review
description: Review Tailwind CSS config and markup: probes, TW-* findings, severity
source: "[Tailwind CSS](docs/tailwindcss.md)"
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

Audits Tailwind that already exists: a PR, a component, a directory, a repository. Writing classes is `tailwind-build`; a configuration fix is `tailwind-setup`; the React inside the component is `react-review`.

## 1. Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/probes.sh <src-dir> <project-root>
```

Probes S1–S11 print the ID next to each hit (`references/probes.md` explains each one and its false positives). In a PR, read only the diff's files but run S1 on the whole project.

Three mandatory stops in S1:

| S1 shows | Then |
| --- | --- |
| `LINE: 3` | only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*` are findings; the rest goes to a separate "if you migrate" list |
| `LINE: MIXED` | the half-finished migration is the first finding |
| a `tailwind.config` nothing loads | Blocking (`TW-CFG-08`); "arbitrary" colors may be workarounds for it, not separate findings |

## 2. Read what no probe reads

Icon-only controls without a name (`TW-A11Y-03`); `sm:` meant as "mobile" (`TW-VAR-01`); content reachable only on `hover:` (`TW-A11Y-08`); design variation passed through `className` at call sites (`TW-COMP-06`); a real list with `list-none` and no `role="list"` (`TW-A11Y-07`). For anything else, scan in the order of `references/scan-order.md`.

## 3. Classify

| Severity | Criterion |
| --- | --- |
| Blocking | the CSS lies: class never generated (`TW-SRC-01`), config or token nobody loads (`TW-CFG-08`), toggle that does nothing (`TW-THEME-09`), `LINE: MIXED` |
| High | a user is hurt today: focus removed (`TW-A11Y-01`), control without a name, token missing in `.dark` (`TW-THEME-13`), conflicting utilities (`TW-UTIL-01`) |
| Medium | debt: raw palette in the design system, merge hiding a conflict, `className` first, repeated arbitraries, `@apply` components, v3 names |
| Low | consistency: arbitrary property with a utility, `!`, unnamed group |

A `†` rule is never Blocking on its own. Not findings: class order (`TW-TOOL-02`), an arbitrary used once for a pixel, a line-4 rule on a project that stays on 3, a missing story.

## 4. Report

Two groups, configuration (fixed once, `tailwind-setup`) then markup (file by file), each ordered by severity. Blocking and High get the block; Medium and Low one line each:

```
[High] `TW-A11Y-01` — src/components/ui/button.tsx:4
What: focus:outline-none, no replacement.
Why: keyboard users lose the only focus cue.
Fix: outline-hidden focus-visible:outline-2 focus-visible:outline-ring
Evidence: S10 → button.tsx:4

[Medium] `TW-COMP-03` — button.tsx:14 — cn(className, button(…)) → cn(button(…), className).
```

Close with "Not verified": always the rendered result light and dark (`TW-CORE-04`) and contrast. Full worked audit: `references/example-audit.md`.

## Lookups

- Rule text by ID: `grep -h 'TW-SRC-01' references/rules.md` (a family: `'TW-A11Y-'`). That is enough to cite; never load `rules.md` or the hub whole.
- The four pairs that look like aliases (`TW-THEME-04`×`TW-UTIL-03`, `TW-SRC-02`×`TW-COMP-06`, `TW-UTIL-01`×`TW-COMP-02`, `TW-MIG-03`×`TW-A11Y-01`) are at the end of `rules.md`; cite each by its own ID.
- The rules were verified on 2026-10-02 against `tailwindcss` 4.3.3. A finding that says "removed", "renamed" or "behaves differently" on a newer version needs a Context7 check (`/tailwindlabs/tailwindcss.com`, topic `upgrade guide`); otherwise the docs are the source, and you report normally.
