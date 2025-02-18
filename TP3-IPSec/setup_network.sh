#!/bin/bash

# create bridges to link R1 to R2 and each one to their respective
# subnet
lxc network create br12 ipv4.address=none ipv6.address=none
lxc network create br1 ipv4.address=none ipv6.address=none
lxc network create br2 ipv4.address=none ipv6.address=none

# create bridge to link the nomad pc to R1
lxc network create brnomad ipv4.address=none ipv6.address=none

# plug devices to R1
lxc config device add R1 eth0 nic nictype=bridged parent=br1
lxc config device add R1 eth1 nic nictype=bridged parent=br12
lxc config device add R1 eth2 nic nictype=bridged parent=brnomad

# plug devices to R2
lxc config device add R2 eth0 nic nictype=bridged parent=br2
lxc config device add R2 eth1 nic nictype=bridged parent=br12

containers=("R1" "R2")
for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  lxc file push "$(pwd)/$cont/50-cloud-init.yaml" "$cont/etc/netplan/50-cloud-init.yaml"
  lxc exec $cont -- netplan apply
  lxc exec $cont -- echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  lxc exec $cont -- sysctl -p /etc/sysctl.conf
done

# connect the clients to the corresponding bridges
containers=("C1" "C2" "nomad")
bridges=("br1" "br2" "brnomad")
for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  br=${bridges[$i]}
  lxc config device add $cont eth0 nic nictype=bridged parent=$br
  lxc file push "$(pwd)/$cont/50-cloud-init.yaml" "$cont/etc/netplan/50-cloud-init.yaml"
  lxc exec $cont -- netplan apply
done


