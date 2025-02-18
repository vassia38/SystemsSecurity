#!/bin/bash

pk=$(xxd -l 32 -p /dev/random | tr -d "\n")

#ipR1="192.168.1.1"
#ipR2="192.168.2.1"
#lxc exec R1 -- echo ${ipR1} ${ipR2} : PSK '\"'\$pk'\"' >> /etc/ipsec.secrets
#lxc exec R2 -- echo ${ipR2} ${ipR1} : PSK '\"'\$pk'\"' >> /etc/ipsec.secrets

# R1 ======= R2
#      PSK
ipR1="10.0.0.1"
ipR2="10.0.0.2"
lxc exec R1 -- echo ${ipR1} ${ipR2} : PSK '\"'\$pk'\"' >> /etc/ipsec.secrets
lxc exec R2 -- echo ${ipR2} ${ipR1} : PSK '\"'\$pk'\"' >> /etc/ipsec.secrets

# R1 ======= R2
#      CRT
lxc exec R1 -- echo ${ipR1} ${ipR2} : RSA r1.key >> /etc/ipsec.secrets
lxc exec R2 -- echo ${ipR2} ${ipR1} : RSA r2.key >> /etc/ipsec.secrets

lxc file push "$(pwd)/R1/ipsec.conf" "R1/etc/ipsec.conf"
lxc file push "$(pwd)/R2/ipsec.conf" "R2/etc/ipsec.conf"

# R1 ======= nomad
#      CRT
ipR1="192.168.3.2"
ipNomad="192.168.3.1"
lxc exec nomad -- echo ${ipNomad}${ipR1} : RSA nomad.key >> /etc/ipsec.secrets
lxc file push "$(pwd)/nomad/ipsec.conf" "nomad/etc/ipsec.conf"

containers=("R1" "R2" "nomad")
names=("r1" "r2" "nomad")

# create root CA
openssl genrsa -out "ca.key" 2048
openssl req -x509 -new -nodes -key "ca.key" -sha256 -days 3650 -config "openca.cnf" -extensions v3_ca -out "ca.crt"

for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  name=${names[$i]}
  # create RSA key pair, make a certificate request and then use the CA to sign it
  openssl genrsa -out "$cont/$name.key" 2048
  openssl req -new -key "$cont/$name.key" -out "$cont/$name.csr" -config "$cont/openssl.cnf"
  openssl x509 -req -in "$cont/$name.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "$cont/$name.crt" -days 365 -sha256 -extensions v3_ca -extfile "$cont/openssl.cnf"

  # push the needed files to the corresponding host
  lxc file push "$(pwd)/$cont/$name.key" "$cont/etc/ipsec.d/private/$name.key"
  lxc file push "$(pwd)/$cont/$name.crt" "$cont/etc/ipsec.d/certs/$name.crt"
  lxc file push "$(pwd)/ca.crt" "$cont/etc/ipsec.d/cacerts/ca.crt"
done
