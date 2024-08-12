#!/bin/bash

# Constants
declare -r MAX_HEARTS=5
declare -r ACTIONS_PER_HEART_LOSS=100  # Lose a heart every 100 actions
declare -r XP_BAR_LENGTH=20  # Length of the ASCII progress bar
SAVE_FILE="$HOME/rpg_data.json"

# RPG Stats Variables
HEARTS=$MAX_HEARTS
RUPEES=0
XP=0
XP_LEVEL=1
ACTIONS=100
XP_PROGRESS=0
XP_TO_NEXT_LEVEL=100

USERNAME=""
FONT="default"
EMOJI_HEART="❤️"
EMOJI_EMPTY_HEART="🖤"
COLOR="default"

# Function to prompt for hero's name and create a save file
initialize_hero() {
    if [[ ! -f "$SAVE_FILE" ]]; then
        read -rp "Enter your hero's name: " USERNAME
        create_save_file
    else
        load_save_file
    fi
}

# Function to create a save file in JSON format
create_save_file() {
    cat <<EOF > "$SAVE_FILE"
{
    "username": "$USERNAME",
    "hearts": $HEARTS,
    "rupees": $RUPEES,
    "xp": $XP,
    "xp_level": $XP_LEVEL,
    "actions": $ACTIONS,
    "xp_progress": $XP_PROGRESS,
    "xp_to_next_level": $XP_TO_NEXT_LEVEL,
    "font": "$FONT",
    "emoji_heart": "$EMOJI_HEART",
    "emoji_empty_heart": "$EMOJI_EMPTY_HEART",
    "color": "$COLOR"
}
EOF
    echo "Welcome, $USERNAME! Your adventure begins."
}

# Function to load data from the JSON save file
load_save_file() {
    USERNAME=$(jq -r '.username' "$SAVE_FILE")
    HEARTS=$(jq -r '.hearts' "$SAVE_FILE")
    RUPEES=$(jq -r '.rupees' "$SAVE_FILE")
    XP=$(jq -r '.xp' "$SAVE_FILE")
    XP_LEVEL=$(jq -r '.xp_level' "$SAVE_FILE")
    ACTIONS=$(jq -r '.actions' "$SAVE_FILE")
    XP_PROGRESS=$(jq -r '.xp_progress' "$SAVE_FILE")
    XP_TO_NEXT_LEVEL=$(jq -r '.xp_to_next_level' "$SAVE_FILE")
    FONT=$(jq -r '.font' "$SAVE_FILE")
    EMOJI_HEART=$(jq -r '.emoji_heart' "$SAVE_FILE")
    EMOJI_EMPTY_HEART=$(jq -r '.emoji_empty_heart' "$SAVE_FILE")
    COLOR=$(jq -r '.color' "$SAVE_FILE")
    echo "Welcome back, $USERNAME!"
}

# Function to save the current game state to the JSON save file
save_game() {
    cat <<EOF > "$SAVE_FILE"
{
    "username": "$USERNAME",
    "hearts": $HEARTS,
    "rupees": $RUPEES,
    "xp": $XP,
    "xp_level": $XP_LEVEL,
    "actions": $ACTIONS,
    "xp_progress": $XP_PROGRESS,
    "xp_to_next_level": $XP_TO_NEXT_LEVEL,
    "font": "$FONT",
    "emoji_heart": "$EMOJI_HEART",
    "emoji_empty_heart": "$EMOJI_EMPTY_HEART",
    "color": "$COLOR"
}
EOF
}

# Display the hero's stats
display_stats() {
    echo -e "\n| Hearts: \c"
    for ((i=0; i<HEARTS; i++)); do echo -n "$EMOJI_HEART "; done
    for ((i=HEARTS; i<MAX_HEARTS; i++)); do echo -n "$EMOJI_EMPTY_HEART "; done
    echo -e "\n| Rupees: $RUPEES"

    local progress=$(( (XP_PROGRESS * XP_BAR_LENGTH) / XP_TO_NEXT_LEVEL ))
    echo -n "| XP: $XP (Level $XP_LEVEL) Progress: [${GREEN}"
    for ((i=0; i<progress; i++)); do echo -n "\\"; done
    for ((i=progress; i<XP_BAR_LENGTH; i++)); do echo -n "."; done
    echo -e "${RESET}] $XP_PROGRESS/$XP_TO_NEXT_LEVEL\n"
}

# Function to display verbose stats
display_verbose_stats() {
    echo -e "\nProfile: $USERNAME"
    echo "Hearts: $HEARTS"
    echo "Rupees: $RUPEES"
    echo "XP: $XP"
    echo "Level: $XP_LEVEL"
    echo "Actions Taken: $ACTIONS"
    echo "XP Progress: $XP_PROGRESS/$XP_TO_NEXT_LEVEL"
    echo "Font: $FONT"
    echo "Heart Emoji: $EMOJI_HEART"
    echo "Empty Heart Emoji: $EMOJI_EMPTY_HEART"
    echo "Color: $COLOR"
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

    if ((random_number <= 10)); then
        rupees_awarded=$((RANDOM % 100 + 1))
    fi

    if ((rupees_awarded > 0)); then
        RUPEES=$((RUPEES + rupees_awarded))
        echo -e "${GREEN}You found $rupees_awarded rupees!${RESET}"
    else
        echo -e "${YELLOW}You found nothing of value.${RESET}"
    fi
}

# Settings functions
change_font() {
    read -rp "Enter new font name: " FONT
    save_game
    echo "Font changed to $FONT."
}

custom_emojis() {
    read -rp "Enter emoji for heart: " EMOJI_HEART
    read -rp "Enter emoji for empty heart: " EMOJI_EMPTY_HEART
    save_game
    echo "Emojis updated."
}

change_colors() {
    read -rp "Enter new color scheme (default, red, blue, green): " COLOR
    save_game
    echo "Color scheme changed to $COLOR."
}

add_to_path() {
    SCRIPT_PATH=$(realpath "$0")
    read -rp "Do you want to add bash-hero to your PATH? (y/n): " add_path
    if [[ $add_path == "y" || $add_path == "Y" ]]; then
        echo "export PATH=\$PATH:$(dirname "$SCRIPT_PATH")" >> ~/.bashrc
        source ~/.bashrc
        echo "bash-hero has been added to your PATH."
    else
        echo "bash-hero not added to PATH."
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n--- Bash Hero Menu ---"
        echo "1. $USERNAME's Profile"
        echo "2. Settings"
        echo "3. Exit"
        read -rp "Choose an option: " option
        case $option in
            1) display_verbose_stats ;;
            2) settings_menu ;;
            3) break ;;
            *) echo "Invalid option. Please choose again." ;;
        esac
    done
}

# Settings menu
settings_menu() {
    while true; do
        echo -e "\n--- Settings Menu ---"
        echo "1. Change Font"
        echo "2. Custom Emojis"
        echo "3. Change Colors"
        echo "4. Add to PATH"
        echo "5. Back to Main Menu"
        read -rp "Choose an option: " option
        case $option in
            1) change_font ;;
            2) custom_emojis ;;
            3) change_colors ;;
            4) add_to_path ;;
            5) break ;;
            *) echo "Invalid option. Please choose again." ;;
        esac
    done
}

# Start the game
start_game() {
    if [[ -z "$USERNAME" ]]; then
        initialize_hero
    fi

    while true; do
        display_stats
        read -rp "> " command
        case "$command” in
menu) main_menu ;;
exit) save_game; break ;;
*) eval “$command” && { award_rupees; gain_xp 5; save_game; } ;;
esac
update_stats
done
}

start_game