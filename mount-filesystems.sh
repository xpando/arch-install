#!/bin.env bash

# Mounts the filesystem structure under /mnt
# This is useful when you have too boot from the arch iso and need to mount the filesystems manually
# before running arch-chroot /mnt
# Don't forget to source the specific host-{name}.env file before running this script

if [ "$TARGET_ENCRYPT" = true ]; then
	cryptsetup luksOpen $TARGET_BTRFS_PART archlinux
	TARGET_BTRFS_PART=/dev/mapper/archlinux
fi

# Mount the root volume
mount -o "$TARGET_MOUNTOPTS,subvol=@" $TARGET_BTRFS_PART /mnt

# Create dirs in the root volume that we will mount the rest of the volumes to
mkdir -p /mnt/{boot,home,tmp,var/log,var/cache/pacman/pkg,swap,.snapshots}

mount -o "$TARGET_MOUNTOPTS,subvol=@home" $TARGET_BTRFS_PART /mnt/home
mount -o "$TARGET_MOUNTOPTS,subvol=@tmp" $TARGET_BTRFS_PART /mnt/tmp
mount -o "$TARGET_MOUNTOPTS,subvol=@log" $TARGET_BTRFS_PART /mnt/var/log
mount -o "$TARGET_MOUNTOPTS,subvol=@pkg" $TARGET_BTRFS_PART /mnt/var/cache/pacman/pkg
mount -o "$TARGET_MOUNTOPTS,subvol=@swap" $TARGET_BTRFS_PART /mnt/swap
mount -o "$TARGET_MOUNTOPTS,subvol=.@snapshots" $TARGET_BTRFS_PART /mnt/.snapshots

# Active a swapfile
swapon /mnt/swap/swapfile

# Mount EFI boot partition
mount $TARGET_EFI_PART /mnt/boot
