export BASE_OS_IMAGE=${BASE_OS_IMAGE:-https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/35.20211029.3.0/x86_64/fedora-coreos-35.20211029.3.0-live.x86_64.iso}

if [ $# -eq 0 ]; then
    echo "USAGE: $0 download_path"
    exit 1
fi

DOWNLOAD_PATH=$1
curl "${BASE_OS_IMAGE}" --retry 5 -o "${DOWNLOAD_PATH}"
