#!/usr/bin/env bash
set -euo pipefail

# Add an SSH host alias (~/.ssh/config) and copy your public key for passwordless login.
# Usage: ./scripts/setup-ssh.sh <ALIAS> <PEER_IP> [USERNAME]

ALIAS="${1:-}"
PEER_IP="${2:-}"
USER_NAME="${3:-$USER}"

if [[ -z "$ALIAS" || -z "$PEER_IP" ]]; then
  echo "Usage: $0 <ALIAS> <PEER_IP> [USERNAME]"
  echo "Example: $0 pi 192.168.10.2 halil"
  exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

if ! grep -qE "^Host\s+${ALIAS}(\s|$)" "$HOME/.ssh/config"; then
  cat >> "$HOME/.ssh/config" <<EOF

Host $ALIAS
    HostName $PEER_IP
    User $USER_NAME
    ConnectTimeout 3
EOF
  echo "Added 'Host $ALIAS ($PEER_IP)' to ~/.ssh/config."
else
  echo "Host '$ALIAS' already exists in ~/.ssh/config; skipping config append."
fi

if [[ ! -f "$HOME/.ssh/id_ed25519.pub" && ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
  echo "No SSH public key found. Generating id_ed25519..."
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
fi

echo "Copying SSH key to $USER_NAME@$PEER_IP (you may be asked for password once)..."
ssh-copy-id "$USER_NAME@$PEER_IP"

echo "Testing passwordless SSH: ssh $ALIAS hostname"
ssh "$ALIAS" hostname
