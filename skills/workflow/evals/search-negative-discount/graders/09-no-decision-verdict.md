---
type: regex
target: trace
pattern: '"name":"(Write|Edit)","input":\{"file_path":"[^"]*\.specs/triage/[^"]*"[^\n]*\|\s*(product-decision|technical-decision)\s*\|'
match: not_contains
---
