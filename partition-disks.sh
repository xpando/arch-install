#!/bin/env bash

set -e

# Partition system installation disk
parted -s $TARGET_DISK \
	mklabel gpt \
	mkpart EFI fat32 2MiB 514MiB \
	set 1 esp on \
	mkpart BTRFS btrfs 514MiB 100% \
	align-check opt 1 \
	align-check opt 2 \
	print

# Encrypt BTRFS partition (optional)
if [ "$TARGET_ENCRYPT" = true ]; then
	cryptsetup luksFormat -v -s 512 -h sha512 $TARGET_BTRFS_PART
	cryptsetup luksOpen $TARGET_BTRFS_PART archlinux
	TARGET_BTRFS_PART=/dev/mapper/archlinux
fi

# Create filesystems
mkfs.fat -F32 -n EFI $TARGET_EFI_PART
mkfs.btrfs -f -L BTRFS $TARGET_BTRFS_PART
lsblk -o NAME,FSTYPE,PARTUUID,PARTLABEL,LABEL,MOUNTPOINT,FSTYPE,FSUSE%

# Create BTRFS volumes:
# Mount the BTRFS partition and create subvolumes
mount $TARGET_BTRFS_PART /mnt
btrfs subvolume create /mnt/{@,@home,@tmp,@log,@pkg,@swap,.@snapshots}

# Disable copy on write on these volumes
chattr +C /mnt/@tmp
chattr +C /mnt/@log
chattr +C /mnt/@swap

umount /mnt

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

# Create a swapfile
btrfs filesystem mkswapfile --size $TARGET_SWAP_SIZE --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Mount EFI boot partition
mount $TARGET_EFI_PART /mnt/boot
