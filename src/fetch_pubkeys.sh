#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default directory for the keypairs and output file
keypair_dir="$(dirname "$0")/../keypairs"
output_file="$(dirname "$0")/../addr_list.txt"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    keypair_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.keypair_dir' "$keypair_dir")
    output_file=$(ore_wizard_get_config '.ore-wizard.default_paths.account_index_file' "$output_file")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --keypairs|-k) keypair_dir="$2"; shift ;;
        --output|-o) output_file="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if the keypair directory exists
if [ ! -d "$keypair_dir" ]; then
    echo "Keypair directory $keypair_dir does not exist."
    exit 1
fi

# Empty the output file if it already exists
> "$output_file"

# Check if there are any keypair files to process
if [ -z "$(ls "$keypair_dir"/*.json 2>/dev/null)" ]; then
    echo "No keypair files found in $keypair_dir."
    exit 1
fi

# Iterate over each .json keypair file in the keypairs directory
for keypair in "$keypair_dir"/*.json; do
    # Extract the public key using solana-keygen
    pubkey=$(solana-keygen pubkey "$keypair")
    if [ $? -ne 0 ]; then
        echo "Failed to extract public key from $keypair."
        continue
    fi

    # Append the public key to the output file
    echo "$pubkey" >> "$output_file"
done

echo "Public keys extracted to $output_file."
