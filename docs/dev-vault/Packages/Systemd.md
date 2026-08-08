# Systemd

User-level systemd services and timers.

## Location

`systemd/.config/systemd/user/` → `~/.config/systemd/user/`

## Services

| Service | Type | Runs | Purpose |
|---------|------|------|---------|
| `daily-wallpaper.service` | oneshot | `fetch-wallpaper` | Daily wallpaper fetch (Nice=10) |
| `seed-wallpapers.service` | oneshot | `seed-wallpapers --quiet` | Populate wallpaper library (Nice=10, IO idle) |
| `wallpaper-cleanup.service` | oneshot | `wallpaper-cleanup --quiet` | Dedupe + age-prune (Nice=15, IO idle) |
| `swaync.service` | simple | swaync | Notification daemon (symlinked from graphical-session.target.wants/) |
| `voice-tv-server.service` | simple | FastAPI backend | Voice control backend |
| `voice-tv-daemon.service` | simple | Wake word + whisper | Voice input daemon |

## Timers

| Timer | Schedule | Purpose |
|-------|----------|---------|
| `daily-wallpaper.timer` | Every 6 hours | Persistent, randomized delay |
| `seed-wallpapers.timer` | Daily | Persistent, 2h randomized delay |
| `wallpaper-cleanup.timer` | Monthly | Persistent, 30min randomized delay |

## Wants Directories

| Directory | Purpose |
|-----------|---------|
| `graphical-session.target.wants/` | Services that start with the graphical session |
| `timers.target.wants/` | All timers enabled here |

## Conventions

- All services are **user-level**: no sudo for management
- Oneshot services for tasks, simple services for daemons
- Timers are persistent (missed runs fire on next boot)
- Nice/IO scheduling classes for background tasks

## Extending

To add a timer + service pair:
1. Create `your-task.service` (oneshot type)
2. Create `your-task.timer` (OnCalendar, Persistent=true)
3. Symlink `.timer` into `timers.target.wants/`
4. Run `systemctl --user daemon-reload`
5. Add to STOW_DIRS or create a new stow package
