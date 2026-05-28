#!/usr/bin/env bash
# tmux-resurrect-guard — reject truncated resurrect saves.
#
# Wired in via `set -g @resurrect-hook-post-save-all` in ~/.tmux.conf.
#
# Failure mode this guards against:
#   tmux-continuum fires a final save during shutdown. By the time the save
#   runs, tmux may already be tearing down sessions/panes, so the resulting
#   layout file captures only a tiny fragment. That truncated file then
#   becomes `last`, and the next boot's auto-restore reads it and silently
#   loses every session that was not in the fragment.
#
# Heuristic:
#   A healthy resurrect snapshot with even a single attached pane contains
#   the window line, the pane line, and one or more state lines (>= 5 lines
#   in practice). Anything below the threshold is treated as a stub.
#
# Behaviour:
#   - If `last` points at a stub: find the most recent prior backup that
#     passes the threshold, repoint `last` to it, delete the stub file,
#     and log the swap.
#   - If no healthy backup is found: leave `last` alone but loudly log.
#   - Always exits 0 (a hook failure must never break tmux saves).

set -u

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOG_FILE="$LOG_DIR/tmux-resurrect-guard.log"
MIN_LINES=5

mkdir -p "$LOG_DIR"

log() { printf '%s %s\n' "$(date -Iseconds)" "$*" >> "$LOG_FILE"; }

last_link="$RESURRECT_DIR/last"
[ -L "$last_link" ] || exit 0

current_target=$(readlink "$last_link")
current_path="$RESURRECT_DIR/$current_target"
[ -f "$current_path" ] || exit 0

current_lines=$(wc -l < "$current_path" 2>/dev/null || echo 0)

if [ "$current_lines" -ge "$MIN_LINES" ]; then
  # Healthy save, nothing to do.
  exit 0
fi

log "stub detected: $current_target ($current_lines lines < $MIN_LINES)"

# Find the most recent backup (excluding the stub itself) that looks healthy.
replacement=""
while IFS= read -r candidate; do
  cand_base=$(basename "$candidate")
  [ "$cand_base" = "$current_target" ] && continue
  cand_lines=$(wc -l < "$candidate" 2>/dev/null || echo 0)
  if [ "$cand_lines" -ge "$MIN_LINES" ]; then
    replacement="$cand_base"
    break
  fi
done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)

if [ -z "$replacement" ]; then
  log "no healthy backup found; leaving stub in place"
  exit 0
fi

ln -sfn "$replacement" "$last_link"
rm -f "$current_path"
log "repointed last -> $replacement; removed stub $current_target"
exit 0
