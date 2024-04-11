#!/bin/bash

# Default prefix for the auto-ore mining scripts
auto_ore_prefix="auto-ore-"
default_rpc_url="https://api.mainnet-beta.solana.com"
default_script_dir="$(dirname "$0")/../scripts"

echo "Please enter the new RPC URL (Press Enter to use default: $default_rpc_url):"
read new_rpc_url
new_rpc_url=${new_rpc_url:-$default_rpc_url}

if [[ ! $new_rpc_url =~ ^(https://|wss://) ]]; then
    echo "Invalid URL format. Please enter a URL starting with 'https://' or 'wss://'."
    exit 1
fi

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
