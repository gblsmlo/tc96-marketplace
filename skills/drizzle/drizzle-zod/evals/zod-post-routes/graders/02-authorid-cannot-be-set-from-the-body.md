---
type: llm
focus: trace
weight: 1
---

authorId cannot be set from the body: the create schema leaves it out (pick/omit), the handler takes it from the session, and a test shows a body with another authorId does not create a post for that user
