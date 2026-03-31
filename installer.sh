#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITIT_PATH="$SCRIPT_DIR/gitIt.sh"

if [ ! -f "$GITIT_PATH" ]; then
    echo "gitIt.sh not found in $SCRIPT_DIR"
    exit 1
fi

chmod +x "$GITIT_PATH"

INSTALL_DIR="$HOME/.local/share/gitIt"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

cp -fv "$SCRIPT_DIR/gitIt.sh" "$INSTALL_DIR/gitIt.sh"
rsync -av "$SCRIPT_DIR/functions/" "$INSTALL_DIR/functions/"

ln -sf "$INSTALL_DIR/gitIt.sh" "$BIN_DIR/gitIt"

if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    SHELL_RC=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    if [ -n "$SHELL_RC" ]; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_RC"
        echo "Added $BIN_DIR to PATH in $SHELL_RC. Please restart your terminal."
    else
        echo "Please add $BIN_DIR to your PATH manually."
    fi
fi

echo "gitIt installed! You can now run 'gitIt' from anywhere."
