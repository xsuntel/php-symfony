# Visual Studio Code

## Download

### Install

#### Option - 1

* .deb package (remove the Snap build first, then install the downloaded .deb)

```text
sudo snap remove code

sudo dpkg -i code_*.deb

sudo apt --fix-broken install
```

#### Option - 2

* Microsoft GPG

```text
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt update
sudo apt install code
```

## Reference

### IDE

* [VSCode](https://code.visualstudio.com/docs/languages/php)
