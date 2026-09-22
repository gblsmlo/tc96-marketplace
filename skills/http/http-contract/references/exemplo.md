# Worked example

Task: *"an endpoint to approve an invoice"*.

**Step 1 — the method.** Approving changes state → not safe. Repeating the approval produces the same final state (already approved stays approved) → **it is idempotent**. Two options survive:

- `POST /invoices/42/approval` — creates the "approval" resource;
- `PUT /invoices/42/approval` — declares the state.

I choose **`PUT`**, because idempotency then lives in the contract instead of depending on a key (`HTTP-METH-04`). And `GET /invoices/42/approve` would be out of the question — a destructive action behind a safe method (`HTTP-METH-01`).

**Step 2 — the status:**

| Case | Status | Obligation |
| --- | --- | --- |
| approved now | `200` with the invoice | `Content-Type` (`HTTP-CORE-03`) |
| already approved | `200` — same final state | visible idempotency |
| invoice does not exist | `404` | — |
| no permission to approve | `403` | valid credential, insufficient permission (`HTTP-STATUS-10`) |
| no credential | `401` | `WWW-Authenticate` (`HTTP-STATUS-10`) |
| valid body, but amount above the approver's limit | **`422`** | not `400` (`HTTP-STATUS-11`) |
| wrong `Content-Type` in the request | **`415`** | not `400` (`HTTP-NEG-07`) |
| the accounting service is down | **`502`** | we are the gateway (`HTTP-STATUS-12`) |

**Step 3 — retry.** `PUT` is idempotent, so a client retry is safe with no idempotency key. **Were it `POST`**, `HTTP-METH-08` would forbid automatic retry without `HTTP-METH-09` being met.

**Step 4 — errors.** `application/problem+json`, the API's single format (`HTTP-SPEC-08`), citing **RFC 9457**.

**Step 5 — the stack.** In Hono, `methodNotAllowed` has to be mounted, otherwise `PATCH /invoices/42/approval` returns `404` instead of `405` (`HTTP-METH-07`).

**What these decisions prevented:**

| Decision | Common alternative | Rule |
| --- | --- | --- |
| `PUT` on a state sub-route | `POST /invoices/42/approve`, with no declared idempotency | `HTTP-METH-04` |
| `422` for the approver limit | `400`, which does not tell syntax from rule | `HTTP-STATUS-11` |
| `415` for the wrong `Content-Type` | `400` | `HTTP-NEG-07` |
| `502` when the upstream falls | `500`, which blames our application | `HTTP-STATUS-12` |
| `200` on re-approval | `409`, which breaks the idempotency `PUT` promised | `HTTP-METH-04` |
| the status carrying the result | `200 {ok: false}` | `HTTP-CORE-06` |
