# Template: Epic

Tool-neutral. Fill these fields in whatever tracker the project uses (GitHub Issues, Linear, a
Multica-style tool); the fields are what matters, not the tool's field names. Written by
`project-manager`. Rules: `rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier in whatever tracker holds it |
| `capability` | the capability this Epic represents; required, and the value every child groups by |
| `milestone` | optional roadmap block this Epic is currently associated with; informational |
| `title` | `EPIC-<capability> · <capability name>` |

## Body (copy from here down into the tracker item)

---

### Who this is for

[The roles that exercise this capability, and what each does with it, in one or two
sentences.]

### The problem it solves

[Two to four sentences. What goes wrong today without this capability. Never a screen, table
or component name here.]

### What a person can do once this Epic is ready

- [One line per Story or group of Stories, starting with a verb. A line with no Story behind
  it is a gap.]
- [...]

### What is explicitly out of this Epic

- [What someone might expect here and is actually a different capability: name it, one line
  per item.]

### How this Epic is accepted

[Every child Story's acceptance scenarios pass, reviewed, with evidence linked. The Epic gets
no separate acceptance round; business acceptance of the whole capability is a later step.]

### Sources

[The PRD, decision record, or research that authorized this capability.]
