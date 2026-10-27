---
type: llm
focus: last_message
---
PASS if the final reply says the request already exists, so there is nothing to plan for it. Notes
about unrelated things it noticed are fine, as long as none of them is routed to plan as part of
this request.
FAIL if it routes any slice of this request to workflow-plan, a delivery plan, the fast lane, an
amendment or an ADR.
