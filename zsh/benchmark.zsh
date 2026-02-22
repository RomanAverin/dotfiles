#!/usr/bin/env zsh
# ============================================================================
# ZSH Benchmark UI Module
# ============================================================================
# Displays beautiful benchmark report with:
# - Overall load time with performance rating
# - Top 10 slowest functions with visual load bars
# - Color-coded performance indicators
# ============================================================================

# ANSI Color Definitions
local -r cyan='\033[36m'
local -r purple='\033[35m'
local -r red='\033[31m'
local -r green='\033[32m'
local -r yellow='\033[33m'
local -r dim='\033[2m'
local -r white='\033[97m'
local -r reset='\033[0m'

# Performance Rating Thresholds and Styles
local rating_emoji rating_label rating_color
if (( total_ms < 40 )); then
    rating_emoji="🚀"
    rating_label="Blazing Fast"
    rating_color="$green"
elif (( total_ms < 100 )); then
    rating_emoji="⚡"
    rating_label="Fast"
    rating_color="$cyan"
elif (( total_ms < 200 )); then
    rating_emoji="🐢"
    rating_label="Acceptable"
    rating_color="$yellow"
else
    rating_emoji="🐌"
    rating_label="Sluggish"
    rating_color="$red"
fi

# ============================================================================
# Print Header with Performance Summary
# ============================================================================
print -P ""
print -P "${cyan}╭─────────────────────────────────────────────────────────────────╮${reset}"
print -P "${cyan}│${reset}  ${white}ZSH STARTUP BENCHMARK${reset}                                          ${cyan}│${reset}"
print -P "${cyan}├─────────────────────────────────────────────────────────────────┤${reset}"
printf "${cyan}│${reset}  Total Load Time: ${white}%-8.2f ms${reset}                                   ${cyan}│${reset}\n" "$total_ms"
printf "${cyan}│${reset}  Performance:     ${rating_color}%-20s${reset} ${rating_emoji}                       ${cyan}│${reset}\n" "$rating_label"
print -P "${cyan}╰─────────────────────────────────────────────────────────────────╯${reset}"

# ============================================================================
# Print Top 10 Functions Table (if zprof is available)
# ============================================================================
if (( $+builtins[zprof] )); then
    print -P ""
    print -P "${purple}╭─────────────────────────────────────────────────────────────────╮${reset}"
    print -P "${purple}│${reset}  ${white}TOP 10 SLOWEST FUNCTIONS${reset}                                       ${purple}│${reset}"
    print -P "${purple}├─────────────────────────────────────────────────────────────────┤${reset}"
    printf "${purple}│${reset}  ${dim}%-28s %12s %6s  %-12s${reset} ${purple}│${reset}\n" "FUNCTION" "TIME" "CALLS" "LOAD"
    print -P "${purple}├─────────────────────────────────────────────────────────────────┤${reset}"

    # Parse zprof output and format top 10 functions (sorted by load descending)
    zprof | awk -v purple="$purple" -v reset="$reset" -v dim="$dim" -v white="$white" \
                 -v yellow="$yellow" -v red="$red" '
    BEGIN {
        count = 0
        max_entries = 10
    }

    /^[0-9]+\)/ {
        func_name = $NF
        if (func_name in seen_funcs) next
        seen_funcs[func_name] = 1

        time_ms = $3 + 0
        calls = $2 + 0
        percent = $5; gsub(/%/, "", percent); percent = percent + 0

        if (length(func_name) > 26) func_name = substr(func_name, 1, 23) "..."

        funcs[count]      = func_name
        times[count]      = time_ms
        all_calls[count]  = calls
        percents[count]   = percent
        count++
    }

    END {
        # Selection sort by percent descending
        for (i = 0; i < count - 1; i++) {
            max_idx = i
            for (j = i + 1; j < count; j++) {
                if (percents[j] > percents[max_idx]) max_idx = j
            }
            if (max_idx != i) {
                tmp = funcs[i];     funcs[i] = funcs[max_idx];         funcs[max_idx] = tmp
                tmp = times[i];     times[i] = times[max_idx];         times[max_idx] = tmp
                tmp = all_calls[i]; all_calls[i] = all_calls[max_idx]; all_calls[max_idx] = tmp
                tmp = percents[i];  percents[i] = percents[max_idx];   percents[max_idx] = tmp
            }
        }

        limit = count < max_entries ? count : max_entries
        for (i = 0; i < limit; i++) {
            func_name = funcs[i]
            time_ms   = times[i]
            calls     = all_calls[i]
            percent   = percents[i]

            time_color = white
            if (time_ms > 20) time_color = red
            else if (time_ms > 5) time_color = yellow

            # Build load bar with explicit padding (avoids UTF-8 byte/char mismatch in %-Ns)
            blocks = int(percent / 5)
            if (blocks > 12) blocks = 12
            load_bar = ""; for (j = 0; j < blocks; j++) load_bar = load_bar "█"
            pad      = ""; for (j = blocks; j < 12; j++) pad = pad " "

            printf "%s│%s  %-28s %s%9.2f ms%s %6d  %s%s%s%s %s│%s\n",
                purple, dim, func_name, time_color, time_ms, reset, calls,
                time_color, load_bar, pad, reset, purple, reset
        }
    }
    '

    print -P "${purple}╰─────────────────────────────────────────────────────────────────╯${reset}"
else
    print -P ""
    print -P "${yellow}ℹ  zprof not available - install zsh/zprof module for detailed stats${reset}"
fi

print -P ""

# ============================================================================
# Optional: Show warning for slow startup
# ============================================================================
if (( total_ms >= 200 )); then
    print -P "${red}⚠  Warning: ZSH startup time is slower than recommended (≥200ms)${reset}"
    print -P "${dim}   Tip: Review plugins and consider lazy-loading with zinit${reset}"
    print -P ""
fi

# Clean up global variables to avoid pollution
unset _zsh_load_start _zsh_load_end total_ms
