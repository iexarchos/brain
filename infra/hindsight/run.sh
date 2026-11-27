#!/usr/bin/env bash
# Start Hindsight API in the foreground with the lean config (used by systemd and for testing).
cd "$(dirname "$0")"
set -a; . ./hindsight.env; set +a
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
exec .venv/bin/hindsight-api
