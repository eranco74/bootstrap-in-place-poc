#!/bin/bash

if [ -z ${NET_NAME+x} ]; then
	echo "Please set the NET_NAME that should be destroyed"
	exit 1
fi

sudo virsh net-undefine "$NET_NAME"
sudo virsh net-destroy "$NET_NAME"
