#!/bin/bash

ext_name="extbr0"
ext_ip="10.100.0.1"
ext_mask="24"
# external, NAT enabled for internal access to outside world
echo "Create ${ext_name} (NAT-Enabled) -> ${ext_ip}/${ext_mask}"
lxc network create $ext_name ipv4.address=$ext_ip/$ext_mask ipv6.address=none ipv4.dhcp=true ipv6.dhcp=false ipv4.nat=true ipv6.nat=false

dmz_name="dmzbr0"
dmz_ip="10.100.1.1"
dmz_mask="24"
# DMZ, no NAT, no DHCP
echo "Create ${dmz_name} (NAT-Disabled) -> ${dmz_ip}/${dmz_mask}"
lxc network create $dmz_name ipv4.address=$dmz_ip/$dmz_mask ipv6.address=none ipv4.dhcp=false ipv6.dhcp=false ipv4.nat=false ipv6.nat=false  

int_name="intbr0"
int_ip="192.168.111.1"
int_mask="24"
# internal, no NAT, but DHCP enabled for client IPs
echo "Create ${int_name} (NAT-Disabled) -> ${int_ip}/${int_mask}"
lxc network create $int_name ipv4.address=$int_ip/$int_mask ipv6.address=none ipv4.dhcp=true ipv6.dhcp=false ipv4.nat=false ipv6.nat=false

