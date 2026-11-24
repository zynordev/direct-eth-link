#!/usr/bin/env bash
set -euo pipefail

# Configure the Raspberry Pi side of a direct Ethernet link.
# Supports Raspberry Pi OS Bookworm/Trixie (NetworkManager) and legacy dhcpcd.

IFACE="${1:-eth0}"
IP_CIDR="${2:-192.168.10.2/24}"
CON_NAME="${CON_NAME:-direct-eth-link}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [INTERFACE] [IP/PREFIX]"
  echo "Default: $0 eth0 192.168.10.2/24"
  exit 0
fi

if command -v nmcli >/dev/null 2>&1; then
  echo "Detected NetworkManager (nmcli). Configuring $IFACE -> $IP_CIDR..."
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
  sudo nmcli con modify "$CON_NAME" 802-3-ethernet.wake-on-lan magic 2>/dev/null || true
  sudo nmcli con up "$CON_NAME"
elif [[ -f /etc/dhcpcd.conf ]]; then
  echo "Detected dhcpcd.conf. Appending static IP configuration for $IFACE..."
  if grep -q "# direct-eth-link" /etc/dhcpcd.conf; then
    echo "Entry already exists in /etc/dhcpcd.conf. Please check it manually."
  else
    sudo tee -a /etc/dhcpcd.conf >/dev/null <<EOF

# direct-eth-link
interface $IFACE
static ip_address=$IP_CIDR
nogateway
EOF
    sudo systemctl restart dhcpcd
  fi
else
  echo "Error: Neither NetworkManager (nmcli) nor /etc/dhcpcd.conf found." >&2
  exit 1
fi

echo ""
echo "Done! Current IPv4 on $IFACE:"
ip -4 -brief addr show "$IFACE"
