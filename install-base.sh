#!/bin/env bash

# Set timezone
timedatectl set-timezone America/Los_Angeles

# Verify that NTP service is enabled
timedatectl

# Rate and use the fastest mirrors
reflector --save /etc/pacman.d/mirrorlist --protocol https --country US --sort rate --age 6 --latest 10

# Update package DB
pacman -Syy

# Install the base system
./pacstrap.sh

# Generate the file system table for the currently mounted target
genfstab -U /mnt >>/mnt/etc/fstab
