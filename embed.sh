#!/bin/bash

set -euxo pipefail

if [ -z ${ISO_PATH+x} ]; then
	echo "Please set ISO_PATH"
	exit 1
fi

if [ -z ${IGNITION_PATH+x} ]; then
	echo "Please set IGNITION_PATH"
	exit 1
fi

if [ -z ${OUTPUT_PATH+x} ]; then
	echo "Please set OUTPUT_PATH"
	exit 1
fi

podman run \
    --pull=always \
    --privileged \
    --rm \
    -v /dev:/dev \
    -v /run/udev:/run/udev \
    -v $(realpath $(dirname $ISO_PATH)):/data:Z \
    -v $(realpath $(dirname $IGNITION_PATH)):/ignition_data:Z \
    -v $(realpath $(dirname $OUTPUT_PATH)):/output_data:Z \
    --workdir /data \
    quay.io/coreos/coreos-installer:release \
    iso ignition embed /data/$(basename $ISO_PATH) \
    --force \
    --ignition-file /ignition_data/$(basename $IGNITION_PATH) \
    --output /output_data/$(basename $OUTPUT_PATH)

