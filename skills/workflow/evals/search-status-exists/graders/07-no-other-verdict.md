---
type: regex
target: trace
pattern: '"name":"(Write|Edit)","input":\{"file_path":"[^"]*\.specs/triage/[^"]*"[^\n]*\|\s*(product-decision|technical-decision|build|no-behavior-change|untraced)\s*\|'
match: not_contains
---
