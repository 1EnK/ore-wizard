#!/bin/bash

# Default Configuration
default_rpc_url="https://api.mainnet-beta.solana.com"
default_trigger_balance=0.003  # Balance level that triggers the funding action
default_maintain_balance=0.01  # Balance level to maintain after funding
default_funding_account_keypair="$HOME/.config/solana/id.json"
default_addr_list="$(dirname "$0")/../addr_list.txt"
default_priority_fee=500000  # Compute unit price in lamports as the priority fee
sleep_duration=14400 # 4 hours


# Prompt for the RPC URL
echo "Enter the RPC URL (default $default_rpc_url):"
read -r input_rpc_url
rpc_url=${input_rpc_url:-$default_rpc_url}

# Prompt for the address list file for funding
echo "Enter the path to the address list file (default $default_addr_list):"
read -r input_addr_list
addr_list=${input_addr_list:-$default_addr_list}

# Prompt for the funding account keypair
echo "Enter the path to the funding account keypair (default $default_funding_account_keypair):"
read -r input_funding_account_keypair
funding_account_keypair=${input_funding_account_keypair:-$default_funding_account_keypair}

# Prompt for the trigger balance
echo "Enter the trigger balance (default $default_trigger_balance):"
read -r input_trigger_balance
trigger_balance=${input_trigger_balance:-$default_trigger_balance}

# Prompt for the maintain balance
echo "Enter the maintain balance (default $default_maintain_balance):"
read -r input_maintain_balance
maintain_balance=${input_maintain_balance:-$default_maintain_balance}

# Prompt for the priority fee
echo "Enter the priority fee (default $default_priority_fee):"
read -r input_priority_fee
priority_fee=${input_priority_fee:-$default_priority_fee}


# Validate file paths
if [ ! -f "$addr_list" ]; then
    echo "Address list file not found: $addr_list"
    exit 1
fi
if [ ! -f "$funding_account_keypair" ]; then
    echo "Funding account keypair file not found: $funding_account_keypair"
    exit 1
fi


# Start funding process loop
while true; do
    echo "Starting funding session..."
    echo "---------------------------------------------"
    echo "Address                                : Balance"
    echo "-------------------------------------- : -------"

    while IFS= read -r addr; do
        if [[ -z "$addr" ]]; then
            continue  # Skip empty lines or invalid addresses
        fi

        balance=$(solana balance "$addr" --url $rpc_url 2>/dev/null | awk '{print $1}')
        echo "$addr : $balance SOL"

        if [[ "$balance" && "$(echo "$balance < $trigger_balance" | bc)" -eq 1 ]]; then
            amount_to_fund=$(echo "$maintain_balance - $balance" | bc)
            echo "Funding $addr with $amount_to_fund SOL..."

            if solana transfer --from "$funding_account_keypair" "$addr" "$amount_to_fund" \
                --url $rpc_url --fee-payer "$funding_account_keypair" \
                --allow-unfunded-recipient --with-compute-unit-price $priority_fee -v; then
                echo "Funding transaction successful for $addr."
            else
                echo "Funding transaction failed for $addr. Continuing to next address..."
                continue
            fi

            # Check the funding account balance after each transaction
            while true; do
                funding_account_balance=$(solana balance --keypair "$funding_account_keypair" --url $rpc_url | awk '{print $1}')
                echo "Funding account balance: $funding_account_balance SOL"

                # Check if balance is sufficient to continue
                if [[ "$(echo "$funding_account_balance >= $maintain_balance" | bc)" -eq 1 ]]; then
                    echo "Funding account balance is sufficient to continue."
                    break  # Exit the loop and proceed with next address
                else
                    echo "Funding account balance is low ($funding_account_balance SOL). Please fund the account. Sleeping for $sleep_duration seconds..."
                    sleep "$sleep_duration"
                fi
            done

        fi
    done < "$addr_list"

    echo "Funding session completed. Waiting for next round..."
    sleep "$sleep_duration"
done