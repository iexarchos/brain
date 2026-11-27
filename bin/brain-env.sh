# brain-env.sh — sourced by the bin/ shell scripts (not run directly).
#
# Sets up the two checkouts and the owner's settings:
#   REPO   the engine (public repo): bin/, prompts/, skills/, infra/, AGENTS.md
#   DATA   the owner's data (private repo): knowledge/, archive/, runs/, brain.env, AGENTS.md
#          default $REPO/data; override with BRAIN_DATA
# Then loads $DATA/brain.env (OWNER_NAME, HINDSIGHT_BANK_ID, BRAIN_DATA_REPO, …); variables
# already set in the environment win. GH_REPO points `gh` at the data repo, so PRs and issues
# (which carry personal content) never land on the public engine repo.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${BRAIN_DATA:-$REPO/data}"
if [ -f "$DATA/brain.env" ]; then
  while IFS='=' read -r _k _v; do
    _k="${_k//[[:space:]]/}"
    case "$_k" in ''|\#*) continue ;; esac
    [ -n "${!_k+x}" ] || export "$_k=$(printf '%s' "$_v" | sed -E "s/^[\"']//; s/[\"']$//")"
  done < "$DATA/brain.env"
  unset _k _v
fi
OWNER_NAME="${OWNER_NAME:-the owner}"
HINDSIGHT_BANK_ID="${HINDSIGHT_BANK_ID:-brain}"
if [ -z "${GH_REPO:-}" ]; then
  GH_REPO="${BRAIN_DATA_REPO:-$(git -C "$DATA" remote get-url origin 2>/dev/null \
    | sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##' || true)}"
fi
export REPO DATA OWNER_NAME HINDSIGHT_BANK_ID
[ -n "$GH_REPO" ] && export GH_REPO || unset GH_REPO

# render <file>: print a prompt template with {{OWNER}} replaced by the owner's name.
render() { OWNER="$OWNER_NAME" python3 -c 'import os,sys; sys.stdout.write(open(sys.argv[1]).read().replace("{{OWNER}}", os.environ["OWNER"]))' "$1"; }

# require_data: stop with a hint when there is no data checkout yet.
require_data() {
  [ -d "$DATA/knowledge" ] || { echo "$(basename "$0"): no data repo at $DATA (see bin/init-data)" >&2; exit 1; }
}
