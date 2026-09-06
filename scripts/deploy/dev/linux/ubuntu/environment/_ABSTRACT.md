# Scripts - Linux

## Dev Environment

## Platform

* Linux - Ubuntu Desktop

### System

### Crontab

* Update cron

```bash
sudo chown root:root /etc/crontab
sudo chmod 640 /etc/crontab

sudo chown root:root /etc/cron.d/
sudo chmod 640 /etc/cron.d/

sudo chown root:root /etc/cron.daily/
sudo chmod 640 /etc/cron.daily/

sudo chown root:root /etc/cron.hourly/
sudo chmod 640 /etc/cron.hourly/

sudo chown root:root /etc/cron.monthly/
sudo chmod 640 /etc/cron.monthly/

sudo chown root:root /etc/cron.weekly/
sudo chmod 640 /etc/cron.weekly/

sudo chown root:root /etc/cron.yearly/
sudo chmod 640 /etc/cron.yearly/

sudo ls -l /etc/crontab

sudo vi /etc/crontab
~
#17 * * * * root cd / && run-parts --report /etc/cron.hourly
#25 6 * * * root test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
#47 6 * * 7 root test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
#52 6 1 * * root test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
```

* Check status

```bash
sudo systemctl status cron
```

* Modify crontab

```bash
sudo vi /etc/crontab
~
01 02 15 * * root /root/backup.sh
```

### ntpd

* Test cron

```bash
timedatectl set-ntp 0

date 011502002026

sudo systemctl restart cron

ls -l /raid6/backup/
```

```bash
timedatectl set-ntp 1
```

### Services

* Check services list

```bash
cat /etc/services

service --status-all
```

#### anacron

* Disable anacron

```bash
sudo vi /etc/anacrontab

# These replace cron's entries
#1      5       cron.daily      run-parts --report /etc/cron.daily
#7      10      cron.weekly     run-parts --report /etc/cron.weekly
#@monthly       15      cron.monthly    run-parts --report /etc/cron.monthly

sudo systemctl disable anacron
```

#### apport

* Disable apport

```bash
sudo vi /etc/default/apport
~
enabled=0

sudo systemctl disable apport
```

#### unattended-upgrades

* Disable unattended-upgrades

```bash
sudo systemctl disable unattended-upgrades

sudo apt remove --purge unattended-upgrades
```

### backup

* Create a shell-script

```bash
cd /root
touch backup.sh
chmod 755 backup.sh
ls -l backup.sh
```

* Modify the shell-script

```bash
sudo vi ./backup.sh

#!/bin/bash
set $(date)
file_name="backup-$1$2$3tar.xz"
tar cfj /home/$USER/ /home
```

* Crete a directory for backup

```bash
mkdir -p /raid6/backup

sudo systemctl restart cron
```

#### Power

* Monitor

```bash
# Display
gsettings set org.gnome.desktop.session idle-delay 0
```

* Disable Suspend

```bash
# AC Power
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Bettery
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

* System

```bash
# System
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
