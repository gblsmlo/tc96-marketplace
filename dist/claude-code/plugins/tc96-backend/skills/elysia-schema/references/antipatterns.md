# Antipatterns — schemas

| Antipattern | What happens | ID | Doc section |
| --- | --- | --- | --- |
| an `interface` that repeats a `t.Object` | two sources of truth that drift | `ELYSIA-TYPE-01` | § 1 |
| `z.file()` without `fileType()` | a renamed executable passes as an image | `ELYSIA-TYPE-02` | § 2 |
| `headers: t.Object({ Authorization: … })` | never matches; the header "is never sent" | `ELYSIA-TYPE-03` | § 3 |
| `t.Number()` in a body expecting `"2"` to pass | 422 | `ELYSIA-TYPE-04` | § 3 |
| a flat guard expected to add to the route's schema | the route's schema replaces it | `ELYSIA-TYPE-05` | § 4 |
| a route answering 404/409 with no response map | the client sees the error as `unknown` | `ELYSIA-TYPE-06` | § 5 |
| `response: { 201: X }` with `return value` | goes out as 200, unvalidated; the spec documents a 201 that never happens | `ELYSIA-CORE-04` | § 1, § 5 |
| `allowUnsafeValidationDetails: true` left on | every 422 publishes the schema | `ELYSIA-TYPE-12` | § 5 |
| a paginated `GET` answering a bare array | the client cannot know whether there is a next page | `ELYSIA-TYPE-13` | [Elysia - Eden](../../../docs/elysia/elysia-eden.md) |
| returning a field the response schema does not list | silently dropped by `normalize` | — | § 3 |

Doc sections refer to [Elysia - Schema and Validation](../../../docs/elysia/elysia-schema-and-validation.md) unless named.
