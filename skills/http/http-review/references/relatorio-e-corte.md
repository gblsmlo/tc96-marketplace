# Finding format, and the cut

Four parts, the same contract as `playwright-review`, `bun-test-review` and `react-review`:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

For a probe, **the evidence is the command's output** — paste the headers.

### Example

```
`HTTP-CACHE-08` — apps/server/src/features/invoices/routes.ts:88
The PUT /invoices/:id route does not accept If-Match and always applies the write; two
concurrent edits overwrite each other with no warning.
Evidence: S5 — `curl -i -X PUT -H 'If-Match: "stale"'` returned 200, not 412.
Fix: compare the If-Match with the current ETag and answer 412 when they diverge;
 the ETag has to be strong, without W/ (HTTP-CACHE-09). The client treats the 412 as
 UI state, not as an exception.
See HTTP - Cache e Requisições Condicionais.
```

```
`HTTP-CORE-06` — apps/server/src/features/orders/routes.ts:41
A domain error returned as 200 with {ok: false}; Hono's hc does not throw on an error
status, so the client's query stays in success with the error inside data —
isError is false, the retry does not run, the Error Boundary does not catch.
Fix: 422 for a rejected business rule (HTTP-STATUS-11), with problem+json.
See HTTP § 6, and Hono - Validação e RPC for the client side.
```

Rules of the format: **ID checked against § 6**, and **never an alias** (§ 6.2); location always; a concrete fix — if another route in the service already does it right, point at it; one satellite link.

---

## Step 5 — The cut: finding × opinion

**A finding without an ID is an opinion**, with three ways out:

1. **There is an ID** → a finding, cite the ID.
2. **There is no ID, but there is a normative note** → cite the note: `OWASP - Sessão e Autorização`. Do not invent `HTTP-*`.
3. **Neither** → a separate "Suggestions (no rule)" section.

Four cases that are **not** findings:

- **URL style.** `/invoices/42/approval` × `/invoices/42:approve` has no ID. It is convention, and becomes a finding only if it violates method semantics.
- **Verbosity of the response body.** There is no rule about how much to return — there is one about having **one** error format (`HTTP-SPEC-08`).
- **Absence of caching.** `Cache-Control: no-store` on a route that could cache is a decision, not a violation — what **is** a violation is the **absence** of the header (`HTTP-CACHE-01`).
- **The framework not doing it on its own.** "Bun.serve does not do CORS" is not a finding against the team; the finding is the route without CORS where it needs it.

And one **invalid** case: citing `HTTP-STATUS-01`. It is an alias of `HTTP-CORE-06` (§ 6.2).

If the scan finds a real, recurring defect with no rule, the product is a **rule proposal** for [HTTP](../../../../knowledge-base/http.md) § 6 — suggested ID, text, and the case that motivated it.
