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
print -P "${cyan}│${reset}  ${white}ZSH STARTUP BENCHMARK${reset}                                        ${cyan}│${reset}"
print -P "${cyan}├─────────────────────────────────────────────────────────────────┤${reset}"
printf "${cyan}│${reset}  Total Load Time: ${white}%-8.2f ms${reset}                               ${cyan}│${reset}\n" "$total_ms"
printf "${cyan}│${reset}  Performance:     ${rating_color}%-20s${reset} ${rating_emoji}              ${cyan}│${reset}\n" "$rating_label"
print -P "${cyan}╰─────────────────────────────────────────────────────────────────╯${reset}"

# ============================================================================
# Print Top 10 Functions Table (if zprof is available)
# ============================================================================
if (( $+functions[zprof] )); then
    print -P ""
    print -P "${purple}╭─────────────────────────────────────────────────────────────────╮${reset}"
    print -P "${purple}│${reset}  ${white}TOP 10 SLOWEST FUNCTIONS${reset}                                     ${purple}│${reset}"
    print -P "${purple}├─────────────────────────────────────────────────────────────────┤${reset}"
    printf "${purple}│${reset}  ${dim}%-28s %10s %7s %12s${reset}  ${purple}│${reset}\n" "FUNCTION" "TIME" "CALLS" "LOAD"
    print -P "${purple}├─────────────────────────────────────────────────────────────────┤${reset}"

    # Parse zprof output and format top 10 functions
    zprof | awk -v purple="$purple" -v reset="$reset" -v dim="$dim" -v white="$white" \
                 -v yellow="$yellow" -v red="$red" '
    BEGIN {
        count = 0
        max_entries = 10
    }

    # Skip header lines and capture function data
    /^[0-9]+\)/ {
        if (count >= max_entries) exit

        # Extract function name (column 2)
        func_name = $2

        # Extract time in milliseconds (column 3)
        time_ms = $3

        # Extract call count (column 4)
        calls = $4

        # Extract percentage (column 5, remove % sign)
        percent = $5
        gsub(/%/, "", percent)

        # Truncate long function names
        if (length(func_name) > 26) {
            func_name = substr(func_name, 1, 23) "..."
        }

        # Color coding based on time
        time_color = white
        if (time_ms > 20) time_color = red
        else if (time_ms > 5) time_color = yellow

        # Create visual load bar (each block = 5%)
        load_bar = ""
        blocks = int(percent / 5)
        for (i = 0; i < blocks && i < 20; i++) {
            load_bar = load_bar "█"
        }

        # Print formatted row
        printf "%s│%s  %-28s %s%9.2f ms%s %6d  %s%-12s%s %s│%s\n",
            purple, dim, func_name, time_color, time_ms, reset, calls,
            time_color, load_bar, reset, purple, reset

        count++
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
