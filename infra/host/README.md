# Host hardening

How the `brain` droplet is locked down. Access is public key-only SSH plus the provider's web
console; there is no VPN or overlay network (Tailscale was removed 2026-11-03).

| File here | Installed as |
|---|---|
| `sshd-00-hardening.conf` | `/etc/ssh/sshd_config.d/00-hardening.conf` |
| `fail2ban-zz-sshd-session.conf` | `/etc/fail2ban/jail.d/zz-sshd-session.conf` |
| `journald-size.conf` | `/etc/systemd/journald.conf.d/size.conf` |

```bash
# sshd: key-only, AllowUsers brain root, no X11/agent forwarding. Delete cloud-init's drop-in,
# which says "PasswordAuthentication yes" (overridden today only because 00- is read first).
sudo install -m 644 sshd-00-hardening.conf /etc/ssh/sshd_config.d/00-hardening.conf
sudo rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo sshd -t && sudo systemctl reload ssh

# Firewall: deny incoming, allow SSH only.
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow OpenSSH && sudo ufw enable

# fail2ban: Ubuntu's defaults-debian.conf matches only _COMM=sshd, but OpenSSH >= 9.8 logs
# auth failures from sshd-session, so without this override nothing is ever banned.
sudo apt install fail2ban
sudo install -m 644 fail2ban-zz-sshd-session.conf /etc/fail2ban/jail.d/zz-sshd-session.conf
sudo fail2ban-client -t && sudo systemctl restart fail2ban
sudo fail2ban-client status sshd      # "Total failed" should climb within minutes

# The image's default "ubuntu" user: locked, no keys; also remove its sudo rights.
sudo gpasswd -d ubuntu sudo
sudo sed -i '/^ubuntu ALL=/d' /etc/sudoers.d/90-cloud-init-users && sudo visudo -c

# Journal: cap at 200 MB (it is otherwise unbounded up to 10% of the disk).
sudo install -D -m 644 journald-size.conf /etc/systemd/journald.conf.d/size.conf
sudo systemctl restart systemd-journald
```

RAM: `/tmp` is a tmpfs capped at half of the 1 GB RAM, so anything written there uses memory.
Keep large temporary files on disk (e.g. `~/.cache/`); `brain-signal.service` does this for
signal-cli's ~190 MB native library.

Updates: unattended-upgrades installs security updates daily, but kernel updates need a reboot
(`/var/run/reboot-required`). Use a clean `sudo reboot`, not the provider's hard power cycle;
all services are enabled and come back on their own.

## Session-start sync hook

`bin/sync-main` runs from the Claude Code and Codex SessionStart hooks, which live outside the
repo; see step 4 of [../README.md](../README.md).
