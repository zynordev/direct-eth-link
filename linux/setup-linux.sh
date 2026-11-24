#!/usr/bin/env bash
set -euo pipefail

# Configure a direct point-to-point Ethernet link on Linux (NetworkManager / nmcli).
# Sets a static IP with NO default gateway so Wi-Fi/internet routing stays intact.

IFACE="${1:-}"
IP_CIDR="${2:-192.168.10.1/24}"
CON_NAME="${CON_NAME:-direct-eth-link}"
ENABLE_WOL="${ENABLE_WOL:-1}"

usage() {
  cat <<EOF
Usage: $0 [INTERFACE] [IP/PREFIX]

Examples:
  $0                    # Auto-detect wired Ethernet interface, use 192.168.10.1/24
  $0 eno1 192.168.10.1/24
  $0 --remove           # Remove the '$CON_NAME' NetworkManager profile

Environment variables:
  CON_NAME=direct-eth-link   NetworkManager connection name
  ENABLE_WOL=1               Enable Wake-on-LAN (magic packet) if supported
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo "Error: nmcli (NetworkManager) is required on Linux." >&2
  exit 1
fi

if [[ "${1:-}" == "--remove" ]]; then
  if nmcli -t -f NAME con show | grep -qx "$CON_NAME"; then
    sudo nmcli con delete "$CON_NAME"
    echo "Removed NetworkManager profile '$CON_NAME'."
  else
    echo "Profile '$CON_NAME' not found."
  fi
  exit 0
fi

if [[ -z "$IFACE" ]]; then
  mapfile -t ETH_DEVS < <(nmcli -t -f DEVICE,TYPE dev status | awk -F: '$2=="ethernet"{print $1}')
  if [[ ${#ETH_DEVS[@]} -eq 0 ]]; then
    echo "Error: No Ethernet interface found." >&2
    exit 1
  elif [[ ${#ETH_DEVS[@]} -eq 1 ]]; then
    IFACE="${ETH_DEVS[0]}"
  else
    echo "Multiple Ethernet interfaces detected:"
    for i in "${!ETH_DEVS[@]}"; do
      echo "  [$i] ${ETH_DEVS[$i]}"
    done
    read -rp "Select interface index [0]: " idx
    idx="${idx:-0}"
    IFACE="${ETH_DEVS[$idx]}"
  fi
fi

echo "Configuring '$IFACE' with static IP $IP_CIDR (no gateway) as '$CON_NAME'..."

if nmcli -t -f NAME con show | grep -qx "$CON_NAME"; then
  sudo nmcli con modify "$CON_NAME" \
    connection.interface-name "$IFACE" \
    ipv4.method manual \
    ipv4.addresses "$IP_CIDR" \
    ipv4.gateway "" \
    ipv4.never-default yes \
    ipv6.method ignore \
    connection.autoconnect yes \
    connection.autoconnect-priority 10
else
  sudo nmcli con add type ethernet ifname "$IFACE" con-name "$CON_NAME" \
    ipv4.method manual \
    ipv4.addresses "$IP_CIDR" \
    ipv4.never-default yes \
    ipv6.method ignore \
    connection.autoconnect yes \
    connection.autoconnect-priority 10
fi

if [[ "$ENABLE_WOL" == "1" ]]; then
  sudo nmcli con modify "$CON_NAME" 802-3-ethernet.wake-on-lan magic 2>/dev/null || true
fi

sudo nmcli con up "$CON_NAME"

echo ""
echo "Done! Current IPv4 on $IFACE:"
ip -4 -brief addr show "$IFACE"
