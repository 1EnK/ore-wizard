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

echo "Address                                : Rewards"
echo "-------------------------------------- : -------"

# Read each address from the file and accumulate the rewards
while IFS= read -r addr; do
    if [[ -z "$addr" ]]; then
        echo "Skipping empty line"
        continue
    fi

    reward=$(ore rewards "$addr" 2>/dev/null | grep -oP '\d+\.\d+')
    if [[ -z "$reward" ]]; then
        echo "$addr : No reward data available"
    else
        total_rewards=$(echo "$total_rewards + $reward" | bc)
        echo "$addr : $reward ORE"
    fi
    address_count=$((address_count + 1))
done < "$addr_list"

echo "Total rewards: $total_rewards ORE | Processed $address_count addresses"
