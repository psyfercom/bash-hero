#!/bin/bash

# Redis server connection details
REDIS_HOST="localhost"
REDIS_PORT="6379"

# Function to initialize or reset the game stats in Redis
initialize_stats() {
    local username=$1
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_hearts" 3
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_rupees" 0
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_xp" 0
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_actions" 0
    echo "Game stats initialized for $username."
}

# Function to display current stats from Redis
display_stats() {
    local username=$1
    local hearts=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_hearts")
    local rupees=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_rupees")
    local xp=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_xp")
    local actions=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_actions")

    echo "Current stats for $username:"
    echo "Hearts: $hearts"
    echo "Rupees: $rupees"
    echo "XP: $xp"
    echo "Actions: $actions"
}

# Function to log in (load stats from Redis)
login() {
    local username=$1
    if [ -z "$(redis-cli -h $REDIS_HOST -p $REDIS_PORT exists "${username}_hearts")" ]; then
        echo "No existing stats found for $username. Initializing..."
        initialize_stats "$username"
    else
        echo "Welcome back, $username!"
        display_stats "$username"
    fi
}

# Function to log out (reset stats in Redis)
logout() {
    local username=$1
    redis-cli -h $REDIS_HOST -p $REDIS_PORT del "${username}_hearts" "${username}_rupees" "${username}_xp" "${username}_actions"
    echo "Logged out and stats reset for $username."
}

# Function to heal one heart
potion() {
    local username=$1
    local hearts=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_hearts")
    hearts=$((hearts + 1))
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_hearts" $hearts
    echo "Healed one heart. Current hearts: $hearts"
}

# Function to gain XP
gain_xp() {
    local username=$1
    local xp=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_xp")
    local actions=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT get "${username}_actions")
    xp=$((xp + 10))
    actions=$((actions + 1))
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_xp" $xp
    redis-cli -h $REDIS_HOST -p $REDIS_PORT set "${username}_actions" $actions
    echo "Gained 10 XP. Current XP: $xp"
}

# Command-line interface
case $1 in
    login)
        login "$2"
        ;;
    logout)
        logout "$2"
        ;;
    potion)
        potion "$2"
        ;;
    xp)
        gain_xp "$2"
        ;;
    stats)
        display_stats "$2"
        ;;
    *)
        echo "Usage: $0 {login|logout|potion|xp|stats} <username>"
        ;;
esac#!/bin/bash

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
USER_FILE="$HOME/.bash_hero_user"
REDIS_SIMULATION_FILE="$HOME/.bash_hero_redis"

# Probability and Reward Arrays
declare -A RUPEE_REWARDS=(
    [0]=800
    [1]=900
    [5]=950
    [10]=980
    [25]=995
    [50]=1000
)

# Load or create user data
load_user_data() {
    if [[ -f "$USER_FILE" ]]; then
        USERNAME=$(<"$USER_FILE")
    else
        read -rp "Enter your hero name: " USERNAME
        echo "$USERNAME" > "$USER_FILE"
    fi
}

# Simulate Redis data retrieval (for demo purposes)
load_redis_data() {
    [[ -f "$REDIS_SIMULATION_FILE" ]] && source "$REDIS_SIMULATION_FILE"
}

# Utility function to print a separator line
print_line() {
    echo "--------------------------"
}

# Display the hero's stats
display_stats() {
    print_line
    echo -n "|   Hearts: "
    for ((i=0; i<HEARTS; i++)); do echo -n "❤️ "; done
    for ((i=HEARTS; i<MAX_HEARTS; i++)); do echo -n "🖤 "; done
    echo -e "\n|   Rupees: $RUPEES\n|   XP: $XP (Level $XP_LEVEL)"
    print_line
}

# Display verbose stats
display_verbose_stats() {
    echo -e "\n--- Stats for $USERNAME ---"
    echo "|   Hearts: $HEARTS/$MAX_HEARTS"
    echo "|   Rupees: $RUPEES"
    echo "|   XP: $XP (Level $XP_LEVEL)"
    echo "|   Actions taken: $ACTIONS"
    echo "|   XP Progress: $XP_PROGRESS/$XP_TO_NEXT_LEVEL"
    print_line
}

# Update the hero's stats
update_stats() {
    ((ACTIONS++))
    if ((ACTIONS % ACTIONS_PER_HEART_LOSS == 0)); then
        ((HEARTS--))
        [[ $HEARTS -le 0 ]] && { echo "You have been defeated!"; exit 1; }
        echo "You lost a heart due to exhaustion!"
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
        echo "Level Up! You're now level $XP_LEVEL"
    fi
    echo "You gained $1 XP!"
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
        echo "You found $rupees_awarded rupees!"
    else
        echo "You found nothing of value."
    fi
}

# Heal one heart
heal_heart() {
    if ((HEARTS < MAX_HEARTS)); then
        ((HEARTS++))
        echo "You healed 1 heart!"
    else
        echo "You're already at full health!"
    fi
}

# Simulate login and pull data from Redis
login() {
    $LOGGED_IN && { echo "Already logged in!"; return; }
    read -rp "Username: " input_username
    read -rsp "Password: " input_password
    echo ""
    if [[ "$input_username" == "$USERNAME" && "$input_password" == "password" ]]; then
        echo "Login successful!"
        load_redis_data
        HEARTS=$REDIS_HEARTS
        RUPEES=$REDIS_RUPEES
        XP=$REDIS_XP
        XP_LEVEL=$REDIS_XP_LEVEL
        LOGGED_IN=true
        echo "Data loaded from Redis simulation."
    else
        echo "Login failed!"
    fi
}

# Simulate logout
logout() {
    if $LOGGED_IN; then
        echo "Logged out."
        LOGGED_IN=false
        HEARTS=$MAX_HEARTS RUPEES=0 XP=0 XP_LEVEL=1 ACTIONS=100 XP_PROGRESS=0 XP_TO_NEXT_LEVEL=10
    else
        echo "Not logged in."
    fi
}

# Display the version of bash-hero
version() {
    echo "bash-hero version 1.0"
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
        *) echo "Unknown command: $1" ;;
    esac
}

# Display help (also the default action)
help() {
    echo "bash-hero commands:"
    echo "1) $USERNAME: Display verbose stats."
    echo "2) potion: Heal one heart."
    $LOGGED_IN && echo "3) logout: Log out and reset stats." || echo "3) login: Log in and load stats from Redis simulation."
    echo "4) version: Display bash-hero version."
    echo "5) help: Display this help message."
}

# Main loop
while true; do
    display_stats
    read -rp "> " command
    case "$command" in
        exit) break ;;
        bash-hero*) bash_hero "${command#bash-hero }" ;;
        *) eval "$command" && { award_rupees; gain_xp 10; } ;;
    esac
    update_stats
done
