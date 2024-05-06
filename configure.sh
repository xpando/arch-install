#!/bin/env bash

# This scipt is intended to be run after arch-chrooting into the target system during inital installation

# Timezone and hardware clock
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

if [ "$TARGET_ENCRYPT" = true ]; then
	# add the uuid of TARGET_BTRFS_PART to default kernel command line in /etc/default/grub
	$TARGET_BTRFS_PART_BLKID=$(blkid -s UUID -o value $TARGET_BTRFS_PART)
	sed -i 's|\(^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)|\1 cryptdevice=UUID='"$TARGET_BTRFS_PART_BLKID"':archlinux root=/dev/mapper/archlinux|' grub
fi

# Boot loader (GRUB)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Create the Grub configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Eanble services
systemctl enable avahi-daemon
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable tlp
systemctl enable acpid
systemctl enable reflector.timer
systemctl enable fstrim.timer # For SSDs
systemctl enable upower

# Set root password
echo Set password for root:
passwd

# Create user
groupadd docker
useradd -mg users -G wheel,docker -s /usr/bin/zsh david

# Set user full name (optional)
usermod -c 'David Findley' david

# Set user's password
echo Set password for user david:
passwd david

# Enabled sudo for wheel group
mkdir -p /etc/sudoers.d
echo '%wheel ALL=(ALL) ALL' >/etc/sudoers.d/10-wheel
