#!/usr/bin/env bash
# Waybar custom module for power-profiles-daemon.
#   status → emits JSON {text, tooltip, class} for the current profile
#   next   → cycles to the next profile (power-saver → balanced → performance → ...)

set -euo pipefail

profile="$(powerprofilesctl get 2>/dev/null || echo unknown)"

case "${1:-status}" in
  status)
    case "$profile" in
      performance) icon="" ; class="performance" ;;  # nf-fa-bolt
      balanced)    icon="󰓅" ; class="balanced"    ;;  # nf-md-speedometer
      power-saver) icon="" ; class="powersaver"  ;;  # nf-fa-leaf
      *)           icon="" ; class="unknown"     ;;  # nf-fa-question
    esac
    # Capitalise first letter for tooltip
    tooltip="Power profile: ${profile^}"
    printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' \
      "$icon" "$tooltip" "$class" "$profile"
    ;;
  next)
    case "$profile" in
      power-saver) target="balanced"    ;;
      balanced)    target="performance" ;;
      performance) target="power-saver" ;;
      *)           target="balanced"    ;;
    esac
    powerprofilesctl set "$target"
    ;;
  *)
    echo "usage: $0 {status|next}" >&2
    exit 2
    ;;
esac
