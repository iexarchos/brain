---
name: remember
description: Save a durable fact about the owner, a person, or a project into the knowledge graph (data/knowledge/). Use when the owner says "remember …", or when a session produced a decision or fact worth keeping.
---

# remember

1. Decide which entity the fact belongs to (`me`, a project, a person, an org, a topic).
2. Search for an existing note: `rg -il "<name or keyword>" data/knowledge/`.
3. If found, add the fact in the right section, set `updated:` to today, and add any new
   `[[links]]` to `related:`. If not found, copy the matching file from
   `data/knowledge/_templates/` to a kebab-case file name and fill it in.
4. If the fact contradicts something already written, replace the old statement (note the
   change under "Decisions" with a date if it's a project decision).
5. Commit and push **in the data repo** (private), never the engine repo:
   `git -C data add knowledge && git -C data commit -m "knowledge: <short description>"`,
   then `git -C data pull --rebase && git -C data push`.
6. Tell the owner in one line what was saved and where.
