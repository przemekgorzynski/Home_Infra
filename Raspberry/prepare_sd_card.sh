#!/bin/bash


check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run with sudo."
        exit 1
    else
        echo "OK - running as root"
    fi
}
#######################################################################################
download_img_file(){
    # Define the download URL using the version variable
    URL="https://cdimage.ubuntu.com/releases/$VERSION/release/ubuntu-$VERSION-preinstalled-server-arm64+raspi.img.xz"

    if [ -f "$UNPACKED_FILE" ]; then
        echo "The image file already exists at $UNPACKED_FILE. No need to download."
    else
        echo "Downloading the image file..."
        wget -O $OUTPUT_FILE $URL

        # Check if the download was successful
        if [ $? -eq 0 ]; then
            echo "Download completed successfully."
            # Unpack the image
            echo "Unpacking the image..."
            xz -d $OUTPUT_FILE
            if [ $? -eq 0 ]; then
                echo "Unpacking completed successfully."
                # Remove the .img.xz file after unpacking
                echo "Removing the .img.xz file..."
                rm -f $OUTPUT_FILE
            else
                echo "Unpacking failed."
                exit 1
            fi
        else
            echo "Download failed."
            exit 1
        fi
    fi
}

#######################################################################################
format_sd_card() {
    local device="$1"

    # Check if the device is mounted
    if mount | grep -q "$device"; then
        echo "Error: Device $device is currently mounted. Please unmount it before formatting."
        exit 1
    fi

    # Format the device as FAT32
    echo "Formatting $device as FAT32..."
    mkfs.vfat -I "$device"

    # Check if the formatting was successful
    if [ $? -eq 0 ]; then
        echo "Successfully formatted $device as FAT32."
    else
        echo "Failed to format $device."
        exit 1
    fi
}
#######################################################################################
write_img_to_sd_card(){
    local img_file="$1"
    local device="$2"
    echo "Writing $img_file to $device..."
    dd bs=4M conv=fsync if="$img_file" of="$device" status=progress
    sync

    # Check if the dd command was successful
    if [ $? -eq 0 ]; then
        echo "Successfully wrote $img_file to $device."
    else
        echo "Failed to write $img_file to $device."
        exit 1
    fi
}
#######################################################################################
cloud_init() {
    local boot_partition="$1"
    local cloud_config_file="$2"

    # Mount the boot partition
    mkdir -p /mnt/boot
    mount "$boot_partition" /mnt/boot

    # Check if the mount was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount $boot_partition."
        exit 1
    fi

    # Create SSH configuration file
    echo "Creating SSH configuration"
    touch /mnt/boot/ssh
    echo "OK"

    echo "Copying $cloud_config_file file"
    # Copy user-data configuration to boot partition
    if [ -f "$cloud_config_file" ]; then
        cp "$cloud_config_file" /mnt/boot/user-data
        echo "OK"
    else
        echo "Error: user-data file does not exist."
        exit 1
    fi

    # Unmount the boot partition after operations
    umount /mnt/boot
}
#######################################################################################
# Define the device to unmount and format
DEVICE=$1
VERSION="24.04.2"
OUTPUT_FILE="/tmp/ubuntu-$VERSION-preinstalled-server-arm64+raspi.img.xz"
UNPACKED_FILE="/tmp/ubuntu-$VERSION-preinstalled-server-arm64+raspi.img"
BOOT_PARTITION="${DEVICE}p1"
CLOUD_CONFIG_FILE="cloud-config.yml"

# Check if the device parameter is provided
if [ -z "$DEVICE" ]; then
    echo "ERROR:
No device provided.
Usage: $0 <device>"
    exit 1
fi

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: Device $DEVICE does not exist."
    exit 1
fi

echo "##### Running function: check_sudo #####"
check_sudo
echo ""

echo "##### Running function: download_img_file #####"
download_img_file
echo ""

echo "##### Running function: format_sd_card #####"
format_sd_card "$DEVICE"
echo ""

echo "##### Running function: write_img_to_sd_card #####"
write_img_to_sd_card "${UNPACKED_FILE}" "$DEVICE"
echo ""

echo "##### Running function: cloud_init #####"
cloud_init "$BOOT_PARTITION" "$CLOUD_CONFIG_FILE"
