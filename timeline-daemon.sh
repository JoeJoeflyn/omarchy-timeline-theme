#!/bin/bash
# Timeline theme daemon — shifts Omarchy colors and backgrounds based on time of day
# 8 phases: sunrise, morning, noon, afternoon, sunset, dusk, night, midnight

THEME_DIR="$HOME/.config/omarchy/themes/timeline"
STATE_FILE="$HOME/.local/state/omarchy/timeline-phase"
SKIP_REFRESH="${TIMELINE_SKIP_REFRESH:-0}"

get_phase() {
  local hour=$(date +%H)
  local minute=$(date +%M)
  local time=$((hour * 60 + minute))

  # Sunrise: 5:00 - 7:00
  if (( time >= 300 && time < 420 )); then
    echo "sunrise"
  # Morning: 7:00 - 10:00
  elif (( time >= 420 && time < 600 )); then
    echo "morning"
  # Noon: 10:00 - 13:00
  elif (( time >= 600 && time < 780 )); then
    echo "noon"
  # Afternoon: 13:00 - 16:00
  elif (( time >= 780 && time < 960 )); then
    echo "afternoon"
  # Sunset: 16:00 - 19:00
  elif (( time >= 960 && time < 1140 )); then
    echo "sunset"
  # Dusk: 19:00 - 21:00
  elif (( time >= 1140 && time < 1260 )); then
    echo "dusk"
  # Night: 21:00 - 24:00
  elif (( time >= 1260 && time < 1440 )); then
    echo "night"
  # Midnight: 0:00 - 5:00
  else
    echo "midnight"
  fi
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

  # Save state
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$phase" > "$STATE_FILE"

  # Refresh theme (skip if headless)
  if [[ "$SKIP_REFRESH" != "1" ]]; then
    OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy theme refresh 2>/dev/null
  fi

  echo "Timeline: applied phase '$phase' at $(date '+%H:%M')"
}

# Main
phase=$(get_phase)
apply_phase "$phase"
