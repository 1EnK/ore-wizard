#!/bin/bash

# Default values
default_id_prefix="id_"
default_priority_fee=100000
default_rpc_url="https://api.mainnet-beta.solana.com"
default_keypair_dir="$(dirname "$0")/../keypairs"
default_script_dir="$(dirname "$0")/../scripts"
default_threads=10

# Create the directories
mkdir -p "$default_keypair_dir" "$default_script_dir"

# Set the RPC URL
echo "Enter the RPC URL (default $default_rpc_url):"
read rpc_url
rpc_url=${rpc_url:-$default_rpc_url}

# Set the prefix of keypair files
echo "Enter the prefix for keypair files (default is $default_id_prefix):"
read id_prefix
id_prefix=${id_prefix:-$default_id_prefix}

# Prompt for the number of keypairs to create
echo "Enter the number of keypairs to create:"
read keypair_count

# Validate that keypair_count is numeric and greater than zero
if ! [[ "$keypair_count" =~ ^[0-9]+$ ]] || [ "$keypair_count" -le 0 ]; then
    echo "Invalid number of keypairs. Please enter a positive integer."
    exit 1
fi

# Set the number of Sessions (copies of each script) per keypair
echo "Enter the number of mining sessions per keypair (default is 1):"
read session_count
session_count=${session_count:-1}  # Default to 1 if no input is given

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
