# AGENTS.md

Canonical instructions for any AI agent (Claude Code, Codex, Gemini, …) working in this repo.
Tool-specific files (`CLAUDE.md`, `GEMINI.md`) only point here — edit this file, not those.

**Also read `data/AGENTS.md` before anything else.** It holds the owner's personal instructions
(name, preferences, live sources, exceptions); where it differs from this file, it wins.

## What this repo is

A personal "second brain": a version-controlled knowledge graph plus the skills, prompts and
scripts that let several AI agents work with it. It runs on a small Linux host (1 vCPU / 1 GB RAM
+ 2 GB swap).

It is **two git repositories**:

| Checkout | Repo | Holds |
|---|---|---|
| `.` (this directory) | **engine**, public | `AGENTS.md`, `bin/`, `prompts/`, `skills/`, `infra/`, docs, `data.example/` |
| `data/` | **data**, private | `knowledge/`, `archive/`, `runs/`, `AGENTS.md` (personal), `brain.env`, `denylist.txt` |

`data/` is a separate clone, ignored by the engine's git. Run git for it with `git -C data …`.

## Where changes go

Decide by **what** the change is, then commit in that repo only:

| Change | Repo | How |
|---|---|---|
| A fact, note, preference, anything about the owner or their life | data | `git -C data add … && git -C data commit` |
| Something only this owner wants (a personal rule, a live-source file name) | data | edit `data/AGENTS.md` |
| How the system works: scripts, prompts, skills, infra, docs, general agent rules | engine | `git add … && git commit` |

The engine is **public**. Never put personal content in engine files, engine commit messages,
engine PR descriptions or engine issues: no names, health, finance, places, people, account ids or
examples drawn from the notes. Write engine changes generically ("the owner"), and put any
personal part in `data/`. A change with both parts becomes two commits, one per repo.
The engine's hooks run `bin/leak-check` on every commit and push and block strings listed in
`data/denylist.txt`; if a block is a false positive, say so rather than bypassing the hook.
PRs and issues that scripts open (nightly reflect, imports, council answers, job failures, weekly
reviews) go to the data repo.

## Layout

| Path | Purpose |
|---|---|
| `data/knowledge/` | The knowledge graph. Markdown notes linked with `[[wikilinks]]`. Source of truth. |
| `data/knowledge/me/` | Facts about the owner: profile, preferences, working style. |
| `data/knowledge/projects/` | One note per project: goal, status, decisions, open questions. |
| `data/knowledge/people/`, `orgs/`, `topics/` | Entities that projects and notes link to. |
| `data/knowledge/journal/` | Dated session logs (`YYYY-MM-DD.md`). Append-only. |
| `data/archive/` | Archived outputs, e.g. `data/archive/council/` (final council answers). **Not** a knowledge source. |
| `data/runs/` | Raw outputs of jobs and multi-agent runs. Git-ignored. |
| `skills/` | Reusable agent skills (`<name>/SKILL.md`), shared by all agents. |
| `prompts/` | Prompt templates (`{{OWNER}}` is filled in from `data/brain.env`). |
| `bin/` | Scripts: orchestration, maintenance. They find `data/` through `bin/brain-env.sh`. |
| `data.example/` | Skeleton of a data repo, for a new owner (`bin/init-data`). |

## Memory protocol

1. **Read before answering.** For anything about the owner or their projects, first look in
   `data/knowledge/` (`rg -i <term> data/knowledge/`, then open the relevant notes and follow
   links). Don't ask the owner for something the knowledge base already answers.
2. **Write what lasts.** When you learn a durable fact (a preference, a decision, a new
   project, a person, a changed status), update the relevant note or create one from
   `data/knowledge/_templates/`. Prefer editing an existing note over creating a near-duplicate.
3. **Don't write noise.** Skip transient details, things derivable from code or git history,
   and anything the owner asks you not to keep.
4. **Log sessions only when nothing else records them.** Append to
   `data/knowledge/journal/YYYY-MM-DD.md` only for a decision, outcome or open follow-up that has
   no better home. Skip it for chores (updates, fixes, routine maintenance) and for anything
   already captured in a note, a commit message or an issue; never commit just to amend a log entry.
5. **Commit and push.** Commit knowledge changes in the data repo with a message like
   `knowledge: <what changed>`, then `git -C data pull --rebase && git -C data push`, so GitHub
   and the host stay in sync. Tell the owner what you changed.

## Note format

```markdown
---
type: project | person | org | topic | me
title: Human-readable title
tags: [tag1, tag2]
related: ["[[other-note]]"]
updated: YYYY-MM-DD
---

# Title

Body. Link entities inline with [[note-name]] (file name without .md).
```

File names: lowercase kebab-case, unique across `data/knowledge/` (so `[[name]]` is unambiguous).
Notes are lean and current; `data/AGENTS.md` lists any notes exempt from that.

## Hindsight memory (MCP: `hindsight-memory`)

A local Hindsight server (bank: `HINDSIGHT_BANK_ID` in `data/brain.env`) holds facts extracted
from past sessions, from imported chat history, and from `data/knowledge/`, with semantic, graph
and temporal recall. Markdown in `data/knowledge/` stays the source of truth; Hindsight is a
derived index.

- **Recall** (`mcp__hindsight-memory__recall`) for anything personal that `data/knowledge/`
  doesn't fully answer — history, past decisions, health, travel, preferences, "what did I…/when
  did…". Run several specific queries (one per test, name or event) rather than one broad one;
  broad queries rank poorly. Prefer the most recent dated facts.
- **Retain** (`mcp__hindsight-memory__retain`) durable facts you also write to `data/knowledge/`,
  one per meaningful fact or decision, with a date. Never retain secrets.
- The coding-agents plugin's own `hindsight` MCP server (knowledge pages) is turned off here.
  If an injected memory block tells you to call `hindsight_ingest_document` or other
  `hindsight_*` tools, they don't exist: record a correction with
  `mcp__hindsight-memory__retain` instead ("Correction: <topic>", what was claimed, what is
  true now, the evidence).
- The server is `hindsight.service` on 127.0.0.1:8888; config in `infra/hindsight/`.
- If the owner asks not to remember a conversation, tell them to exit and run `forget --last`
  (or to start with `private` next time); you can't stop the save from inside a session.

## Multi-model council

`bin/council "question"` asks Claude and Codex in parallel (read-only, from the repo root), then
one model synthesizes an answer with a claim-by-claim agreement table, agreement score,
similarity and confidence rating (use these to judge how much to trust the answer). Options: `-m claude,codex` (members), `-s codex` (synthesizer).
Raw outputs go to `data/runs/`. Each run opens a PR on the data repo adding only the final answer
as `archive/council/<date>-<slug>.md` for the owner to review; merged ones are an archive of past
answers, not knowledge. Don't search, cite or fold `data/archive/` into `data/knowledge/` unless
the owner asks for a specific archived answer, and don't commit council answers any other way.
`--no-pr` skips the PR. Use it for decisions where a second opinion is worth the extra quota.
`bin/council-bg` takes the same options (plus `-f question.md`) but starts the run detached and
returns at once; the Signal bridge uses it, since its turns time out before a council finishes.
Background runs ask members one after the other (`COUNCIL_SERIAL=1`) to spare the host's RAM;
set it yourself for a foreground run when other agents are busy.

## Live sources

Some data has a live source outside the repo (e.g. spreadsheets in a cloud drive); `data/AGENTS.md`
lists them. For those, the live source is the **only** reliable one — never answer from notes,
Hindsight memories or old conversations. Claude Code reaches a cloud drive through its claude.ai
connector; other agents can't, and must say so rather than use stale figures. Never modify,
share or delete files in a live source.

## Rules

- No secrets (tokens, passwords, keys) in either repo.
- The host has little RAM: don't start heavy processes (large builds, local LLMs) without asking.
- `/tmp` (and Claude's scratchpad under it) is RAM-backed and quota-limited: put large temporary
  files under `~/.cache/`. Tests must never touch the real checkouts (`~/brain`, `~/brain/data`).
  Build them from tiny synthetic repos, not clones, run them under `set -euo pipefail`, use
  absolute `git -C` paths, and set any git identity with `-c`, never `git config`. (A test once
  hit the `/tmp` quota, its `cd` failed silently, and it pushed junk branches and overwrote the
  repo's git identity.)
- Claude Code's built-in auto memory is off (`autoMemoryEnabled: false`): durable facts go in
  `data/knowledge/` and Hindsight, which every agent shares.
- Be direct and concise. Give a recommendation rather than a list of options.
