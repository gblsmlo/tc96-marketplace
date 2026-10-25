---
type: llm
focus: trace
weight: 1
---

vite.config.ts registers `tailwindcss()` from `@tailwindcss/vite`, and the PostCSS setup is gone: postcss.config.mjs is deleted (or no longer lists `@tailwindcss/postcss`/autoprefixer) and the response says to remove `@tailwindcss/postcss`, `autoprefixer` and `postcss` and add `@tailwindcss/vite` at the same version as tailwindcss
