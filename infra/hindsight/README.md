# Hindsight (lean config)

Runs on the `brain` host as `hindsight.service`, bound to 127.0.0.1:8888, one bank named by
`HINDSIGHT_BANK_ID` in `data/brain.env` (below: `$BANK`).
Footprint (v1.2.1, measured 2026-11-13): ~100–400 MB resident, plus ~1.1 GB that the API
process allocates at startup and rarely touches, so it sits in swap. That's about 375 MB of ONNX
model weights and about 300 MB of heap left over from loading them; the glibc `MALLOC_*`
settings in `hindsight.env` reclaim only ~100 MB of it. The earlier figure of ~400–470 MB counted
only resident memory. The cost is speed: the first recall after a restart takes ~6 s while pages
come back from swap, and later ones are under 1 s. The unit caps RAM at 900 MB and swap at
1.5 GB, so a runaway process is OOM-killed and restarted (`Restart=on-failure`) instead of filling
the host's swap. A 1.2 GB swap cap was too tight: it got OOM-killed during startup.

| Choice | Setting | Why |
|---|---|---|
| LLM | `claude-code`, `claude-haiku-5-5`, max 2 concurrent | Uses the Claude subscription, no API key; Haiku spares rate limits |
| Embeddings | `onnx` (default `multilingual-e5-small`) | Light runtime, no PyTorch |
| Reranker | `rrf` | No neural reranker; fine at personal scale |
| Database | embedded pg0 (data in `~/.pg0`) | No separate Postgres service |

## Rebuild on a fresh host

```bash
mkdir -p ~/hindsight && cd ~/hindsight
cp ~/brain/infra/hindsight/{hindsight.env,run.sh} . && chmod +x run.sh
uv venv .venv && uv pip install --python .venv/bin/python "hindsight-api-slim[local-onnx,embedded-db]==1.2.3"
sudo loginctl enable-linger brain
sudo mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nRemoveIPC=no\n' | sudo tee /etc/systemd/logind.conf.d/no-removeipc.conf
sudo systemctl restart systemd-logind
sudo cp ~/brain/infra/hindsight/hindsight.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now hindsight
BANK=$(sed -n 's/^HINDSIGHT_BANK_ID=//p' ~/brain/data/brain.env)
claude mcp add --transport http --scope user hindsight-memory http://127.0.0.1:8888/mcp/$BANK/
codex mcp add hindsight-memory --url http://127.0.0.1:8888/mcp/$BANK/
# Retain mission (what the bank keeps): owner-specific, so it lives in the data repo.
curl -sf -X PATCH -H 'Content-Type: application/json' -d @$HOME/brain/data/hindsight/bank-config.json \
  http://127.0.0.1:8888/v1/default/banks/$BANK/config
```

Then re-index: `~/brain/bin/reindex --all`.

**Linger and `RemoveIPC=no` are required.** The embedded Postgres runs as `brain`, and by
default systemd deletes a user's shared memory when their last login session ends. Postgres
keeps running, but every query fails with `could not open shared memory segment
"/PostgreSQL.…"`, so Hindsight returns HTTP 500s until it is restarted. Linger keeps the
`brain` user manager alive (which exempts it); `RemoveIPC=no` disables the clean-up outright, as
the Postgres docs recommend. If you see that error, apply both and
`sudo systemctl restart hindsight`.

## Backups and restore

`bin/backup-memory` (run first thing by `bin/nightly`) writes a plain-SQL `pg_dump` of the
Hindsight database to `hindsight.sql` on the orphan branch `memory-backup` of the private data
repo (never the engine repo: it is the full personal memory), via a worktree at
`~/brain-memory-backup`. Plain text keeps git storage to daily deltas; the
`llm_requests` log table is dumped schema-only.

Restore onto a fresh install (after the rebuild steps above, with the service started once so
pg0 exists):

```bash
sudo systemctl stop hindsight
git -C ~/brain/data fetch origin memory-backup
git -C ~/brain/data show origin/memory-backup:hindsight.sql > /tmp/hindsight.sql
PG=$(ls -d ~/.pg0/installation/*/bin)
~/.pg0/installation/*/bin/pg_ctl -D ~/.pg0/instances/hindsight/data status || \
  ~/.pg0/installation/*/bin/pg_ctl -D ~/.pg0/instances/hindsight/data -l /tmp/pg.log start
PGPASSWORD=hindsight $PG/psql -h 127.0.0.1 -U hindsight -d postgres \
  -c "DROP DATABASE IF EXISTS hindsight" -c "CREATE DATABASE hindsight"
PGPASSWORD=hindsight $PG/psql -h 127.0.0.1 -U hindsight -d hindsight -q -f /tmp/hindsight.sql
~/.pg0/installation/*/bin/pg_ctl -D ~/.pg0/instances/hindsight/data stop
sudo systemctl start hindsight
```

## Session hooks (auto recall / auto retain)

Hindsight coding-agents plugin, config in `coding-agent.json` (copy to `~/.hindsight/` and set
`bankId` to your `HINDSIGHT_BANK_ID`):

    npx @vectorize-io/hindsight-coding-agents install claude-code --server self-hosted --api-url http://127.0.0.1:8888
    npx @vectorize-io/hindsight-coding-agents install codex --server self-hosted --api-url http://127.0.0.1:8888

Recall is injected on the first prompt; the transcript is retained on Stop. Set
`HINDSIGHT_DISABLE_HOOKS=1` to skip both for a call (`bin/council` does this).
