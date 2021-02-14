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
${INSTALLER_BIN} create single-node-ignition-config --dir=${INSTALLER_WORKDIR}

if [ -z ${INSTALLATION_DISK+x} ]; then
	echo "INSTALLATION_DISK was not set"
else
  #Add complete-installation to the bootstrap-in-place-ignition
	echo "INSTALLATION_DISK set to $INSTALLATION_DISK adding complete-installation.service"

  sed 's,REPLACE_INSTALLATION_DISK,'"$INSTALLATION_DISK"',' ignition-overrides/complete-installation.sh.template > ignition-overrides/complete-installation.sh
  cp ${INSTALLER_WORKDIR}/bootstrap-in-place-for-live-iso.ign ignition-overrides/

  podman run \
    --rm \
    --privileged \
    --volume "./ignition-overrides:/assets:z" \
    quay.io/coreos/fcct:release \
    --pretty \
    --strict \
    --files-dir assets \
    /assets/complete-installation.fcc > ${INSTALLER_WORKDIR}/bootstrap-in-place-for-live-iso.ign
fi

