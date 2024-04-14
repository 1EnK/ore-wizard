#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default Configuration
default_rpc_url="https://api.mainnet-beta.solana.com"
default_trigger_balance=0.003  # Balance level that triggers the funding action
default_maintain_balance=0.01  # Balance level to maintain after funding
default_funding_account_keypair="$HOME/.config/solana/id.json"
default_addr_list="$(dirname "$0")/../addr_list.txt"
default_priority_fee=500000  # Compute unit price in lamports as the priority fee
sleep_duration=14400 # 4 hours
skip_prompt=false  # Skip prompt if set to true, not functional yet

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.funding_url' "$default_rpc_url")
    default_trigger_balance=$(ore_wizard_get_config '.ore-wizard.funding.trigger_balance' "$default_trigger_balance")
    default_maintain_balance=$(ore_wizard_get_config '.ore-wizard.funding.maintain_balance' "$default_maintain_balance")
    default_funding_account_keypair=$(ore_wizard_get_config '.ore-wizard.funding.funding_account_keypair' "$default_funding_account_keypair")
    default_addr_list=$(ore_wizard_get_config '.ore-wizard.default_paths.account_index_file' "$default_addr_list")
    default_priority_fee=$(ore_wizard_get_config '.ore-wizard.funding.priority_fee' "$default_priority_fee")
    sleep_duration=$(ore_wizard_get_config '.ore-wizard.funding.sleep_duration' "$sleep_duration")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rpc) default_rpc_url="$2"; shift ;;
        --trigger-balance|-t) default_trigger_balance="$2"; shift ;;
        --maintain-balance|-m) default_maintain_balance="$2"; shift ;;
        --funding-account|-f) default_funding_account_keypair="$2"; shift ;;
        --index) default_addr_list="$2"; shift ;;
        --priority-fee) default_priority_fee="$2"; shift ;;
        --sleep) sleep_duration="$2"; shift ;;
        --skip-prompt) skip_prompt=true ;; # Not functional yet
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Prompt user for values if not skipping
if [[ "$skip_prompt" = false ]]; then # Start of the prompt section
    echo "Enter the RPC URL (default $default_rpc_url):"
    read -r input_rpc_url
    rpc_url=${input_rpc_url:-$default_rpc_url}

    # Prompt for the address list file for funding
    echo "Enter the path to the address list file (default $default_addr_list):"
    read -r input_addr_list
    input_addr_list=${input_addr_list:-$default_addr_list}
    addr_list=$(eval echo $input_addr_list)

    # Validate address file path
    if [ ! -f "$addr_list" ]; then
        echo "Address list file not found: $addr_list"
        exit 1
    fi

    # Prompt for the funding account keypair
    echo "Enter the path to the funding account keypair (default $default_funding_account_keypair):"
    read -r input_funding_account_keypair
    input_funding_account_keypair=${input_funding_account_keypair:-$default_funding_account_keypair}
    funding_account_keypair=$(eval echo $input_funding_account_keypair)

    # Validate funding account keypair file
    if [ ! -f "$funding_account_keypair" ]; then
        echo "Funding account keypair file not found: $funding_account_keypair"
        exit 1
    fi

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

# End of the prompt section
fi


# Start funding process loop
current_time=$(date "+%Y-%m-%d %H:%M:%S")

while true; do
    echo "Starting funding session at $current_time..."
    echo "------------------------------------------------------"
    echo "Address                                      : Balance"
    echo "-------------------------------------------- : -------"

    while IFS= read -r addr; do
        if [[ -z "$addr" ]]; then
            continue  # Skip empty lines or invalid addresses
        fi

        balance=$(solana balance "$addr" --url $rpc_url 2>/dev/null | awk '{print $1}')
        echo "$addr : $balance SOL"

        if [[ "$balance" && "$(echo "$balance < $trigger_balance" | bc)" -eq 1 ]]; then
            amount_to_fund=$(echo "$maintain_balance - $balance" | bc)

            # Skip zero or negative funding amounts
            if [[ "$(echo "$amount_to_fund > 0" | bc)" -eq 0 ]]; then
                continue
            fi

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

    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "Funding session completed at $current_time. Sleeping for $sleep_duration seconds before the next session..."
    sleep "$sleep_duration"
done