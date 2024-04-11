#!/bin/bash

# Define the SPL token address and set the default address list file
token_address="oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz"
addr_list="$(dirname "$0")/../addr_list.txt"

# Check if the address list file exists
if [ ! -f "$addr_list" ]; then
    echo "Address list file not found: $addr_list"
    exit 1
fi

# Read each address from the file and check the SPL token balance
while IFS= read -r owner_address; do
    if [[ -z "$owner_address" ]]; then
        echo "Skipping empty line"
        continue
    fi

    balance=$(spl-token balance "$token_address" --owner "$owner_address")

    echo "$owner_address : $balance ORE"
done < "$addr_list"