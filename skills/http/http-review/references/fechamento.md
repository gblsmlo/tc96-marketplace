# Closing the audit

1. **Turn a probe into a test.** S3, S4, S5 and S6 are verifiable in an API test — [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) § 5. A finding that only exists in the report comes back in six months (`TS-CORE-06` in [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md)).
2. **Separate "the team's mistake" from "the framework does not do it".** § 8 of the hub decides: in raw `Bun.serve` every rule is an explicit responsibility; in Hono and Elysia there are built-ins, and the finding becomes the middleware not mounted.
3. **Order by severity**, not by file.
4. **Report an inconsistent error body separately.** It is a public contract, and every new route widens the cost (`HTTP-SPEC-08`).
5. **If there is sensitive data in a query string or CORS as authorization**, report it first and separately — those are security findings, with a different deadline.
6. **Declare what was not verified.** A probe that did not run — the service does not start, the environment is unreachable, a CDN sits in between — say which and why. **"Not verified" is not "no findings"**, and it is invariant 5 of § 7 of the hub: "it worked in Chrome" is not verification.
