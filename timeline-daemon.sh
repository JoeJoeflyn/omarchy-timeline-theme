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

apply_phase() {
  local phase=$1
  local phase_file="$THEME_DIR/colors-${phase}.toml"
  local bg_file="$THEME_DIR/backgrounds/${phase}.jpg"

  if [[ ! -f "$phase_file" ]]; then
    echo "Timeline: phase file not found: $phase_file" >&2
    return 1
  fi

  # Check if phase already applied
  local current_phase=""
  [[ -f "$STATE_FILE" ]] && current_phase=$(cat "$STATE_FILE")
  if [[ "$current_phase" == "$phase" ]] && [[ "$TIMELINE_FORCE" != "1" ]]; then
    return 0
  fi

  # Swap colors
  cp "$phase_file" "$THEME_DIR/colors.toml"

  # Swap background if exists
  if [[ -f "$bg_file" ]]; then
    omarchy theme bg set "$bg_file" 2>/dev/null
  fi

  # Swap unlock.png from the phase background
  if [[ -f "$bg_file" ]]; then
    make_unlock "$bg_file" "$THEME_DIR/unlock.png"
    # Regenerate preview-unlock with phase colors
    local bg_color fg_color
    bg_color=$(get_color "$phase_file" "background")
    fg_color=$(get_color "$phase_file" "foreground")
    omarchy plymouth preview "$bg_color" "$fg_color" \
      "$THEME_DIR/unlock.png" "$THEME_DIR/preview-unlock.png" 2>/dev/null
  fi

  # Update cursor color to match phase accent
  local accent_color
  accent_color=$(get_color "$phase_file" "accent")
  if [[ -n "$accent_color" ]]; then
    local cursor_hook="$HOME/.config/omarchy/hooks/theme-set.d/cursor-theme-reflect.sh"
    if [[ -f "$cursor_hook" ]]; then
      "$cursor_hook" "timeline" 2>/dev/null
    fi
  fi

  # Save state
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$phase" > "$STATE_FILE"

  # Refresh theme (skip if headless)
  if [[ "$SKIP_REFRESH" != "1" ]]; then
    omarchy theme refresh 2>/dev/null
  fi

  echo "Timeline: applied phase '$phase' at $(date '+%H:%M')"
}

# Main
phase=$(get_phase)
apply_phase "$phase"
