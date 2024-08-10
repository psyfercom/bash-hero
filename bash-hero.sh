#!/bin/bash

# Constants
declare -r MAX_HEARTS=5
declare -r ACTIONS_PER_HEART_LOSS=100  # Lose a heart every 100 actions
declare -r XP_BAR_LENGTH=20  # Length of the ASCII progress bar

# RPG Stats Variables
HEARTS=$MAX_HEARTS
RUPEES=0
XP=0
XP_LEVEL=1
ACTIONS=100
XP_PROGRESS=0
XP_TO_NEXT_LEVEL=100

USERNAME=""
SAVE_FILE=""

# Function to prompt for hero's name and create a save file
initialize_hero() {
    if [[ ! -f "$SAVE_FILE" ]]; then
        read -rp "Enter your hero's name: " USERNAME
        SAVE_FILE="$HOME/.bash_hero_${USERNAME}_save"
        create_save_file
    else
        load_save_file
    fi
}

# Function to create a save file
create_save_file() {
    echo -e "username=$USERNAME\nhearts=$HEARTS\nrupees=$RUPEES\nxp=$XP\nxp_level=$XP_LEVEL\nactions=$ACTIONS\nxp_progress=$XP_PROGRESS\nxp_to_next_level=$XP_TO_NEXT_LEVEL" > "$SAVE_FILE"
    echo "Welcome, $USERNAME! Your adventure begins."
}

# Function to load data from the save file
load_save_file() {
    source "$SAVE_FILE"
    echo "Welcome back, $USERNAME!"
}

# Function to save the current game state to the save file
save_game() {
    echo -e "username=$USERNAME\nhearts=$HEARTS\nrupees=$RUPEES\nxp=$XP\nxp_level=$XP_LEVEL\nactions=$ACTIONS\nxp_progress=$XP_PROGRESS\nxp_to_next_level=$XP_TO_NEXT_LEVEL" > "$SAVE_FILE"
}

# Display the hero's stats
display_stats() {
    echo -e "\n| Hearts: \c"
    for ((i=0; i<HEARTS; i++)); do echo -n "❤️ "; done
    for ((i=HEARTS; i<MAX_HEARTS; i++)); do echo -n "🖤 "; done
    echo -e "\n| Rupees: $RUPEES"

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
    if [[ -z "$USERNAME" ]]; then
        initialize_hero
    fi

    display_stats
    read -rp "> " command
    case "$command" in
        exit) save_game; break ;;
        *) eval "$command" && { award_rupees; gain_xp 5; save_game; } ;;
    esac
    update_stats
done

