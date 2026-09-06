# Dev Environment

## Platform

* Mac - MacOS

### Security

* Gatekeeper — application execution policy

```bash
spctl --status
```

* System Integrity Protection (SIP) — read from Recovery if disabled

```bash
csrutil status
```

* FileVault — full-disk encryption status

```bash
fdesetup status
```

### Users

* Default file creation mask (zsh login shell)

```bash
grep -qsF "umask 022" ~/.zprofile || printf '# Default File Creation Mask\numask 022\n' >> ~/.zprofile
```

* Group membership (read-only)

```bash
id -Gn "${USER}"

dscl . -read "/Users/${USER}" NFSHomeDirectory PrimaryGroupID
```

> Do not delete accounts on macOS. System daemons use `_`-prefixed accounts managed by
> Directory Service — removing them can break the OS.

## Reference

* [spctl](https://ss64.com/mac/spctl.html)
* [csrutil](https://ss64.com/mac/csrutil.html)
* [fdesetup](https://ss64.com/mac/fdesetup.html)
