# zsh setup — `zsh-autocomplete` + Antidote

Documentation for the interactive zsh environment on this machine.
Last verified: **2026-08-15** (macOS, zsh 5.9, arm64).

The headline feature is [`zsh-autocomplete`](https://github.com/marlonrichert/zsh-autocomplete),
which shows a completion menu **live as you type**, with no keypress required.
Most of the work below is not installing it — it is stopping four other tools
from stealing the keys it needs.

---

## 1. Layout

```
~/.zshrc                        # single entry point, all config lives here
~/.zsh_plugins.txt              # Antidote plugin manifest (load order matters)
~/.zsh/antidote/                # plugin manager (auto-cloned on first run)
~/.zsh/plugins/                 # $ANTIDOTE_HOME — cloned plugins + .antidote.load cache
~/.cache/zsh/zcompdump          # completion dump ($ZSH_COMPDUMP)
```

`ZDOTDIR` is **not** set, so zsh reads `~/.zshrc` directly.

---

## 2. Installation from scratch

The setup is self-bootstrapping. On a new machine:

1. Install the external tools (all optional except zsh itself):

   ```sh
   brew install zsh fzf atuin starship zoxide eza
   ```

2. Copy `~/.zshrc` into place.

3. Start a new shell. `~/.zshrc` will automatically:
   - clone Antidote into `~/.zsh/antidote` if missing,
   - write a default `~/.zsh_plugins.txt` if missing,
   - clone every plugin listed in the manifest on first `antidote load`.

The first launch takes a few seconds while plugins are cloned; subsequent
launches use Antidote's static cache (`~/.zsh/plugins/.antidote.load`).

> **Note:** the manifest is only generated when `~/.zsh_plugins.txt` does not
> exist. If you edit the heredoc in `~/.zshrc` later, the existing file is *not*
> rewritten — edit `~/.zsh_plugins.txt` directly.

---

## 3. Plugins and load order

`~/.zsh_plugins.txt` — **order is significant**:

```
marlonrichert/zsh-autocomplete
mafredri/zsh-async
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
zsh-users/zsh-syntax-highlighting
```

| # | Plugin | Pinned at | Why it sits here |
|---|---|---|---|
| 1 | `zsh-autocomplete` | `027cdab` (2026-08-05) | Must load **before any `compdef` call**; it initialises the completion system itself. |
| 2 | `zsh-async` | `ee1d11b` (2023-01-05) | Dependency; must precede its consumers. |
| 3 | `zsh-autosuggestions` | `85919cd` (2025-06-24) | Wraps ZLE widgets, so it loads after autocomplete defines them. |
| 4 | `fzf-tab` | `24105b1` (2026-06-04) | Captures the current Tab binding at load time, so it must see autocomplete's widgets already in place. |
| 5 | `zsh-syntax-highlighting` | `c4d9559` (2024-09-23) | **Must be last.** It wraps every widget defined before it; anything loaded afterwards is not highlighted. |

Plugin manager: `mattmc3/antidote` @ `db19ea3` (2026-08-12).

---

## 4. The `compinit` rule

`zsh-autocomplete` runs `compinit` itself (in `Functions/Init/.autocomplete__compinit`)
and then removes the function so nothing can run it twice. Its README states
plainly: *"Remove any calls to `compinit`."*

So `~/.zshrc` contains **no `compinit` call**. Instead it only exports the dump path:

```sh
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.cache/zsh/zcompdump"
mkdir -p "${ZDOTDIR:-$HOME}/.cache/zsh"
```

`ZSH_COMPDUMP` is the variable the plugin actually reads. A custom variable name
such as `ZCOMPDUMP` is silently ignored and the dump lands in the default
XDG location instead.

Completion is initialised lazily from autocomplete's `precmd` hook, so it is
**not** populated in a non-interactive `zsh -c` invocation. Test it in a real
interactive shell (see §7).

---

## 5. Key bindings and conflicts

Four tools compete for the same keys. Current resolution:

| Key | Goes to | Widget |
|---|---|---|
| *(typing)* | zsh-autocomplete live menu | — |
| <kbd>Tab</kbd> | fzf-tab | `fzf-tab-complete` |
| <kbd>↑</kbd> | zsh-autocomplete history | `.autocomplete__up-line-or-search__zle-widget` |
| <kbd>↓</kbd> | zsh-autocomplete menu | `.autocomplete__down-line-or-select__zle-widget` |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | atuin | `_atuin_search` |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> | fzf file picker | `fzf-file-widget` |
| <kbd>Alt</kbd>+<kbd>C</kbd> | fzf cd picker | `fzf-cd-widget` |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | `expand-word` | — |

### 5.1 Tab — fzf-tab vs zsh-autocomplete

Both replace the Tab completion UI; they cannot both own it. **fzf-tab wins here
by choice.** The trade-off: you keep autocomplete's live menu and history
navigation, but Tab-completion is fzf's interface, not autocomplete's.

Additionally, `eval "$(fzf --zsh)"` runs *after* `antidote load` and rebinds
<kbd>Tab</kbd> to `fzf-completion`, clobbering fzf-tab. `~/.zshrc` hands it back:

```sh
eval "$(fzf --zsh)" 2>/dev/null || true
if (( $+widgets[fzf-tab-complete] )); then
  bindkey -M emacs '^I' fzf-tab-complete
  bindkey -M viins '^I' fzf-tab-complete
fi
```

The `$+widgets` guard means this degrades safely if fzf-tab is ever removed.

### 5.2 Up arrow — atuin vs zsh-autocomplete

By default `atuin init zsh` binds both <kbd>↑</kbd> and <kbd>Ctrl</kbd>+<kbd>R</kbd>,
and because it initialises near the end of `~/.zshrc` it used to win both.
`ATUIN_NOBIND` disables its entire default keymap so the arrow keys stay with
autocomplete, then Ctrl+R is bound back manually:

```sh
export ATUIN_NOBIND=true
eval "$(atuin init zsh)"
bindkey -M emacs '^R' atuin-search
bindkey -M viins '^R' atuin-search
```

### 5.3 Ctrl+R — atuin vs fzf

Both want it. **atuin owns it**; fzf keeps only Ctrl+T and Alt+C.
To flip this, drop the two `bindkey ... atuin-search` lines — fzf's own
Ctrl+R binding will then survive.

---

## 6. Rule of thumb for adding new tools

Anything that emits `bindkey` — `fzf`, `atuin`, `zoxide`, `mcfly`, `navi` —
will fight zsh-autocomplete if it initialises *after* `antidote load`.
When adding one:

1. Check what it grabbed: `bindkey | grep -i <tool>`
2. Prefer the tool's own opt-out (`ATUIN_NOBIND`, `FZF_DEFAULT_OPTS`, `--no-bind`).
3. Failing that, re-bind the contested key immediately after the tool's `eval`,
   guarded with `(( $+widgets[...] ))`.

---

## 7. Verifying the setup

> **Do not test with `whence autocomplete`.** `zsh-autocomplete` never defines a
> command by that name — it only exposes ZLE widgets and dot-prefixed functions.
> That check always reports failure even on a perfectly working install, and is
> the single most common false alarm with this plugin.

Correct checks — **type these at a prompt**, do not run them via `zsh -c`.
`zsh -c` never renders a prompt, so the `precmd` hook never fires, `compinit`
never runs, and `${#_comps}` misreports `0` on a perfectly healthy setup:

```sh
# plugin actually loaded
(( $+functions[.autocomplete__main] )) && echo loaded

# its precmd hook is installed (should be first)
print $precmd_functions

# who owns each key (query one at a time — passing several
# arguments to bindkey *assigns* them instead of listing them)
for k in '^I' '^[[A' '^R'; do bindkey "$k"; done

# completion system is live (expect a few thousand, not 0)
print ${#_comps}
```

Fastest end-to-end test: open a new shell and type `ls --` — a menu of options
should appear on its own, without pressing anything.

The two fzf/atuin overlays can only be confirmed visually by pressing
<kbd>Tab</kbd> and <kbd>Ctrl</kbd>+<kbd>R</kbd>. They cannot be verified through
a `zpty` harness, because `zpty` supplies no terminal window size and both
programs refuse to draw without one.

Apply changes with `exec zsh`.

---

## 8. Known inert files

None of these are loaded; they are leftovers, safe to delete:

- `~/.zsh/.zshrc` — one orphaned `PATH` line, duplicating one already in the
  real `~/.zshrc`. Only ever read if `ZDOTDIR=~/.zsh`, which is not set.
- `~/.config/zsh/` — empty directory.
- `~/.cache/zsh/compdump`, `~/.cache/zsh/compdump.zwc` — stale dumps from
  before `ZSH_COMPDUMP` was set. The live dump is `zcompdump`.

## 9. Backups

Timestamped copies are written before edits, e.g.:

```
~/.zshrc.bak.20260815122520
~/.zsh_plugins.txt.bak.20260815122520
```

Restore with `cp ~/.zshrc.bak.<stamp> ~/.zshrc && exec zsh`.
