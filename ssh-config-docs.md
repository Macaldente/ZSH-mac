# SSH Configuration Documentation

*Stand: 29. April 2026*

---

## Konfigurationsdatei `~/.ssh/config`

### Globale Einstellungen (`Host *`)

```ssh-config
Host *
    SendEnv -LANG -LC_*
```

Verhindert, dass macOS automatisch Locale-Variablen (`LANG`, `LC_*`) an Remote-Hosts überträgt.
Überschreibt das systemweite Default aus `/etc/ssh/ssh_config`.

---

### Host-Übersicht

| Alias | Funktion | User | Auth |
|---|---|---|---|
| `macbookpro` | RSI MacBook | `root` | Standard |
| `server` | Fedora Server | `master` | Standard |
| `lxc100` | Zoraxy (Reverse Proxy) | `root` | Standard |
| `lxc101` | Portainer | `root` | Standard |
| `lxc102` | CasaOS | `root` | Standard |
| `lxc106` | Paperless-ngx | `root` | Standard |
| `lxc109` | Cloudflare Tunnel | `root` | Standard |
| `lxc110` | (reserviert) | `root` | Standard |
| `lxc111` | AdguardHome | `root` | Standard |
| `pve` | Proxmox VE | `root` | `~/.ssh/id_ed25519` |

---

## Verbindungsstatus

| Host | Status | Anmerkung |
|---|---|---|
| `pve` | ✅ OK | — |
| `server` | ✅ OK | — |
| `lxc100` | ✅ OK | Host-Key erneuert; Locale generiert |
| `macbookpro` | ❌ Timeout | Gerät nicht im Netz |
| `lxc101` | ❌ Timeout | Container nicht gestartet |
| `lxc102` | ❌ Timeout | Container nicht gestartet |
| `lxc106` | ❌ Timeout | Container nicht gestartet |
| `lxc109` | ❌ Timeout | Container nicht gestartet |
| `lxc110` | ❌ Timeout | Container nicht gestartet |
| `lxc111` | ❌ Timeout | Container nicht gestartet |

---

## Durchgeführte Fixes

### Locale-Unterdrückung (macOS → alle Hosts)

macOS sendet per Default via `/etc/ssh/ssh_config` alle `LANG` und `LC_*` Variablen an Remote-Hosts.
LXC-Container haben diese Locales oft nicht installiert und werfen Warnungen beim Login.

**Fix:** `SendEnv -LANG -LC_*` in `~/.ssh/config` unter `Host *` eingetragen.

---

### `lxc100` – Host-Key erneuert

Der gespeicherte ECDSA-Key in `~/.ssh/known_hosts` war veraltet (3 Einträge, Zeilen 7, 13, 14).

```zsh
# Alten Key entfernen
ssh-keygen -R <HostName von lxc100>

# Neuen Key beim nächsten Connect automatisch akzeptieren
ssh -o StrictHostKeyChecking=accept-new lxc100 'echo OK'
```

Neuer Key-Typ: **ED25519**

---

### `lxc100` – Locale generiert

Der Container hatte `en_US.UTF-8` in `/etc/locale.gen` auskommentiert, weshalb die Locale nicht verfügbar war.

```bash
# en_US.UTF-8 in /etc/locale.gen aktivieren
sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen

# Locale generieren
locale-gen

# Als Standard setzen
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

---

## Nächste Schritte

- **LXC-Container starten** und Verbindungen testen (`lxc101`–`lxc111`)
- Bei neuen Containern ggf. Locale-Fix wiederholen (gleiche Prozedur wie bei `lxc100`)
- **`macbookpro`** testen sobald das Gerät erreichbar ist
