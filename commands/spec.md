---
nome: spec
descricao: Gera só a especificação de um incremento em .specs/<capability>/ (requirements, design, user-experience, o plano em tasks/, ADRs), cada arquivo como rascunho que o dono aprova, e para antes da implementação
tipo: comando
idioma: en
tags:
  - workflow
  - spec
---
# Spec generation only

**Input:** the request the person typed with the command: a feature, a change, or a problem.
**Output:** the files in `.specs/` that the scope needs, each written as a draft the owner
reviewed, and the planning envelope. No code.

This command runs two pillars, `workflow-research` and `workflow-planning`, and stops. It does
not decide anything those skills do not already decide; it fixes their order and the stop.
Every file is written through `workflow-spec`.
Rules: `WF-SPEC-*` in [Fluxo de Entrega — Quatro Pilares](../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5.

---

## Phase 0: Name the capability, read the project's document set

The folder is the capability's, not the request's (`WF-SPEC-08`): its slug is the `capability`
of the Epic this request belongs to, in kebab-case. With no Epic yet, propose the slug in one
line and let the owner confirm it before Phase 1 writes anything. If `.specs/<capability>/` already exists,
read only the status lines of its files and of their last amendment:

| Found | This run |
| --- | --- |
| no folder | starts at Phase 1 and creates it |
| a `Draft` file or amendment | resumes at that review |
| everything approved, and this request already has an approved amendment or a new plan in `tasks/` | resumes at Phase 2 |
| everything approved, nothing about this request | starts at Phase 1: research decides whether this increment needs an amendment |

Read the record of which documents this project keeps: `## Specs` in `AGENTS.md`, then
`.specs/README.md` (`WF-SPEC-07`). Missing: `workflow-spec` asks the owner once, and asks
before writing to `AGENTS.md`.

---

## Phase 1: Research

Run `workflow-research` on the request.

- The scope (product, architecture, implementation detail) decides which files exist (`WF-SPEC-03`).
- Product scope: `workflow-spec` starts `product-manager` on `.specs/<capability>/requirements.md`,
  or on an amendment to it when it is already `Approved`, and returns the `Draft` to the owner: path, problem sentence, open gaps, "approve, change,
  or reject?".
- A gap with `fecha-em: pesquisa` stops the run here: start the agent its `decide` names, or
  ask the owner, with the gap in one sentence, when it is `dono`. A gap with
  `fecha-em: planejamento` travels to Phase 2 (`WF-CORE-09`).

**Gate:** product scope requires `requirements.md`, and the amendment this run wrote, in `Approved` before Phase 2, and only the
owner's answer sets it (`WF-SPEC-06`). No answer: the run ends here, with the path under
`lacunas`.

---

## Phase 2: Planning

Run `workflow-planning` from the research envelope. One `workflow-spec` call per file, each
returned to the owner for review before the next depends on it.

| File | Agent | When |
| --- | --- | --- |
| `.specs/<capability>/design.md`, or an amendment | `software-architect` | architecture scope, or a boundary or contract |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | one per accepted decision that outlives the increment |
| `.specs/<capability>/user-experience.md`, or an amendment | `product-designer` | product scope with an interface |
| `.specs/<capability>/tasks/NNNN-<slug>.md` | `project-manager` | always, a new one per increment |

A document the project turned off is not written; its decision goes as one line to the plan
under **Origin** (`WF-SPEC-07`).

**Gate:** a `design.md` in `rfc` mode stays `In review` until its decision date; the run
reports it as an open gap instead of accepting it.

---

## Phase 3: Stop

Return the planning envelope, with every `.specs/` path in `artefato` and every file not yet
approved under `lacunas` as `awaiting owner approval: <path>`, `decide: dono`. Every other gap
still open stays there too, with its `decide` and `fecha-em` (`WF-CORE-09`). Do not start
`workflow-implementation` (`WF-SPEC-05`). Implementation starts only on a new request from the
owner, one Task at a time, and only on files the owner approved (`WF-SPEC-04`).

---

## Checklist

- [ ] The project's document set was read, or asked once and recorded with permission.
- [ ] The scope is classified, and only the files it needs exist.
- [ ] Every rule and scenario went through the edge sweep; each applicable edge is a scenario, a non-goal or a gap (`WF-RES-06`).
- [ ] Every gap under `lacunas` names who decides it and where it closes, and none is left for implementation (`WF-CORE-09`).
- [ ] Each file was written by its own agent through `workflow-spec`, and links the others instead of copying them.
- [ ] Every status past `Draft` came from the owner's answer in this conversation.
- [ ] The plan in `tasks/` names one owner, acceptance, evidence and test types per Task (`WF-PLAN-06`).
- [ ] Approved text was amended, never rewritten; this increment got its own plan (`WF-SPEC-08`).
- [ ] No code, branch, commit or PR was created.
