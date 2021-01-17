#!/bin/bash

if [ -z ${NET_XML+x} ]; then
	echo "Please set NET_XML"
	exit 1
fi

sudo virsh net-create ${NET_XML}

echo server=/api.test-cluster.redhat.com/192.168.126.1 | sudo tee /etc/NetworkManager/dnsmasq.d/aio.conf
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/aio.conf
systemctl reload NetworkManager.service
