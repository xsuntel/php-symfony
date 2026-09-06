# Dev Environment

## Platform

* Windows 11 - WSL2 (Ubuntu)

WSL2 runs the guest on a lightweight VM whose networking is managed by the Windows host. The physical
NIC, Wi-Fi radio, `netplan`, `NetworkManager`, `ebtables`, and `udev` interface naming that a native
Ubuntu Desktop install would configure **do not apply here**. Those Ubuntu-desktop artifacts were
removed from this tree; only host-level (`/etc/hosts`) configuration remains active in `_base.sh`.

### Networking Mode

WSL2 defaults to NAT. Networking behaviour is controlled from `/etc/wsl.conf` inside the distro and,
for host-wide settings, `%UserProfile%\.wslconfig` on Windows.

```bash
sudo vi /etc/wsl.conf

[boot]
systemd=true

[network]
generateHosts=true
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=true
```

Apply changes from a Windows terminal:

```bash
wsl --shutdown
```

### Hosts

WSL2 regenerates `/etc/hosts` on each boot when `generateHosts=true`. `_base.sh` only ensures a
`127.0.0.1 localhost` entry is present for local development; do not hand-maintain this file unless
`generateHosts=false`.

### DNS

With `generateResolvConf=true`, WSL2 writes `/etc/resolv.conf` from the Windows resolver. Disable
generation only if you need to pin custom nameservers.

```bash
resolvectl status --no-pager
```

## Reference

* Microsoft - [WSL Configuration (wsl.conf / .wslconfig)](https://learn.microsoft.com/windows/wsl/wsl-config)
* Microsoft - [WSL Networking](https://learn.microsoft.com/windows/wsl/networking)
