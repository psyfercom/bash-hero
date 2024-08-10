#!/bin/bash

# Constants
declare -r MAX_HEARTS=5
declare -r ACTIONS_PER_HEART_LOSS=200  # Lose a heart every 200 actions

# RPG Stats Variables
HEARTS=$MAX_HEARTS
RUPEES=0
XP=0
XP_LEVEL=1
ACTIONS=100  # Start actions at 100
XP_PROGRESS=0
XP_TO_NEXT_LEVEL=10
LOGGED_IN=false

# User details
USERNAME=""
USER_FILE=""
SAVE_FILE=""

# Probability and Reward Arrays
declare -A RUPEE_REWARDS=(
    [0]=800
    [1]=900
    [5]=950
    [10]=980
    [25]=995
    [50]=1000
)

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'
BORDER_COLOR='\033[0;34m'

# Initialize user data based on input
initialize_user() {
    echo -e "${CYAN}Welcome to bash-hero!${RESET}"
    echo -e "1) Start a new game"
    echo -e "2) Load an existing save file"
    read -rp "Choose an option (1 or 2): " option

    if [[ "$option" == "1" ]]; then
        read -rp "Enter your hero name: " USERNAME
        USER_FILE="$HOME/.bash_hero_${USERNAME}_save"
        SAVE_FILE="$HOME/bash_hero_${USERNAME}_details.txt"
        echo "$USERNAME" > "$USER_FILE"
        echo -e "${GREEN}New game started for $USERNAME.${RESET}"
    elif [[ "$option" == "2" ]]; then
        read -rp "Enter the path to your save file: " save_path
        if [[ -f "$save_path" ]]; then
            USER_FILE="$save_path"
            USERNAME=$(basename "$save_path" | sed 's/\.bash_hero_//;s/_save//')
            SAVE_FILE="${save_path%/*}/bash_hero_${USERNAME}_details.txt"
            echo -e "${GREEN}Loaded game for $USERNAME.${RESET}"
        else
            echo -e "${RED}Save file not found. Exiting...${RESET}"
            exit 1
        fi
    else
        echo -e "${RED}Invalid option. Exiting...${RESET}"
        exit 1
    fi
}

# Save detailed stats to a file
save_detailed_stats() {
    cat <<EOL > "$SAVE_FILE"
========================================
         BASH-HERO SAVE FILE
========================================
Hero Name: $USERNAME
----------------------------------------
Hearts: $HEARTS/$MAX_HEARTS
Rupees: $RUPEES
XP: $XP (Level $XP_LEVEL)
XP Progress: $XP_PROGRESS/$XP_TO_NEXT_LEVEL
Actions Taken: $ACTIONS
Logged In: $LOGGED_IN
Save File: $USER_FILE
----------------------------------------
Saved at: $(date)
========================================
EOL
}

# Utility function to print a border line
print_border_line() {
    echo -e "${BORDER_COLOR}----------------------------------------${RESET}"
}

# Display the hero's stats
display_stats() {
    print_border_line
    echo -e "${CYAN}|   Hearts: \c"
    for ((i=0; i<HEARTS; i++)); do echo -n "❤️ "; done
    for ((i=HEARTS; i<MAX_HEARTS; i++)); do echo -n "🖤 "; done
    echo -e "\n|   Rupees: $RUPEES\n|   XP: $XP (Level $XP_LEVEL)${RESET}"
    print_border_line
}

# Display verbose stats
display_verbose_stats() {
    echo -e "${MAGENTA}\n--- Stats for $USERNAME ---${RESET}"
    echo "|   Hearts: $HEARTS/$MAX_HEARTS"
    echo "|   Rupees: $RUPEES"
    echo "|   XP: $XP (Level $XP_LEVEL)"
    echo "|   Actions taken: $ACTIONS"
    echo "|   XP Progress: $XP_PROGRESS/$XP_TO_NEXT_LEVEL"
    print_border_line
}

# Update the hero's stats
update_stats() {
    ((ACTIONS++))
    if ((ACTIONS % ACTIONS_PER_HEART_LOSS == 0)); then
        ((HEARTS--))
        [[ $HEARTS -le 0 ]] && { echo -e "${RED}You have been defeated!${RESET}"; exit 1; }
        echo -e "${YELLOW}You lost a heart due to exhaustion!${RESET}"
    fi
}

# Gain XP and check for leveling up
gain_xp() {
    XP=$((XP + $1))
    XP_PROGRESS=$((XP_PROGRESS + $1))
    if ((XP_PROGRESS >= XP_TO_NEXT_LEVEL)); then
        XP_LEVEL=$((XP_LEVEL + 1))
        XP_PROGRESS=$((XP_PROGRESS - XP_TO_NEXT_LEVEL))
        XP_TO_NEXT_LEVEL=$((XP_TO_NEXT_LEVEL * 2))
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

# Heal one heart
heal_heart() {
    if ((HEARTS < MAX_HEARTS)); then
        ((HEARTS++))
        echo -e "${GREEN}You healed 1 heart!${RESET}"
    else
        echo -e "${CYAN}You're already at full health!${RESET}"
    fi
}

# Simulate login and pull data from Redis
login() {
    $LOGGED_IN && { echo -e "${YELLOW}Already logged in!${RESET}"; return; }
    read -rp "Username: " input_username
    read -rsp "Password: " input_password
    echo ""
    if [[ "$input_username" == "$USERNAME" && "$input_password" == "password" ]]; then
        echo -e "${GREEN}Login successful!${RESET}"
        load_redis_data
        HEARTS=$REDIS_HEARTS
        RUPEES=$REDIS_RUPEES
        XP=$REDIS_XP
        XP_LEVEL=$REDIS_XP_LEVEL
        LOGGED_IN=true
        echo -e "${GREEN}Data loaded from Redis simulation.${RESET}"
    else
        echo -e "${RED}Login failed!${RESET}"
    fi
}

# Simulate logout
logout() {
    if $LOGGED_IN; then
        echo -e "${CYAN}Logged out.${RESET}"
        LOGGED_IN=false
        HEARTS=$MAX_HEARTS RUPEES=0 XP=0 XP_LEVEL=1 ACTIONS=100 XP_PROGRESS=0 XP_TO_NEXT_LEVEL=10
    else
        echo -e "${YELLOW}Not logged in.${RESET}"
    fi
}

# Display the version of bash-hero
version() {
    echo -e "${MAGENTA}bash-hero version 1.0${RESET}"
}

# Handle bash-hero commands
bash_hero() {
    load_user_data
    case "$1" in
        "") help ;;
        "$USERNAME") display_verbose_stats ;;
        potion) heal_heart ;;
        login) login ;;
        logout) logout ;;
        version) version ;;
        help) help ;;
        *) echo -e "${RED}Unknown command: $1${RESET}" ;;
    esac
}

# Display help (also the default action)
help() {
    print_border_line
    echo -e "${YELLOW}bash-hero commands:${RESET}"
    echo -e "${CYAN}1) $USERNAME: Display verbose stats.${RESET}"
    echo -e "${CYAN}2) potion: Heal one heart.${RESET}"
    $LOGGED_IN && echo -e "${CYAN}3) logout: Log out and reset stats.${RESET}" || echo -e "${CYAN}3) login: Log in and load stats from Redis simulation.${RESET}"
    echo -e "${CYAN}4) version: Display bash-hero version.${RESET}"
    echo -e "${CYAN}5) help: Display this help message.${RESET}"
    print_border_line
}

# Main loop
while true; do
    display_stats
    read -rp "> " command
    case "$command" in
        exit) break ;;
        bash-hero*) bash_hero "${command#bash-hero }" ;;
        *) eval "$command" && { award_rupees; gain_xp 10; save_detailed_stats; } ;;
    esac
    update_stats
done

