#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Initialize variables with default values
default_rpc_url="https://api.mainnet-beta.solana.com"
default_priority_fee=1000000
default_recipient=""  # Self-claiming if left empty
default_trigger_level=0.01
default_hourly_rate=0.001
keypair_dir="$(dirname "$0")/../keypairs"
auto_claim_script="$(dirname "$0")/auto_ore_claim.sh"
default_screen_prefix="claim-ore-"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
  default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.default_url' "$default_rpc_url")
  default_priority_fee=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.priority_fee' "$default_priority_fee")
  default_recipient=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.recipient' "$default_recipient")
  default_trigger_level=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.trigger_level' "$default_trigger_level")
  default_hourly_rate=$(ore_wizard_get_config '.ore-wizard.rewards_claiming.hourly_rate' "$default_hourly_rate")
  keypair_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.keypair_dir' "$keypair_dir")
  default_screen_prefix=$(ore_wizard_get_config '.ore-wizard.naming_convention.claim_screen_prefix' "$default_screen_prefix")
fi

# Parse command-line arguments first to allow overrides
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

# Prompt user for values if not set by command-line arguments
rpc_url=${rpc_url:-$(read -p "Enter the RPC URL (default $default_rpc_url): " input_rpc_url; echo ${input_rpc_url:-$default_rpc_url})}
priority_fee=${priority_fee:-$(read -p "Enter the priority fee (default $default_priority_fee): " input_priority_fee; echo ${input_priority_fee:-$default_priority_fee})}
recipient=${recipient:-$(read -p "Enter the recipient address (leave blank for self-claiming): " input_recipient; echo ${input_recipient:-$default_recipient})}
trigger_level=${trigger_level:-$(read -p "Enter the trigger level for claiming (default $default_trigger_level): " input_trigger_level; echo ${input_trigger_level:-$default_trigger_level})}
hourly_rate=${hourly_rate:-$(read -p "Enter the hourly rate (default $default_hourly_rate): " input_hourly_rate; echo ${input_hourly_rate:-$default_hourly_rate})}

# Ensure the keypair directory exists
if [ ! -d "$keypair_dir" ]; then
    echo "Keypair directory not found: $keypair_dir"
    exit 1
fi

# Ensure the auto_claim script exists and is executable
if [ ! -f "$auto_claim_script" ] || [ ! -x "$auto_claim_script" ]; then
    echo "Auto-claim script not found or not executable: $auto_claim_script; please check the path and permissions."
    echo "You can set the path to the auto-claim script using the --auto-claim-script parameter."
    echo "Grant execute permissions to the script using 'chmod +x $auto_claim_script'."
    echo "Place the auto-claim script in the same directory as this script (default: 'ore-wizard/src/') or provide the full path to the script."
    exit 1
fi

# Iterate over the keypair files in the directory
index=0
for keypair in "$keypair_dir"/*.json; do
    screen_name="$default_screen_prefix$index"
    echo "Starting claim process for '$(basename "$keypair")' in screen session '$screen_name'"
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
