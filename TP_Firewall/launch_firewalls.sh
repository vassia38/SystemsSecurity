#! /bin/bash

containers=("firewall1" "firewall2")
eth0_ifs=("extbr0" "intbr0")
dmz_name="dmzbr0"

for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  interf=${eth0_ifs[$i]}
  
  lxc init ubuntu:24.04 $cont -n $interf
  lxc network attach $dmz_name $cont eth1
  conf="$(pwd)/config/${cont}/01-netcfg.yaml"
  lxc config set $cont user.network-config="$(cat $conf)"
  
  echo "$cont Launch"
  lxc start $cont

  echo "$cont Update"
  lxc exec $cont -- apt update && apt upgrade -y && apt autoremove
  lxc exec $cont -- apt install iptables-persistent -y
  lxc exec $cont -- apt install -y ssh 

  echo "[$cont] Change root password"
  lxc exec $cont -- bash -c "echo 'root:passwd' | chpasswd"
  
  echo "[$cont] modify ssh root permissions"
  lxc exec $cont -- bash -c "sed -i 's/^#PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config"
  lxc exec $cont -- bash -c "sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config"
  lxc exec $cont -- bash -c "rm /etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
  lxc exec $cont -- systemctl restart ssh

  # ensure each firewall has IP Forwarding enabled for traffic to flow between interfaces
  echo "Enable ipv4 forwarding"
  lxc exec $cont -- echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  lxc exec $cont -- sysctl -p /etc/sysctl.conf
  
  lxc exec $cont -- iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  lxc exec $cont -- netfilter-persistent save

done

