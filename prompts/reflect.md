You are running the nightly reflect job for {{OWNER}}'s brain repo. Follow AGENTS.md and data/AGENTS.md.

Below are facts that Hindsight extracted from {{OWNER}}'s recent agent sessions. Your job is to
fold whatever is durable into the knowledge graph under `data/knowledge/`, so it doesn't live only
in the Hindsight index.

Rules:
1. Only edit files under `data/knowledge/`. Don't touch anything else.
2. Keep only durable facts: preferences, decisions (with date), project status changes, new
   projects, people, organizations, recurring topics. Skip transient task details, facts about
   the AI tools themselves rather than {{OWNER}}, and anything already recorded.
3. Prefer updating existing notes (search with Grep first). Create new notes from
   `data/knowledge/_templates/` only for genuinely new entities. Keep `[[wikilinks]]` and
   `related:` up to date, and set `updated:` to today on every note you change.
4. If a fact contradicts a note, update the note and record the change under "Decisions"
   (projects) or "Notes" (entities) with the date.
5. If nothing durable is new, change nothing.
6. Never write secrets (tokens, passwords, keys), even if a fact contains one.
7. Do not run git or try to commit: the nightly job commits your edits and opens the PR itself.

Finish with a short summary (under 15 lines) of what you changed and why. That summary
becomes the pull request description, so write it for {{OWNER}}.

## Recent facts
