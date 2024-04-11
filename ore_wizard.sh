#!/bin/bash

# Default relative path to the scripts directory
SCRIPT_DIR="$(dirname "$0")/src"

case "$1" in
    --setup)
        "$SCRIPT_DIR/ore_setup.sh"
        ;;
    --update-urls)
        "$SCRIPT_DIR/update_urls.sh"
        ;;
    --sol-balance|-s)
        "$SCRIPT_DIR/check_sol_balance.sh"
        ;;
    --rewards)
        "$SCRIPT_DIR/check_ore_rewards.sh"
        ;;
    --claim)
        "$SCRIPT_DIR/claim_ore_batch.sh"
        ;;
    --ore-balance|-o)
        "$SCRIPT_DIR/check_ore_balance.sh"
        ;;
    --start-workers|-w)
        "$SCRIPT_DIR/start_worker_screens.sh"
        ;;
    --pubkeys)
        "$SCRIPT_DIR/fetch_pubkey.sh"
        ;;
    --help)
        echo "Usage: $0 COMMAND"
        echo "Commands:"
        echo "  --setup         Initialize and configure wallets and mining scripts."
        echo "  --update-urls   Update the RPC URLs in the ORE scripts."
        echo "  --sol-balance   Check the SOL balance for each address."
        echo "  --rewards       Check the ORE rewards for each address."
        echo "  --claim         Automate claiming ORE rewards for configured wallets."
        echo "  --ore-balance   Check the ORE balance for each address."
        echo "  --start-worker  Start multiple screens for ORE mining sessions."
        echo "  --pubkeys       Fetch the public keys for each address and export to addr_list.txt."
        echo ""
        echo "Options:"
        echo "  -s, --sol-balance   Check the SOL balance for each address."
        echo "  -o, --ore-balance   Check the ORE balance for each address."
        echo "  -w, --start-worker  Start multiple screens for ORE mining sessions."
        echo ""
        echo "Example:"
        echo "  $0 --setup       Initialize and configure wallets and mining scripts."
        echo "  $0 --sol-balance Checks the SOL balance for addresses in addr_list.txt."
        ;;
    *)
        echo "Usage: $0 COMMAND"
        echo "Try '$0 --help' for more information."
        exit 1
        ;;
esac
