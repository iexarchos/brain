You are importing knowledge about {{OWNER}} into their brain repo from an external source.
Follow AGENTS.md and data/AGENTS.md (note format, file naming, linking). The source material is in the directory
given at the end of this prompt; read every file in it (use Glob, then Read).

Build or update the knowledge graph under `data/knowledge/`:

1. **Profile** (`data/knowledge/me/profile.md`): fill in who {{OWNER}} is — current role, employer,
   career history, education, expertise, interests — concisely. Keep existing content; add to it.
2. **Projects** (`data/knowledge/projects/`): one note per meaningful project, paper, or codebase,
   from the template. Capture: goal, what it is, their role, status, period, key results, links
   (repo, paper). Group trivially related items (e.g. a paper and its code repo) into one note.
3. **Topics** (`data/knowledge/topics/`): one note per recurring research or work theme, linking the
   projects that belong to it.
4. **People / orgs** (`data/knowledge/people/`, `data/knowledge/orgs/`): only collaborators and
   organisations that recur or matter (e.g. frequent co-authors, employers, universities).
   A short summary and links are enough. Don't create notes for one-off names.
5. Link generously with `[[wikilinks]]` and keep `related:` in frontmatter consistent in both
   directions where it helps navigation.

Rules:
- **Current over historical.** Record what is current and active: present role, ongoing
  projects, live interests. Don't create notes for past or inactive projects, old papers,
  former collaborators or past organisations; at most summarise them in one line of the
  profile. When in doubt, leave it out — {{OWNER}} prefers a lean graph over a complete archive.
- Record only what the source supports; don't invent or embellish. Use dates the source gives.
- Prefer updating existing notes (Grep first) over creating near-duplicates.
- Skip boilerplate (licences, installation instructions, theme/template text).
- Don't record secrets, home addresses, phone numbers, or account IDs.
- Set `updated:` to today on every note you create or change.
- Only edit files under `data/knowledge/`. Don't run git; the import script commits and opens the PR.

Finish with a concise summary for {{OWNER}} (under 25 lines): notes created and updated, grouped
by type, plus anything in the source you were unsure about or deliberately skipped. It becomes
the pull request description.
