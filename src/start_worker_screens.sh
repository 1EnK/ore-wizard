#!/bin/bash

# Default directory for the scripts:
default_script_dir="$(dirname "$0")/../scripts"

# Prompt the user for the number of `auto-ore` scripts to run
echo "Enter the number of auto-ore scripts to run:"
read user_input

# Check if user_input is a number
if ! [[ "$user_input" =~ ^[0-9]+$ ]]; then
    echo "Error: Input is not a valid number."
    exit 1
fi

# Calculate the end number (user_input - 1)
end_num=$((user_input - 1))

# Navigate to the directory containing the scripts, or exit if it doesn't exist
cd "$default_script_dir" || { echo "Script directory not found: $default_script_dir"; exit 1; }

# Iterate and start each auto-ore script in a new screen session
for i in $(seq 0 $end_num); do
    script_name="auto-ore-$i.sh"
    screen_name="ore-$i"

    if [ -f "$script_name" ]; then
        echo "Starting $script_name in screen session $screen_name"
        screen -dmS "$screen_name" ./"$script_name"
    else
        echo "Script $script_name does not exist, skipping..."
    fi
done

echo "Started $user_input auto-ore worker(s) in separate screen sessions."