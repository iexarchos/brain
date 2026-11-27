# brain data

Private data for a brain engine checkout: the knowledge graph, archived
council answers, and the owner's settings. Clone it as `data/` inside the engine checkout
(`bin/init-data --clone <owner>/<repo>`). Keep this repository private.

| Path | What |
|---|---|
| `knowledge/` | The knowledge graph (Markdown notes). Source of truth. |
| `archive/council/` | Final council answers, merged from PRs. Not a knowledge source. |
| `AGENTS.md` | Personal instructions, read by agents after the engine's `AGENTS.md`. |
| `brain.env` | Owner name, Hindsight bank id, this repo's name, for the engine's scripts. |
| `denylist.txt` | Strings the engine's leak-check keeps out of the public engine repo. |
| `hindsight/` | Owner-specific Hindsight settings (retain mission). |
| `runs/` | Raw outputs of jobs and council runs. Git-ignored. |

The `memory-backup` branch holds nightly dumps of the Hindsight database.
