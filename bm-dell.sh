#!/bin/bash
  
set -euxo pipefail

HTTP_IP=$(hostname -i)

if [ -z ${DRAC_IP+x} ]; then
        echo "Please set DRAC_IP"
        exit 1
fi

if [ -z ${DRAC_USER+x} ]; then
        echo "Please set DRAC_USER"
        exit 1
fi

if [ -z ${DRAC_PASSWORD+x} ]; then
        echo "Please set DRAC_PASSWORD"
        exit 1
fi

if [ -z ${INSTALLER_WORKDIR+x} ]; then
        echo "Please set INSTALLER_WORKDIR"
        exit 1
fi

if [ -z ${HTTP_IP+x} ]; then
        echo "Cannot detect HTTP_IP"
        exit 1
fi

podman run -dit --name httpd-iso -p 80:80 -v "$PWD"/"${INSTALLER_WORKDIR}"/:/usr/local/apache2/htdocs/ httpd:2.4
podman run --net=host quay.io/dphillip/racadm-image:latest -r "${DRAC_IP}" -u "${DRAC_USER}" -p "${DRAC_PASSWORD}" -i http://"${HTTP_IP}":80/embedded.iso
