#!/usr/bin/env bash
set -euo pipefail

# Configure a direct point-to-point Ethernet link on macOS (no router/gateway).
# Usage: ./setup-macos.sh [SERVICE_NAME] [IP] [SUBNET_MASK]
# Example: ./setup-macos.sh "USB 10/100/1000 LAN" 192.168.10.1 255.255.255.0

SERVICE="${1:-}"
IP="${2:-192.168.10.1}"
MASK="${3:-255.255.255.0}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [NETWORK_SERVICE_NAME] [IP] [SUBNET_MASK]"
  echo "List services with: networksetup -listallnetworkservices"
  exit 0
fi

if [[ -z "$SERVICE" ]]; then
  echo "Available network services:"
  networksetup -listallnetworkservices | tail -n +2 | nl -v 0
  read -rp "Enter exact service name (e.g. Ethernet or USB 10/100/1000 LAN): " SERVICE
fi

if [[ "${2:-}" == "--remove" ]]; then
  sudo networksetup -setdhcp "$SERVICE"
  echo "Reverted '$SERVICE' to DHCP."
  exit 0
fi

echo "Setting manual IPv4 on '$SERVICE' -> $IP ($MASK), no router..."
sudo networksetup -setmanual "$SERVICE" "$IP" "$MASK" ""
echo "Done! Current settings:"
networksetup -getinfo "$SERVICE"
