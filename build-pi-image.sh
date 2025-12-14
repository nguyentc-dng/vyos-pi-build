#!/bin/bash

ROOTDIR=$(pwd)

if [ ! -z "${DEBUG}" ]; then
    echo "Enable debugging"
    set -x
    exec 3>&1
else
    exec 3>/dev/null
fi

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

exec 4> >(
    # Hotfix to hide stderr messages from applications that cant be "silent" eg grub-install
    while IFS='' read -r line || [ -n "$line" ]; do
        # Hide "Garbage" from GRUB installer
        [[ "${line}" =~ "Installing for arm64-efi platform" ]] && continue
        [[ "${line}" =~ "EFI variables are not supported on this system" ]] && continue
        [[ "${line}" =~ "No error reported" ]] && continue
        echo -e "${line}"
    done
)
set -e

crash_cleanup() {
    echo "OOOPS!!! we crashed.. :/ starting a crude cleanup."
    if [ ! -z "$IMGLOOP" ]; then
        echo "IMGLOOP : ${IMGLOOP}"
        echo "Unmounting ISO"
        umount ${IMGLOOP} || true
        losetup -d ${IMGLOOP} || true
    fi
}
trap "crash_cleanup" ERR


# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

if [ -f "${PIVERSION}" ]; then
	PIVERSION=4
fi

if [ -f "${UBOOTBIN}" ]; then
    echo "Using uboot from ${UBOOTBIN}"
elif [ -f "./packages/u-boot-rpi${PIVERSION}.bin" ]; then
    echo "Using uboot from ./packages/u-boot-rpi${PIVERSION}.bin"
    UBOOTBIN="./packages/u-boot-rpi${PIVERSION}.bin"
else
    1>&2 echo "ERROR: u-boot.bin not found and UBOOTBIN env variable is not set"
    exit 1
fi

echo "VYOS Raspberry Pi3/4 image builder"

# Select devtree to load, if none is spesified pi4b devtree is used
if [ -z "$DEVTREE" ]; then
    DEVTREE="bcm2711-rpi-4-b"
fi

IMGNAME=$(find ${ROOTDIR}/images/ -type f -name *.raw | head -n 1)
IMGLOOP=$(losetup --show -fP ${IMGNAME})
echo "Mounting iso on loopback: $IMGLOOP"

EFIDIR="/mnt/efi"
mkdir -p ${EFIDIR}

echo "Mounting EFI directory"
mount ${IMGLOOP}p2 ${EFIDIR}

# Copy rpi firmware files
echo "Downloading PI Boot files"
if [ "${PIVERSION}" == "4" ]; then
    cp -r $/patches/u-boot/fixup4.dat ${EFIDIR}/
    cp -r ${ROOTDIR}/patches/u-boot/start4.elf ${EFIDIR}/
    cp -r ${ROOTDIR}/patches/u-boot/dts/overlays ${EFIDIR}/ 
elif [ "${PIVERSION}" == "3" ]; then
    cp -r ${ROOTDIR}/patches/u-boot/bootcode.bin ${EFIDIR}/
    cp -r ${ROOTDIR}/patches/u-boot/fixup.dat ${EFIDIR}/
    cp -r ${ROOTDIR}/patches/u-boot/start.elf ${EFIDIR}/
fi
cp ${ROOTDIR}/patches/u-boot/dts/broadcom/${DEVTREE}.dtb ${EFIDIR}/${DEVTREE}.dtb

cp ${UBOOTBIN} ${EFIDIR}/u-boot.bin

echo "Installing GRUB"
if [ "$DEVTREE" == "bcm2711-rpi-cm4" ]; then
  echo "Enabling overlay for CM4 usb"
  CM4USB='dtoverlay=dwc2,dr_mode=host'
fi

cat > ${EFIDIR}/config.txt << EOF
# Enable 64bit mode
arm_64bit=1
 
# Enable Serial console
enable_uart=1
dtoverlay=disable-bt
${CM4USB}

# Boot into u-boot
kernel=u-boot.bin
EOF


cat > ${EFIDIR}/boot.script << EOF
# Load EFI
echo "Loading EFI image ..."
load mmc 0:1 \$loadaddr EFI/BOOT/BOOTAA64.EFI
 
# Slepp a while do the MMC driver can settle down
echo "Sleeping 2 seconds ..."
sleep 2
 
# Boot
echo "Booting into GRUB..."
bootefi \$loadaddr
EOF
 
 
# compile boot script for u-boot
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d ${EFIDIR}/boot.script ${EFIDIR}/boot.scr 1>&3

echo "Unmounting disks"
umount ${EFIDIR}

#unmount image
sudo losetup -d ${IMGLOOP} 
echo "Compressing image"

# Compress image
cd ${ROOTDIR}/images/
IMGZIP=$(basename ${IMGNAME})
zip ${IMGZIP}.zip ${IMGZIP} 1>&3
echo "Done"

# Return to ROOTDIR
cd ${ROOTDIR}