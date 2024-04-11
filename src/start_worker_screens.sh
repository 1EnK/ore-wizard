#!/bin/bash

# Default directory for the scripts:
default_script_dir="$(dirname "$0")/../scripts"

echo "Enter the number of auto-ore scripts to run:"
read user_input

if ! [[ "$user_input" =~ ^[0-9]+$ ]]; then
    echo "Error: Input is not a valid number."
    exit 1
fi

end_num=$((user_input - 1))

# Navigate to the script directory
if ! cd "$default_script_dir"; then
    echo "Script directory not found: $default_script_dir"
    exit 1
fi

start_count=0
# Start each auto-ore script in a new screen session
for i in $(seq 0 $end_num); do
    script_name="auto-ore-$i.sh"
    screen_name="ore-$i"

    if [ -f "$script_name" ]; then
        echo "Starting $script_name in screen session $screen_name..."
        if screen -dmS "$screen_name" ./"$script_name"; then
            echo "$script_name started successfully."
            start_count=$((start_count + 1))
        else
            echo "Failed to start $script_name."
        fi
    else
        echo "Script $script_name does not exist, skipping..."
    fi
done

echo "Attempted to start $user_input auto-ore worker(s); $start_count successfully started in separate screen sessions."
