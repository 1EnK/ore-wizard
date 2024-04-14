#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default values
addr_list="$(dirname "$0")/../addr_list.txt"
rpc_url="https://api.mainnet-beta.solana.com"
total_rewards=0
address_count=0

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
  addr_list=$(ore_wizard_get_config '.ore-wizard.default_paths.account_index_file' "$addr_list")
  rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.default_url' "$rpc_url")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --index) addr_list="$2"; shift ;;
        --url) rpc_url="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if the address list file exists
if [ ! -f "$addr_list" ]; then
    echo "Address list file not found: $addr_list"
    exit 1
fi

# Current system time in a readable format
current_time=$(date "+%Y-%m-%d %H:%M:%S")

# Start the rewards check
echo "Checking ORE rewards for the addresses in '$addr_list' at $current_time"
echo "======================================================"
echo "Address                                      : Rewards"
echo "-------------------------------------------- : -------"

# Read each address from the file and accumulate the rewards
while IFS= read -r addr; do
    if [[ -z "$addr" ]]; then
        echo "Skipping empty line"
        continue
    fi

    # Get the rewards for the address
    rewards=$(ore rewards "$addr" --rpc "$rpc_url" 2>/dev/null | grep -oP '\d+\.\d+')

    if [[ -z "$rewards" ]]; then
        echo "$addr : No rewards data available"
    else
        total_rewards=$(echo "$total_rewards + $rewards" | bc)
        echo "$addr : $rewards ORE"
    fi
    address_count=$((address_count + 1))
done < "$addr_list"

echo "Total rewards: $total_rewards ORE | Processed $address_count addresses"
