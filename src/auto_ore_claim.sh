#!/bin/bash

# Default values
rpc_url="https://api.mainnet-beta.solana.com"
keypair="$HOME/.config/solana/id.json"
priority_fee=1000000 
recipient=""  # Empty by default for self-claiming
trigger_level=0.01 # Minimum reward balance to trigger a claim
hourly_rate=0.001 # ORE per hour for sleep calculation

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

# Function to get the current reward balance
get_reward_balance() {
    addr=$(solana-keygen pubkey "$keypair")
    balance=$(ore rewards "$addr" | grep -oE '[0-9]+(\.[0-9]+)?')
    echo "$balance"
}

# Function to calculate sleep time
calculate_sleep_time() {
    current_reward=$1
    # Ensure current_reward is a number
    if [[ -z "$current_reward" || "$current_reward" == "null" ]]; then
        current_reward=0
    fi
    remaining=$(echo "$trigger_level - $current_reward" | bc)
    hours_left=$(echo "scale=2; $remaining / $hourly_rate" | bc)
    sleep_seconds=$(echo "$hours_left * 3600 / 1" | bc)

    # Ensure sleep_seconds is an integer and greater than 0
    sleep_seconds=$(echo "$sleep_seconds/1" | bc)  # Convert to integer
    if ! [[ "$sleep_seconds" =~ ^[0-9]+$ ]] || [ "$sleep_seconds" -le 0 ]; then
        echo "Invalid sleep time calculated: $sleep_seconds seconds. Defaulting to 1 hour."
        sleep_seconds=3600  # Default to 1 hour if calculation fails
    fi

    echo $sleep_seconds
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
