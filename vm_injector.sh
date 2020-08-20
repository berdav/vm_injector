#!/bin/bash

set -eu

# Path to the key to add in the machine
KEY="id_rsa"
# Privileged user
USER=root
# Unprivileged user
UNPRIVUSER=vagrant
# IP Address
IP=""
# Target port
PORT="22"
# Target image
IMG="target.img"
# Target operating system
TARGET_OS="OpenBSD"
# Base directory of the script
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Number of seconds to wait for the host
SECONDS_TO_WAIT=0

usage() {
	echo "Usage: $1 <-i IP> [optargs]"                               >&2
	echo -e "Optional arguments (optargs):"                          >&2
	echo -e "\t-h print this help and exit"                          >&2
	echo -e "\t-i IP      Set the target IP address to IP"           >&2
	echo -e "\t-I IMAGE   Set the target injected image to IMAGE"    >&2
	echo -e "\t-k KEY     Set the target SSH key to KEY"             >&2
	echo -e "\t-p PORT    Set the target SSH port to PORT"           >&2
	echo -e "\t-s SECONDS Number of seconds to wait for the host"    >&2
	echo -e "\t-t TARGET  Set the target operating system to TARGET" >&2
	echo -e "\t-u USER    Set the target unprivileged user to USER"  >&2
	echo -e "\t-U USER    Set the target privileged user to USER"    >&2
}

while getopts "hi:I:k:p:s:t:u:U:" options; do
	case "$options" in
		i)
			IP="$OPTARG"
			;;
		h)
			usage "$0"
			exit 1;
			;;
		t)
			TARGET_OS="$OPTARG"
			;;
		s)
			SECONDS_TO_WAIT="$OPTARG"
			;;
		p)
			PORT="$OPTARG"
			;;
		k)
			KEY="$OPTARG"
			;;
		u)
			UNPRIVUSER="$OPTARG"
			;;
		U)
			USER="$OPTARG"
			;;
		I)
			IMG="$OPTARG"
			;;
		*)
			echo "Warning: Option not recognized."
			;;
	esac
done

if [ "x$IP" == "x" ]; then
	usage "$0"
	exit 1
fi

echo "[ ] Checking if host is ready"
HOST_READY=false
for WAITED_SECONDS in {0..$(( $SECONDS_TO_WAIT + 1 ))}; do
	if ssh -p "$PORT" -q -n \
		-o PasswordAuthentication=no \
		-o StrictHostKeyChecking=no \
		-i "$KEY" "$USER@$IP" 'true' ; then
		echo -e "\n[+] Success!  Host is ready."
		HOST_READY=true
		break
	else
		echo -n "."
		sleep 1
	fi
done
if ! $HOST_READY; then
	echo -e "\n[-] Seems that the connection has problems, exiting"
	exit 1
fi

# Check if the host is already the target one
OS="$(ssh -p "$PORT" -n -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$KEY" "$UNPRIVUSER@$IP" 'uname -s' || true)"
if [ "x$OS" == "x$TARGET_OS" ]; then
	echo "Seems that the system is already installed."
	exit 0
fi

echo "Seems that this is the first run, nuking the system."
# This machine will get destroyed
scp -P "$PORT" -i "$KEY" "$BASEDIR/injectors/inject.sh" "$USER@$IP:/root/inject.sh"
EXT=$(echo "$IMG" | awk -F . '{print $NF}')

case $EXT in
	ova)
		scp -P "$PORT" -i "$KEY" "$IMG" "$USER@$IP:/root/target.ova"
		;;
	vmdk)
		scp -P "$PORT" -i "$KEY" "$IMG" "$USER@$IP:/root/target.vmdk"
		;;
	*)
		scp -P "$PORT" -i "$KEY" "$IMG" "$USER@$IP:/root/target.img"
		;;
esac

ssh -p "$PORT" -o PasswordAuthentication=no -o StrictHostKeyChecking=no -i "$KEY" "$USER@$IP" /root/inject.sh

ssh-keygen -R "$IP"

echo "In 5 minute connect to the machine"
