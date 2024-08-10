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
esac
