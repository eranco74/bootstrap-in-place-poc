#!/bin/bash

set -euxo pipefail


if [ -z ${INSTALLATION_DISK+x} ]; then
	echo "Please set INSTALLATION_DISK"
	exit 1
fi

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

OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALLER_ARGS=${INSTALLATION_DISK} \
OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="${RELEASE_IMAGE}" \
${INSTALLER_BIN} create single-node-ignition-config --dir=${INSTALLER_WORKDIR}
