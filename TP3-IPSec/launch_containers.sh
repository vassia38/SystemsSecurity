#!/bin/bash

containers=("C1" "C2" "R1" "R2" "nomad")
for i in "${!containers[@]}"; do
  cont=${containers[$i]}
  lxc launch ubuntu:20.04 $cont
done
