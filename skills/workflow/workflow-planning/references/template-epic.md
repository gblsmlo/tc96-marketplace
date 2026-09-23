# Work-item template — Epic

Tool-neutral. Fill these fields in whatever tracker the project uses (GitHub Issues, Linear,
a Multica-style tool) — the fields are what matters, not the tool's field names.

**Model, adapted from a real reference (lemind, ADR 117):** four levels — Milestone, Epic,
Story, Task — connected by parent/child. Per the resolved decision for this family,
**Milestone has no template of its own**: it is a roadmap-block property on Epic, Story, and
Task, not a fourth narrative artifact. Epic is the **permanent capability** level: it does not
close on delivery, it closes when every child Story closes, and reopens when its governing
rule set gains a new rule.

---

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier in whatever tracker holds it |
| `capability` | the product/platform capability this Epic represents — required, and the value every automation in `workflow-planning` groups by (`WF-PLAN-05`) |
| `milestone` | optional roadmap block this Epic is currently associated with — informational, does not gate the Epic's own closure |
| `title` | `EPIC-<capability> · <capability name>` |

## Body (copy from here down into the tracker item)

---

### Who this is for

[The roles that exercise this capability, and what each does with it, in one or two
sentences.]

### The problem it solves

[Two to four sentences. What goes wrong today without this capability — never a screen,
table, or component name here; this is capability-level, not implementation-level.]

### What a person can do once this Epic is ready

- [One line per Story or group of Stories, starting with a verb. A line with no Story behind
  it is a gap — this list is what the review checks against.]
- [...]

### What is explicitly out of this Epic

- [What someone might expect here and is actually a different capability — name it, one line
  per item.]

### How this Epic is accepted

[Every child Story's acceptance scenarios pass, reviewed, with evidence linked. The Epic
itself never gets a separate acceptance round beyond its Stories' — per `WF-VAL-03`, business
acceptance of the whole capability is a later, separate step from this technical acceptance.]

### Sources

[The spec, decision record, or research that authorized this capability, and how many rules
it carries.]

---

## Related

- `workflow-research` — an Epic is typically the resolved output of a product-scope research pass
- `template-story.md`, `template-task.md` — the children this Epic decomposes into
- Reference model: lemind `docs/product/templates/epic.md` and ADR 117 (`docs/decisions/117-o-multica-e-autoridade-unica-do-backlog.md`)
