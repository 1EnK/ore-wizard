#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Initialize variables with default values
default_rpc_url="https://api.mainnet-beta.solana.com"
default_priority_fee=10000 # lamports
keypair_dir="$(dirname "$0")/../keypairs"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
  default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.rewards_url' "$default_rpc_url")
  default_priority_fee=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.priority_fee' "$default_priority_fee")
  keypair_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.keypair_dir' "$keypair_dir")
fi

# Parse command-line arguments first to allow overrides
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --url) rpc_url="$2"; shift ;;
        --priority-fee) priority_fee="$2"; shift ;;
        --keypair-dir) keypair_dir="$2"; shift ;;
        --amount) amount="$2"; shift 2 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Prompt user for values if not set by command-line arguments
rpc_url=${rpc_url:-$(read -p "Enter the RPC URL (default $default_rpc_url): " input_rpc_url; echo ${input_rpc_url:-$default_rpc_url})}
priority_fee=${priority_fee:-$(read -p "Enter the priority fee (default $default_priority_fee): " input_priority_fee; echo ${input_priority_fee:-$default_priority_fee})}

# Ensure the keypair directory exists
if [ ! -d "$keypair_dir" ]; then
    echo "Keypair directory not found: $keypair_dir"
    exit 1
fi

# Iterate over the keypair files in the directory
index=0
for keypair in "$keypair_dir"/*.json; do
    echo "Staking ORE from V1 to V2 for '$(basename "$keypair")'..."
    
    # Build the command to stake the ORE
    command="ore stake --rpc \"$rpc_url\" --keypair \"$keypair\" --priority-fee \"$priority_fee\""

    # Check if an amount has been specified and append it to the command
    if [[ "$amount" != "max" ]]; then
        command+=" --amount \"$amount\""
    fi

    # Execute
    eval $command

    index=$((index + 1))
done
