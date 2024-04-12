# Ore-Wizard

Ore-Wizard is a shell command tool designed to facilitate the management of solana keypairs and mining scripts for the Ore CLI (https://ore.supply/). It streamlines operations such as keypairs setup, RPC URL updates, balance checks, multi-session ore mining, and automated reward claiming.

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

- Ore CLI
    ```bash
    cargo install ore-cli
    ```

    Or any other modified version of the Ore CLI using the same `ore-cli` command.

## Installation

- Clone the repository and navigate to the project directory.

- Add the project directory to the PATH environment variable.
    ```bash
    export PATH=$PATH:$HOME/ore-wizard
    ```

- Grant execute permissions to the scripts.
    ```bash
    chmod +x $HOME/ore-wizard/ore-wizard
    ```

    ```bash
    chmod +x $HOME/ore-wizard/src/*.sh
    ```
Then you can run the script using the `ore-wizard` command. Start by running `ore-wizard --help` to display the usage information. 
Next, run `ore-wizard --setup` to initialize and configure keypairs and mining scripts. See the Account Configuration section for more details.

## Account Configuration

Run `ore-wizard --setup` to configure the keypairs and mining scripts. The script will prompt the user to enter the number of keypairs to generate and the number of mining scripts to create. The keypairs and mining scripts will be generated in the `/keypairs` and `/scripts` directories, respectively.

- rpc_urls:
- id_prefix: the prefix for the miner keypair filenames to classify the miner accounts across different machines.
- session_count: the number of mining screen scripts for each miner account to create. The script will create multiple mining scripts for each miner account to run multiple mining sessions in separate screens.
- priority_fee: the priority fee to set for the mining transactions in lamports. The mining scripts will apply the given priority fee.

An account index file `addr_list.txt` will be generated in the project root after the setup. If the index file is missing, run `ore-wizard --pubkeys` to generate an address list file as the index for the keypair addresses. The address list file will be used as an index to fund the miner addresses and check the balance and ore rewards.

## Funding Miner Accounts

Run `ore-wizard --fund-sol` or `-f` to fund the miner accounts with SOL to maintain the minimum balance. The script will prompt the user to enter the number of miner accounts to fund. The script will then fund the miner accounts with SOL from the configured funding account. Make sure the funding account has enough SOL to fund the miner accounts.

## Mining Configuration

After the setup, run `ore-wizard --start_miners` or `-m` to start multiple mining sessions in separate screens. The script will prompt the user to enter the number of mining sessions to start. The script will then start the mining sessions in separate screens. Default scripts path is `/scripts` and the default screen name is `ore-<index>`.
MAKE SURE TO FUND THE ADDRESSES BEFORE STARTING THE MINING SESSIONS.

Use `screen -ls` to list the active screen sessions and `screen -r ore-<index>` to attach to the screen session and monitor the mining process.
To detach from the screen session, press `Ctrl + A` followed by `D`.

## Reward Claiming

Run `ore-wizard --claim` to automate the claiming of Ore rewards for the configured wallets. Set up the recipient address to claime the rewards to a specific address. Leave the recipient address empty to claim the rewards to the miner address. The claim sessions will be started in separate screens with a set sleep interval between each claim session.

## Script Usage

This script provides a set of commands to manage wallets and mining scripts for Ore (Open Rewards Ecosystem). It accepts a command as an argument and executes the corresponding action.

### Commands

- `--setup`: Initialize and configure wallets and mining scripts.
- `--update-urls`: Update the RPC URLs in the Ore scripts.
- `--sol-balance` or `-s`: Check the SOL balance for each address.
- `--fund-sol` or `-f`: Fund the SOL balance for each miner address to maintain the minimum balance.
- `--rewards`: Check the Ore rewards for each address.
- `--claim`: Automate claiming Ore rewards for configured wallets.
- `--ore-balance` or `-o`: Check the Ore balance for each address.
- `--start-miners` or `-m`: Start multiple screens for Ore mining sessions.
- `--pubkeys`: Fetch the public keys for each address and export to `addr_list.txt`.
- `--help`: Display usage information.

### Example

- `$0 --setup`: Initialize and configure wallets and mining scripts.
- `$0 --sol-balance`: Checks the SOL balance for addresses in `addr_list.txt`.

If an invalid command is provided, the script will display the usage information and exit with an error code.

## Debugging

Account_Not_Found: 
- Transfer a small amount of Ore to the problematic address, or
- Run `spl-token create-account oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz` for the address and try again. 
  Set the correct keypair with `solana config set --keypair <path_to_keypair>` before running the above command.