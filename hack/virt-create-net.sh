#!/bin/bash

# Create a libvirt virtual network called 'test-net' configured
# to assign master1.test-cluster.redhat.com/192.168.126.10 to
# DHCP requests from 52:54:00:ee:42:e1
# libvirt will also configure dnsmasq (listening on 192.168.126.1)
# to respond to DNS queries for several hosts under
# test-cluster.redhat.com with the 192.168.126.10 address.
# This dnsmasq is also configured to not forward unresolved requests
# within the test-cluster.redhat.com domain to upstream DNS servers.
# Finally, we configure NetworkManager to send any DNS queries
# on this machine for api.test-cluster.redhat.com to the libvirt
# configured dnsmasq on 192.168.126.1

sudo virsh net-create ./hack/net.xml

echo server=/api.test-cluster.redhat.com/192.168.126.1 | sudo tee /etc/NetworkManager/dnsmasq.d/aio.conf
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/aio.conf
sudo systemctl reload NetworkManager.service
