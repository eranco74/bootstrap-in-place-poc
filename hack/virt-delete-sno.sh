#!/bin/bash
VM_NAME=`awk -F'"' '/^VM_NAME/ {print $(NF-1)}' hack/virt-install-sno-iso-ign.sh`
sudo virsh destroy $VM_NAME
sudo virsh undefine $VM_NAME

sudo virsh vol-delete --pool default sno-test.qcow2
