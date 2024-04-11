# ORE-Wizard

ORE CLI management tool 

## Prerequisites

- Rust
    ```bash
    curl https://sh.rustup.rs -sSf | sh
    source $HOME/.cargo/env
    ```

- Solana CLI
    ```bash
    sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    ```

- ORE CLI
    ```bash
    cargo install ore-cli
    ```

## Installation

placeholder

## Script Usage

This script provides a set of commands to manage wallets and mining scripts for ORE (Open Rewards Ecosystem). It accepts a command as an argument and executes the corresponding action.

### Commands

- `--setup`: Initialize and configure wallets and mining scripts.
- `--update-urls`: Update the RPC URLs in the ORE scripts.
- `--sol-balance` or `-s`: Check the SOL balance for each address.
- `--rewards`: Check the ORE rewards for each address.
- `--claim`: Automate claiming ORE rewards for configured wallets.
- `--ore-balance` or `-o`: Check the ORE balance for each address.
- `--start-workers` or `-w`: Start multiple screens for ORE mining sessions.
- `--pubkeys`: Fetch the public keys for each address and export to `addr_list.txt`.
- `--help`: Display usage information.

### Options

- `-s` or `--sol-balance`: Check the SOL balance for each address.
- `-o` or `--ore-balance`: Check the ORE balance for each address.
- `-w` or `--start-worker`: Start multiple screens for ORE mining sessions.

### Example

- `$0 --setup`: Initialize and configure wallets and mining scripts.
- `$0 --sol-balance`: Checks the SOL balance for addresses in `addr_list.txt`.

If an invalid command is provided, the script will display the usage information and exit with an error code.

## Wallet Configuration

After the setup, run `ore-wizard --pubkeys` to generate an address list file as the index for the keypair addresses. The address list file will be generated as `addr_list.txt` in the current directory. The address list file will be used to check the SOL and ORE balances, and ORE rewards for each address.

## Mining Configuration

After the setup, run `ore-wizard --start-workers` to start multiple screens for ORE mining sessions. The script will automatically start the mining process for each script file in the `/scripts` directory in a separate screen session.
MAKE SURE TO FUND THE ADDRESSES BEFORE STARTING THE MINING SESSIONS.

## Debugging

Account_Not_Found: 
- Transfer 0.00000001 ORE to the address and try again.
- or run `spl-token create-account oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz` for the address and try again. 
Use `solana config set --keypair <path_to_keypair>` to set the keypair for the account.