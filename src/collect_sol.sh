#!/bin/bash

# Default configurations
default_rpc_url="https://api.mainnet-beta.solana.com"
default_priority_fee=5000  # Default transaction priority fee in lamports
default_reserved_gas=0.001  # Default amount reserved for transaction fees in SOL, recommended at least 0.001 SOL
default_fee_payer=""  # Default fee payer uses the sender as the fee payer

# Set the directory containing the keypairs
keypair_dir="$(dirname "$0")/../keypairs"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --reserved-gas) default_reserved_gas="$2"; shift ;; # Below 0.001 SOL may trigger an error
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Prompt user for values
read -p "Enter the RPC URL (press Enter for default $default_rpc_url): " rpc_url
rpc_url=${rpc_url:-$default_rpc_url}

read -p "Enter the recipient's Solana address: " recipient_address
if [[ -z "$recipient_address" ]]; then
    echo "Recipient address is required."
    exit 1
fi

read -p "Enter the priority fee in lamports (press Enter for default $default_priority_fee): " priority_fee
priority_fee=${priority_fee:-$default_priority_fee}

read -p "Enter the fee payer keypair (press Enter to use sender as fee payer): " fee_payer
fee_payer=${fee_payer:-$default_fee_payer}

# Check if the keypair directory exists
if [ ! -d "$keypair_dir" ]; then
    echo "Keypair directory not found: $keypair_dir"
    exit 1
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

    # Set the fee payer to the keypair if not specified, if specified, use the provided address, if empty use keypair here
    fee_payer=${fee_payer:-$keypair}
    fee_payer_pubkey=$(solana-keygen pubkey "$fee_payer")
    fee_payer_balance=$(solana balance "$fee_payer" --url "$rpc_url" | grep -oE '^[0-9]+(\.[0-9]+)?')
    echo "Fee payer: $fee_payer_pubkey : $fee_payer_balance SOL"

    if [[ $(echo "$fee_payer_balance < 0.001" | bc) -eq 1 ]]; then
        echo "Fee payer $fee_payer_pubkey has insufficient balance to pay for transaction fees."
        continue
    fi

    # Ensure there is enough balance to cover the transfer and the reserved gas
    if [[ $(echo "$transfer_amount > 0" | bc) -eq 1 ]]; then
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
    else
        echo "Not enough balance to transfer from $pubkey. Skipping..."
    fi
done

echo "Funds collection completed."

# Show recipient balance
recipient_balance=$(solana balance "$recipient_address" --url "$rpc_url" | grep -oE '^[0-9]+(\.[0-9]+)?')
echo "New Recipient Balance: $recipient_balance SOL"
