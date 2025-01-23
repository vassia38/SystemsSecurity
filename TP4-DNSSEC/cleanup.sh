#!/bin/bash


NETWORK_NAME="mynet"
CONTAINERS=("client" "DNSmaster" "DNSslave")

for container in "${CONTAINERS[@]}"; do
  lxc delete --force "$container"
done


lxc network delete "$NETWORK_NAME"
