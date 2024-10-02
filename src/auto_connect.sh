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
    (curl -s --max-time 3 --head https://teleport.ludojoy.com | grep -E "HTTP/.* (200|301|302)" > /dev/null) &
    pid1=$!

    (curl -s --max-time 3 --head https://grafana.ludosupreme.com | grep -E "HTTP/.* (200|301|302)" > /dev/null) &
    pid2=$!

    wait $pid1
    result1=$?

    wait $pid2
    result2=$?

    if [ $result1 -eq 0 ] || [ $result2 -eq 0 ]; then
        return 0  # VPN is connected
    else
        return 1  # VPN is not connected
    fi
}

check_and_connect_vpn2() {
  local file_path="$base_path/vpn_profile_2.ovpn"

      if [ -e "$file_path" ]; then
          log "VPN2 config also found, will connect this also"
          reload_config
          $openvpn_path --config "$base_path/vpn_profile_2.ovpn" --auth-user-pass "$base_path/vpn_creds_2.txt" --auth-nocache &
      else
          log "Debug log: No VPN2 config"
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
            check_and_connect_vpn2
            sleep 30
        fi
    done
    log "VPN background script finished"
}

main_script
