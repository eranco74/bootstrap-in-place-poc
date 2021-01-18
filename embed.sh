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

if [[ $(dirname $ISO_PATH) != $(dirname $IGNITION_PATH) ]]; then
    echo $ISO_PATH and $IGNITION_PATH must be in the same directory
    exit 1
fi

if [[ $(dirname $IGNITION_PATH) != $(dirname $OUTPUT_PATH) ]]; then
    echo $IGNITION_PATH and $OUTPUT_PATH must be in the same directory
    exit 1
fi

sudo podman run \
    --pull=always \
    --privileged \
    --rm \
    -v /dev:/dev \
    -v /run/udev:/run/udev \
    -v $(realpath $(dirname $ISO_PATH)):/data \
    --workdir /data \
    quay.io/coreos/coreos-installer:release \
    iso ignition embed /data/$(basename $ISO_PATH) \
    --force \
    --ignition-file /data/$(basename $IGNITION_PATH) \
    --output /data/$(basename $OUTPUT_PATH)

