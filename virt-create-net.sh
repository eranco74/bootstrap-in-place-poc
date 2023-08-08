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

# Warn terminal users about dns changes
if [ -t 1 ]; then
    function ask_yes_or_no() {
        read -p "$1 ([y]es or [N]o): "
        case $(echo "$REPLY" | tr '[A-Z]' '[a-z]') in
            y|yes) echo "yes" ;;
            *)     echo "no" ;;
        esac
    }

    echo "This script will make changes to the DNS configuration of your machine, read $0 to learn more"

    if [[ -f .dns_changes_confirmed || "yes" == $(ask_yes_or_no "Are you sure you want to continue?") ]]; then
        touch .dns_changes_confirmed
    else
        exit 1
    fi
fi

if [ -z ${NET_XML+x} ]; then
	echo "Please set NET_XML"
	exit 1
fi

sudo virsh net-create "${NET_XML}"

echo address=/api.${CLUSTER_NAME}.${BASE_DOMAIN}/${HOST_IP} | sudo tee /etc/NetworkManager/dnsmasq.d/bip.conf
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/bip.conf
sudo systemctl reload NetworkManager.service
