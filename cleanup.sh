#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

rm -rf ${ROOTDIR}/vyos-build/