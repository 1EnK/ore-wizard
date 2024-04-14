#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default prefix for the auto-ore mining scripts
auto_ore_prefix="auto-ore-" # Prefix for auto-ore scripts
default_rpc_url="https://api.mainnet-beta.solana.com"
default_script_dir="$(dirname "$0")/../scripts"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.default_url' "$default_rpc_url")
    default_script_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.script_dir' "$default_script_dir")
    auto_ore_prefix=$(ore_wizard_get_config '.ore-wizard.naming_convention.mining_script_prefix' "$auto_ore_prefix")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rpc) new_rpc_url="$2"; shift ;;
        --scripts) default_script_dir="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# If the new RPC URL is not provided, prompt the user
if [[ -z "$new_rpc_url" ]]; then
    echo "Please enter the new RPC URL (Press Enter to use default: $default_rpc_url):"
    read new_rpc_url
    new_rpc_url=${new_rpc_url:-$default_rpc_url}
fi

# Validate the URL format
if [[ ! $new_rpc_url =~ ^(https://|wss://) ]]; then
    echo "Invalid URL format. Please enter a URL starting with 'https://' or 'wss://'."
    exit 1
fi

# Validate the script directory
script_dir="$default_script_dir"
if [ ! -d "$script_dir" ]; then
    echo "Script directory not found: $script_dir"
    exit 1
fi

echo "Enter the script filenames to update separated by space (leave blank to update all scripts):"
read -r script_names
if [[ -z "$script_names" ]]; then
    script_paths=("$script_dir"/$auto_ore_prefix*.sh)
else
    IFS=' ' read -ra script_names_array <<< "$script_names"
    script_paths=("${script_names_array[@]/#/$script_dir/}")
fi

update_count=0
for script in "${script_paths[@]}"; do
    if [ ! -f "$script" ]; then
        echo "Script not found: $script"
        continue
    fi

    echo "Updating RPC URL in $script..."
    if sed -i "s|--rpc [^ ]* |--rpc $new_rpc_url |" "$script"; then
        update_count=$((update_count + 1))
    fi
done

echo "RPC URL update completed to $new_rpc_url. Total updated scripts: $update_count."
