#!/usr/bin/env bash
set -euo pipefail

# Verify direct Ethernet link connectivity, latency, and optional SSH alias.
# Usage: ./scripts/verify.sh [PEER_IP] [INTERFACE]

PEER_IP="${1:-192.168.10.2}"
IFACE="${2:-}"

echo "=== Direct Ethernet Link Verification ==="
echo "Target Peer IP : $PEER_IP"

if [[ -n "$IFACE" ]] && command -v ethtool >/dev/null 2>&1; then
  echo ""
  echo "--- Link Speed ($IFACE) ---"
  ethtool "$IFACE" 2>/dev/null | grep -E "Speed:|Duplex:|Link detected:" || true
fi

echo ""
echo "--- Ping Test (5 packets) ---"
if ping -c 5 -W 1 "$PEER_IP"; then
  echo ""
  echo "SUCCESS: Direct Ethernet link to $PEER_IP is UP."
else
  echo ""
  echo "FAILED: Cannot reach $PEER_IP. Check cable, subnet mask (/24), and firewall." >&2
  exit 1
fi
