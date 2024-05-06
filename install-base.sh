#!/bin/env bash

# This script is used to install the base arch system just after
# partitioning, formatting and mounting the filesystems

# Set timezone
timedatectl set-timezone America/Los_Angeles

# Rate and use the fastest mirrors
reflector --save /etc/pacman.d/mirrorlist --protocol https --country US --sort rate --age 6 --latest 10

# Update package DB
pacman -Syy

PKGS=(
	base           # Base system packages
	base-devel     # Base development packages
	linux          # linux kernel
	linux-firmware # linux firmware for supported hardware
	linux-headers  # headers needed by package manager to compile packages from source when needed
	lsb-release    # Linux Standard Base version reporting
	btrfs-progs    # filesystem utilities needed to manage btrfs
	pacman-contrib # for checkupdates and other package manager utilities
	avahi          # mDNS/DNS-SD service discovery
	networkmanager # network management daemon
	openssh        # secure shell daemon
	rsync          # remote file sync utility
	acpi           # acpi client
	acpid          # acpi event daemon
	acpi_call      # acpi client for calling ACPI methods
	tlp            # power management
	grub           # boot loader
	grub-btrfs     # btrfs support for grub
	efibootmgr     # EFI boot manager utility
	reflector      # find the fastest package mirrors
	man            # manual pages
	vim            # preferred text editor
	git            # version control system
	zsh            # preferred shell
)

# Include CPU micro-code package for the CPU this script is running on
CPU_NAME=$(lscpu | sed -nr 's/^Model name:.*\s*(Intel|AMD).*/\1/p' | tr '[:upper:]' '[:lower:]')
[[ ! $CPU_NAME =~ ^(intel|amd)$ ]] && echo "Unexpected CPU name: $CPU_NAME" && exit 1

echo "Including CPU micro-code package: $CPU_NAME-ucode"
PKGS+=("$CPU_NAME-ucode")

# The -K option generates a new keyring and populates it with the keys in the archlinux-keyring package
pacstrap -K /mnt ${PKGS[@]}

# Add btrsfs to the beginning of the MODULES array in /etc/mkinitcpio.conf
sed -e '/^MODULES=/s/(/(btrfs /' -i /mnt/etc/mkinitcpio.conf
sed -e '/^MODULES=/s/ )/)/' -i /mnt/etc/mkinitcpio.conf

if [ "$TARGET_ENCRYPT" = true ]; then
	# add encrypt between block and filesystems in /etc/mkinitcpio.conf
	sed -e '/^HOOKS=/s/filesystems/encrypt filesystems/' -i /mnt/etc/mkinitcpio.conf
fi

# Enable English US locales
sed -e '/en_US./s/^#*//g' -i ./locale.gen

cat <<EOF >/mnt/etc/locale.conf
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

cat <<EOF >/mnt/etc/vconsole.conf
KEYMAP=us
EOF

cat <<EOF >/mnt/etc/hostname
$TARGET_HOST_NAME
EOF

cat <<EOF >/mnt/etc/hosts
127.0.0.1 localhost
::1       localhost

127.0.0.1 $TARGET_HOST_NAME.local $TARGET_HOST_NAME
EOF

# copy installation scripts to target system for use after chroot and reboot
cp -r . /mnt/arch-install
