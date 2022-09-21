export BASE_OS_IMAGE=${BASE_OS_IMAGE:-https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.11/4.11.2/rhcos-4.11.2-x86_64-live.x86_64.iso}

if [ $# -eq 0 ]; then
    echo "USAGE: $0 download_path"
    exit 1
fi

DOWNLOAD_PATH=$1
curl -L "${BASE_OS_IMAGE}" --retry 5 -o "${DOWNLOAD_PATH}"
