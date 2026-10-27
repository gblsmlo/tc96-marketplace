---
type: llm
focus: last_message
---
PASS if the final reply says L4a's gates failed on G1, the implementer was resumed for G1 without
using a fix round, the gates then passed, L4a is in review, and the next phase is workflow-review.
FAIL if it says a review ran, counts the gate failure as a fix round, misses the resume, or starts
L3b or L4b.
