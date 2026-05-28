#!/usr/bin/env bash
# Waybar sysinfo module.
# Prints JSON with:
#   text    -> compact "  42% 󰍛 58%" indicator for the bar
#   tooltip -> Pango markup popup: load, mem, uptime, top procs by CPU and MEM
# Click handler (see waybar config) launches btop in a Ghostty window.

set -euo pipefail

# --- CPU % across all cores (1s sample) ----------------------------------
read -r _ a b c idle1 rest1 < /proc/stat
total1=$((a + b + c + idle1))
for n in $rest1; do total1=$((total1 + n)); done
sleep 1
read -r _ a b c idle2 rest2 < /proc/stat
total2=$((a + b + c + idle2))
for n in $rest2; do total2=$((total2 + n)); done
dt=$((total2 - total1))
di=$((idle2 - idle1))
if [ "$dt" -gt 0 ]; then
  cpu=$(( (100 * (dt - di)) / dt ))
else
  cpu=0
fi

# --- Memory --------------------------------------------------------------
mem_total_kb=$(awk '/^MemTotal:/   {print $2; exit}' /proc/meminfo)
mem_avail_kb=$(awk '/^MemAvailable:/{print $2; exit}' /proc/meminfo)
swap_total_kb=$(awk '/^SwapTotal:/  {print $2; exit}' /proc/meminfo)
swap_free_kb=$(awk  '/^SwapFree:/   {print $2; exit}' /proc/meminfo)
mem_used_kb=$((mem_total_kb - mem_avail_kb))
mem_pct=$(( (100 * mem_used_kb) / mem_total_kb ))
swap_used_kb=$((swap_total_kb - swap_free_kb))

fmt_gib() { awk -v k="$1" 'BEGIN{printf "%.1f", k/1024/1024}'; }
mem_used_g=$(fmt_gib "$mem_used_kb")
mem_total_g=$(fmt_gib "$mem_total_kb")
swap_used_g=$(fmt_gib "$swap_used_kb")
swap_total_g=$(fmt_gib "$swap_total_kb")

# --- Load + uptime -------------------------------------------------------
read -r l1 l5 l15 _ < /proc/loadavg
uptime_pretty=$(uptime -p | sed 's/^up //')
ncpu=$(nproc)

# --- Top processes -------------------------------------------------------
# Strip the command path to keep the tooltip narrow.
top_cpu=$(ps -eo pcpu,pmem,comm --sort=-pcpu --no-headers | head -n 6 \
  | awk '{printf "  %5.1f%%  %5.1f%%  %s\n", $1, $2, $3}')
top_mem=$(ps -eo pcpu,pmem,comm --sort=-pmem --no-headers | head -n 6 \
  | awk '{printf "  %5.1f%%  %5.1f%%  %s\n", $1, $2, $3}')

# --- Pango tooltip -------------------------------------------------------
# &, <, > would break Pango parsing; ps output is safe enough (comm is
# /proc/PID/comm, max 15 chars, no shell metacharacters), but escape defensively.
esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
top_cpu_e=$(printf '%s' "$top_cpu" | esc)
top_mem_e=$(printf '%s' "$top_mem" | esc)

tooltip=$(cat <<EOF
<b>System</b>   ${ncpu} cores · up ${uptime_pretty}
<b>Load</b>     ${l1}  ${l5}  ${l15}
<b>CPU</b>      ${cpu}%
<b>Memory</b>   ${mem_used_g} / ${mem_total_g} GiB  (${mem_pct}%)
<b>Swap</b>     ${swap_used_g} / ${swap_total_g} GiB

<b>Top by CPU</b>
<tt>   %CPU    %MEM  COMMAND
${top_cpu_e}</tt>

<b>Top by MEM</b>
<tt>   %CPU    %MEM  COMMAND
${top_mem_e}</tt>

<i>Click to open btop</i>
EOF
)

# Bar text — compact, Nerd Font glyphs for CPU () and memory (󰍛).
text=$(printf ' %s%%  󰍛 %s%%' "$cpu" "$mem_pct")

# CSS class for color thresholds
class="ok"
if [ "$cpu" -ge 85 ] || [ "$mem_pct" -ge 90 ]; then
  class="critical"
elif [ "$cpu" -ge 60 ] || [ "$mem_pct" -ge 75 ]; then
  class="warning"
fi

# Emit JSON (jq for safe escaping of tooltip newlines/markup).
jq -nc \
  --arg text    "$text" \
  --arg tooltip "$tooltip" \
  --arg class   "$class" \
  '{text:$text, tooltip:$tooltip, class:$class}'
