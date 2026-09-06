# Dev Environment

## Platform

* Mac - MacOS

### Network

* Check hosts

```bash
grep -v '#' /etc/hosts
```

* Append localhost entry (only when missing)

```bash
echo $'\n127.0.0.1 localhost' | sudo tee -a /etc/hosts
```

* Host name

```bash
scutil --get HostName
uname -n
```

* Hardware ports and interfaces

```bash
networksetup -listallhardwareports

ifconfig
```

* Routing and DNS

```bash
netstat -rn

scutil --dns
```

### Firewall

* Application Firewall — global state (read-only)

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

* Application Firewall — allowed applications

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
```

## Reference

* [scutil](https://ss64.com/mac/scutil.html)
* [networksetup](https://ss64.com/mac/networksetup.html)
