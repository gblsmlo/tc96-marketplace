# Proportionality of evidence

`WF-VAL-02`, hub §4.4. Validation is a decision about evidence, not a synonym for "run the
broadest suite available." Running everything by default is not rigor — it is a decision
avoided, dressed up as thoroughness, and it costs real time without buying proportional
information (the same economics `TS-CORE-02` applies to individual test placement, one level
up: at the level of an entire change).

## The tree

```
Does the change alter a public contract (API shape, schema, route, status code)?
├── yes → contract checks + independent review required
└── no
    Does it touch authentication, authorization, or sensitive data handling?
    ├── yes → security checks + independent review required (route finding to devops-security)
    └── no → focused checks on what changed are enough
```

## What "focused checks on what changed" means

Run the tests that exercise the changed behavior directly, plus whatever the repository
requires as a baseline gate (lint, typecheck, boundary checks) — not the entire E2E suite,
not every integration test in the repository, unless the change's blast radius actually
reaches them.

## Declaring what was not covered

`WF-CORE-01` requires an artifact, not silence. If a change plausibly affects something that
was not checked — a caller in a part of the codebase not touched, a downstream consumer of a
schema — say so explicitly. A declared gap is a legitimate outcome; an undeclared one is a
finding waiting to be made by someone else, later, at a worse time.

## Worked examples

| Change | Contract? | Security? | Evidence required |
| --- | --- | --- | --- |
| fix an off-by-one in an internal discount calculation, no API change | no | no | the focused unit test for that function, plus baseline gates |
| add a new field to an API response | yes | no | contract check (schema/OpenAPI), independent review of the new field's shape, plus focused tests |
| change how a session cookie is signed | no | yes | security checks, independent review, route the finding path through `devops-security` |
| rename an internal function used only within one module | no | no | the module's existing tests passing is enough; no new evidence needed beyond baseline gates |
