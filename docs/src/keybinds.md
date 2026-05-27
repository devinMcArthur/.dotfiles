# Keybinds

> **Auto-generated.** Do not edit this page by hand.
>
> Regenerate with `docs/regen-keybinds.sh`. Source files:
> [`hyprland.conf`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_config/hypr/hyprland.conf),
> [`tmux.conf`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_tmux.conf),
> [`zshrc`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_zshrc.tmpl).

_Generated 2026-05-27T17:27:50-06:00_

## Hyprland — window manager

| Keys | Dispatcher | Argument |
|---|---|---|
| `ALT + R` | `submap` | resize |
| `down` | `resizeactive` | 0 10 |
| `escape` | `submap` | reset |
| `left` | `resizeactive` | -10 0 |
| `right` | `resizeactive` | 10 0 |
| `SUPER + 0` | `workspace` | 10 |
| `SUPER + 1` | `workspace` | 1 |
| `SUPER + 2` | `workspace` | 2 |
| `SUPER + 3` | `workspace` | 3 |
| `SUPER + 4` | `workspace` | 4 |
| `SUPER + 5` | `workspace` | 5 |
| `SUPER + 6` | `workspace` | 6 |
| `SUPER + 7` | `workspace` | 7 |
| `SUPER + 8` | `workspace` | 8 |
| `SUPER + 9` | `workspace` | 9 |
| `SUPER + B` | `exec` | $browser # open the browser |
| `SUPER + bracketleft` | `workspace` | m-1 |
| `SUPER + bracketright` | `workspace` | m+1 |
| `SUPER + comma` | `focusmonitor` | desc:Acer Technologies KA272 0x13800DD9 |
| `SUPER + CTRL + comma` | `movecurrentworkspacetomonitor` | desc:Acer Technologies KA272 0x13800DD9 |
| `SUPER + CTRL + period` | `movecurrentworkspacetomonitor` | desc:Acer Technologies KA272 0x13800FAE |
| `SUPER + CTRL + S` | `exec` | $HOME/.local/bin/hypr-screenshot output       # screenshot monitor → annotate |
| `SUPER + CTRL + slash` | `movecurrentworkspacetomonitor` | eDP-1 |
| `SUPER + E` | `exec` | $fileManager # Show the graphical file browser |
| `SUPER + escape` | `exec` | $lock                                           # lock the screen |
| `SUPER + F` | `fullscreen` | — |
| `SUPER + grave` | `togglespecialworkspace` | scratch |
| `SUPER + h` | `movefocus` | l |
| `SUPER + I` | `exec` | ghostty --class=nmtui -e nmtui # open the network manager |
| `SUPER + j` | `movefocus` | d |
| `SUPER + k` | `movefocus` | u |
| `SUPER + l` | `movefocus` | r |
| `SUPER + M` | `exec` | wlogout --protocol layer-shell # show the logout window |
| `SUPER + mouse_down` | `workspace` | e+1 |
| `SUPER + mouse_up` | `workspace` | e-1 |
| `SUPER + period` | `focusmonitor` | desc:Acer Technologies KA272 0x13800FAE |
| `SUPER + P` | `pseudo` | # dwindle |
| `SUPER + Q` | `killactive` | # close the active window |
| `SUPER + return` | `exec` | $terminal  #open the terminal |
| `SUPER + semicolon` | `exec` | $HOME/.local/bin/hypr-cheatsheet                              # show keybind cheatsheet |
| `SUPER + S` | `exec` | $HOME/.local/bin/hypr-screenshot region            # screenshot region → annotate |
| `SUPER + SHIFT + 0` | `movetoworkspace` | 10 |
| `SUPER + SHIFT + 1` | `movetoworkspace` | 1 |
| `SUPER + SHIFT + 2` | `movetoworkspace` | 2 |
| `SUPER + SHIFT + 3` | `movetoworkspace` | 3 |
| `SUPER + SHIFT + 4` | `movetoworkspace` | 4 |
| `SUPER + SHIFT + 5` | `movetoworkspace` | 5 |
| `SUPER + SHIFT + 6` | `movetoworkspace` | 6 |
| `SUPER + SHIFT + 7` | `movetoworkspace` | 7 |
| `SUPER + SHIFT + 8` | `movetoworkspace` | 8 |
| `SUPER + SHIFT + 9` | `movetoworkspace` | 9 |
| `SUPER + SHIFT + C` | `exec` | hyprpicker -a                                  # pick color under cursor |
| `SUPER + SHIFT + comma` | `movewindow` | mon:desc:Acer Technologies KA272 0x13800DD9 |
| `SUPER + SHIFT + grave` | `movetoworkspace` | special:scratch |
| `SUPER + SHIFT + H` | `movewindow` | l |
| `SUPER + SHIFT + J` | `movewindow` | d  |
| `SUPER + SHIFT + K` | `movewindow` | u |
| `SUPER + SHIFT + L` | `movewindow` | r |
| `SUPER + SHIFT + period` | `movewindow` | mon:desc:Acer Technologies KA272 0x13800FAE |
| `SUPER + SHIFT + S` | `exec` | $HOME/.local/bin/hypr-screenshot window      # screenshot window → annotate |
| `SUPER + SHIFT + slash` | `exec` | $HOME/.local/bin/laptop-docs # Super+? → open laptop reference site (mdBook). Displaced the previous `movewindow mon:eDP-1` bind below — restore it if you want the comma/period/slash monitor-movement symmetry back. |
| `SUPER + SHIFT + V` | `exec` | cliphist wipe                                  # wipe clipboard history |
| `SUPER + slash` | `focusmonitor` | eDP-1 |
| `SUPER + SPACE` | `exec` | wofi # Show the graphicall app launcher |
| `SUPER + Tab` | `swapactiveworkspaces` | desc:Acer Technologies KA272 0x13800DD9 desc:Acer Technologies KA272 0x13800FAE |
| `SUPER + T` | `togglefloating` | # toggle window float / tile |
| `SUPER + V` | `exec` | cliphist-menu                                        # clipboard history |
| `SUPER + W` | `exec` | $HOME/.local/bin/win # smart launcher for the win11 KVM VM (starts + attaches virt-viewer) |
| `SUPER + Y` | `layoutmsg` | togglesplit # dwindle |
| `up` | `resizeactive` | 0 -10 |
| `XF86AudioLowerVolume` | `exec` | wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- |
| `XF86AudioMicMute` | `exec` | wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle  # mic mute |
| `XF86AudioMute` | `exec` | wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle |
| `XF86AudioNext` | `exec` | playerctl next |
| `XF86AudioPause` | `exec` | playerctl play-pause |
| `XF86AudioPlay` | `exec` | playerctl play-pause |
| `XF86AudioPrev` | `exec` | playerctl previous |
| `XF86AudioRaiseVolume` | `exec` | wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ |
| `XF86MonBrightnessDown` | `exec` | brightnessctl s 10%- |
| `XF86MonBrightnessUp` | `exec` | brightnessctl s +10% |

## tmux

Prefix: `C-a`. Bindings shown below assume prefix unless otherwise noted.

| Keys | Action |
|---|---|
| `C-v (in copy-mode-vi)` | send-keys -X rectangle-toggle |
| `M-g (no prefix)` | display-popup -E -w 80% -h 80% -d "#{pane_current_path}" |
| `prefix C-a` | send-prefix |
| `prefix C-h` | previous-window |
| `prefix C-l` | next-window |
| `prefix h` | select-pane -L |
| `prefix j` | select-pane -D |
| `prefix &` | kill-window |
| `prefix k` | select-pane -U |
| `prefix ^` | last-window |
| `prefix l` | select-pane -R |
| `prefix r` | source-file ~/.tmux.conf \; display " config reloaded" |
| `prefix %` | split-window -h -c "#{pane_current_path}" |
| `prefix '"'` | split-window -v -c "#{pane_current_path}" |
| `prefix T` | display-popup -E -w 80% -h 70% "\ |
| `prefix x` | kill-pane |
| `v (in copy-mode-vi)` | send-keys -X begin-selection |
| `y (in copy-mode-vi)` | send-keys -X copy-selection-and-cancel |

## Zsh aliases

| Alias | Expands to |
|---|---|
| `claude` | `with-secrets claude` |
| `la` | `eza -la --group-directories-first --icons=auto --git` |
| `laptop-docs` | `$HOME/.local/bin/laptop-docs` |
| `ll` | `eza -l --group-directories-first --icons=auto --git` |
| `ls` | `eza --group-directories-first --icons=auto` |
| `lta` | `eza --tree --level=2 --icons=auto -a` |
| `lt` | `eza --tree --level=2 --icons=auto` |
| `pi` | `with-secrets pi-safe` |

## Zsh key bindings (bindkey)

| Keys | Widget |
|---|---|
| `^ ` | autosuggest-accept |

## How to add a new binding

1. Edit the source: `dot_config/hypr/hyprland.conf`, `dot_tmux.conf`, or `dot_zshrc.tmpl`
2. Run `docs/regen-keybinds.sh` from the chezmoi repo root or `docs/`
3. Commit both the source change and the regenerated `docs/src/keybinds.md`

_End of auto-generated content._
