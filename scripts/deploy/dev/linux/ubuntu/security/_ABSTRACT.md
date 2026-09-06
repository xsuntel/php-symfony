# Dev Environment

## Platform

* Linux - Ubuntu Desktop

### User

* User

```bash
sudo cat /etc/shadow

# Login ID : User Password : Last changed data : MIN : MAX : WARNING : INACTIVE : EXPIRE : Flag
```

```bash
sudo lastlog -b 90
```

* Group

```bash
sudo cat /etc/group

# Group Name : x : GID : Group Members
```

```bash
sudo cat /etc/gshadow

# Group Name : Group Password : Administrator : Group Members
```

* Services

```bash
/usr/bin/systemd-sysusers --cat-config
```

* Modify passwd

```bash
sudo cat /etc/passwd

# Login ID : x : UID : GID : Description : Home Directory : Login Shell

sudo userdel list
sudo userdel sync
sudo userdel games
sudo userdel uucp
sudo userdel uuidd
sudo userdel news
sudo userdel tcpdump
sudo userdel speech-dispatcher
sudo userdel tss

sudo userdel adm
sudo userdel shutdown
sudo userdel halt
sudo userdel operator
sudo userdel gopher
sudo userdel nfsnobody
sudo userdel squid

sudo vi /usr/lib/sysusers.d/basic.conf
~

g fax   21  -
g vioce 22  -
g tape  26  -
g game  38  -

u sync       4:65534 - /bin                 /bin/sync
u games      5:60    - /usr/games           /usr/sbin/nologin

u news       9       - /var/spool/news      /usr/sbin/nologin
u uucp       10      - /var/spool/uucp      /usr/sbin/nologin

u list       38      - /var/list            /usr/sbin/nologin
u irc        39      - /run/ircd            /usr/sbin/nologin
```

```bash
sudo rm -f /etc/init.d/cups

sudo rm -f /etc/init.d/speech-dispatcher

sudo rm -f /etc/init.d/uuidd
```

#### Directories

* Update permission

```bash
sudo chown root:root /etc/sysctl.conf
sudo chmod 600 /etc/sysctl.conf
sudo ls -l /etc/sysctl.conf

sudo chown root:root /etc/hosts
sudo chmod 644 /etc/hosts
sudo ls -l /etc/hosts

sudo chown root:root /etc/passwd
sudo chmod 644 /etc/passwd
sudo ls -l /etc/passwd

sudo chown root:root /etc/shadow
sudo chmod 400 /etc/shadow
sudo ls -l /etc/shadow

sudo chown root:root /etc/rsyslog.conf
sudo chmod 640 /etc/rsyslog.conf
sudo ls -l /etc/rsyslog.conf

sudo chown root:root /etc/services
sudo chmod 644 /etc/services
sudo ls -l /etc/services

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
```

* Update umask in Prod Environment

```bash
sudo vi /etc/profile
~
TMOUT=600
export TMOUT

umask 022
export umask
```

```bash
sudo vi ~/.bashrc
~
umask 022
```
