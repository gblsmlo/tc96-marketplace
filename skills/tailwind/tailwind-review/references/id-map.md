---
generated-by: skills/tailwind/tailwind-setup/scripts/generate-id-map.sh
generated-at: 2026-10-02
---

# ID map `TW-*`

> An index, not a copy. **The TW-* rules are written for line 4.** On a project that stays on
> line 3, only `TW-SRC-01`, `TW-SRC-02`, `TW-UTIL-01`, `TW-A11Y-*` and `TW-COMP-*` may be cited.
> Discover the line first — `bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh`.
> Regenerate with `bash skills/tailwind/tailwind-setup/scripts/generate-id-map.sh`.

## Canonical IDs and the pairs that look like aliases


**There are no aliases in the `TW-*` family.** Each principle has a single ID, in the satellite that owns it: variant order and `hover:` on touch, which the migration touches, are cited by the general ID (`TW-VAR-07`, `TW-A11Y-08`) and did not get a migration ID.

> **Four pairs that look like aliases and are not**, and so remain citable each by its own ID:
>
> - `TW-THEME-04` × `TW-UTIL-03` — the first is the arbitrary value that **duplicates an existing token**; the second is the arbitrary value that repeats **with no token at all**. The fix for the first is to use the token; the fix for the second is to create it.
> - `TW-SRC-02` × `TW-COMP-06` — the first is about the **scanner** (the string must be complete); the second is about the component's **API** (design variation is a variant, not `className`). A map of complete strings satisfies the first and can violate the second.
> - `TW-UTIL-01` × `TW-COMP-02` — the first forbids the conflict on the **element**; the second forbids using merge to hide an **internal** conflict. A `cn('px-4', x && 'px-2')` violates the second; the final element, after the merge, does not violate the first.
> - `TW-MIG-03` × `TW-A11Y-01` — the first is the **rename** in the migration (v3's `outline-none` becomes `outline-hidden`); the second is the **obligation** of a custom focus style, which applies to both utilities.


## Full index

| ID | Satellite | Section |
| --- | --- | --- |
| `TW-A11Y-01` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-02` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-03` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-04` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-05` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-06` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-07` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-A11Y-08` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 6. Accessibility |
| `TW-CFG-01` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 1. The integration, and which one to choose |
| `TW-CFG-02` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 1. The integration, and which one to choose |
| `TW-CFG-03` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 1. The integration, and which one to choose |
| `TW-CFG-04` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 1. The integration, and which one to choose |
| `TW-CFG-05` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 2. The entry stylesheet |
| `TW-CFG-06` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 2. The entry stylesheet |
| `TW-CFG-07` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 2. The entry stylesheet |
| `TW-CFG-08` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 2. The entry stylesheet |
| `TW-CFG-09` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 2. The entry stylesheet |
| `TW-CFG-10` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 4. Preflight |
| `TW-CFG-11` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 5. Compatibility |
| `TW-COMP-01` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 1. Reuse: the component is the unit |
| `TW-COMP-02` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 2. Concatenate × merge |
| `TW-COMP-03` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 2. Concatenate × merge |
| `TW-COMP-04` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 2. Concatenate × merge |
| `TW-COMP-05` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 2. Concatenate × merge |
| `TW-COMP-06` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 3. Declared variants: cva and tailwind-variants |
| `TW-COMP-07` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 3. Declared variants: cva and tailwind-variants |
| `TW-COMP-08` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 3. Declared variants: cva and tailwind-variants |
| `TW-CORE-01` | [Tailwind CSS](../../docs/tailwindcss.md) | 6. Normative rules |
| `TW-CORE-02` | [Tailwind CSS](../../docs/tailwindcss.md) | 6. Normative rules |
| `TW-CORE-03` | [Tailwind CSS](../../docs/tailwindcss.md) | 6. Normative rules |
| `TW-CORE-04` | [Tailwind CSS](../../docs/tailwindcss.md) | 6. Normative rules |
| `TW-MIG-01` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 2. Removed and renamed utilities |
| `TW-MIG-02` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 2. Removed and renamed utilities |
| `TW-MIG-03` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 2. Removed and renamed utilities |
| `TW-MIG-04` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 2. Removed and renamed utilities |
| `TW-MIG-05` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 3. Defaults that changed value |
| `TW-MIG-06` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 3. Defaults that changed value |
| `TW-MIG-07` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 4. Syntax that changed form |
| `TW-MIG-08` | [Tailwind CSS - Migration v3 to v4](../../docs/tailwindcss-migration-v3-to-v4.md) | 4. Syntax that changed form |
| `TW-SRC-01` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-SRC-02` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-SRC-03` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-SRC-04` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-SRC-05` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-SRC-06` | [Tailwind CSS - Installation and Detection](../../docs/tailwindcss-installation-and-detection.md) | 3. What the scanner sees |
| `TW-THEME-01` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 1. Theme variable × regular variable |
| `TW-THEME-02` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 1. Theme variable × regular variable |
| `TW-THEME-03` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 1. Theme variable × regular variable |
| `TW-THEME-04` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 1. Theme variable × regular variable |
| `TW-THEME-05` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 2. `@theme inline`, and why the runtime theme depends on it |
| `TW-THEME-06` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 2. `@theme inline`, and why the runtime theme depends on it |
| `TW-THEME-07` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 2. `@theme inline`, and why the runtime theme depends on it |
| `TW-THEME-08` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 2. `@theme inline`, and why the runtime theme depends on it |
| `TW-THEME-09` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 4. Dark mode |
| `TW-THEME-10` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 4. Dark mode |
| `TW-THEME-11` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 5. The shadcn/ui semantic token pattern |
| `TW-THEME-12` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 5. The shadcn/ui semantic token pattern |
| `TW-THEME-13` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 5. The shadcn/ui semantic token pattern |
| `TW-THEME-14` | [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md) | 5. The shadcn/ui semantic token pattern |
| `TW-TOOL-01` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 4. Editor and formatter tools |
| `TW-TOOL-02` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 4. Editor and formatter tools |
| `TW-TOOL-03` | [Tailwind CSS - Components and Composition](../../docs/tailwindcss-components-and-composition.md) | 4. Editor and formatter tools |
| `TW-UTIL-01` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 1. Conflict: the winner is not whoever comes later in `className` |
| `TW-UTIL-02` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 1. Conflict: the winner is not whoever comes later in `className` |
| `TW-UTIL-03` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 2. Arbitrary value, arbitrary property, runtime value |
| `TW-UTIL-04` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 2. Arbitrary value, arbitrary property, runtime value |
| `TW-UTIL-05` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 2. Arbitrary value, arbitrary property, runtime value |
| `TW-UTIL-06` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 3. Your own CSS: `@utility`, `@layer components`, `@apply` |
| `TW-UTIL-07` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 3. Your own CSS: `@utility`, `@layer components`, `@apply` |
| `TW-UTIL-08` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 3. Your own CSS: `@utility`, `@layer components`, `@apply` |
| `TW-VAR-01` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 5. Responsiveness and container queries |
| `TW-VAR-02` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 5. Responsiveness and container queries |
| `TW-VAR-03` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 5. Responsiveness and container queries |
| `TW-VAR-04` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 4. State variants |
| `TW-VAR-05` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 4. State variants |
| `TW-VAR-06` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 4. State variants |
| `TW-VAR-07` | [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) | 4. State variants |
