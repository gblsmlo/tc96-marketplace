---
type: llm
focus: trace
weight: 1
---

/settings and /dashboard check auth in beforeLoad (each route or a shared parent or pathless layout) and throw redirect() to /login; the useEffect + navigate guard in SettingsPage is gone
