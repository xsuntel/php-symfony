# Visual Studio Code

## Manage

### Extensions

> Extension IDs are the source of truth (Marketplace display names change). This list is kept in sync
> with `tools/ide/vscode/CLAUDE.md` §4.1 (the recommended-extension SoT).

* App
  * CSS
    * Tailwind CSS IntelliSense                (`bradlc.vscode-tailwindcss`)
  * HTML
    * Auto Close Tag                           (`formulahendry.auto-close-tag`)
  * Javascript
    * Stimulus LSP                             (`marcoroth.stimulus-lsp`)
  * PHP
    * PHP Intelephense                         (`bmewburn.vscode-intelephense-client`)
    * PHP Debug                                (`xdebug.php-debug`)
  * Symfony Framework
    * Symfony for VSCode                        (`thenouillet.symfony-vscode`)
    * Symfony UX Twig Component                (`sanderverschoor.vscode-symfony-ux-twig-component`)
    * Modern Twig                              (`stanislav.vscode-twig`)
* Cache
  * Redis for VS Code                          (`redis.redis-for-vscode`)
* Database
  * PostgreSQL                                 (`ms-ossdata.vscode-pgsql`)
* Tools
  * IDE
    * YAML                                     (`redhat.vscode-yaml`)
    * DotENV                                   (`mikestead.dotenv`)
    * Prettier - Code formatter                (`esbenp.prettier-vscode`)
    * Markdownlint                             (`davidanson.vscode-markdownlint`)
    * Material Icon Theme                      (`pkief.material-icon-theme`)
* Util
  * Draw.io Integration                        (`hediet.vscode-drawio`)

### Settings

* Application / Proxy

```text
Use Local Proxy Configuration - UnChecked
```

* Extensions / .ipynb Support

```text
Experimental: Serialization - UnChecked
```

#### Language

* PHP

```text
Manage / Settings / PHP Suggest Basic - false
```

#### Keyboard Shortcuts

* ibus

```bash
ibus restart

IBUS_ENABLE_SYNC_MODE=1 code
```

```bash
vi ~/.bashrc

export IBUS_ENABLE_SYNC_MODE=1
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
```

```bash
vi ~/.profile

export IBUS_ENABLE_SYNC_MODE=1
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
```

* keybinding

```bash
ls -la ~/.config/Code/User/keybindings.json

sudo chown $USER:$USER ~/.config/Code/User/keybindings.json
chmod 644 ~/.config/Code/User/keybindings.json
```

```bash
cp ~/.config/Code/User/keybindings.json ~/.config/Code/User/keybindings.json.bak

echo "[]" > ~/.config/Code/User/keybindings.json
```

#### Tools

* Code Runner

```text
Code-runner: Enable App Insights - false
Code-runner: Run In Terminal - true
```

#### Tools - Copilot

* Copilot

```text
Chat: Disable AI Features - Disable (Checked)
Pgsql › Copilot: Enable   - UnChecked
```

#### Tools - Gemini Code Assist

* Gemini Code Assist
  * Geminicodeassist: Rules

```text
Always read the GEMINI.md file at the @workspace root before answering.
```

* Control + ,

```text
"geminicodeassist.updateChannel": Insiders,
"geminicodeassist.contextualAwareness.enabled": true,
"geminicodeassist.search.maxResults": 10
```

* Control + Shift + P

```text
Developer: Reload Window
```

### Tasks - ${PROJECT_PATH}/.vscode/tasks.json

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "App - Console - Cache",
            "type": "shell",
            "command": "./scripts/base/app/symfony/cache.sh",
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        }
    ]
}
```

## Reference

### IDE

* [VSCode](https://code.visualstudio.com/docs/languages/php)
