# Function to check if a command exists
command_exists() {
    command -v "$@" >/dev/null 2>&1
}

# Function to install Rust
install_rust() {
    if command_exists rustc; then
        echo "Rust is already installed."
    else
        echo "Installing Rust..."
        curl https://sh.rustup.rs -sSf | sh
        source "$HOME/.cargo/env"
    fi
}

# Function to install Solana CLI
install_solana() {
    if command_exists solana; then
        echo "Solana CLI is already installed."
    else
        echo "Installing Solana CLI..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    fi
}

# Function to install Ore CLI
install_ore_cli() {
    if command_exists ore-cli; then
        echo "Ore CLI is already installed."
    else
        echo "Installing Ore CLI..."
        cargo install ore-cli
    fi
}

# Function to install Screen
install_screen() {
    if command_exists screen; then
        echo "Screen is already installed."
    else
        echo "Installing Screen..."
        sudo apt-get install screen
    fi
}

# Function to install YQ
install_yq() {
    if command_exists yq; then
        echo "YQ is already installed."
    else
        echo "Installing YQ..."
        sudo snap install yq || echo "Failed to install YQ, continuing..."
    fi
}

# Main installation routine
install_rust
install_solana
install_ore_cli
install_screen
install_yq

# Instructions for the user to finalize the setup
echo "Please run the following commands to finalize the setup:"
echo "1. Navigate to the project directory:"
echo "   cd ore-wizard"
echo "2. Add the project directory to your PATH and grant execute permissions:"
echo "   chmod +x ore-wizard/src/*.sh"
echo "3. To make the PATH change permanent, add the following line to your .bashrc or .bash_profile:"
echo "   echo 'export PATH=\$PATH:\$HOME/ore-wizard' >> \$HOME/.bashrc"
echo "   source \$HOME/.bashrc"
echo "Follow these steps to complete the installation and setup of your environment."