# Timeline — Omarchy Theme ⏰

A **dynamic** desktop theme for [Omarchy](https://omarchy.org/) that shifts colors, wallpapers, cursors, and icons throughout the day — inspired by Apple's time-based dynamic themes, built for Omarchy.

8 time phases cycle automatically from warm sunrise to deep midnight, each with its own distinct color identity:

![Timeline Theme Preview](preview.png)

---

## 🎨 Palette

Each phase has a deliberately distinct accent — no mixed or shared colors between phases:

| Phase | Time | Accent | Hex | Background |
| :--- | :--- | :--- | :--- | :--- |
| 🌅 Sunrise | 05:00–07:00 | Pink/Peach | `#F0A8A0` | Mt Fuji sunrise |
| ☀️ Morning | 07:00–10:00 | Golden Yellow | `#E8C050` | Mt Fuji golden morning |
| 🏜️ Noon | 10:00–13:00 | Warm Gold | `#D4A838` | Mt Fuji from Lake Yamanaka |
| 🌇 Afternoon | 13:00–16:00 | Amber | `#D48838` | Mt Fuji from ISS |
| 🔥 Sunset | 16:00–19:00 | Red/Orange | `#E25828` | Mt Fuji sunset |
| 🌆 Dusk | 19:00–21:00 | Purple/Magenta | `#C04878` | Mt Fuji silhouette |
| 🌙 Night | 21:00–24:00 | Blue/Purple | `#6858A8` | Mt Fuji at Kawaguchiko |
| 🌑 Midnight | 00:00–05:00 | Dark Violet | `#4A3A78` | Fuji City lights from Mt Fuji |

---

## 📦 What's Included

- `colors.toml` — Active palette (auto-updated by daemon based on current time).
- `colors-{phase}.toml` — 8 phase palettes (sunrise, morning, noon, afternoon, sunset, dusk, night, midnight).
- `hyprland.lua` — Auto-generated per phase with accent-colored active borders, rounded corners (6), and soft shadows.
- `backgrounds/` — 8 Mt Fuji wallpapers, one per time phase.
- `timeline-daemon.sh` — Time-based daemon that shifts colors, background, cursor, and icons per phase.
- `systemd/` — systemd user service and timer (runs every 30 min).
- `icons.theme` — Auto-switched per phase (`Yaru-purple`, `Yaru-magenta`, `Yaru-yellow`, `Yaru-red`, `Yaru-blue`, etc.) so folder and file manager icons match the active accent.
- `unlock.png` & `preview-unlock.png` — Plymouth boot and lock screen asset, auto-updated per phase.
- `preview.png` — 1920x1080 theme switcher preview with live fastfetch and btop layout.
- `btop.theme` — Color-matched btop process monitor theme.
- `neovim.lua` — Aether.nvim colorscheme tuned to the active phase palette.
- `vscode.json` — VS Code color theme integration.

---

## ✨ What Changes Per Phase

- **Window borders** — Active border color follows the phase accent, with rounded corners and shadows.
- **Top bar / menu** — Bar background, text, and menu borders all follow the phase palette via shell IPC.
- **Cursor** — Pre-compiled per-phase cursor slugs (`Adwaita-timeline-sunrise`, etc.) so Hyprland reloads the cursor color instantly without needing to switch workspaces.
- **File/folder icons** — Yaru icon theme switches per phase to match the accent (purple, magenta, yellow, red, blue, etc.).
- **Background** — Mt Fuji wallpaper shifts to match the time of day.
- **btop & Neovim** — Color schemes regenerate from the active `colors.toml`.
- **Lock screen** — `unlock.png` regenerates from the phase background.

---

## 🚀 Installation

### Option 1: Via Omarchy Menu (GUI)
1. Open the Omarchy menu: `SUPER + ALT + SPACE`
2. Go to **Install > Theme**
3. Enter the repository URL: `https://github.com/JoeJoeflyn/omarchy-timeline-theme`

### Option 2: Via Omarchy CLI
```bash
omarchy theme install https://github.com/JoeJoeflyn/omarchy-timeline-theme
```

### Option 3: Apply Manually
```bash
omarchy theme set timeline
```

### Enable the auto-switching daemon:
```bash
cp ~/.config/omarchy/themes/timeline/systemd/timeline-daemon.service ~/.config/systemd/user/
cp ~/.config/omarchy/themes/timeline/systemd/timeline-daemon.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now timeline-daemon.timer
```

The daemon runs every 30 minutes and shifts the theme automatically. No restart needed — colors transition live.

---

## 📄 License
MIT
