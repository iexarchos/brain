# brain

Personal AI workspace: a git-tracked knowledge graph that any agent CLI can read and update,
running on subscription-based CLIs (Claude Code, Codex) rather than paid API credits.

- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Instructions for agents: [AGENTS.md](AGENTS.md)
- Setting up a host from scratch: [infra/README.md](infra/README.md)

This repository is the **engine**: scripts, prompts, skills, service units and docs. Your notes
and personal settings live in a separate **private data repo**, checked out as `data/` inside
this one (git ignores it). Start one from the skeleton in [data.example/](data.example/):

```bash
bin/init-data "Your Name" your-github-user/brain-data   # creates data/ and a private GitHub repo
```

Daily use updates whichever repo a change belongs to: notes and anything about you are
committed in `data/`; changes to how the system works are committed here. Commit hooks
(`bin/leak-check`) stop personal strings listed in `data/denylist.txt` from reaching this repo.

## Use

Connect from the laptop or phone, then work from the repo so agents load `AGENTS.md`:

```bash
ssh brain
cd ~/brain
```

There are three modes:

| Mode | Command | Memory | Use for |
|---|---|---|---|
| Normal session | `claude` or `codex` | recalls at start, saved to Hindsight | everyday questions and work |
| Council | `council "question"` | can read memory; final answer opened as a PR | decisions where a second opinion matters |
| Private session | `private` or `private codex` | recalls at start, **not** saved | conversations you don't want remembered |

### 1. Normal session

```bash
claude                # or: codex
claude --continue     # resume the most recent session in this directory
claude --resume       # pick an earlier session to resume
```

Relevant memories are injected on your first message, and the conversation is saved to
Hindsight each time the agent replies. Say "remember …" to also write a fact to `data/knowledge/`.

### 2. Council mode

One-shot question to several models in parallel, combined into a single report:

```bash
council "Should this project use Postgres or SQLite?"
council -m claude,codex -s codex "question"     # members (-m) and synthesizer (-s)
council < question.md                            # long question from a file
council --no-pr "quick question"                 # skip the PR for this run
```

- Claude and Codex answer independently (read-only, with access to `data/knowledge/` and memory);
  a third call synthesizes. Takes about 30–60 s.
- The report has two parts: **Answer**, then **Agreement** — a claim-by-claim table of which
  model supported or contradicted each point, an agreement score, a similarity rating and a
  confidence level. Low agreement means treat the answer with caution.
- Each run ends by opening a PR on the data repo that adds **only the final answer** as
  `archive/council/<date>-<slug>.md`. Merge it to archive the answer, or close the PR to
  discard it. `archive/` is outside `knowledge/`: it isn't indexed into Hindsight, isn't
  touched by nightly reflect, and agents don't read it unless you point them at it. Use `--no-pr` to
  skip the PR. If the PR can't be opened (no network, `gh` not logged in), you get a warning
  and the answer is still printed.
- The council calls themselves aren't saved to Hindsight. Raw answers are kept locally in
  `data/runs/<timestamp>-…/` (`claude.md`, `codex.md`, `final.md`).
- It's one-shot: to discuss the result, start `claude` and say e.g. "read
  data/runs/<that folder>/final.md and let's go through it".
- Codex has no Google Drive access, so for questions that need a live source (listed in
  `data/AGENTS.md`) its answer won't use it.

### 3. Private mode (no saving to memory)

```bash
private               # Claude session that isn't saved to Hindsight
private codex         # same for Codex
```

The session can still use existing memory; it just doesn't add to it. If you only decide
afterwards:

```bash
forget --last         # after exiting: remove the most recent session from memory
forget --list         # list stored sessions; then `forget <id>` removes a specific one
```

`forget` deletes the session and every fact extracted from it, and waits if the session is
still queued. Run it after exiting (an open session is re-saved on every reply) and before the
nightly run at 04:00 UTC, after which facts may already be in a reflect PR or the
`memory-backup` branch history.

### 4. Signal (phone)

Message brain's Signal number from your phone. `bin/signal-bridge` runs each message through
`claude -p` in the repo (memory recall and saving work as in a normal session) and replies.
Only your number/UUID gets an answer; everyone else is ignored. Messages are handled one at a
time and replies take ~10–60 s ("typing…" shows meanwhile).

For separate topic threads, create a Signal group with just you and brain's number (e.g.
"Health", "Investments"). Each group, and the direct chat, keeps its own conversation; a new
group starts one on its first message, so groups can be added any time. In groups only your
messages are answered. Sessions are in `~/.local/state/brain/signal-session.json`.

| Message | Effect (in the chat it's sent in) |
|---|---|
| anything | continues that chat's conversation |
| `/new` | starts a new conversation |
| `/private` | new conversation that is not saved to memory (until `/new`) |
| `/help` | lists commands |

Headless runs can't ask for permissions, so the bridge allows a fixed set of tools: read/edit
the repo, Hindsight, Drive (read-only), web, git add/commit/pull/push, and `bin/council-bg`.
Ask for a council in a message and it starts one in the background (a council outlasts a
Signal turn) and replies at once; the answer arrives as the usual PR. Anything else needs SSH.

Setup and operation:

```bash
# one-time: register brain's second number (Signal usually requires a captcha:
# open https://signalcaptchas.org/registration/generate.html, solve, copy the signalcaptcha:// link)
signal-cli -a +BRAIN register --captcha 'signalcaptcha://…'   # add --voice for a call instead of SMS
signal-cli -a +BRAIN verify 123456
signal-cli -a +BRAIN updateProfile --given-name brain
# set BRAIN_SIGNAL_ACCOUNT and BRAIN_SIGNAL_OWNER in ~/.config/brain/signal.env, then:
sudo systemctl enable --now brain-signal brain-signal-bridge
journalctl -u brain-signal-bridge -f          # logs; ignored senders are logged with their UUID
```

Units are in `infra/` (copy to `/etc/systemd/system/` after changes). signal-cli is the native
build in `~/.local/opt/`. Signal stops accepting old clients after a few months, so the nightly
job opens a "signal-cli <version> available" issue when a new release is out, with the
(manual, signature-checked) update steps.

### tmux (optional)

Not required. Sessions are kept on disk, so after a disconnect you can reconnect and run
`claude --continue`. Use tmux when the **agent must keep working while you're disconnected**:
long tasks, or flaky phone connections, where a dropped SSH connection would otherwise stop the
agent mid-task.

```bash
tmux new -A -s main   # start, or re-attach to, a session named "main"
                      # detach: Ctrl-b then d  ·  new window: Ctrl-b c  ·  switch: Ctrl-b n
```

## Roadmap

- [x] Host: droplet, key-only SSH, firewall, CLIs logged in
- [x] Repo skeleton
- [x] `bin/council`: same prompt to several models, then a synthesizer
- [x] Hindsight (lean config) as shared MCP memory — see `infra/hindsight/`
- [x] Session hooks: recall at start, retain at end (Hindsight coding-agents plugin)
- [x] Nightly reflect job → PR with proposed knowledge edits (`bin/nightly`, 04:00 UTC timer)
- [x] `bin/reindex`: knowledge/ → Hindsight (incremental)
- [x] Phone access over Signal (`bin/signal-bridge`)
- [x] Engine and data split into a public and a private repo (`data/`, `bin/leak-check`)
