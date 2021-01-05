#!/bin/bash
VM_NAME=`awk -F'"' '/^VM_NAME/ {print $(NF-1)}' hack/virt-install-sno-iso-ign.sh`
sudo virsh destroy $VM_NAME
sudo virsh undefine $VM_NAME

NET_NAME=`xmllint  --xpath 'string(//network/name)' hack/net.xml`
sudo virsh net-destroy $NET_NAME
sudo virsh net-undefine $NET_NAME

sudo virsh vol-delete --pool default sno-test.qcow2
