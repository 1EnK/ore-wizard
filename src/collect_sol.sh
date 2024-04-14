#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default configurations
default_rpc_url="https://api.mainnet-beta.solana.com"
default_priority_fee=5000  # Default transaction priority fee in lamports
default_reserved_gas=0.001  # Default amount reserved for transaction fees in SOL, recommended at least 0.001 SOL
default_fee_payer=""  # Default fee payer uses the sender as the fee payer
default_recipient=""  # Can't be empty, must be provided by the user
skip_prompt=false  # Skip prompt if set to true, not functional yet

# Set the directory containing the keypairs
keypair_dir="$(dirname "$0")/../keypairs"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    default_rpc_url=$(ore_wizard_get_config '.ore-wizard.rpc.collect_url' "$default_rpc_url")
    default_priority_fee=$(ore_wizard_get_config '.ore-wizard.collect_sol.priority_fee' "$default_priority_fee")
    default_reserved_gas=$(ore_wizard_get_config '.ore-wizard.collect_sol.reserved_gas' "$default_reserved_gas")
    default_fee_payer=$(ore_wizard_get_config '.ore-wizard.collect_sol.fee_payer' "$default_fee_payer")
    default_recipient=$(ore_wizard_get_config '.ore-wizard.collect_sol.recipient' "$default_recipient")
    keypair_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.keypair_dir' "$keypair_dir")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --reserved-gas) default_reserved_gas="$2"; shift ;; # Below 0.001 SOL may trigger an error
        --rpc) default_rpc_url="$2"; shift ;;
        --priority-fee) default_priority_fee="$2"; shift ;;
        --fee-payer) default_fee_payer="$2"; shift ;;
        --recipient) default_recipient="$2"; shift ;;
        --keypair-dir) keypair_dir="$2"; shift ;;
        --skip-prompt) skip_prompt=true ;; # Not functional yet
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done


# Prompt user for values if not skipping
if [[ "$skip_prompt" = false ]]; then
    read -p "Enter the RPC URL (press Enter for default $default_rpc_url): " rpc_url
    rpc_url=${rpc_url:-$default_rpc_url}

    read -p "Enter the recipient's Solana address: " recipient_address
    if [[ -z "$recipient_address" ]]; then
        echo "Recipient address is required."
        exit 1
    fi

    read -p "Enter the priority fee in lamports (press Enter for default $default_priority_fee): " priority_fee
    priority_fee=${priority_fee:-$default_priority_fee}

    read -p "Enter the fee payer keypair (press Enter to use sender as fee payer): " input_fee_payer
    input_fee_payer=${input_fee_payer:-$default_fee_payer}

    # Check if the keypair directory exists
    if [ ! -d "$keypair_dir" ]; then
        echo "Keypair directory not found: $keypair_dir"
        exit 1
    fi
fi

# Iterate over each .json keypair file in the directory
for keypair in "$keypair_dir"/*.json; do
    # Extract the public key using solana-keygen
    pubkey=$(solana-keygen pubkey "$keypair")

    # Get the current balance for the keypair
    balance=$(solana balance "$pubkey" --url "$rpc_url" | grep -oE '^[0-9]+(\.[0-9]+)?')

    # Skip if the balance < reserved gas
    if [[ $(echo "$balance < $default_reserved_gas" | bc) -eq 1 ]]; then
        echo "Skipping $pubkey due to insufficient balance."
        continue
    fi

    # Calculate the amount to transfer, subtracting the reserved gas
    transfer_amount=$(echo "$balance - $default_reserved_gas" | bc)

    # Early exit if the transfer amount is zero or negative
    if [[ $(echo "$transfer_amount <= 0" | bc) -eq 1 ]]; then
        echo "No funds to transfer for $pubkey."
        continue
    fi

    fee_payer=${input_fee_payer:-${default_fee_payer:-$keypair}} # Use the keypair as the fee payer if not specified
    fee_payer_pubkey=$(solana-keygen pubkey "$fee_payer")
    fee_payer_balance=$(solana balance "$fee_payer" --url "$rpc_url" | grep -oE '^[0-9]+(\.[0-9]+)?')
    echo "Fee payer: $fee_payer_pubkey : $fee_payer_balance SOL"

    if [[ $(echo "$fee_payer_balance < 0.001" | bc) -eq 1 ]]; then
        echo "Fee payer $fee_payer_pubkey has insufficient balance to pay for transaction fees."
        continue
    fi

    # Transfer the calculated amount to the recipient address
    echo "Attempting to transfer $transfer_amount SOL from $pubkey to $recipient_address..."
    if solana transfer --from "$keypair" "$recipient_address" "$transfer_amount" \
        --url "$rpc_url" --fee-payer "$keypair" \
        --allow-unfunded-recipient --with-compute-unit-price "$priority_fee" -v; then
        echo "Fund collected from $pubkey."
    else
        echo "Transaction failed for $pubkey. Continuing to next address..."
        continue
    fi
done

echo "Funds collection completed."

# Show recipient balance
recipient_balance=$(solana balance "$recipient_address" --url "$rpc_url" | grep -oE '^[0-9]+(\.[0-9]+)?')
echo "New Recipient Balance: $recipient_balance SOL"
