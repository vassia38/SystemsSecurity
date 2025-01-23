#!/bin/bash

# Exit on errors
set -e

# Configuration
NETWORK_NAME="mynet"
SUBNET="192.168.1.1/24"
CONTAINERS=("client" "DNSmaster" "DNSslave")
IP_ADDRESSES=("192.168.1.10" "192.168.1.11" "192.168.1.12")
IMAGE="images:alpine/3.20"

USE_NAT="true"

echo "Creating LXD network: $NETWORK_NAME"
lxc network create "$NETWORK_NAME" \
  ipv4.address="$SUBNET" \
  ipv4.nat="$USE_NAT" \
  ipv6.address=none

# Step 2: Launch containers and attach to the network
for i in "${!CONTAINERS[@]}"; do
  CONTAINER="${CONTAINERS[i]}"
  IP="${IP_ADDRESSES[i]}"

  echo "Launching container: $CONTAINER"
  lxc launch "$IMAGE" "$CONTAINER"

  echo "Attaching $CONTAINER to network $NETWORK_NAME with IP $IP"
  lxc network attach "$NETWORK_NAME" "$CONTAINER" eth0
  lxc config device set "$CONTAINER" eth0 ipv4.address "$IP"
  # normally we should just do the following
  # lxc exec "$CONTAINER" -- rc-service networking restart
  # but sometimes it fails, rc-service networking status shows that it's basically
  # stuck on 'starting'
  # so we restart the whole container
  lxc restart -f "$CONTAINER"
done

for CONTAINER in "${CONTAINERS[@]:1}"; do
  echo "Installing networking tools in $CONTAINER"
  lxc exec "$CONTAINER" -- apk update
  lxc exec "$CONTAINER" -- apk add --no-cache bind bind-tools bash bash-completion vim
done

echo "Setup complete. Containers are configured:"
for i in "${!CONTAINERS[@]}"; do
  echo "- ${CONTAINERS[i]}: ${IP_ADDRESSES[i]}"
done

