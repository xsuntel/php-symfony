# CLAUDE.md

This file configures Claude's behavior and expertise context for this project; Claude reads it automatically when
working in this repository.

## Platform Premises (Non-negotiable)

This directory covers **only the WSL2 (Ubuntu) development environment on Windows**. It is a
**terminal-only environment** with no desktop session, and the premises below apply to every file in this tree.

- **GNOME is not used.** WSL2 has no desktop session, so **do not add** GUI items such as `gnome-*`
  packages, `org.gnome.SettingsDaemon.*` units, `gsettings org.gnome.*` settings,
  `/etc/xdg/autostart/**`, or `snap-store`.
- **All work happens in the terminal.** Desktop concerns such as screen blanking, auto-lock, remote
  desktop, and input methods (ibus) are **managed by the Windows host** and are not this tree's responsibility.
- **Power management does not apply.** WSL2 has no suspend/hibernate, so
  `systemctl mask sleep.target ...` has no effect either.
- When porting a file from `linux/ubuntu/`, **strip the GNOME and desktop sections first**, then apply it —
  do not diff the two trees naively, judge the removal a "gap", and revert it.

## Directory Structure & Path Context

```text
./                                           ← repository root
└── scripts/deploy/dev/windows/wsl/          ← Windows WSL2 development environment deployment scripts
    ├── environment/                         ← cron · log cleanup
    │   ├── usr/local/bin/                   ← cron executables installed into /usr/local/bin
    │   │   ├── symfony-scripts-logs.sh      ← empty the Symfony logs
    │   │   └── ubuntu-var-logs.sh           ← clean up /var/log · supervisor · ufw logs
    │   ├── _ABSTRACT.md
    │   └── _crontab.sh                      ← cron.allow · crontab registration
    ├── network/                             ← hosts file configuration
    │   ├── _ABSTRACT.md
    │   └── _base.sh
    ├── packages/                            ← package installation · removal
    │   ├── _ABSTRACT.md
    │   ├── _base.sh                         ← curl·git·wget·unzip·net-tools·lsof·shfmt·shellcheck
    │   ├── _network.sh                      ← remove openssh-server·telnet and friends
    │   └── _ubuntu_pro.sh                   ← remove Ubuntu Pro·unattended-upgrades
    ├── security/                            ← permissions · files · user cleanup
    │   ├── _ABSTRACT.md
    │   ├── _directories.sh
    │   ├── _files.sh
    │   └── _users.sh
    ├── _ABSTRACT.md                         ← WSL2 installation · project variables · deployment procedure
    ├── _DESKTOP.md                          ← hardware specification (desktop)
    ├── _NOTEBOOK.md                         ← hardware specification (notebook)
    ├── deploy.sh                            ← entry point — run the initial setup
    ├── status.sh                            ← entry point — status check
    └── CLAUDE.md
```

## Differences from the ubuntu Tree

These items exist in the `linux/ubuntu/` counterpart but are **intentionally absent** from this tree. When asked
to add one, push back on the grounds of the `Platform Premises` above.

| Item | Reason for absence |
| --- | --- |
| `packages/_remote_desktop.sh` | Exists solely to remove `gnome-remote-desktop` and mask the GNOME SettingsDaemon |
| `environment/_booting.sh`·`etc/rc.local` | Boot is managed by `[boot] systemd=true` in `/etc/wsl.conf` (`_ABSTRACT.md`) |
| `environment/_ntpd.sh`·`_power.sh` | Time synchronization and power are the Windows host's concern |
| The `ibus-hangul` and GNOME removal sections of `packages/_base.sh` | There is no input method and there are no desktop apps |

## Authoring Conventions

The single source of truth (SoT) for shell script criteria is `.claude/rules/utility-shell-script-rule.md`;
what follows are the additional conventions that apply only to this tree.

- **The header banner follows the folder path** — `# Scripts - Deploy - Dev - Windows - WSL - {role}`.
  When copying from `linux/ubuntu/`, always fix it so no `Linux - Ubuntu` is left behind.
- **The platform notation in documents (`_ABSTRACT.md`) is written as `* Windows - WSL (Ubuntu)`**.
- **Do not use macOS-only commands** — this tree is Ubuntu, so it is `md5sum`, not `md5`
  (these frequently slip in when porting documents from `mac/os/`).
- On top of the `PLATFORM_TYPE != Linux` check, the entry points (`deploy.sh`·`status.sh`) verify that
  `/proc/sys/kernel/osrelease` contains `microsoft`, to **block native Ubuntu machines**.
- The sourcing order in `deploy.sh` is `network` → `packages`(`_base` → `_network` → `_ubuntu_pro`) →
  `security`(`_directories` → `_files` → `_users`) → `environment`(`_crontab`).
  Keep the same order as the ubuntu counterpart, but skip the items absent per the table above.

## Usage

```bash
# WSL2 development environment initial setup (run once on a new machine)
bash scripts/deploy/dev/windows/wsl/deploy.sh

# Status check
bash scripts/deploy/dev/windows/wsl/status.sh
```

## Quality Gates

```bash
# ShellCheck (respecting the rules disabled in scripts/base/.shellcheckrc) — 0 findings is the baseline
find scripts/deploy/dev/windows/wsl -name "*.sh" -exec shellcheck {} +

# Syntax check
find scripts/deploy/dev/windows/wsl -name "*.sh" -exec bash -n {} \;

# Verify no GNOME item has crept back in — the output must be empty
# --exclude=CLAUDE.md : prevents the self-referential false positive where this file's own
#                       prohibition text and the pattern literals below match themselves
# grep -vE ...        : drops comment (#) and quote (>) lines, so only executed commands are
#                       detected rather than explanatory prose
grep -rniI --exclude=CLAUDE.md "gnome\|gsd-\|gsettings\|xdg/autostart\|snap-store" \
  scripts/deploy/dev/windows/wsl/ | grep -vE ':[0-9]+:[[:space:]]*(#|>)'
```

## References

- `scripts/CLAUDE.md` — the overall `scripts/**` structure · category purposes · shared function pattern
- `.claude/rules/utility-shell-script-rule.md` — shell script criteria (SoT)
- `scripts/deploy/dev/windows/wsl/network/_ABSTRACT.md` — why `netplan`·`NetworkManager`·`ebtables`·`udev`
  interface naming are host concerns in this tree
- `scripts/deploy/dev/linux/ubuntu/` — the counterpart tree that does have a desktop session
