#!/bin/bash

log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message"
}

check_vpn_connection() {
    if netstat -nr | grep "3.6.0.175"; then
        return 0
    else
        return 1
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
