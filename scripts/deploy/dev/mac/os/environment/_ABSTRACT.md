# Scripts - Mac

## Dev Environment

## Platform

* Mac - MacOS

### Time Synchronization

macOS uses `sntp` (not `ntpd`/`timedatectl`).

* Force a one-time sync

```bash
sudo sntp -sS time.apple.com
```

* Toggle automatic network time

```bash
sudo systemsetup -setusingnetworktime on

sudo systemsetup -getusingnetworktime
```

### Power

macOS uses `pmset` (not `systemd` targets).

* Show current settings

```bash
pmset -g
```

* Disable display/system sleep on AC power

```bash
sudo pmset -c displaysleep 0
sudo pmset -c sleep 0
```

### Scheduler

macOS uses `launchd` (not `cron`/`systemd`).

* List loaded jobs

```bash
launchctl list
```

* User LaunchAgents directory

```bash
ls -l ~/Library/LaunchAgents
```

## Reference

* [launchd.info](https://launchd.info)
* [pmset](https://ss64.com/mac/pmset.html)
