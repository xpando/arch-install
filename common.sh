#!/bin/env bash

set -e

# Common functions used during installation

function getPackages() {
  if [ $# -eq 0 ]; then
    echo "Error: No package list(s) provided. Please provide at least one package list that you want to install."
    exit 1
  fi

  cat "$@" | sed -e 's/#.*//' | sort | uniq
}

function rateMirrors() {
  echo "Ranking the fastest mirrors..."
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
  reflector --save /etc/pacman.d/mirrorlist --protocol https --country US --sort rate --age 6 --latest 10
}

function enableAUR() {
  echo "Installing yay AUR package manager"
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay
  makepkg -si
  popd

  echo "Installing Paru AUR package manager"
  yay -S paru
}

function configureTimezone() {
  ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  hwclock --systohc
}

function configureLocale() {
  sed -e '/en_US./s/^#*//g' -i ./locale.gen

cat <<EOF >/etc/locale.conf
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

cat <<EOF >/etc/vconsole.conf
KEYMAP=us
EOF
}

function createDockerGroup() {
  groupadd docker
}

function setRootPassword() {
  echo "Set password for root:"
  passwd
}

function createMyUser() {
  useradd -mg users -G wheel,docker -s /usr/bin/zsh david
  usermod -c 'David Findley' david
  echo "Set password for user david:"
  passwd david
}

function configureHostName() {
  hostName=$1
  # validate hostname argument exists
  if [ -z "$hostName" ]; then
    echo "Error: No hostname argument provided to configureHostName($hostName) function. Exiting."
    exit 1
  fi

cat <<EOF >/etc/hostname
$TARGET_HOST_NAME
EOF

cat <<EOF >/etc/hosts
127.0.0.1 localhost $TARGET_HOST_NAME.local $TARGET_HOST_NAME
::1       localhost $TARGET_HOST_NAME.local $TARGET_HOST_NAME
EOF
}

function enableSudoForWheelGroup() {
  mkdir -p /etc/sudoers.d
  echo '%wheel ALL=(ALL) ALL' >/etc/sudoers.d/10-wheel
}

# Args: $1 = encryptedRootPartition
function installGrub() {
  _encryptedRootPartition=$1

  if [ ! -z "$_encryptedRootPartition" ]; then
    # Backup the original grub configuration file, if it already exists then use it as the source
    if [ -f /etc/default/grub.orig ]; then
      cp /etc/default/grub.orig /etc/default/grub
    else
      cp /etc/default/grub /etc/default/grub.orig
    fi

    _blkId="$(blkid -s UUID -o value "$_encryptedRootPartition")"
    sed -i 's|\(^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)|\1 cryptdevice=UUID='"$_blkId"':cryptroot root=/dev/mapper/cryptroot|' /etc/default/grub
  fi

  mkdir -p /boot/efi
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
}

# Args: $1 = hook, $2 = the name of the hook to add the new hook before
function addInitCPIOHook() {
  # validate that arg 1 has a non-empty string value
  if [ -z "$1" ]; then
    echo "Error: No hook argument provided to add_mkinitcpioHook($hook, $before) function. Exiting."
    exit 1
  fi

  # validate that arg 2 has a non-empty string value
  if [ -z "$2" ]; then
    echo "Error: No mkinitcpio.conf file argument provided to add_mkinitcpioHook($hook, $before) function. Exiting."
    exit 1
  fi

  if grep -q "^HOOKS=(.*$1 $2" /etc/mkinitcpio.conf; then
    echo "Error: /etc/mkinitcpio.conf already contains '$1 $2' in the HOOKS line."
    exit 0
  fi

  sed -e "/^HOOKS=/s/$2/$1 $2/" -i /etc/mkinitcpio.conf
}
