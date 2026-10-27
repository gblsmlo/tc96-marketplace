---
type: llm
focus: trace
---
Judge the Route section of the triage file the run wrote under .specs/triage/.
PASS if the route puts the PRD amendment before the delivery plan, and, where it orders the build
slices, the backend export endpoint before the frontend button that consumes it (marking that
order "(proposed)" is fine).
FAIL if the delivery plan comes before the amendment, or the frontend comes before the backend.
