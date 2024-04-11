#!/bin/bash

# Default address list file
addr_list="$(dirname "$0")/../addr_list.txt"

# Check if the address list file exists
if [ ! -f "$addr_list" ]; then
    echo "Address list file not found: $addr_list"
    exit 1
fi

# Read each address from the file and check the SOL balance
while IFS= read -r addr; do
    if [[ -z "$addr" ]]; then
        echo "Skipping empty line"
        continue
    fi

    # Get the balance for the address
    balance=$(solana balance "$addr" | awk '{print $1}')

    # Print the address and its balance in SOL
    echo "$addr : $balance SOL"
done < "$addr_list"

echo "SOL balance check completed."