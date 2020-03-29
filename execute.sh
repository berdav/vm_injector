#!/bin/bash

set -eu

# Path to the key to add in the machine
KEY="${2:-id_rsa}"
# Privileged user
USER=root
# Unprivileged user
UNPRIVUSER=vagrant
# IP Address
IP="$1"
# Target image
IMG="target.img"

# Check if the host is already openbsd
OS="$(ssh -n -o PasswordAuthentication=no -i "$KEY" "$UNPRIVUSER@$IP" 'uname -s' || true)"

if [ "x$OS" == "xOpenBSD" ]; then
	echo "Seems that the system is already installed."
	exit 0
fi

echo "Seems that this is the first run, nuking the system."
# This machine will get destroyed
scp -i "$KEY" inject.sh "$USER@$IP:/root/inject.sh"
scp -i "$KEY" "$IMG" "$USER@$IP:/root/$IMG"

ssh -i "$KEY" "$USER@$IP" /root/inject.sh

echo "In 5 minute connect to the machine"
