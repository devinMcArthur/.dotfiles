#!/usr/bin/env bash
# Waybar custom module for power-profiles-daemon.
#   status → emits JSON {text, tooltip, class} for the current profile
#   next   → cycles to the next profile (power-saver → balanced → performance → ...)
#
# Icons use \u escapes (bash $'...') so they survive any file-write tool
# that occasionally mangles raw multi-byte UTF-8 literals.

set -euo pipefail

# Nerd Font glyphs:
#   \uf0e7 = nf-fa-bolt        (performance)
#   \U000f04c5 = nf-md-speedometer (balanced)
#   \uf06c = nf-fa-leaf        (power-saver)
ICON_PERF=$'\uf0e7'
ICON_BAL=$'\U000f04c5'
ICON_SAVE=$'\uf06c'
ICON_UNKNOWN=$'\uf128'   # nf-fa-question

# Read via D-Bus directly, NOT `powerprofilesctl get`: that CLI is a Python/
# PyGObject script with an interpreter-teardown race on Python 3.14 that
# segfaulted (harmlessly, after output) on a fraction of this module's
# 5-second polls — filling coredumpctl with a crash every ~30 min. Found by
# crash-claude, 2026-08-25. busctl is C, no interpreter, nothing to race.
profile="$(busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
             net.hadess.PowerProfiles ActiveProfile 2>/dev/null \
           | sed 's/^s "\(.*\)"$/\1/' || true)"
profile="${profile:-unknown}"

case "${1:-status}" in
  status)
    case "$profile" in
      performance) icon="$ICON_PERF"    ; class="performance" ;;
      balanced)    icon="$ICON_BAL"     ; class="balanced"    ;;
      power-saver) icon="$ICON_SAVE"    ; class="powersaver"  ;;
      *)           icon="$ICON_UNKNOWN" ; class="unknown"     ;;
    esac
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
    # Same D-Bus-direct approach as the read above (and click-time set was
    # hitting the same Python teardown race, just far less often).
    busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
      net.hadess.PowerProfiles ActiveProfile s "$target"
    ;;
  *)
    echo "usage: $0 {status|next}" >&2
    exit 2
    ;;
esac
