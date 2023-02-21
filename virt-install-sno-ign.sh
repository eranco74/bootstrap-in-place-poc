#!/bin/bash

if [ -z ${IMAGE+x} ]; then
	echo "Please set IMAGE"
	exit 1
fi

if [ -z ${VM_NAME+x} ]; then
	echo "Please set the VM_NAME"
	exit 1
fi

if [ -z ${NET_NAME+x} ]; then
	echo "Please set the NET_NAME"
	exit 1
fi

OS_VARIANT="rhel8.1"
RAM_MB="${RAM_MB:-16384}"
DISK_GB="${DISK_GB:-20}"

virt-install \
    --connect qemu:///system \
    -n "${VM_NAME}" \
    -r "${RAM_MB}" \
    --os-variant="${OS_VARIANT}" \
    --import \
    --network=network:${NET_NAME},mac=52:54:00:ee:42:f2 \
    --graphics=none \
    --disk "size=${DISK_GB},backing_store=${IMAGE}"
