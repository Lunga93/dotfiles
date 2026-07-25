# Architecture

> [!WARNING] Living document — update when data flows or components change.

## Layer Diagram

```mermaid
graph LR
    subgraph Display["Display Server"]
        NIRI[Niri]
    end
    subgraph Shell["Shell Layer"]
        QS[Quickshell]
        SY[swaync]
    end
    subgraph Apps["Application Layer"]
        WO[Wofi]
        AL[Alacritty]
        FF[Fastfetch]
    end
    subgraph Theme["Theming Pipeline"]
        S1[set-wallpaper] --> S2[swww]
        S2 --> S3[pywal]
        S3 --> AT[apply-theme]
        AT --> NI[Niri config]
        AT --> AC[Alacritty .toml]
        AT --> SC[swaync colors.css]
        AT --> WC[wofi colors-wal.css]
        AT --> GC[GTK colors-wal.css]
        AT --> QC[Quickshell Palette.qml]
        AT --> SDDM[sddm]
    end
    subgraph Sys["System Layer"]
        SD[systemd --user]
        SL[~/.local/bin/ scripts]
    end
    NIRI --> QS
    NIRI --> SY
    QS --> SL
    SL --> SD
```

## Testing Pipeline

```mermaid
graph LR
    subgraph Test["Testing Pipeline"]
        BATS[bats test/]
        KCOV[kcov]
        COV[coverage.py]
        TC[test-coverage]
        BL[.coverage-baseline.json]
    end
    BATS --> KCOV
    BATS --> COV
    KCOV --> TC
    COV --> TC
    TC --> BL
    SL -.->|tested by| BATS
```

## Data Flow: Theming

```mermaid
sequenceDiagram
    actor U as User
    U->>SW: set-wallpaper ~/img.jpg
    SW->>SWW: swww img
    SW->>AT: apply-theme
    AT->>PW: pywal
    PW-->>AT: 16 colors
    AT->>ALC: alacritty.toml
    AT->>NIRI: focus-ring colors
    AT->>SY: colors.css + reload
    AT->>QS: Palette.qml
    Note over QS: live file watch
```

## Data Flow: Audio

```mermaid
sequenceDiagram
    actor U as User
    U->>BAR: click volume
    BAR->>AP: qs ipc call audio toggle
    AP->>AS: audio-status
    AS-->>AP: JSON stream
    U->>AP: adjust volume
    AP->>AA: audio-set --volume 80%
    AA->>PW: wpctl set-volume
    PW-->>AA: ok
```

## Stow Layout

Each package mirrors target path:

```
quickshell/.config/quickshell/Bar.qml  →  ~/.config/quickshell/Bar.qml
scripts/.local/bin/audio-status         →  ~/.local/bin/audio-status
```

> [!NOTE] Run `stow -n -v <pkg>` to dry-run, `stow -R <pkg>` to apply.

## File Conventions

| Purpose | Path | Managed by |
|---------|------|-----------|
| Autostart .desktop | `~/.config/autostart/` | Niri spawn |
| State files | `~/.local/state/` | Scripts |
| Cache | `~/.cache/` | pywal, scripts |
| systemd user | `~/.config/systemd/user/` | stow |
| SDDM theme sync | `/var/lib/sddm-theme/` | apply-theme |
| Coverage baseline | `test/.coverage-baseline.json` | test-coverage |

---

**Next:** [[Packages Reference]] | [[Testing Standards]]
