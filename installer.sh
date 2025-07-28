#!/bin/bash

# Absolute path to gitIt.sh (assumed to be in the same directory as installer.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITIT_PATH="$SCRIPT_DIR/gitIt.sh"

# Check if gitIt.sh exists
if [ ! -f "$GITIT_PATH" ]; then
    echo "gitIt.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Make gitIt.sh executable
chmod +x "$GITIT_PATH"

# Choose install location (default: ~/.local/bin)
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Copy gitIt.sh to install location
cp "$GITIT_PATH" "$INSTALL_DIR/gitIt"
# Create a link because trust issues
ln -s "$INSTALL_DIR/gitIt" "$INSTALL_DIR/gitIt.sh"


# Add install location to PATH if not already present
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    SHELL_RC=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    if [ -n "$SHELL_RC" ]; then
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
        echo "Added $INSTALL_DIR to PATH in $SHELL_RC. Please restart your terminal."
    else
        echo "Please add $INSTALL_DIR to your PATH manually."
    fi
fi

echo "gitIt installed! You can now run 'gitIt' from anywhere."