#!/bin/bash

base_path="/usr/local/lib/vpn-infinity"
source "$base_path/helper.sh"

VPN_PROFILE_PATH=""
SECRET_KEY=""
openvpn_path="invalid-path"
oathtool_path="invalid-auth-path"

reload_config() {
    file_name="$base_path/config.txt"
    if [ -f "$file_name" ]; then
        VPN_PROFILE_PATH=$(sed '1q;d' "$file_name")
        VPN_PROFILE_PATH="$base_path/vpn_profile.ovpn"
        SECRET_KEY=$(sed '4q;d' "$file_name")
    else
        log "Error: Configuration file not found."
    fi

    deps_file_name="$base_path/deps.txt"
    if [ -f "$deps_file_name" ]; then
        openvpn_path=$(sed '1q;d' "$deps_file_name")
        oathtool_path=$(sed '2q;d' "$deps_file_name")
    else
        log "Error: openvpn or oathtool not installed yet"
    fi
}

generate_otp() {
    otp=$("$oathtool_path" --totp -b "$SECRET_KEY")
    echo "$otp"
}

connect_to_vpn() {
    reload_config
    expect -c "
    send_user \"\nConnecting to VPN...\n\"
    spawn $openvpn_path --config \"$VPN_PROFILE_PATH\" --auth-user-pass \"$base_path/vpn_creds.txt\" --auth-nocache --auth-retry interact
    expect \"CHALLENGE: Enter OTP Code\"
    send \"$(generate_otp)\r\n\"
    "
}

check_vpn_connection() {
    if netstat -nr | grep "3.6.0.175"; then
        return 0
    else
        return 1
    fi
}

main_script() {
    log "VPN background script started"
    while true; do
        if check_vpn_connection; then
            log "VPN is already connected, sleeping for 10 seconds..."
            sleep 10
        else
            log "VPN is not connected, will try to connect..."
            kill_existing_openvpn_processes
            connect_to_vpn &
            sleep 30
        fi
    done
    log "VPN background script finished"
}

main_script
