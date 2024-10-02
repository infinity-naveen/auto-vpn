#!/bin/bash

log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message"
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

kill_existing_openvpn_processes() {
    local pids=$(ps aux | grep openvpn | grep auth-user-pass | awk '{print $2}')

    if [ -z "$pids" ]; then
        log "No existing OpenVPN processes found."
    else
        log "Found the following OpenVPN processes:"
        log "$pids"

        for pid in $pids; do
            log "Killing process $pid..."
            sudo kill -9 $pid
            log "Process $pid killed."
        done
        sleep 1
    fi
}
