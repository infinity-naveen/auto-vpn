#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Permission denied, please run this command with sudo"
    exit 1
fi

base_path="/usr/local/lib/vpn-infinity"
source "$base_path/helper.sh"

start_vpn() {
    if [ ! -f "$base_path/config.txt" ]; then
        echo "Error: Configuration is not set yet. Please set the configuration using the --set-config option."
    else
        if ! openvpn_path=$(brew --prefix openvpn); then
            echo "Error: openvpn command not found, please install the dependency (brew install openvpn)"
            return 1
        fi

        if ! oathtool_path=$(brew --prefix oath-toolkit); then
            echo "Error: oathtool command not found, please install this dependency (brew install oath-toolkit)"
            return 1
        fi

        echo "$openvpn_path/sbin/openvpn" > "$base_path/deps.txt"
        echo "$oathtool_path/bin/oathtool" >> "$base_path/deps.txt"

        sudo launchctl load /Library/LaunchDaemons/com.infinity.vpn.plist
        echo "Started VPN Background process."
        echo "Use --status option to check the status."
    fi
}

stop_vpn() {
    echo "Stopping VPN Background process..."
    sudo launchctl unload /Library/LaunchDaemons/com.infinity.vpn.plist
    echo "Stopping existing VPN connection (if any)"
    kill_existing_openvpn_processes
}

check_status() {
    if check_vpn_connection; then
        echo "Current VPN status: Connected"
    else
        echo "Current VPN status: Not connected"
    fi

    echo -n "Background process status: "
    if sudo launchctl list | grep -q com.infinity.vpn; then
        echo "Running"
    else
        echo "Not running"
    fi
}

get_config() {
    file_name="$base_path/config.txt"
    if [ -f "$file_name" ]; then
        echo "VPN Profile Path: $(sed '1q;d' "$file_name")"
        echo "Username: $(sed '2q;d' "$file_name")"
        echo "Password: $(sed '3q;d' "$file_name")"
        echo "Secret Key: $(sed '4q;d' "$file_name")"
    else
        echo "Error: Configuration not set yet."
    fi
}

set_config() {
    if [ $# -ne 4 ]; then
        echo "Error: Missing parameters. Usage: auto-vpn --set-config profile_path username password secret_key"
    else
        echo "Setting VPN configuration..."
        if [ ! -f "$1" ]; then
            echo "Error: VPN profile file does not exist."
            return 1
        fi

        profile_path=$(realpath "$1")
        file_name="$base_path/config.txt"

        echo "$profile_path" > "$file_name"
        echo "$2" >> "$file_name"
        echo "$3" >> "$file_name"
        echo "$4" >> "$file_name"

        cp "$profile_path" "$base_path/vpn_profile.ovpn"

        cred_file_name="$base_path/vpn_creds.txt"
        echo "$2" > "$cred_file_name"
        echo "$3" >> "$cred_file_name"

        echo "Configuration set successfully."
    fi
}

show_logs() {
    cat /var/log/vpn-infinity/logs.log
}

show_help() {
    echo "Usage: auto-vpn [OPTIONS]"
    echo "Options:"
    echo "  --start              Start the background process for automatic VPN connection."
    echo "                       Once started, it will keep running in the background indefinitely,"
    echo "                       even through internet disconnections, user logouts, or system restarts."
    echo "                       It can only be stopped manually using the --stop option."
    echo "  --stop               Stop the background process & drop VPN connection if any is established"
    echo "  --status             Show whether VPN is connected or not currently"
    echo "  --set-config         Set VPN configuration (requires 4 additional arguments: profile_ovpn_file_path username pin 2fa_secret_key)"
    echo "  --get-config         Show current VPN configuration"
    echo "  --logs               Show logs of background process for debugging purpose"
    echo "  --help               Show this help message"
}

main_command_executor() {
    case "$1" in
        --start)
            start_vpn
            ;;
        --stop)
            stop_vpn
            ;;
        --status)
            check_status
            ;;
        --set-config)
            set_config "${@:2}"
            ;;
        --get-config)
            get_config
            ;;
        --logs)
            show_logs
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Invalid option: $1"
            show_help
            ;;
    esac
}

main_command_executor "$@"
