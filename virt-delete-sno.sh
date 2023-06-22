#!/bin/bash

if [ -z ${VM_NAME+x} ]; then
	echo "Please set the VM_NAME that should be destroyed"
	exit 1
fi

if [ -z ${NET_NAME+x} ]; then
	echo "Please set the NET_NAME that should be destroyed"
	exit 1
fi

if [ -z ${VOL_NAME+x} ]; then
	echo "Please set the VOL_NAME that should be destroyed"
	exit 1
fi

export POOL="${POOL:-default}"


sudo virsh undefine "$VM_NAME"
sudo virsh destroy "$VM_NAME"

sudo virsh net-undefine "$NET_NAME"
sudo virsh net-destroy "$NET_NAME"

sudo virsh vol-delete --pool "$POOL" "${VOL_NAME}"
