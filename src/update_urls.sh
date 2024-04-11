#!/bin/bash

# Default prefix for the auto-ore mining scripts
auto_ore_prefix="auto-ore-"
default_rpc_url="https://api.mainnet-beta.solana.com"
default_script_dir="$(dirname "$0")/../scripts"

# Ask the user for the new RPC URL
echo "Please enter the new RPC URL (Press Enter to use default: $default_rpc_url):"
read new_rpc_url
if [[ -z "$new_rpc_url" ]]; then
    new_rpc_url=$default_rpc_url
fi

# Validate the new URL format (https:// or wss://)
if [[ ! $new_rpc_url =~ ^https:// ]] && [[ ! $new_rpc_url =~ ^wss:// ]]; then
    echo "Invalid URL format. Please enter a URL starting with 'https://' or 'wss://'."
    exit 1
fi

# Directory where the scripts are located
script_dir="$default_script_dir"

# Check if the directory exists
if [ ! -d "$script_dir" ]; then
    echo "Script directory not found: $script_dir"
    exit 1
fi

# Prompt the user for specific scripts to update, or all by default
echo "Enter the script filenames to update separated by space (leave blank to update all scripts):"
read -r script_names

if [[ -z "$script_names" ]]; then
    script_paths=("$script_dir"/$auto_ore_prefix*.sh)
else # Split the input string into an array of script names
    read -ra script_names_array <<< "$script_names"
    script_paths=()
    for name in "${script_names_array[@]}"; do
        script_paths+=("$script_dir/$name")
    done
fi

# Iterate over each script and update the RPC URL
for script in "${script_paths[@]}"; do
    if [ ! -f "$script" ]; then
        echo "Script not found: $script"
        continue
    fi

    echo "Updating RPC URL in $script..."
    # Use sed to replace the RPC URL in each script
    sed -i "s|--rpc [^ ]* |--rpc $new_rpc_url |" "$script"
done

echo "RPC URL update completed to $new_rpc_url."
