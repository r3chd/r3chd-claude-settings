#!/bin/bash
# Claude Code statusLine — Oh My Zsh robbyrussell theme + model / context / cost
#
# Line 1:  ➜  <model>  · <worktree>/<subdir> git:(<branch>) ✗N ?N
# Line 2:  <used>/<size> tokens                                   (this session)
# Line 3:  plan 5h [▓░░░░░░░░░] NN% ↻<reset>  · 7d [░░░░░░░░░░] NN% ↻<reset>  (overall, Pro/Max)

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# ----- model -----
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# ----- context window -----
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')

# ----- plan rate limits (Pro/Max only, after first API response; may be absent) -----
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_at=$(echo "$input"  | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_at=$(echo "$input"  | jq -r '.rate_limits.seven_day.resets_at // empty')

# ----- git: worktree, branch, status -----
toplevel=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$toplevel" ]; then
  worktree=$(basename "$toplevel")
  # path within the repo, asked from git to dodge symlink mismatches
  prefix=$(git -C "$cwd" --no-optional-locks rev-parse --show-prefix 2>/dev/null)
  [ -n "$prefix" ] && subpath="/${prefix%/}" || subpath=""
else
  worktree=$(basename "$cwd")
  subpath=""
fi
git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
total_changes=$(printf '%s' "$git_status" | grep -c .)
untracked=$(printf '%s' "$git_status" | grep -c '^??')
modified=$(( total_changes - untracked ))

# ----- ANSI colors (real ESC bytes) -----
GREEN=$'\033[1;32m'; CYAN=$'\033[0;36m'; BLUE=$'\033[1;34m'
RED=$'\033[0;31m';   YELLOW=$'\033[0;33m'; MAGENTA=$'\033[0;35m'
ORANGE=$'\033[38;5;208m'
DIM=$'\033[0;90m';   BOLD=$'\033[1m';      RESET=$'\033[0m'

# Compact token count: 1234 -> 1.2k, 200000 -> 200k
fmt() {
  awk -v n="$1" 'BEGIN{
    if (n >= 1000000) { v=n/1000000; s="M" }
    else if (n >= 1000) { v=n/1000; s="k" }
    else { printf "%d", n; exit }
    r=sprintf("%.1f", v); sub(/\.0$/, "", r); printf "%s%s", r, s
  }'
}

# 10-char progress bar coloured by usage: green <40, yellow <80, red >=80
make_bar() {
  local pct=$1 width=10 filled empty i bar=""
  filled=$(( pct * width / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  empty=$(( width - filled ))
  for ((i=0; i<filled; i++)); do bar+="▓"; done
  for ((i=0; i<empty;  i++)); do bar+="░"; done
  printf '%s' "$bar"
}
# Colour by absolute session token count: green <100k, orange <200k, red >=200k
if   [ "$ctx_used" -ge 200000 ]; then ctx_color=$RED
elif [ "$ctx_used" -ge 100000 ]; then ctx_color=$ORANGE
else                                   ctx_color=$GREEN
fi

# Colour a 0-100 percentage: green <40, yellow <80, red >=80
pct_color() {
  if   [ "$1" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 40 ]; then printf '%s' "$YELLOW"
  else                       printf '%s' "$GREEN"; fi
}

# Compact "time until" from an epoch: 1738425600 -> "2h13m" / "3d4h" / "5m"
fmt_reset() {
  local target=$1 now diff d h m
  [ -z "$target" ] && return
  now=$(date +%s); diff=$(( target - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else                      printf '%dm' "$m"; fi
}

# Build one "<label> [bar] <pct>% ↻<reset>" segment if the limit is present
usage_seg() {
  local label=$1 pct=$2 at=$3 p c r b
  [ -z "$pct" ] && return
  p=${pct%.*}; [ -z "$p" ] && p=0
  c=$(pct_color "$p"); r=$(fmt_reset "$at"); b=$(make_bar "$p")
  printf '%s%s%s %s[%s%s%s]%s %s%s%%%s' \
    "$DIM" "$label" "$RESET" \
    "$DIM" "$c" "$b" "$DIM" "$RESET" \
    "$c" "$p" "$RESET"
  [ -n "$r" ] && printf ' %s↻%s%s' "$DIM" "$r" "$RESET"
}

# ----- git segment -----
if [ -n "$git_branch" ]; then
  git_part=" ${BLUE}git:(${RED}${git_branch}${BLUE})${RESET}"
  [ "$modified"  -gt 0 ] && git_part+=" ${YELLOW}✗${modified}${RESET}"
  [ "$untracked" -gt 0 ] && git_part+=" ${CYAN}?${untracked}${RESET}"
else
  git_part=""
fi

# ----- render two lines -----
line1=$(printf "%s➜%s  %s%s%s  %s·%s %s%s%s%s%s%s" \
  "$GREEN" "$RESET" \
  "$BOLD" "$model" "$RESET" \
  "$DIM" "$RESET" \
  "$CYAN" "$worktree" "$RESET" "$DIM" "$subpath" "$RESET")
line1+="$git_part"

line2=$(printf "   %s%s%s%s tokens%s" \
  "$ctx_color" "$(fmt "$ctx_used")" "$RESET" "$DIM" "$RESET")

# Line 3: overall plan usage (only when the rate-limit fields are present)
seg5=$(usage_seg "5h" "$rl_5h_pct" "$rl_5h_at")
seg7=$(usage_seg "7d" "$rl_7d_pct" "$rl_7d_at")
line3=""
if [ -n "$seg5" ] || [ -n "$seg7" ]; then
  line3="   ${DIM}plan${RESET} $seg5"
  [ -n "$seg5" ] && [ -n "$seg7" ] && line3+="  ${DIM}·${RESET}  "
  line3+="$seg7"
fi

out="$line1"$'\n'"$line2"
[ -n "$line3" ] && out+=$'\n'"$line3"
printf '%s' "$out"
