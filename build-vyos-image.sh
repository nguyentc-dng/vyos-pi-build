#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Copy prebuilt package
echo "Copy prebuilt packages"
rm -rf vyos-build/packages/*
for a in $(find ./packages/ -type f -name "*.deb" | grep -v -e "-dbgsym_" -e "libnetfilter-conntrack3-dbg"); do
	echo "Copying package: $a"
	cp $a ./vyos-build/packages/
done

# Build VyOS RAW image
echo "Copy prebuilt packages"
cd ${ROOTDIR}/vyos-build
make clean
export VYOS1X_REPO_URL=file:///${ROOTDIR}/vyos-build/scripts/package-build/vyos-1x/vyos-1x
./build-vyos-image rpi4 --architecture arm64 --build-by "${VYOS_BUILD_BY}" --build-type "${VYOS_BUILD_TYPE}"

# Copy RAW image to images directory
RAW_IMAGE=$(find ./ -type f -name *.raw | head -n 1)
if [ ! -e ${RAW_IMAGE} ]; then
	echo "File ${RAW_IMAGE} not exists."
	exit -1
else
	cp ${RAW_IMAGE} ${ROOTDIR}/images/
fi

# Clean built directory
rm -rf ./build/

# Return to ROOTDIR
cd ${ROOTDIR}