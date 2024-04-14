#!/bin/bash

# Include the utilities script from the same directory
source "$(dirname "$0")/utils.sh"

# Default configuration file path
config_file="$(dirname "$0")/../.config.yaml"

# Default directory for the scripts:
default_script_dir="$(dirname "$0")/../scripts"
miner_count=0
script_prefix="auto-ore-"
screen_prefix="ore-"

# Load configurations from the config file to update the default values
if [[ -f "$config_file" ]]; then
    default_script_dir=$(ore_wizard_get_config '.ore-wizard.default_paths.script_dir' "$default_script_dir")
    script_prefix=$(ore_wizard_get_config '.ore-wizard.naming_convention.mining_script_prefix' "$script_prefix")
    screen_prefix=$(ore_wizard_get_config '.ore-wizard.naming_convention.mining_screen_prefix' "$screen_prefix")
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --scripts) default_script_dir="$2"; shift ;;
        --miners) miner_count="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "Current script directory: $default_script_dir"

# Prompt if miner count is not provided or zero
if [[ -z "$miner_count" || "$miner_count" -eq 0 ]]; then
    echo "Enter the number of auto-ore scripts to run:"
    read miner_count
fi

# Validate the input
if ! [[ "$miner_count" =~ ^[0-9]+$ ]]; then
    echo "Error: Input is not a valid number."
    exit 1
fi

end_num=$((miner_count - 1))

# Navigate to the script directory
if ! cd "$default_script_dir"; then
    echo "Script directory not found: $default_script_dir"
    exit 1
fi

start_count=0
# Start each auto-ore script in a new screen session
for i in $(seq 0 $end_num); do
    script_name="$script_prefix$i.sh"
    screen_name="$screen_prefix$i"
    current_time=$(date "+%Y-%m-%d %H:%M:%S")

    if [ -f "$script_name" ]; then
        echo "Starting $script_name in screen session $screen_name..."
        if screen -dmS "$screen_name" ./"$script_name"; then
            echo "$script_name started successfully at $current_time."
            start_count=$((start_count + 1))
        else
            echo "Failed to start $script_name at $current_time."
        fi
    else
        echo "Script $script_name does not exist, skipping..."
    fi
done

echo "Attempted to start $miner_count auto-ore worker(s); $start_count successfully started in separate screen sessions."
