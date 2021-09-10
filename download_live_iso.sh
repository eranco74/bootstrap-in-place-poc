export BASE_OS_IMAGE=${BASE_OS_IMAGE:-https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/latest-4.9/rhcos-4.9.0-rc.0-x86_64-live.x86_64.iso}

if [ $# -eq 0 ]; then
    echo "USAGE: $0 download_path"
    exit 1
fi

DOWNLOAD_PATH=$1
curl ${BASE_OS_IMAGE} --retry 5 -o $DOWNLOAD_PATH

