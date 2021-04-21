#!/bin/bash
set -x

if [ -z ${RHCOS_IMAGE+x} ]; then
	echo "Please set RHCOS_ISO"
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

IGNITION_CONFIG="/var/lib/libvirt/images/worker.ign"
sudo cp "$1" "${IGNITION_CONFIG}"
sudo chown qemu:qemu "${IGNITION_CONFIG}"
sudo restorecon "${IGNITION_CONFIG}"

OS_VARIANT="rhel8.1"
RAM_MB="16384"
DISK_GB="10"
CPU_CORE="6"


virt-install \
    --connect qemu:///system \
    -n "${VM_NAME}" \
    -r "${RAM_MB}" \
    --vcpus "${CPU_CORE}" \
    --os-variant="${OS_VARIANT}" \
    --network=network:${NET_NAME},mac=52:54:00:ee:42:aa \
    --graphics=none \
    --events on_reboot=restart \
    --import \
    --disk pool=default,size=${DISK_GB},backing_store=${RHCOS_IMAGE} \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
