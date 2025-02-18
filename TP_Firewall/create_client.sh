#! /bin/bash

# need container name
if [[ $# -le 0 ]]; then
  exit 1
fi

default_interf="lxdbr0"
int_interf="intbr0"
cont=$1
lxc init ubuntu:24.04 $cont -n intbr0
#lxc exec $cont -- apt update
#lxc network detach $default_interf $cont
#lxc network attach $int_interf $cont eth0
#lxc exec $cont -- bash -c "/lib/systemd/systemd-networkd-wait-online"
#lxc exec $cont -- bash -c "/lib/systemd/systemd-udevd --daemon && systemctl daemon-reload"
conf="$(pwd)/config/client/01-netcfg.yaml"
lxc config set $cont user.network-config="$(cat $conf)"

lxc start $cont
