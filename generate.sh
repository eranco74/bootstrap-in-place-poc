#!/bin/bash

set -euxo pipefail

if [ -z ${RELEASE_IMAGE+x} ]; then
	echo "Please set RELEASE_IMAGE"
	exit 1
fi

if [ -z ${INSTALLER_BIN+x} ]; then
	echo "Please set INSTALLER_BIN"
	exit 1
fi

if [ -z ${INSTALLER_WORKDIR+x} ]; then
	echo "Please set INSTALLER_WORKDIR"
	exit 1
fi

OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="${RELEASE_IMAGE}" \

if [ ${USE_INTERNAL_IP+x} ]; then
OPENSHIFT_INSTALL_BOOTSTRAP_NODE_IP=192.168.99.1
fi

${INSTALLER_BIN} create single-node-ignition-config --dir="${INSTALLER_WORKDIR}"

if [ ${USE_INTERNAL_IP+x} ]; then
	echo "adding dummy interface service to ignition file"
	jq '.systemd.units += [{
"contents": "[Unit]\nDescription=Create dummy network\nAfter=NetworkManager.service\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/bin/nmcli conn add type dummy ifname eth10 autoconnect yes save yes con-name internalEtcd ip4 192.168.99.1/30\n\n[Install]\nWantedBy=multi-user.target\n",
"enabled": true,
"name": "dummy-network.service"
}]' "${INSTALLER_WORKDIR}"/bootstrap-in-place-for-live-iso.ign | sponge "${INSTALLER_WORKDIR}"/bootstrap-in-place-for-live-iso.ign
fi
