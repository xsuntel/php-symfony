# Dev Environment

## Platform

* Linux - Ubuntu Desktop

### System

#### GRUB (Grand Unified Bootloader)

* Update Kernel - /etc/default/grub

```bash
sudo vi /etc/default/grub
~
GRUB_CMDLINE_LINUX="ipv6.disable=1 crashkernel=no net.ifnames=0 biosdevname=0"
CRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=nommconf"

sudo update-grub
```

#### Kernel

* Remove kerneloops

```bash
sudo systemctl stop kerneloops

sudo systemctl disable kerneloops
```

```bash
sudo systemctl stop sysstat

sudo systemctl disable sysstat
```

* Update Kernel - /etc/sysctl.conf

```bash
sudo vi /etc/sysctl.conf
~

# Network - ipv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

net.ipv6.conf.all.use_tempaddr=0
net.ipv6.conf.default.use_tempaddr=0

# Network - ipv4
net.ipv4.icmp_echo_ignore_all=1
```

```bash
sudo sysctl -a | grep userns

sudo ls -ltr /proc/sys/kernel

sudo dmesg | tail -n 100
```

#### Module

* Update Kernel - /etc/modprobe.d/blacklist.conf

```bash
lsmod

sudo vi /etc/modprobe.d/blacklist.conf
~
# Customize - Mainboard ACPI
blacklist acpi_thermal_rel
blacklist int3403_thermal
blacklist i801_smbus
blacklist lp

sudo dpkg-reconfigure linux-image-$(uname -r)
```

* Update Kernel - /etc/sysctl.d/10-ipv6-privacy.conf

```bash
sudo vi /etc/sysctl.d/10-ipv6-privacy.conf

net.ipv6.conf.all.use_tempaddr = 0
net.ipv6.conf.default.use_tempaddr = 0


netstat -lpn
```

#### Boot Up

* Update a file : /etc/rc.local

```bash
sudo vi /etc/rc.local
~
```

```bash
sudo chmod +x /etc/rc.local

sudo systemctl status rc-local.service
```

```bash
sudo vi /lib/systemd/system/rc-local.service
~

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable rc-local.service

sudo systemctl start rc-local.service
```
