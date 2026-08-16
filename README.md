# ZSH-Mac

MacOS dotfiles und Konfigurationsdateien für ZSH, SSH und weitere Tools.

---

## Inhalt

| Datei / Ordner | Beschreibung |
|---|---|
| `.zshrc` | ZSH-Konfiguration (Antidote-basiert) |
| `.zsh_plugins.txt` | Antidote Plugin-Liste |
| `.zsh_plugins.zsh` | Generierte Antidote Plugin-Datei |
| `ZSH-AUTOCOMPLETE.md` | Ladereihenfolge, `compinit`-Regel und Tastenbelegung (Tab / ↑ / Ctrl+R) |
| `starship.toml` | Starship Prompt-Konfiguration |
| `.vimrc` | Vim-Konfiguration |
| `.nanorc` | Nano-Konfiguration |
| `config` | Weitere Konfigurationsdateien |

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
stow --target=$HOME --dir=$HOME/Git/ZSH-Mac .
```

---

## ZSH-Konfiguration

Kernstück ist [`zsh-autocomplete`](https://github.com/marlonrichert/zsh-autocomplete):
das Completion-Menü erscheint **live beim Tippen**, ohne Tastendruck.
Der Aufwand liegt weniger in der Installation als darin, anderen Tools die
benötigten Tasten wieder abzunehmen.

### Ladereihenfolge

Die Reihenfolge in `.zsh_plugins.txt` ist funktionsrelevant:

1. `marlonrichert/zsh-autocomplete` — muss **vor jedem `compdef`** geladen werden
2. `mafredri/zsh-async` — Abhängigkeit, vor den Nutzern
3. `zsh-users/zsh-autosuggestions`
4. `Aloxaf/fzf-tab` — übernimmt beim Laden die aktuelle Tab-Belegung
5. `zsh-users/zsh-syntax-highlighting` — muss **zuletzt** stehen

### compinit

`zsh-autocomplete` ruft `compinit` selbst auf und ersetzt die Funktion danach.
In `.zshrc` steht deshalb **kein eigener `compinit`-Aufruf**, nur der Dump-Pfad:

```zsh
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.cache/zsh/zcompdump"
```

`ZSH_COMPDUMP` ist die Variable, die das Plugin ausliest — ein eigener Name wie
`ZCOMPDUMP` wird stillschweigend ignoriert.

### Tastenbelegung

| Taste | Zuständig | Widget |
|---|---|---|
| *(Tippen)* | zsh-autocomplete Live-Menü | — |
| <kbd>Tab</kbd> | fzf-tab | `fzf-tab-complete` |
| <kbd>↑</kbd> / <kbd>↓</kbd> | zsh-autocomplete | `up-line-or-search` / `down-line-or-select` |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | atuin | `_atuin_search` |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> / <kbd>Alt</kbd>+<kbd>C</kbd> | fzf | `fzf-file-widget` / `fzf-cd-widget` |

Zwei Konflikte werden in `.zshrc` aufgelöst:

- `eval "$(fzf --zsh)"` läuft **nach** `antidote load` und belegt <kbd>Tab</kbd> mit
  `fzf-completion`. Die Belegung wird danach an `fzf-tab` zurückgegeben.
- `atuin init zsh` belegt standardmäßig <kbd>↑</kbd> **und** <kbd>Ctrl</kbd>+<kbd>R</kbd>.
  `ATUIN_NOBIND=true` deaktiviert das Keymap; <kbd>Ctrl</kbd>+<kbd>R</kbd> wird manuell gesetzt.

> **Merkregel:** Jedes Tool, das `bindkey` ausführt (fzf, atuin, mcfly, navi),
> kollidiert mit zsh-autocomplete, wenn es nach `antidote load` initialisiert.

### Prüfen

`whence autocomplete` ist **kein** gültiger Test — das Plugin definiert keinen
Befehl dieses Namens und der Test schlägt auch bei korrekter Installation fehl.

Die folgenden Zeilen **am Prompt eintippen**, nicht per `zsh -c` ausführen:
`zsh -c` zeichnet keinen Prompt, dadurch läuft der `precmd`-Hook nie und
`compinit` bleibt aus — `${#_comps}` meldet dann fälschlich `0`.

```zsh
(( $+functions[.autocomplete__main] )) && print geladen
print ${#_comps}                                  # erwartet: einige Tausend, nicht 0
for k in '^I' '^[[A' '^R'; do bindkey "$k"; done  # einzeln abfragen
```

Schnelltest: neue Shell öffnen und `ls --` tippen — das Menü muss von selbst
erscheinen. Details siehe [`ZSH-AUTOCOMPLETE.md`](ZSH-AUTOCOMPLETE.md).

---

## SSH-Konfiguration

Die `~/.ssh/config` enthält Host-Aliase für alle Remote-Systeme.

### Globale Einstellung (Locale-Fix)

macOS sendet standardmäßig alle `LANG`/`LC_*` Variablen an Remote-Hosts.
Dies wird in `~/.ssh/config` global unterdrückt:

```ssh-config
Host *
    SendEnv -LANG -LC_*
```

---

## Changelog

- **2026-08-16** — Repository von `ZSH-mac` in `ZSH-Mac` umbenannt (Konsistenz mit `ZSH-Linux`).
- **2026-08-16** — `~/.atuin/bin/env`-Sourcing in `.zshrc` mit einer Existenzprüfung
  abgesichert (`[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"`).
  Diese Datei wird nur vom offiziellen Atuin-Install-Skript angelegt, nicht von
  Homebrew — die hier dokumentierte Installationsmethode (`brew install ... atuin`)
  erzeugt sie also nicht, wodurch die Zeile bei jedem Shell-Start einen Fehler
  auslöste. Der Fix wurde zuerst in `ZSH-Linux` gefunden und dort interaktiv
  verifiziert, dann hierher zurückportiert.
