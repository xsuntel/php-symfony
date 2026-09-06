# Dev Environment

## Platform

* Mac - MacOS

### Packages

Homebrew prefix differs by CPU architecture:

| Architecture | `PLATFORM_PROCESSOR` | Prefix |
| -------------- | ---------------------- | -------------- |
| Apple Silicon | `arm64` | `/opt/homebrew` |
| Intel | `x86_64` | `/usr/local` |

* Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

* Load brew into a login shell (append once to `~/.zprofile`)

```bash
# Apple Silicon
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

# Intel
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
```

* Check status

```bash
brew --version

brew doctor
```

* Manage packages

```bash
brew install git

brew list

brew cleanup
```

## Reference

* [Homebrew](https://brew.sh)
