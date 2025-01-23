#!/bin/bash

net_name="dmzbr0"
containers="web db dns"

for cont in $containers;do
  lxc init ubuntu:24.04 $cont
  lxc network attach $net_name $cont eth1
  conf="$(pwd)/config/${cont}/01-netcfg.yaml"
  lxc config set $cont user.network-config="$(cat $conf)"
  
  echo "[$cont] Launch"
  lxc start $cont
  
  echo "[$cont] Update"
  lxc exec $cont -- apt update -y
  lxc exec $cont -- apt install -y ssh

  echo "[$cont] Change root password"
  lxc exec $cont -- bash -c "echo 'root:passwd' | chpasswd"
  
  echo "[$cont] modify ssh root permissions"
  lxc exec $cont -- bash -c "sed -i 's/^#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config"
  lxc exec $cont -- bash -c "sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
  lxc exec $cont -- bash -c "rm /etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
  lxc exec $cont -- systemctl restart ssh
  
done

