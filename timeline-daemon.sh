#!/bin/bash
# Timeline theme daemon — shifts Omarchy colors, backgrounds, unlock image, and cursor based on time of day
# 8 phases: sunrise, morning, noon, afternoon, sunset, dusk, night, midnight

THEME_DIR="$HOME/.config/omarchy/themes/timeline"
STATE_FILE="$HOME/.local/state/omarchy/timeline-phase"
SKIP_REFRESH="${TIMELINE_SKIP_REFRESH:-0}"

get_phase() {
  local hour minute time
  if [[ -n "$TIMELINE_TEST_HOUR" ]]; then
    hour=$TIMELINE_TEST_HOUR
    minute=0
  else
    hour=$(date +%H)
    minute=$(date +%M)
  fi
  hour=$((10#$hour))
  minute=$((10#$minute))
  time=$((hour * 60 + minute))

  if (( time >= 300 && time < 420 )); then
    echo "sunrise"
  elif (( time >= 420 && time < 600 )); then
    echo "morning"
  elif (( time >= 600 && time < 780 )); then
    echo "noon"
  elif (( time >= 780 && time < 960 )); then
    echo "afternoon"
  elif (( time >= 960 && time < 1140 )); then
    echo "sunset"
  elif (( time >= 1140 && time < 1260 )); then
    echo "dusk"
  elif (( time >= 1260 && time < 1440 )); then
    echo "night"
  else
    echo "midnight"
  fi
}

# Extract a color value from a phase colors file
get_color() {
  local file=$1 key=$2
  grep "^${key} =" "$file" | head -1 | sed 's/.*= *"\(.*\)"/\1/'
}

# Crop/resize an image to 1920x1080 for unlock.png
make_unlock() {
  local src=$1 dest=$2
  python3 -c "
from PIL import Image
im = Image.open('$src').convert('RGBA')
target = (1920, 1080)
scale = max(target[0]/im.width, target[1]/im.height)
new_size = (int(im.width*scale), int(im.height*scale))
im = im.resize(new_size, Image.LANCZOS)
left = (im.width - target[0]) // 2
top = (im.height - target[1]) // 2
im = im.crop((left, top, left + target[0], top + target[1]))
im.save('$dest', 'PNG')
"
}

# Regenerate ghostty.conf from a phase colors file + the Omarchy template
generate_ghostty_conf() {
  local colors_file=$1 dest=$2
  local tpl="/usr/share/omarchy/default/themed/ghostty.conf.tpl"
  [[ -f "$tpl" ]] || return 0
  python3 -c "
import re
colors = {}
with open('$colors_file') as f:
    for line in f:
        m = re.match(r'^(\\w+)\\s*=\\s*\"?(#[0-9a-fA-F]+)\"?', line)
        if m: colors[m.group(1)] = m.group(2)
colors.setdefault('selection_background', colors.get('selection',''))
colors.setdefault('selection_foreground', colors.get('bright_foreground',''))
with open('$tpl') as f: tpl = f.read()
for k,v in colors.items(): tpl = tpl.replace('{{ '+k+' }}', v)
# Use accent or cursor color for terminal cursor instead of bright_foreground
cursor_color = colors.get('cursor') or colors.get('accent') or colors.get('bright_foreground','')
if cursor_color:
    tpl = re.sub(r'cursor-color = .*', 'cursor-color = ' + cursor_color.lstrip('#'), tpl)
with open('$dest','w') as f: f.write(tpl)
"
}

# Generate hyprland.lua with phase accent + rounded corners
make_hyprland() {
  local accent=$1 inactive=$2 fg=$3 muted=$4 dest=$5
  cat > "$dest" << LUA
-- Timeline — Hyprland decoration: auto-generated, accent = $accent

hl.config({
  general = {
    col = {
      active_border = "rgb(${accent#\#})",
      inactive_border = "rgb(${inactive#\#})",
    },
    gaps_in = 7,
    gaps_out = 11,
    border_size = 2,
  },
  group = {
    col = {
      border_active = "rgb(${accent#\#})",
      border_inactive = "rgb(${inactive#\#})",
    },
    groupbar = {
      col = {
        active = "rgba(${accent#\#}99)",
        inactive = "rgba(${inactive#\#}88)",
      },
      text_color = "rgb(${fg#\#})",
      text_color_inactive = "rgba(${muted#\#}ee)",
    },
  },
  decoration = {
    rounding = 6,
    rounding_power = 3,
  },
})
LUA
}

# Generate shell.toml with phase colors for top bar, menus, launcher, popups
make_shell() {
  local bg=$1 fg=$2 accent=$3 dest=$4
  cat > "$dest" << TOML
# Omarchy Quattro surfaces for Timeline (auto-generated for current phase).

[bar]
background = "$bg"
background-alpha = 1.0
text = "$fg"
active = "$accent"
scale-with-font = true

[hyprland]
active-border = "$accent"
active-border-foreground = "$accent"

[popups]
background = "$bg"
background-alpha = 1.0
text = "$fg"
border = "hyprland.active-border"
border-alpha = 1.0
border-width = 2

[tooltip]
background = "$bg"
background-alpha = 0.97
text = "$fg"
border = "hyprland.active-border-foreground"
border-alpha = 1.0

[notifications]
background = "$bg"
background-alpha = 1.0
text = "$fg"
border = "hyprland.active-border"
border-alpha = 1.0
border-width = 2
countdown = "$accent"

[launcher]
background = "$bg"
background-alpha = 0.95
text = "$fg"
border = "hyprland.active-border"
border-alpha = 1.0
border-width = 2
scrim = "$bg"
scrim-alpha = 0.5
selected-background = "$fg"
selected-background-alpha = 0.08
selected-text = "$accent"
selected-border = "hyprland.active-border"
selected-border-alpha = 0.25

[menu]
background = "$bg"
background-alpha = 1.0
text = "$fg"
border = "hyprland.active-border"
border-alpha = 1.0
border-width = 2
scrim = "$bg"
scrim-alpha = 0.5
selected-background = "$fg"
selected-background-alpha = 0.08
selected-text = "$accent"
selected-border = "hyprland.active-border"
selected-border-alpha = 0.25

[polkit]
background = "$bg"
background-alpha = 1.0
text = "$fg"
text-error = "$accent"
border = "hyprland.active-border"
border-error = "$accent"
border-alpha = 1.0
border-width = 2
scrim = "$bg"
scrim-alpha = 0.5
accent = "$accent"

[lock]
background = "$bg"
background-alpha = 0.8
text = "$fg"
placeholder = "${fg}B3"
text-error = "$accent"
border = "hyprland.active-border"
border-active = "hyprland.active-border"
border-error = "$accent"
border-alpha = 1.0
border-width = 2
selection = "$accent"
selection-alpha = 0.45
TOML
}

apply_phase() {
  local phase=$1
  local phase_file="$THEME_DIR/colors-${phase}.toml"
  local bg_file="$THEME_DIR/backgrounds/${phase}.jpg"

  if [[ ! -f "$phase_file" ]]; then
    echo "Timeline: phase file not found: $phase_file" >&2
    return 1
  fi

  # Check if phase already applied (skip unless forced)
  local current_phase=""
  [[ -f "$STATE_FILE" ]] && current_phase=$(cat "$STATE_FILE")

  # Is timeline actually the active theme? Read once, used by both the
  # fast-path below and the not-active guard further down.
  local active_theme=""
  [[ -f "$HOME/.local/state/omarchy/current/theme.name" ]] && \
    active_theme=$(cat "$HOME/.local/state/omarchy/current/theme.name")

  if [[ "$current_phase" == "$phase" ]] && [[ "$TIMELINE_FORCE" != "1" ]]; then
    # Phase unchanged — still re-apply cursor so it survives post-boot hook
    # overwrite, but ONLY when timeline is the active theme. Otherwise this
    # daemon would clobber whatever cursor the user's current theme set.
    if [[ "$active_theme" == "timeline" ]]; then
      local cursor_hook="$HOME/.config/omarchy/hooks/theme-set.d/cursor-theme-reflect.sh"
      if [[ -f "$cursor_hook" ]]; then
        "$cursor_hook" "timeline-${phase}" 2>/dev/null
      fi
    fi
    return 0
  fi

  # Always update theme dir files so they're correct when someone switches to timeline
  cp "$phase_file" "$THEME_DIR/colors.toml"

  # Generate hyprland.lua with phase accent + rounded corners
  local accent_color inactive_color fg_color muted_color bg_color
  accent_color=$(get_color "$phase_file" "accent")
  inactive_color=$(get_color "$phase_file" "lighter_background")
  fg_color=$(get_color "$phase_file" "foreground")
  muted_color=$(get_color "$phase_file" "muted")
  bg_color=$(get_color "$phase_file" "background")
  make_hyprland "$accent_color" "$inactive_color" "$fg_color" "$muted_color" "$THEME_DIR/hyprland.lua"
  make_shell "$bg_color" "$fg_color" "$accent_color" "$THEME_DIR/shell.toml"

  # Swap icon theme to match phase accent (folders/files match the accent)
  local icon_theme
  case "$phase" in
    midnight)  icon_theme="Yaru-purple" ;;
    sunrise)   icon_theme="Yaru-magenta" ;;
    morning)   icon_theme="Yaru-yellow" ;;
    noon)      icon_theme="Yaru-yellow" ;;
    afternoon) icon_theme="Yaru-wartybrown" ;;
    sunset)    icon_theme="Yaru-red" ;;
    dusk)      icon_theme="Yaru-magenta" ;;
    night)     icon_theme="Yaru-blue" ;;
  esac
  echo "$icon_theme" > "$THEME_DIR/icons.theme"

  # Update unlock.png in theme dir (used by actual lock screen)
  if [[ -f "$bg_file" ]]; then
    make_unlock "$bg_file" "$THEME_DIR/unlock.png"
  fi

  # Save state
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$phase" > "$STATE_FILE"

  # If timeline isn't the active theme, just keep the theme dir updated.
  # The live apply happens when the user switches to timeline (via the hook).
  if [[ "$active_theme" != "timeline" ]] && [[ "$TIMELINE_FORCE" != "1" ]]; then
    echo "Timeline: pre-updated theme dir for phase '$phase' (not active theme)"
    return 0
  fi

  # Fast phase switch: skip full omarchy theme refresh (7s) and only do
  # what's visible — update state colors, hyprland.lua, bar IPC, cursor.
  # Terminal/app configs (btop, neovim, etc.) update on next full theme set.
  if [[ "$SKIP_REFRESH" != "1" ]]; then
    local state_dir="$HOME/.local/state/omarchy/current/theme"
    local next_dir="$HOME/.local/state/omarchy/current/next-theme"
    # 1. Set background FIRST so it's ready before anything else
    if [[ -f "$bg_file" ]]; then
      omarchy theme bg set "$bg_file" 2>/dev/null
    fi
    # 2. Stage next-theme dir so template generator can read it
    rm -rf "$next_dir"
    mkdir -p "$next_dir"
    cp "$phase_file" "$next_dir/colors.toml"
    cp "$THEME_DIR/hyprland.lua" "$next_dir/hyprland.lua"
    cp "$THEME_DIR/icons.theme" "$next_dir/icons.theme"
    # 3. Generate shell.toml from template (fast — single file)
    omarchy-theme-set-templates 2>/dev/null
    cp "$THEME_DIR/shell.toml" "$state_dir/shell.toml" 2>/dev/null
    # 5. Swap into state
    cp "$next_dir/colors.toml" "$state_dir/colors.toml"
    cp "$next_dir/hyprland.lua" "$state_dir/hyprland.lua"
    cp "$next_dir/icons.theme" "$state_dir/icons.theme" 2>/dev/null
    cp "$next_dir/chromium.theme" "$state_dir/chromium.theme" 2>/dev/null
    cp "$next_dir/btop.theme" "$state_dir/btop.theme" 2>/dev/null
    cp "$next_dir/neovim.lua" "$state_dir/neovim.lua" 2>/dev/null
    rm -rf "$next_dir"
    # 5b. Regenerate ghostty.conf from phase colors and reload Ghostty
    generate_ghostty_conf "$phase_file" "$state_dir/ghostty.conf"
    pkill -USR2 ghostty 2>/dev/null
    # 5c. Trigger btop config reload so it re-reads the symlinked theme file
    # btop watches btop.conf via inotify; touching it reloads config + theme
    if pgrep -x btop >/dev/null 2>&1; then
      touch "$HOME/.config/btop/btop.conf" 2>/dev/null
    fi
    # 6. Apply icon theme so file/folder colors match accent
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null
    # 7. Update browser color (Brave/Chromium tab strip)
    omarchy-theme-set-browser 2>/dev/null
    # 8. Send bar IPC so the top bar picks up new colors instantly
    local colors_payload shell_payload
    colors_payload=$(base64 -w 0 "$state_dir/colors.toml" 2>/dev/null)
    shell_payload=$(base64 -w 0 "$state_dir/shell.toml" 2>/dev/null)
    timeout 2 omarchy-shell shell applyTheme "$colors_payload" "$shell_payload" 2>/dev/null
    # 9. Reload Hyprland so borders update
    hyprctl reload >/dev/null 2>&1
  fi

  # Switch to pre-compiled per-phase cursor slug so Hyprland actually
  # reloads the cursor pixels (same name = Hyprland caches, no reload).
  # All 8 slugs are pre-compiled so this is instant (fast-path).
  local cursor_hook="$HOME/.config/omarchy/hooks/theme-set.d/cursor-theme-reflect.sh"
  if [[ -f "$cursor_hook" ]]; then
    "$cursor_hook" "timeline-${phase}" 2>/dev/null
  fi

  local kbd_hook="$HOME/.config/omarchy/hooks/theme-set.d/asus-tuf-kbd-sync.sh"
  if [[ -x "$kbd_hook" ]]; then
    "$kbd_hook" "timeline" 2>/dev/null
  fi

  echo "Timeline: applied phase '$phase' at $(date '+%H:%M')"
}

# Main
phase=$(get_phase)
apply_phase "$phase"
