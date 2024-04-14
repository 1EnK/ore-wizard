#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default values
addr_list="$(dirname "$0")/../addr_list.txt"
rpc_url="https://api.mainnet-beta.solana.com"

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

# Start the balance check
echo "Checking SOL balances for the addresses in '$addr_list' at $current_time"
echo "======================================================"
echo "Address                                      : Balance"
echo "-------------------------------------------- : -------"

# Read each address from the file and check the SOL balance
while IFS= read -r addr; do
    if [[ -z "$addr" ]]; then
        echo "Skipping empty line"
        continue
    fi

    # Get the balance for the address
    balance=$(solana balance "$addr" --url "$rpc_url" 2>/dev/null | awk '{print $1}')
    if [[ -z "$balance" ]]; then
        echo "$addr : Error retrieving balance"
        continue
    fi

    # Print the address and its balance in SOL
    echo "$addr : $balance SOL"
done < "$addr_list"

echo "SOL balance check completed."
