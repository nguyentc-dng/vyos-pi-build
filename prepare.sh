#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

echo "Clean old vyos-build dir if exist"
rm -rf ${ROOTDIR}/vyos-build
git clone -b ${VYOS_BRANCH} https://github.com/vyos/vyos-build.git vyos-build
sed -i "s/build_type\ =.*/build_type\ =\ \"${VYOS_BUILD_TYPE}\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml

echo "Create packages and images directory"
mkdir -p ${ROOTDIR}/packages && rm -rf ${ROOTDIR}/packages/*
mkdir -p ${ROOTDIR}/images && rm -rf ${ROOTDIR}/images/*

cd ${ROOTDIR}
