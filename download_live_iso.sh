export RHCOS_VERSION=${RHCOS_VERSION:-47.83.202102090044-0}
export BASE_OS_IMAGE=${BASE_OS_IMAGE:-https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.7/${RHCOS_VERSION}/x86_64/rhcos-${RHCOS_VERSION}-live.x86_64.iso}

if [ $# -eq 0 ]; then
    echo "USAGE: $0 download_path"
    exit 1
fi

DOWNLOAD_PATH=$1
curl ${BASE_OS_IMAGE} --retry 5 -o $DOWNLOAD_PATH

