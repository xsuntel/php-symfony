# Claude Code

## Prompt Framework (PROMPT)

Mnemonic used when authoring prompts / `CLAUDE.md` for this project:

* P : Persona — the role Claude should adopt
* R : Reference — source material and links to ground the answer
* O : Objective — the goal / deliverable
* M : Mode, Message format — output structure (markdown, code, table)
* P : Point of View — perspective and audience
* T : Tone — professional, concise, Korean for chat

## Platform

* Linux - Ubuntu
  * install

    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```

* Mac - MacOS
  * install

    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```

* Windows
  * Enable WSL2 (run in an elevated PowerShell on the Windows host)

    ```powershell
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    ```

    ```powershell
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```

    ```powershell
    Restart-Computer
    ```

    ```powershell
    wsl --update
    ```

    ```powershell
    wsl --set-default-version 2
    ```

    ```powershell
    wsl --list --online
    ```

    ```powershell
    wsl --install Ubuntu-24.04
    ```

  * Install Node.js + Claude Code (run inside the WSL Ubuntu shell)

    ```bash
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    ```

    ```bash
    \. "$HOME/.nvm/nvm.sh"
    ```

    ```bash
    nvm install 24
    ```

    ```bash
    node -v
    npm -v
    ```

    ```bash
    npm install -g @anthropic-ai/claude-code
    ```

## Project

* Global settings — edit `~/.claude/settings.json`

    ```bash
    vi ~/.claude/settings.json
    ```

    ```json
    {
        "attribution": {
            "commit": ""
        }
    }
    ```

## Tools

* Packages - uvx

    ```bash
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ```

### MCP Servers

* GitHub - Settings / Developer settings / Personal access tokens / Tokens (classic) - repo (only)

  ```bash
  claude mcp add -s user --transport http github https://api.githubcopilot.com/mcp --header "Authorization: Bearer YOUR_GITHUB_PAT"
  ```

  ```bash
  vi ~/.claude.json
  ```

  ```json
  {
    "mcpServers": {
      "github": {
        "type": "http",
        "url": "https://api.githubcopilot.com/mcp",
        "headers": {
          "Authorization": "Bearer YOUR_GITHUB_PAT"
        }
      }
    }
  }
  ```

## Reference

* Claude
  * [Code](https://claude.com/product/claude-code)
    * Developing inside a container - [Document](https://docs.anthropic.com/en/docs/claude-code/devcontainer)
    * [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin)
  * Reference
    * GitHub
      * [claude-cmd](https://github.com/kiliczsh/claude-cmd)
* VSCode
  * Developing inside a Container - [Document](https://code.visualstudio.com/docs/devcontainers/containers)
    * Development Containers - [Document](https://containers.dev/)
