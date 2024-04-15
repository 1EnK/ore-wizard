# Ore-Wizard

Ore-Wizard is a bash command tool based on multiple screen sessions.

## Features
- Multi-screen mining
- Parallel mining sessions for single miner account
- Periodic SOL balance checking and funding for multiple miner accounts
- Periodic reward claiming for multiple miner accounts in the background
- Check SOL balance, Ore rewards, and Ore balance for multiple miner accounts

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

- Ore CLI or Ore CLI forks
    - Official Ore CLI:
    ```bash
    cargo install ore-cli
    ```

    -  Ore CLI GPU:
    ```bash
    https://github.com/BenjaSOL/ore-cli-gpu
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

- Add the project directory to the PATH.
    ```bash
    export PATH=$PATH:$HOME/ore-wizard
    ```

- Grant execute permissions to the scripts.
    ```bash
    chmod +x $HOME/ore-wizard/ore-wizard
    chmod +x $HOME/ore-wizard/src/*.sh
    ```

    Add path to the `.bashrc` or `.bash_profile` to make it permanent (optional).
    ```bash
    nano $HOME/.bashrc
    ```

    Add the following line at the end of the file and save
    ```bash
    export PATH=$PATH:$HOME/ore-wizard
    ```

    Reload the bashrc file.
    ```bash
    source $HOME/.bashrc
    ```

    or use the following command to append the path to the `.bashrc` file, then reload the file as above.
    ```bash
    echo 'export PATH=$PATH:$HOME/ore-wizard' >> $HOME/.bashrc
    ```

- For GPU mining, after installing the forked Ore CLI, add `<path_to_forked_ore_cli>/target/release` to the PATH.
    ```bash
    nano $HOME/.bashrc
    ```

    Add the following line at the end of the file and save
    ```bash
    export PATH=$PATH:<path_to_forked_ore_cli>/target/release
    ```
    or
    ```bash
    echo 'export PATH=$PATH:<path_to_forked_ore_cli>/target/release' >> $HOME/.bashrc
    ```
    
    Reload the bashrc file.
    ```bash
    source $HOME/.bashrc
    ```

## Setup Account and Mining Configuration

- Run the setup command to create the keypairs and corresponding mining scripts.
    ```bash
    ore-wizard --setup
    ```
    Default keypairs path: `ore-wizard/keypairs`
    Default scripts path: `ore-wizard/scripts`


- `rpc_urls`: enter your RPC URLs here, default is `https://api.mainnet-beta.solana.com`.
- `id_prefix`: the prefix for the miner keypair filenames to classify the miner accounts across different machines.
- `session_count`: parallel mining sessions for each miner account, set to 1 for single mining session.
- `priority_fee`: the priority fee to set for the mining transactions in lamports.
- `addr_list.txt`: the index file for the keypair addresses. Use `ore-wizard --pubkeys` to generate the address list file if it is missing.

## Fund Miner Accounts

- Fund the miner accounts with SOL to maintain the minimum balance. 
    ```bash
    ore-wizard --fund-sol
    ```
    or
    ```bash
    ore-wizard -f
    ```

- `trigger_balance`: the minimum SOL balance to trigger the fund transfer.
- `maintain_balance`: the SOL balance to maintain for each miner account.
- `funding_account_keypair`: the keypair to fund the miner accounts. Ensure the funding account has sufficient SOL balance for distribution.

- Display the SOL balance for each address.
    ```bash
    ore-wizard --sol-balance
    ```
    or
    ```bash
    ore-wizard -s
    ```

## Start Mining Sessions

- Start the mining sessions for the configured miner accounts.
    ```bash
    ore-wizard --start-miners
    ```
    or
    ```bash
    ore-wizard -m
    ```
The limit of mining sessions is determined by the number of mining scripts in `/scripts` directory.
MAKE SURE THE MINER ACCOUNTS ARE FUNDED BEFORE STARTING THE MINING SESSIONS. 

- List all active screen sessions.
    ```bash
    screen -ls
    ```
- Attach to the screen session to monitor the mining process. Default screen name is `ore-<index>`.
    ```bash
    screen -r <session_name>
    
    ```
- Detach from the screen session.
    ```bash
    Ctrl + A + D
    ```

## Claim Ore Rewards

- Initialize the reward claiming sessions for each miner account in `/keypairs` directory.
    ```bash
    ore-wizard --claim
    ```
    or
    ```bash
    ore-wizard -c
    ```

- `priority_fee`: the priority fee to set for the reward claim transactions in lamports.
- `recipient`: the address to receive the claimed Ore rewards. Leave empty to claim the rewards to the miner addresses.
- `trigger_level`: the Ore balance to trigger the reward claim. 
- `hourly_rate`: the estimtad hourly rewards for calculating the reward claim frequency. e.g. 0.1 Ore/hour for a trigger level of 0.5 Ore will claim every 5 hours.
- `keypair_dir`: the directory containing the miner keypairs for reward claiming.
- `auto-claim-script`: script to claim rewards for single address. 

## Script Usage

- Display the help information for commands.
    ```bash
    ore-wizard --help
    ```
    or
    ```bash
    ore-wizard -h
    ```

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

## Configuration

- Modify the configuration file for default paths and settings. Install `yq` to make it functional.
    ```bash
    nano <root directory for ore-wizard>/.config.yaml
    ```
    or 
    ```bash
    cd <root directory for ore-wizard>
    nano .config.yaml
    ```

- Default configuration file:
    ```yaml
    ore-wizard:
    default_paths:
        root: "$HOME/ore-wizard" 
        keypair_dir: "$HOME/ore-wizard/keypairs" 
        script_dir: "$HOME/ore-wizard/scripts" 
        account_index_file: "$HOME/ore-wizard/addr_list.txt" 
        primary_keypair: "$HOME/.config/solana/id.json"

    rpc: 
        default_url: "https://api.mainnet-beta.solana.com" # For regular use. e.g. checking balance, checking rewards, etc.
        backup_urls: ["https://api.mainnet-beta.solana.com"] # Placeholder for rpc switch.
        mining_url: "https://api.mainnet-beta.solana.com"
        funding_url: "https://api.mainnet-beta.solana.com"
        rewards_url: "https://api.mainnet-beta.solana.com"
        collect_url: "https://api.mainnet-beta.solana.com"

    naming_convention:
        keypair_file_prefix: "id_"
        mining_screen_prefix: "ore-"
        claim_screen_prefix: "claim-ore-"
        mining_script_prefix: "auto-ore-"

    mining:
        session_count: 1
        priority_fee: 50000  # Default fee in lamports.
        thread_count: 4
        session_count: 1 # Number of mining screen sessions per keypair.

    funding:
        trigger_balance: 0.003 # SOL
        maintain_balance: 0.01  # SOL
        funding_account_keypair: "$HOME/.config/solana/id.json"
        priority_fee: 1  # Default fee in lamports.
        sleep_duration: 14400  # Seconds

    rewards_claiming:
        trigger_level: 0.01  # Ore
        hourly_rate: 0.001  # Ore/hour
        recipient: ""  # Empty for self-claiming to the miner accounts.
        priority_fee: 50000  # Default fee in lamports.

    collect_sol:
        reserved_gas: 0.001  # SOL
        fee_payer: ""  # Empty for self-paying.
        priority_fee: 1  # Default fee in lamports.
        recipient: ""  # ADD YOUR ADDRESS HERE.

    commands:
        setup: ["--setup"]
        update_urls: ["--update-urls", "-u"]
        check_sol_balance: ["--sol-balance", "-s"]
        fund_sol: ["--fund-sol", "-f"]
        check_rewards: ["--rewards", "-r"]
        claim_rewards: ["--claim", "-c"]
        check_ore_balance: ["--ore-balance", "-o"]
        start_miners: ["--start-miners", "-m"]
        fetch_pubkeys: ["--pubkeys", "-p"]
        collect_sol: ["--collect-sol", "-cs"]
        help: ["--help", "-h"]

    version: "0.6.5"
    ```

## Debugging

Account_Not_Found: 
- Transfer a small amount of Ore to the problematic address, or
- Run `spl-token create-account oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz` for the address and try again. 
  Set the correct keypair with `solana config set --keypair <path_to_keypair>` before running the above command.

addr_list.txt not found:
- Run `ore-wizard --pubkeys` to generate the address list file.
