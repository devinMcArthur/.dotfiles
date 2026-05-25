#!/usr/bin/env bash
# Regenerate docs/src/keybinds.md from authoritative sources.
#
# Sources (paths relative to this script):
#   ../dot_config/hypr/hyprland.conf
#   ../dot_tmux.conf
#   ../dot_zshrc.tmpl
#
# Run manually after editing any of those, or wire into a git hook.
# Output is git-tracked but should NEVER be hand-edited.

set -euo pipefail
cd "$(dirname "$0")"

REPO=".."
HYPR="$REPO/dot_config/hypr/hyprland.conf"
TMUX="$REPO/dot_tmux.conf"
ZSHRC="$REPO/dot_zshrc.tmpl"
OUT="src/keybinds.md"

if [[ ! -f "$HYPR" || ! -f "$TMUX" || ! -f "$ZSHRC" ]]; then
  echo "ERROR: expected source files not found relative to $(pwd)" >&2
  exit 1
fi

# ---------- writers ----------
exec > "$OUT"

cat <<'HEADER'
# Keybinds

> **Auto-generated.** Do not edit this page by hand.
>
> Regenerate with `docs/regen-keybinds.sh`. Source files:
> [`hyprland.conf`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_config/hypr/hyprland.conf),
> [`tmux.conf`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_tmux.conf),
> [`zshrc`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_zshrc.tmpl).

HEADER

echo "_Generated $(date -Iseconds)_"
echo ""

# ---------- Hyprland ----------
# Pre-extract variable definitions ($mainMod = SUPER etc.) so we can
# substitute them in the bindings table.
MAINMOD=$(awk -F'=' '
  /^[[:space:]]*\$mainMod[[:space:]]*=/ {
    val = $2
    sub(/#.*/, "", val)        # strip trailing comment
    gsub(/[[:space:]]/, "", val) # strip whitespace
    print val; exit
  }' "$HYPR")
MAINMOD=${MAINMOD:-SUPER}

echo "## Hyprland — window manager"
echo ""
echo "| Keys | Dispatcher | Argument |"
echo "|---|---|---|"

# Match: bind = MODS, KEY, dispatcher [, args]
# Also: bindd (description), binde (repeat), bindel/binde l (locked + repeat)
awk -v IGNORECASE=1 '
  /^[[:space:]]*bind[del]*[[:space:]]*=/ {
    # Strip "bind*  = " prefix
    sub(/^[[:space:]]*bind[del]*[[:space:]]*=[[:space:]]*/, "", $0)
    # Split CSV. Be careful: dispatcher args may contain commas.
    n = split($0, parts, /[[:space:]]*,[[:space:]]*/)
    mods = parts[1]; key = parts[2]; disp = parts[3]
    # Rejoin rest as the argument
    arg = ""
    for (i = 4; i <= n; i++) {
      arg = (arg == "" ? parts[i] : arg ", " parts[i])
    }
    # Tidy: empty mods becomes "(none)"
    if (mods == "") mods = "(none)"
    # Format keys: SUPER + Q
    gsub(/[[:space:]]+/, " + ", mods)
    keys = (mods == "(none)" ? key : mods " + " key)
    # Escape pipe chars in arg
    gsub(/\|/, "\\|", arg)
    printf "| `%s` | `%s` | %s |\n", keys, disp, (arg == "" ? "—" : arg)
  }
' "$HYPR" | sed "s/\\\$mainMod/$MAINMOD/g" | sort -u

echo ""

# ---------- Tmux ----------
echo "## tmux"
echo ""
echo "Prefix: \`C-a\`. Bindings shown below assume prefix unless otherwise noted."
echo ""
echo "| Keys | Action |"
echo "|---|---|"

# Match: bind [flags] KEY ACTION ...
# Flags we care about: -n (no prefix), -T <table> (eg copy-mode-vi)
awk '
  /^[[:space:]]*bind([[:space:]]|-)/ {
    # Strip leading bind / bind -[flag] markers but capture context
    line = $0
    sub(/^[[:space:]]*bind[[:space:]]+/, "", line)
    # Optional -N "desc" (note); just drop it for now
    sub(/^-N[[:space:]]+"[^"]*"[[:space:]]+/, "", line)
    context = "prefix"
    if (match(line, /^-n[[:space:]]+/)) {
      context = "(no prefix)"
      sub(/^-n[[:space:]]+/, "", line)
    } else if (match(line, /^-T[[:space:]]+[^[:space:]]+[[:space:]]+/)) {
      m = substr(line, RSTART, RLENGTH)
      sub(/^-T[[:space:]]+/, "", m)
      sub(/[[:space:]]+$/, "", m)
      context = m
      sub(/^-T[[:space:]]+[^[:space:]]+[[:space:]]+/, "", line)
    } else if (match(line, /^-r[[:space:]]+/)) {
      # -r = repeatable; keep prefix context
      sub(/^-r[[:space:]]+/, "", line)
    }
    # First token is the key, rest is the action
    n = split(line, fields, /[[:space:]]+/)
    key = fields[1]
    act = ""
    for (i = 2; i <= n; i++) act = (act == "" ? fields[i] : act " " fields[i])
    # Truncate very long actions
    if (length(act) > 80) act = substr(act, 1, 77) "..."
    gsub(/\|/, "\\|", act)
    key_label = (context == "prefix" ? "prefix " key : (context == "(no prefix)" ? key " (no prefix)" : key " (in " context ")"))
    printf "| `%s` | %s |\n", key_label, act
  }
' "$TMUX" | sort -u

echo ""

# ---------- Zsh aliases + key bindings ----------
echo "## Zsh aliases"
echo ""
echo "| Alias | Expands to |"
echo "|---|---|"

# Match: alias name='...' or alias name="..."
# Skip lines inside conditional blocks for now — list them all; user can read
# the source for context.
awk '
  /^[[:space:]]*alias[[:space:]]+[a-zA-Z_][a-zA-Z0-9_-]*=/ {
    line = $0
    sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
    idx = index(line, "=")
    if (idx == 0) next
    name = substr(line, 1, idx-1)
    rest = substr(line, idx+1)
    # Strip surrounding single or double quotes
    gsub(/^["\047]/, "", rest)
    gsub(/["\047][[:space:]]*$/, "", rest)
    if (name ~ /^(#|template)/) next
    gsub(/\|/, "\\|", rest)
    printf "| `%s` | `%s` |\n", name, rest
  }
' "$ZSHRC" | sort -u

echo ""
echo "## Zsh key bindings (bindkey)"
echo ""
echo "| Keys | Widget |"
echo "|---|---|"

awk '
  /^[[:space:]]*bindkey[[:space:]]+["\047]/ {
    line = $0
    sub(/^[[:space:]]*bindkey[[:space:]]+/, "", line)
    if (match(line, /^["\047][^"\047]+["\047]/)) {
      key = substr(line, RSTART+1, RLENGTH-2)
      rest = substr(line, RSTART+RLENGTH)
      sub(/^[[:space:]]+/, "", rest)
      printf "| `%s` | %s |\n", key, rest
    }
  }
' "$ZSHRC" | sort -u

echo ""
echo "## How to add a new binding"
echo ""
echo "1. Edit the source: \`dot_config/hypr/hyprland.conf\`, \`dot_tmux.conf\`, or \`dot_zshrc.tmpl\`"
echo "2. Run \`docs/regen-keybinds.sh\` from the chezmoi repo root or \`docs/\`"
echo "3. Commit both the source change and the regenerated \`docs/src/keybinds.md\`"
echo ""
echo "_End of auto-generated content._"
