#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default values
rpc_url="https://api.mainnet-beta.solana.com"
keypair="$HOME/.config/solana/id.json"
priority_fee=1000000 
recipient=""  # Empty by default for self-claiming
trigger_level=0.01 # Minimum reward balance to trigger a claim
hourly_rate=0.001 # ORE per hour for sleep calculation

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
  rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.rewards_url' "$rpc_url")
  keypair=$(ore_wizard_get_config '.ore-wizard.default_paths.primary_keypair' "$keypair")
  priority_fee=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.priority_fee' "$priority_fee")
  recipient=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.recipient' "$recipient")
  trigger_level=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.trigger_level' "$trigger_level")
  hourly_rate=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.hourly_rate' "$hourly_rate")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --url) rpc_url="$2"; shift ;;
        --keypair) keypair="$2"; shift ;;
        --priority-fee) priority_fee="$2"; shift ;;
        --recipient) recipient="$2"; shift ;;
        --trigger-level) trigger_level="$2"; shift ;;
        --hourly-rate) hourly_rate="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Current system time in a readable format
current_time=$(date "+%Y-%m-%d %H:%M:%S")

# Print configurations with a header and timestamp
echo "==========================================================="
echo "Configuration for Auto ORE Claim"
echo "==========================================================="
echo "RPC URL        : $rpc_url"
echo "Keypair        : $keypair"
echo "Priority Fee   : $priority_fee (lamports)"
echo "Recipient      : ${recipient:-'self (default)'}"  # Showing 'self (default)' if empty
echo "Trigger Level  : $trigger_level ORE"
echo "Hourly Rate    : $hourly_rate ORE/hour"
echo "==========================================================="
echo "Starting the auto-claim loop at $current_time..."
echo "==========================================================="


# Validate the recipient address if not empty
if [[ -n "$recipient" ]]; then
    if ! [[ "$recipient" =~ ^[0-9a-zA-Z]{32,44}$ ]]; then
        echo "Invalid recipient address: $recipient"
        exit 1
    fi
fi

# Get the current reward balance
get_reward_balance() {
    addr=$(solana-keygen pubkey "$keypair")
    balance=$(ore rewards "$addr" | grep -oE '[0-9]+(\.[0-9]+)?')
    if [[ -z "$balance" ]]; then
        echo "Failed to fetch rewards for $addr."
        balance=0
    fi
    echo "$balance"
}

# Calculate sleep time
calculate_sleep_time() {
    current_reward=$1
    if [[ -z "$current_reward" || ! "$current_reward" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Invalid current reward: $current_reward"
        current_reward=0
    fi

    remaining=$(echo "$trigger_level - $current_reward" | bc)
    if [[ $(echo "$remaining <= 0" | bc) -eq 1 ]]; then
        remaining=0
    fi

    hours_left=$(echo "scale=2; $remaining / $hourly_rate" | bc)
    sleep_seconds=$(echo "scale=0; $hours_left * 3600 / 1" | bc)

    # Ensure sleep_seconds is positive
    if [[ "$sleep_seconds" -le 0 ]]; then
        sleep_seconds=3600  # Default to 1 hour if calculation fails or is below zero
    fi

    echo "$sleep_seconds"
}


# Main loop
while true; do
    current_reward=$(get_reward_balance)
    echo "Current reward: $current_reward ORE, Trigger level: $trigger_level ORE"

    if (( $(echo "$current_reward >= $trigger_level" | bc -l) )); then
        echo "Claiming reward..."
        if [[ -n "$recipient" ]]; then
            ore --rpc "$rpc_url" \
                --keypair "$keypair" \
                --priority-fee "$priority_fee" \
                claim "$current_reward" "$recipient"
        else
            ore --rpc "$rpc_url" \
                --keypair "$keypair" \
                --priority-fee "$priority_fee" \
                claim
        fi
        sleep 1  # short delay between claims
    else
        echo "Reward below trigger level..."
        sleep_time=$(calculate_sleep_time $current_reward)
        echo "Sleeping for $(echo "$sleep_time/3600" | bc) hours..."
        sleep $sleep_time
    fi
done
