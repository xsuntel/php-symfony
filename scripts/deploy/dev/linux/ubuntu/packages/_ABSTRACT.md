# Dev Environment

## Platform

* Linux - Ubuntu Desktop

### Packages

#### snap

* Update snap-store

```bash
sudo killall snap-store

sudo snap refresh
```

#### gsd

* Disable gsd-sharing

```bash
sudo vi /etc/xdg/autostart/org.gnome.SettingsDaemon.Sharing.desktop
~
X-GNOME-Autostart-Phase=false
X-GNOME-Autostart-Notify=false
X-GNOME-AutoRestart=false

systemctl --user status org.gnome.SettingsDaemon.Sharing.service

systemctl --user mask org.gnome.SettingsDaemon.Sharing.service
```

* Disable gsd-smartcard

```bash
sudo vi /etc/xdg/autostart/org.gnome.SettingsDaemon.Smartcard.desktop
~
X-GNOME-Autostart-Phase=false
X-GNOME-Autostart-Notify=false
X-GNOME-AutoRestart=false

systemctl --user mask org.gnome.SettingsDaemon.Smartcard.service
```

* Disable gsd-wacom

```bash
sudo vi /etc/xdg/autostart/org.gnome.SettingsDaemon.Wacom.desktop
~
X-GNOME-Autostart-Phase=false
X-GNOME-Autostart-Notify=false
X-GNOME-AutoRestart=false

systemctl --user mask org.gnome.SettingsDaemon.Wacom.service
```
