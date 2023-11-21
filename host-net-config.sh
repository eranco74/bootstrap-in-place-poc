#!/bin/bash

tmpfile=$(mktemp)
_cleanup(){
    rm -f $tmpfile
}
trap _cleanup exit

# Update libvirt dhcp configuration
if sudo virsh net-dumpxml $NET_NAME | grep -q "mac='$HOST_MAC'" ; then
    action=modify
else
    action=add-last
fi
sudo virsh net-update $NET_NAME $action ip-dhcp-host '<host mac="'$HOST_MAC'" name="'$HOST_NAME'" ip="'$HOST_IP'"/>' --live --parent-index 0

# Update dnsmasq configuration
grep -vx address=/api.${CLUSTER_NAME}.${BASE_DOMAIN}/${HOST_IP} /etc/NetworkManager/dnsmasq.d/bip.conf > $tmpfile
echo address=/api.${CLUSTER_NAME}.${BASE_DOMAIN}/${HOST_IP} >> $tmpfile
cat $tmpfile | sudo tee /etc/NetworkManager/dnsmasq.d/bip.conf
sudo systemctl reload NetworkManager.service
