#!/bin/bash

# Initialize variables with default values
default_rpc_url="https://api.mainnet-beta.solana.com"
default_priority_fee=1000000
default_trigger_level=0.01
default_hourly_rate=0.001
keypair_dir="$(dirname "$0")/../keypairs"
auto_claim_script="$(dirname "$0")/auto_ore_claim.sh"

# Prompt user for values
echo "Enter the RPC URL (default $default_rpc_url):"
read -r input_rpc_url
rpc_url=${input_rpc_url:-$default_rpc_url}

echo "Enter the recipient address:"
read -r recipient  # No default for recipient address

echo "Enter the priority fee (default $default_priority_fee):"
read -r input_priority_fee
priority_fee=${input_priority_fee:-$default_priority_fee}

echo "Enter the trigger level for claiming (default $default_trigger_level):"
read -r input_trigger_level
trigger_level=${input_trigger_level:-$default_trigger_level}

echo "Enter the hourly rate (default $default_hourly_rate):"
read -r input_hourly_rate
hourly_rate=${input_hourly_rate:-$default_hourly_rate}

# Now check for command-line arguments which can override the user input
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --url) rpc_url="$2"; shift ;;
        --priority-fee) priority_fee="$2"; shift ;;
        --recipient) recipient="$2"; shift ;;
        --trigger-level) trigger_level="$2"; shift ;;
        --hourly-rate) hourly_rate="$2"; shift ;;
        --keypair-dir) keypair_dir="$2"; shift ;;
        --auto-claim-script) auto_claim_script="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Ensure the keypair directory exists
if [ ! -d "$keypair_dir" ]; then
    echo "keypair directory not found: $keypair_dir"
    exit 1
fi

# Ensure the auto_claim script exists and is executable
if [ ! -f "$auto_claim_script" ] || [ ! -x "$auto_claim_script" ]; then
    echo "Auto-claim script not found or not executable: $auto_claim_script"
    exit 1
fi

# Iterate over the keypair files in the directory
index=0
for keypair in "$keypair_dir"/*.json; do
    screen_name="claim-ore-$index"
    echo "Starting claim process for $keypair in screen $screen_name..."
    screen -dmS "$screen_name" "$auto_claim_script" \
        --url "$rpc_url" \
        --keypair "$keypair" \
        --priority-fee "$priority_fee" \
        --recipient "$recipient" \
        --trigger-level "$trigger_level" \
        --hourly-rate "$hourly_rate"
    index=$((index + 1))
done

echo "Batch claim processes started in separate screen sessions."
