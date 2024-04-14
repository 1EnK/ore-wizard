# Ore-Wizard

Ore-Wizard is a shell command tool designed to facilitate the management of solana keypairs and mining scripts for the Ore CLI (https://ore.supply/). It streamlines operations to utilize the Ore CLI or any other modified versions using the same commands, without major conflicts to potential future updates or forks as long as the same commands are used. 

## Features

```
- Initialize and configure keypairs and mining scripts for multiple mining screen sessions.
- Update the RPC URLs in the Ore scripts.
- Check the SOL balance for each address.
- Fund the SOL balance for each miner address to maintain the minimum balance.
- Check the Ore rewards for each address.
- Automate claiming Ore rewards for configured wallets.
- Check the Ore balance for each address.
- Start multiple screens for Ore mining sessions.
- Fetch the public keys for each address and export to `addr_list.txt`.
- Collect the SOL balance for each address.
```

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

- Screen
    ```bash
    sudo apt-get install screen
    ```

- YQ
    ```bash
    sudo snap install yq
    ```
    For more installation options, refer to https://github.com/mikefarah/yq/#install

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

- `rpc_urls`: Enter your RPC URLs here, default is `https://api.mainnet-beta.solana.com`.
- `id_prefix`: the prefix for the miner keypair filenames to classify the miner accounts across different machines.
- `session_count`: the number of mining screen scripts for each miner account to create. The script will create multiple mining scripts for each miner account to run multiple mining sessions in separate screens.
- `priority_fee`: the priority fee to set for the mining transactions in lamports. The mining scripts will apply the given priority fee.

An account index file `addr_list.txt` will be generated in the project root after the setup. If the index file is missing, run `ore-wizard --pubkeys` to generate an address list file as the index for the keypair addresses. The address list file will be used as an index to fund the miner addresses and check the balance and ore rewards.

## Funding Miner Accounts

Run `ore-wizard --fund-sol` or `-f` to fund the miner accounts with SOL to maintain the minimum balance. 

- `trigger_balance`: the minimum SOL balance to trigger the fund transfer.
- `maintain_balance`: the SOL balance to maintain in the miner accounts. The script will transfer the difference between the maintain balance and the current balance to the miner accounts.
- `funding_account_keypair`: the keypair to fund the miner accounts. The script will use the given keypair to fund the miner accounts. The keypair should have enough SOL balance to fund the miner accounts.

## Mining Configuration

Run `ore-wizard --start_miners` or `-m` to start multiple mining sessions in separate screens. The script will prompt the user to enter the number of mining sessions to start. The script will then start the mining sessions in separate screens. Default scripts path is `/scripts` and the default screen name is `ore-<index>`.
MAKE SURE TO FUND THE ADDRESSES BEFORE STARTING THE MINING SESSIONS.

Use `screen -ls` to list the active screen sessions and `screen -r ore-<index>` to attach to the screen session and monitor the mining process.
To detach from the screen session, press `Ctrl + A` followed by `D`.

## Reward Claiming

Run `ore-wizard --claim` to automate the reward claiming process for the configured wallets in separated screens. The script will claim the Ore rewards for the configured wallets when the Ore balance exceeds the trigger level. The script will sleep for the calculated time after each reward claim session. Default screen name is `claim-ore-<index>`.

- `priority_fee`: the priority fee to set for the reward claim transactions in lamports.
- `recipient`: the address to receive the claimed Ore rewards. Leave empty to claim the rewards to the miner addresses.
- `trigger_level`: the Ore balance to trigger the reward claim. The script will claim the rewards if the Ore balance is greater than the trigger level.
- `hourly_rate`: the estimtad hourly rewards for calculating the reward claim frequency. it determines the time to reach the trigger level, and the script will sleep for the calculated time after each reward claim session. e.g., 0.1 Ore/hour. and trigger level is 1 Ore, the script will claim the rewards every 10 hours. 
- `keypair_dir`: the directory to store the keypair for the recipient address. 
- `auto-claim-script`: script to claim rewards for single address. Multiple screen sessions of this script will be created for each address in the keypair directory.

## Script Usage

This script provides a set of commands to manage wallets and mining scripts for Ore (Open Rewards Ecosystem). It accepts a command as an argument and executes the corresponding action.

### Commands

- `--setup`: Initialize and configure wallets and mining scripts.
- `--update-urls` or `-u`: Update the RPC URLs in the Ore scripts.
- `--sol-balance` or `-s`: Check the SOL balance for each address.
- `--fund-sol` or `-f`: Fund the SOL balance for each miner address to maintain the minimum balance.
- `--rewards` or `-r`: Check the Ore rewards for each address.
- `--claim` or `-c`: Automate claiming Ore rewards for configured wallets.
- `--ore-balance` or `-o`: Check the Ore balance for each address.
- `--start-miners` or `-m`: Start multiple screens for Ore mining sessions.
- `--pubkeys`: Fetch the public keys for each address and export to `addr_list.txt`.
- `--collect-sol` or `-cs`: Collect the SOL balance for each address.
- `--help` or `-h`: Display usage information.

### Example

- `ore-wizard --setup`: Initialize and configure wallets and mining scripts.
- `ore-wizard -s`: Checks the SOL balance for addresses in `addr_list.txt`.

If an invalid command is provided, the script will display the usage information and exit with an error code.

## Debugging

Account_Not_Found: 
- Transfer a small amount of Ore to the problematic address, or
- Run `spl-token create-account oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz` for the address and try again. 
  Set the correct keypair with `solana config set --keypair <path_to_keypair>` before running the above command.

addr_list.txt not found:
- Run `ore-wizard --pubkeys` to generate the address list file.