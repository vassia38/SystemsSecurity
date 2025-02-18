#!/bin/bash

containers=("R1" "R2" "nomad")
for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  lxc exec $cont -- apt update -y
  lxc exec $cont -- apt install strongswan strongswan-pki -y
done
