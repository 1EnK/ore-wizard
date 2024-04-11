#!/bin/bash

# Default directory for the keypairs and output file
keypair_dir="$(dirname "$0")/../keypairs"
output_file="$(dirname "$0")/../addr_list.txt"

# Empty the output file if it already exists
> "$output_file"

# Iterate over each .json keypair file in the keypairs directory
for keypair in "$keypair_dir"/*.json; do
    # Extract the public key using solana-keygen
    pubkey=$(solana-keygen pubkey "$keypair")

    # Append the public key to the output file
    echo "$pubkey" >> "$output_file"
done
echo "Public keys extracted to $output_file."