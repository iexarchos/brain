# Rebuilding the host

Everything needed to set `brain` up again on a fresh Ubuntu droplet (1 vCPU / 1 GB), in order.
Secrets are not in the repo: you need the laptop's SSH key, logins for GitHub, Claude and
ChatGPT, and brain's Signal number. Notes come back from the private data repo and memory from
its `memory-backup` branch.

## 1. User and access (as root, from the provider's web console)

```bash
adduser --disabled-password --gecos "" brain
echo 'brain ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-brain && chmod 440 /etc/sudoers.d/90-brain
install -d -m 700 -o brain -g brain /home/brain/.ssh
cp /root/.ssh/authorized_keys /home/brain/.ssh/ && chown brain: /home/brain/.ssh/authorized_keys
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

Then harden SSH, the firewall and fail2ban: [host/README.md](host/README.md). Everything below
runs as `brain` over SSH.

## 2. Tools and logins

```bash
sudo apt install -y git gh nodejs npm tmux
npm config set prefix ~/.npm-global && npm i -g @openai/codex
curl -fsSL https://claude.ai/install.sh | bash                # Claude Code → ~/.local/bin
curl -LsSf https://astral.sh/uv/install.sh | sh                # uv → ~/.local/bin
echo 'export PATH="$HOME/brain/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> ~/.profile
. ~/.profile
gh auth login                 # HTTPS, browser/device code; also sets up git credentials
claude                        # log in with the Claude subscription, then exit
codex login                   # ChatGPT subscription
```

Codex keeps project config and MCP servers off for `codex exec` in untrusted folders (since
0.169), which would cut the council's Codex member off from Hindsight. Mark the repo trusted in
`~/.codex/config.toml`:

```toml
[projects."/home/brain/brain"]
trust_level = "trusted"
```

Codex renews its ChatGPT login only when it runs; the weekly review makes one tiny call to keep it
renewed and reports a failure (fix: `codex login`).

Interactive logins expire, and the headless jobs (nightly, weekly review, Hindsight's fact
extraction) then fail silently. Give them a long-lived token instead. It stays outside the repo,
and their units load it with `EnvironmentFile=-`:

```bash
claude setup-token            # browser sign-in; prints a token valid for about a year
install -m 600 /dev/null ~/.config/brain/claude.env
printf 'CLAUDE_CODE_OAUTH_TOKEN=%s\n' 'PASTE-TOKEN' > ~/.config/brain/claude.env
sudo systemctl restart hindsight
```

**Not for the Signal bridge.** A setup-token can only make model requests and can't fetch
claude.ai connectors, and it takes priority over the `/login` sign-in, so the bridge would lose
Google Drive ([docs](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token)).
The bridge keeps the interactive login: renew it with `claude auth login` when it nears expiry.
Don't use `--bare` with the token either, because bare mode doesn't read it.

The nightly job warns (as a "Nightly failed" issue) when the interactive sign-in ends within 7 days,
or the token is within 14 days of its one-year life (counted from when `claude.env` was written).

## 3. Repos

The engine (this repo) goes in `~/brain`, the owner's private data repo inside it as `data/`:

```bash
gh repo clone <you>/brain ~/brain
~/brain/bin/init-data --clone <you>/brain-data     # or, first time: init-data "Your Name" <you>/brain-data
git -C ~/brain config core.hooksPath .githooks      # leak-check on commit and push (init-data sets this)
# Commits to the public engine should not carry your private email: use GitHub's noreply address.
git -C ~/brain config user.name <you>
git -C ~/brain config user.email <id>+<you>@users.noreply.github.com
git -C ~/brain/data config user.name "<Your Name>"
git -C ~/brain/data config user.email <your email>
```

Then list your name, email, phone numbers and other identifying strings in
`~/brain/data/denylist.txt`; `bin/leak-check --tree` checks the whole engine against it.

## 4. Hindsight, memory restore and session hooks

Follow [hindsight/README.md](hindsight/README.md): install, restore the `memory-backup` dump,
`bin/reindex --all`, then the coding-agents plugin, which writes the recall/retain hooks into
`~/.claude/settings.json` and `~/.codex/hooks.json`.

**After** the plugin install (it rewrites those files), add `bin/sync-main` as the first
SessionStart hook in both, so every session fast-forwards `main` from GitHub:

```json
{ "type": "command", "command": "/home/brain/brain/bin/sync-main", "timeout": 20 }
```

Also set `"autoMemoryEnabled": false` in `~/.claude/settings.json`. That turns off Claude Code's
own memory, so memory lives only in `data/knowledge/` and Hindsight, which Codex sees too.

In `~/.claude/settings.json` it goes in `hooks.SessionStart[0].hooks`, before the Hindsight
entry; `~/.codex/hooks.json` has the same shape. These files live outside the repo because
they apply to every session on the host, wherever it starts.

**Turn off the plugin's knowledge pages** (unused here; memory goes through `hindsight-memory`).
A plugin reinstall undoes all three steps, so redo them after one:

1. Prefix the Hindsight SessionStart hook in both files with the filter, which strips the
   `<hindsight_pages>` tool guide the plugin always injects (it has no setting for that):

   ```json
   { "type": "command", "command": "/home/brain/brain/bin/hindsight-hook-filter node \"/home/brain/.hindsight/coding-agents/dist/claude-sessionstart-hook.js\"", "timeout": 30 }
   ```

   (`codex-sessionstart-hook.js` in `~/.codex/hooks.json`). The per-turn refresh of the same
   guide is off via `"pageRefreshEveryTurns": 1000000000` in `coding-agent.json` (`0` means 1).
2. Remove the plugin's MCP server from Claude Code: `claude mcp remove hindsight -s user`.
3. Disable it in Codex: add `enabled = false` under `[mcp_servers.hindsight]` in
   `~/.codex/config.toml` (keep the entry, so a reinstall doesn't add a second one).

Recall injection and session write-back keep working; they come from the hooks, not the server.

## 5. Nightly job

```bash
sudo cp ~/brain/infra/brain-nightly.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now brain-nightly.timer
~/brain/bin/nightly --dry-run    # should list facts (or "no new facts") without errors
```

## 5b. Weekly review

```bash
sudo cp ~/brain/infra/brain-weekly-review.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now brain-weekly-review.timer
~/brain/bin/weekly-review --dry-run    # prints the host facts the review is based on
```

## 6. Signal bridge

Install the native signal-cli build (signing key: AsamK, `FA10826A74907F9EC6BBB7FC2BA2CD21B5B09570`):

```bash
gpg --keyserver keys.openpgp.org --recv-keys FA10826A74907F9EC6BBB7FC2BA2CD21B5B09570
v=$(gh api repos/AsamK/signal-cli/releases/latest -q .tag_name); v=${v#v}; mkdir -p ~/.cache && cd ~/.cache   # not /tmp: it is RAM-backed here
gh release download v$v -R AsamK/signal-cli -p "signal-cli-$v-Linux-native.tar.gz*"
gpg --verify signal-cli-$v-Linux-native.tar.gz.asc      # "Good signature from AsamK"
mkdir -p ~/.local/opt/signal-cli-$v && tar -xzf signal-cli-$v-Linux-native.tar.gz -C ~/.local/opt/signal-cli-$v
ln -sfn ~/.local/opt/signal-cli-$v/signal-cli ~/.local/bin/signal-cli
sudo cp ~/brain/infra/brain-signal{,-bridge}.service /etc/systemd/system/ && sudo systemctl daemon-reload
```

Then register the number, write `~/.config/brain/signal.env` (mode 600) and enable both units,
as in the README's [Signal section](../README.md#4-signal-phone). Signal data (account keys,
linked groups) lives in `~/.local/share/signal-cli` and is not backed up: on a new host,
re-register the number and recreate the topic groups.

## 7. Check

```bash
systemctl is-active hindsight brain-signal brain-signal-bridge fail2ban ufw ssh.socket
systemctl list-timers brain-nightly.timer brain-weekly-review.timer
sudo ufw status && sudo fail2ban-client status sshd
```

Start `claude` in `~/brain` and confirm the Hindsight banner appears, then message brain on
Signal.
