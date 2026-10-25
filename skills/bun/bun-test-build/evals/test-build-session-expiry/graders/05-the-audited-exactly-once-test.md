---
type: llm
focus: trace
weight: 1
---

The 'audited exactly once' test calls sessionExpired at least twice after expiry and asserts toHaveBeenCalledTimes(1) on a spy of audit.record, and the spy is restored (mockRestore, or mock.restore in the preload)
