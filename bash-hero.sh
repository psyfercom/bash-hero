#!/bin/bash

# Constants
declare -r MAX_HEARTS=5
declare -r ACTIONS_PER_HEART_LOSS=100  # Lose a heart every 100 actions
declare -r XP_BAR_LENGTH=20  # Length of the ASCII progress bar

# RPG Stats Variables
HEARTS=$MAX_HEARTS  # Use a separate variable to track the current number of hearts
RUPEES=0
XP=0
XP_LEVEL=1
ACTIONS=100  # Start actions at 100
XP_PROGRESS=0
XP_TO_NEXT_LEVEL=100  # Set to 100 for easier demonstration

LOGGED_IN=false

# User details
USERNAME=""
USER_FILE=""
SAVE_FILE=""

# Probability and Reward Arrays
declare -A RUPEE_REWARDS=(
    [0]=950   # 95% chance of getting 0 rupees
    [1]=980   # 3% chance of getting 1 rupee
    [5]=990   # 1% chance of getting 5 rupees
    [10]=995  # 0.5% chance of getting 10 rupees
    [25]=999  # 0.4% chance of getting 25 rupees
    [50]=1000 # 0.1% chance of getting 50 rupees
)

# Color Codes
GREEN='\033[0;32m'
RESET='\033[0m'

# Display the hero's stats
display_stats() {
    echo -e "\n| Hearts: \c"
    for ((i=0; i<HEARTS; i++)); do echo -n "❤️ "; done
    for ((i=HEARTS; i<MAX_HEARTS; i++)); do echo -n "🖤 "; done
    echo -e "\n| Rupees: $RUPEES"

    # Display XP and progress with simplified ASCII bar
    local progress=$(( (XP_PROGRESS * XP_BAR_LENGTH) / XP_TO_NEXT_LEVEL ))
    echo -n "| XP: $XP (Level $XP_LEVEL) Progress: [${GREEN}"
    for ((i=0; i<progress; i++)); do echo -n "\\"; done
    for ((i=progress; i<XP_BAR_LENGTH; i++)); do echo -n "."; done
    echo -e "${RESET}] $XP_PROGRESS/$XP_TO_NEXT_LEVEL\n"
}

# Update the hero's stats
update_stats() {
    ((ACTIONS++))
    if ((ACTIONS % ACTIONS_PER_HEART_LOSS == 0)); then
        ((HEARTS--))
        if ((HEARTS <= 0)); then
            echo -e "${RED}You have been defeated!${RESET}"
            exit 1
        else
            echo -e "${YELLOW}You lost a heart due to exhaustion!${RESET}"
        fi
    fi
}

# Gain XP and check for leveling up
gain_xp() {
    XP=$((XP + $1))
    XP_PROGRESS=$((XP_PROGRESS + $1))
    if ((XP_PROGRESS >= XP_TO_NEXT_LEVEL)); then
        XP_LEVEL=$((XP_LEVEL + 1))
        XP_PROGRESS=$((XP_PROGRESS - XP_TO_NEXT_LEVEL))
        XP_TO_NEXT_LEVEL=$((XP_TO_NEXT_LEVEL * 2))  # Double XP needed for next level
        echo -e "${GREEN}Level Up! You're now level $XP_LEVEL${RESET}"
    fi
    echo -e "${GREEN}You gained $1 XP!${RESET}"
}

# Award rupees with very scarce chances
award_rupees() {
    local random_number=$((RANDOM % 1000 + 1))
    local rupees_awarded=0

    for value in "${!RUPEE_REWARDS[@]}"; do
        if ((random_number <= RUPEE_REWARDS[$value])); then
            rupees_awarded=$value
            break
        fi
    done

    if ((rupees_awarded > 0)); then
        RUPEES=$((RUPEES + rupees_awarded))
        echo -e "${GREEN}You found $rupees_awarded rupees!${RESET}"
    else
        echo -e "${YELLOW}You found nothing of value.${RESET}"
    fi
}

# Main loop
while true; do
    display_stats
    read -rp "> " command
    case "$command" in
        exit) break ;;
        *) eval "$command" && { award_rupees; gain_xp 5; } ;;
    esac
    update_stats
done

