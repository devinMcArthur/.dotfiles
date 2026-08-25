#!/usr/bin/env bash
# Windows-style calendar flyout for the bar clock (yad GTK calendar).
# Click the clock to open, click again to close — it also closes on its own
# when it loses focus (click anywhere else).
#
# Implementation notes:
#   - yad ignores --class for the Wayland app-id; --name is what sets it
#     (rules in hyprland.conf match class bar.calendar).
#   - Hyprland 0.56's windowrule `move` formulas (50%-w/2) silently don't
#     parse (same hyprlang quirk family as the windowrule notes in
#     hyprland.conf), so the popup is positioned here instead: centered
#     under the bar clock on the FOCUSED monitor, scale-aware.

if pkill -f 'yad --calendar --name=bar.calendar'; then
  exit 0
fi

# Match the greeter/desktop theming; fall back gracefully if absent.
GTK_THEME="$(ls /usr/share/themes 2>/dev/null | grep -im1 'catppuccin.*mocha' || echo Adwaita-dark)"
export GTK_THEME

yad --calendar --name=bar.calendar --undecorated --no-buttons \
  --close-on-unfocus --borders=12 --width=320 --height=300 &

# Wait for the window to map, then center it under the clock.
w=""
for _ in $(seq 1 60); do
  w="$(hyprctl clients -j | jq -r '.[] | select(.class=="bar.calendar") | .size[0]' 2>/dev/null)"
  [ -n "$w" ] && break
  sleep 0.05
done
[ -n "$w" ] || exit 0   # never mapped (yad failed) — nothing to position

read -r x y < <(hyprctl monitors -j | jq -r --argjson w "$w" \
  '.[] | select(.focused) | "\((.x + (((.width / .scale) | floor) - $w) / 2) | floor) \(.y + 38)"')
hyprctl dispatch movewindowpixel "exact $x $y,class:bar.calendar" >/dev/null
