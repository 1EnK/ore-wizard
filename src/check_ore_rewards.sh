#!/bin/bash

# Default address list file and total rewards initialized to 0
addr_list="$(dirname "$0")/../addr_list.txt"
total_rewards=0
address_count=0

# Check if the address list file exists
if [ ! -f "$addr_list" ]; then
    echo "Address list file not found: $addr_list"
    exit 1
fi

# Read each address from the file and accumulate the rewards
while IFS= read -r addr; do
    if [[ -z "$addr" ]]; then
        echo "Skipping empty line"
        continue
    fi

    reward=$(ore rewards "$addr" | grep -oP '\d+\.\d+')  # Assuming the rewards are in a format that can be parsed with this regex

    if [[ -z "$reward" ]]; then
        address_count=$((address_count + 1))
        echo "No reward data available for $addr."
    else
        address_count=$((address_count + 1))
        total_rewards=$(echo "$total_rewards + $reward" | bc)
        echo "$addr : $reward ORE"
    fi
done < "$addr_list"

echo "Total rewards: $total_rewards ORE | $address_count addresses"