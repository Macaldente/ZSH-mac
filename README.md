# ZSH-mac

MacOS dotfiles und Konfigurationsdateien für ZSH, SSH und weitere Tools.

---

## Inhalt

| Datei / Ordner | Beschreibung |
|---|---|
| `.zshrc` | ZSH-Konfiguration (Antidote-basiert) |
| `.zsh_plugins.txt` | Antidote Plugin-Liste |
| `.zsh_plugins.zsh` | Generierte Antidote Plugin-Datei |
| `starship.toml` | Starship Prompt-Konfiguration |
| `.vimrc` | Vim-Konfiguration |
| `.nanorc` | Nano-Konfiguration |
| `config` | Weitere Konfigurationsdateien |
| `ssh-config-docs.md` | SSH-Konfiguration und Verbindungsstatus |

---

## Installation

### Voraussetzungen

Initiale CLI-Tools installieren:
```zsh
brew install antidote atuin eza fzf genpass helix starship zoxide
```

Weitere CLI-Tools:
```zsh
brew install bat fastfetch podman podman-compose ripgrep rsync stow tree wget
```

Casks:
```zsh
brew install --cask ghostty ungoogled-chromium raycast soundanchor timemachineeditor warp zed
```

### Dotfiles einrichten

Dateien mit `stow` ins Home-Verzeichnis symlinken:
```zsh
stow --target=$HOME --dir=$HOME/Git/ZSH-mac .
```

---

## SSH-Konfiguration

Die vollständige Dokumentation befindet sich in [`ssh-config-docs.md`](ssh-config-docs.md).

### Schnellübersicht `~/.ssh/config`

| Alias | Host | User |
|---|---|---|
| `pve` | Proxmox VE | root |
| `server` | Fedora Server | master |
| `lxc100` | Zoraxy (Reverse Proxy) | root |
| `lxc101` | Portainer | root |
| `lxc102` | CasaOS | root |
| `lxc106` | Paperless-ngx | root |
| `lxc109` | Cloudflare Tunnel | root |
| `lxc110` | (reserviert) | root |
| `lxc111` | AdguardHome | root |
| `macbookpro` | RSI MacBook | root |

### Globale Einstellung (Locale-Fix)

macOS sendet standardmäßig alle `LANG`/`LC_*` Variablen an Remote-Hosts.
Dies wird in `~/.ssh/config` global unterdrückt:

```ssh-config
Host *
    SendEnv -LANG -LC_*
```

### Verbindung testen

```zsh
ssh pve
ssh server
ssh lxc100
```
