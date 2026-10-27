# Template: the slice question

The prompt `workflow-search` sends to `repo-explorer` for one open slice, in Step 3. One slice,
one question, one round (`SDD-FLOW-06`). Fill the brackets; send nothing else.

## Body (copy from here down)

---

Slice [S-number], axis [axis]: [the slice, in one sentence].
Entities and capabilities: [list].
The record already says: [what the PRD, ADRs, bundles, docs or memory answered, or "nothing"].
Likely place in the code: [paths from the request's wording or the record, or "unknown"].

Answer with facts only, each with file:line, at most 30 lines:
- what already exists for this slice;
- every caller of what it would change;
- the tests around it;
- the conventions of that layer (naming, folder, error shape).
Under "Not found", list what you searched and where, with no match. No opinions, no fixes, no
file contents.
