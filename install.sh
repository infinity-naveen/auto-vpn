#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Permission denied, please run this command with sudo"
    exit 1
fi

show_completion_message() {
    echo "Installation Completed Successfully!"
    echo ""
    echo "To get started, please follow the steps below for one-time setup and usage:"
    echo ""
    echo "1. Configuration:"
    echo "   sudo auto-vpn --set-config profile_ovpn_file_path username pin 2fa_secret_key"
    echo ""
    echo "2. Start VPN:"
    echo "   sudo auto-vpn --start"
    echo ""
    echo "3. Check VPN Status:"
    echo "   sudo auto-vpn --status"
    echo ""
    echo "For more detailed documentation and additional commands, use:"
    echo "   sudo auto-vpn --help"
    echo ""
}

uninstall() {
    if [ -d "/usr/local/lib/vpn-infinity" ]; then
        echo "Uninstalling any existing installation of utility"
        sudo rm -rf /usr/local/lib/vpn-infinity
        sudo rm -f /usr/local/bin/auto-vpn
        sudo launchctl unload /Library/LaunchDaemons/com.infinity.vpn.plist
        sudo rm -f /Library/LaunchDaemons/com.infinity.vpn.plist
        echo "Existing installation of utility has been removed"
    else
        echo "No existing installation found, continuing new installation."
    fi
}

install() {
    echo "Downloading utility..."
    DEST_DIR="/usr/local/lib/vpn-infinity"
    BIN_LINK="/usr/local/bin/auto-vpn"

    curl -sLJO "https://github.com/infinity-naveen/auto-vpn/archive/refs/heads/main.zip" && unzip -o auto-vpn-main.zip && rm auto-vpn-main.zip

    echo "Installation directory: $DEST_DIR"
    echo "Installing utility..."
    if [ ! -d "/usr/local/lib" ]; then
        sudo mkdir -p "/usr/local/lib"
    fi
    sudo mv auto-vpn-main/src "$DEST_DIR"
    sudo rm -rf auto-vpn-main
    sudo chmod +x "$DEST_DIR/main_command.sh"

    echo "Creating utility command auto-vpn ..."
    sudo ln -sf "$DEST_DIR/main_command.sh" "$BIN_LINK"

    echo "Creating background service..."
    sudo cp "$DEST_DIR/com.infinity.vpn.plist" "/Library/LaunchDaemons/"

    show_completion_message
}

main_installer() {
    if [ "$1" = "--uninstall" ]; then
        uninstall
        exit 0
    fi

    if [ "$1" = "--install" ]; then
        install
        exit 0
    fi

    uninstall
    install
}

main_installer "$@"
