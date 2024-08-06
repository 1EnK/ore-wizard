#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default values
default_id_prefix="id_"
default_priority_fee=10000  # lamports
default_rpc_url="https://api.mainnet-beta.solana.com"
default_keypair_dir="$(dirname "$0")/../keypairs"
default_script_dir="$(dirname "$0")/../scripts"
default_threads=10
default_session_count=1
fetch_pubkeys_script="$(dirname "$0")/fetch_pubkeys.sh"
skip_prompt=false # Skip prompt if set to true, not functional yet

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    default_id_prefix=$(ore_wizard_get_config '.ore-wizard.naming_convention.keypair_file_prefix' "$default_id_prefix")
    default_priority_fee=$(ore_wizard_get_config '.ore-wizard.mining.priority_fee' "$default_priority_fee")
    default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.mining_url' "$default_rpc_url")
    default_keypair_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.keypair_dir' "$default_keypair_dir")
    default_script_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.script_dir' "$default_script_dir")
    default_threads=$(ore_wizard_get_config '.ore-wizard.mining.thread_count' "$default_threads")
    default_session_count=$(ore_wizard_get_config '.ore-wizard.mining.session_count' "$default_session_count")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rpc) default_rpc_url="$2"; shift ;;
        --prefix) default_id_prefix="$2"; shift ;;
        --priority-fee) default_priority_fee="$2"; shift ;;
        --keypairs) default_keypair_dir="$2"; shift ;;
        --scripts) default_script_dir="$2"; shift ;;
        --threads) default_threads="$2"; shift ;;
        --sessions|--screens) default_session_count="$2"; shift ;;
        --skip-prompt) skip_prompt=true ;; # Not functional yet
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Create the directories
mkdir -p "$default_keypair_dir" "$default_script_dir"

# Prompt user for values if not skipping
if [[ "$skip_prompt" = false ]]; then
    # Set the RPC URL
    echo "Enter the RPC URL (default $default_rpc_url):"
    read rpc_url
    rpc_url=${rpc_url:-$default_rpc_url}

    # Validate the URL format
    if [[ ! $rpc_url =~ ^(https://|wss://) ]]; then
        echo "Invalid URL format. Please enter a URL starting with 'https://' or 'wss://'."
        exit 1
    fi

    # Set the prefix of keypair files
    echo "Enter the prefix for keypair files (default is $default_id_prefix):"
    read id_prefix
    id_prefix=${id_prefix:-$default_id_prefix}

    # Prompt for the number of keypairs to create
    echo "Enter the number of keypairs to create:"
    read keypair_count

    # Validate that keypair_count is numeric and greater than zero
    if ! [[ "$keypair_count" =~ ^[0-9]+$ ]] || [ "$keypair_count" -lt 0 ]; then
        echo "Invalid number of keypairs. Please enter a positive integer."
        exit 1
    fi

    # Set the number of Sessions (copies of each script) per keypair
    echo "Enter the number of mining sessions per keypair (default is $default_session_count):"
    read session_count
    session_count=${session_count:-$default_session_count}  # Use default if no input is given

    # Validate that session_count is numeric and greater than zero
    if ! [[ "$session_count" =~ ^[0-9]+$ ]] || [ "$session_count" -le 0 ]; then
        echo "Invalid number of sessions. Please enter a positive integer."
        exit 1
    fi

    # Set the priority fee for mining sessions
    echo "Enter the priority fee (default is $default_priority_fee):"
    read priority_fee
    priority_fee=${priority_fee:-$default_priority_fee}  # Use default if no input is given

    # Set the threads for mining sessions
    echo "Enter the number of threads per mining session (default is $default_threads):"
    read threads
    threads=${threads:-$default_threads}  # Use default if no input is given
fi

# Generate keypairs and corresponding ore mining scripts
for i in $(seq 0 $((keypair_count - 1))); do
    keypair_id="${id_prefix}${i}"
    solana-keygen new -o "$default_keypair_dir/${keypair_id}.json"

    for t in $(seq 0 $((session_count - 1))); do
        script_index=$((i * session_count + t))

        cat <<EOF > "$default_script_dir/auto-ore-$script_index.sh"
#!/bin/bash

# Auto-ore mining script for keypair ${keypair_id} using the specified RPC URL

while true; do
    ore --rpc "$rpc_url" \
        --keypair "$default_keypair_dir/${keypair_id}.json" \
        --priority-fee "$priority_fee" \
        mine \
        --threads "$threads"
    echo "ore process exited, restarting..."
    sleep 1  # wait for 1 second before restarting
done
EOF

        chmod +x "$default_script_dir/auto-ore-$script_index.sh"
    done
done

total_scripts=$((keypair_count * session_count))
echo "$keypair_count keypairs and $total_scripts scripts created using RPC URL: $rpc_url, prefix: $id_prefix, priority fee: $priority_fee, and $threads threads per session."

# Run the fetch_pubkeys script to extract the public keys
if [ -f "$fetch_pubkeys_script" ]; then
    echo "Running fetch public keys script..."
    bash "$fetch_pubkeys_script"
else
    echo "Fetch public keys script not found: $fetch_pubkeys_script"
    exit 1
fi
