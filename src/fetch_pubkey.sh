#!/bin/bash

# Default directory for the keypairs and output file
keypair_dir="$(dirname "$0")/../keypairs"
output_file="$(dirname "$0")/../addr_list.txt"

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
