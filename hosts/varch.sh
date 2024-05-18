#!/bin/env bash

# Installation specifics for a virtual machine

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/common.sh"

export HOST_NAME="varch"
export TARGET_DISK="/dev/vda"
export ENCRYPTED_ROOT=true
export BASE_PKGS="$(getPackages "$SCRIPT_DIR/pkgs/base.txt")"

# Initialize the target disk
function initializeTargetDisk() {
  # Partition the target disk
  sgdisk --clear \
         --new=1::+512M --typecode=1:ef00 --change-name=1:"EFI System Partition" \
         --new=2::+1G   --typecode=2:8300 --change-name=2:"Boot Partition" \
         --new=3::-1    --typecode=3:8300 --change-name=3:"LUKS Partition" \
         --print \
         "$TARGET_DISK"

  # Encrypt the root partition
  echo "Encrypting the root partition..."
  cryptsetup luksFormat "${TARGET_DISK}3"

  # Open the encrypted root partition
  echo "Opening the encrypted root partition..."
  cryptsetup open "${TARGET_DISK}3" cryptroot

  # Create the physical root volume
  pvcreate /dev/mapper/cryptroot

  # Create the root volume group
  vgcreate vg_root /dev/mapper/cryptroot

  # Create logical volumes for root and home
  lvcreate -L 20G -n root_lv vg_root
  lvcreate -l 100%FREE -n home_lv vg_root

  # Format the logical volumes
  mkfs.ext4 /dev/vg_root/root_lv
  mkfs.ext4 /dev/vg_root/home_lv

  # Format the boot partition
  mkfs.ext4 "${TARGET_DISK}2"

  # Format the EFI partition
  mkfs.fat -F32 "${TARGET_DISK}1"
}

# Mount the target file systems
function mountFileSystems() {
  # Mount the root volume
  mount /dev/vg_root/root_lv /mnt

  # Create mount points for boot and home
  mkdir -p /mnt/{boot, home}

  # Mount the boot and home volumes
  mount "${TARGET_DISK}2" /mnt/boot
  mount /dev/vg_root/home_lv /mnt/home

  # Mount the EFI partition
  mkdir /mnt/boot/efi
  mount "${TARGET_DISK}1" /mnt/boot/efi
}

# Install the base system packages
function bootstrap() {
  echo "Installing base packages: ${BASE_PKGS}"
  pacstrap -K /mnt "${BASE_PKGS[@]}"
  genfstab -U /mnt >>/mnt/etc/fstab
}

# Install additional packages
function installPackages() {
  echo "Installing additional packages..."
}

function configureInitCPIOHooks() {
  # Include encryption and LVM the initramfs image in /boot
  addInitCPIOHook 'encrypt' 'filesystems'
  addInitCPIOHook 'lvm2' 'filesystems'
  mkinitcpio -p linux
}

function enableServices() {
  # Enable network services
  systemctl enable avahi-daemon     # Avahi mDNS/DNS-SD daemon
  systemctl enable NetworkManager   # Network connection manager
  systemctl enable sshd             # OpenSSH server daemon

  # Enable power management services
  #systemctl enable tlp             # Advanced power management for Linux
  #systemctl enable acpid           # Advanced Configuration and Power Interface event daemon
  #systemctl enable upower          # Power management service

  #systemctl enable reflector.timer # Refresh mirrorlist for package managers
  #systemctl enable fstrim.timer    # Discard unused blocks on the filesystem
}
