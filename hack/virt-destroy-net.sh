#!/bin/bash

sudo rm -f /etc/NetworkManager/conf.d/aio.conf /etc/NetworkManager/dnsmasq.d/aio.conf
sudo systemctl reload NetworkManager.service

NET_NAME=`xmllint  --xpath 'string(//network/name)' hack/net.xml`
sudo virsh net-destroy $NET_NAME
