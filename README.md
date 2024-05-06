# Getting Started

Boot the arch installation media

Clone git repo with installation configuration and scripts

```shell
pacman -Sy
pacman -S git
git clone https://github.com/xpando/arch-install.git
```

# Remote Isntallation

Once the Arch installation ISO is booted installation can be done from another machine connected via SSH for easier copy paste and SCP of any keys etc.

```shell
# SSH required password so set a root password for the isntallation session
passwd

# Get IP address to use with SSH/SCP from another machine
ip a
```

# Disk Partitioning and File Systems

First source the env config for the host being installed

```shell
export $(envsubst < host-beebox.env)
export $(envsubst < host-corsairone.env)
export $(envsubst < host-varch.env)
```

Partition the disk(s)

```shell
./partition-disks.sh
```

# Base Installation:

```shell
# Set timezone
timedatectl set-timezone America/Los_Angeles

# Verify that NTP service is enabled
timedatectl

# Rate and use the fastest mirrors
reflector --save /etc/pacman.d/mirrorlist --protocol https --country US --sort rate --age 6 --latest 10

# Update package DB
pacman -Syy

# Minimal system initialation.
# ./install-pkgs.sh can be used after first boot into the new system to complete the system setup
./pacstrap.sh

# Enter the newly initialized system for further configuration
arch-chroot /mnt

# Timezone and hardware clock
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

# Generate locales
vim /etc/locale.gen # uncomment the desired locales
locale-gen
echo -e "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n" > /etc/locale.conf
echo -e "KEYMAP=us" > /etc/vconsole.conf

# set host name
echo "beebox" >> /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.0.1\t$(cat /etc/hostname).local,$(cat /etc/hostname)\n" > /etc/hosts

# Boot loader (GRUB)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# My Corsairone BIOS requires the --romovable flag :(
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

# if using Luks encryption, get the device id of the BTRFS partition
blkid -s UUID -o value $TARGET_BTRFS_PART

# Add encryption kernel parameters to grub config. For example:
# cryptdevice=UUID=4fc38db5-18be-46b8-9a32-b8c7f593c85c:archlinux root=/dev/mapper/archlinux
vim /etc/default/grub

# Create the Grub configuration
grub-mkconfig -o /boot/grub/grub.cfg

# Add btrfs to the MODULES= section
# Add the encrypt hook between 'block' and 'filesystems' if using Luks to the HOOKE= section
vim /etc/mkinitcpio.conf

# Enable networking
systemctl enable avahi-daemon
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable tlp
systemctl enable acpid
systemctl enable reflector.timer
systemctl enable fstrim.timer     # For SSDs
systemctl enable upower

# Set root password
passwd

# Create user
groupadd docker
useradd -mg users -G wheel,docker -s /usr/bin/zsh david

# Set user full name (optional)
usermod -c 'David Findley' david

# Set user's password
passwd david

# Enable sudo
echo "david ALL=(ALL) ALL" > /etc/sudoers.d/david

# or uncomment wheel group in main conf with
visudo

exit
swapoff /mnt/swap/swapfile

umount -R /mnt
reboot
```

# Post Install Setup

## AUR Helpers

```shell
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Paru, AUR helper like Yay but written in Rust
yay -S paru-bin
```

## Install desired packages from package lists. For example:

```shell
./install-pkgs pkgs-base.txt pkgs-audio.txt pkgs-video-amd.txt
```

## NVIDIA Configuration

```shell
# See: https://github.com/korvahannu/arch-nvidia-drivers-installation-guide
# Add kernal parameters to GRUB
sudo vim /etc/default/grub

# Append nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT

sudo vim /etc/mkinitcpio.conf

# MODULES=(nvidia nvidia_uvm nvidia_drm)
# Remove the word "kms" from HOOKS()

sudo mkinitcpio -p linux
```

Auto build a new boot image with NVIDIA kernel modules when either the Linux kernel is updated or the NVIDIA drivers are updated.

```shell
sudo vim /etc/pacman.d/hooks/nvidia.hook
```

Add this content:

```
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

# Adjust line(6) above to match your driver, e.g. Target=nvidia-dkms
# Change line(7) above, if you are not using the regular kernel For example, Target=linux-lts

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
```

```
cat /etc/modprobe.d/nvidia.conf

blacklist nouveau
options nvidia_drm modeset=1 fbdev=1 NVreg_PreserveVideoMemoryAllocations=1
```

# Timeshift and Timeshift-Autosnap

```shell
paru -S timeshift-bin timeshift-autosnap
timeshift --list-devices
timeshift --snapshot-device /dev/vda2
```

# Tips

List Disks

```shell
lsblk -o NAME,FSTYPE,PARTUUID,PARTLABEL,LABEL,MOUNTPOINT,FSTYPE,FSUSE%
```

Find the UUID of a partition:

```
# Get uuid of partition
blkid -s UUID -o value /dev/vda2
```

Connect to WiFi using network manager text UI

```shell
nmtui
```

Enable Parallel Package Downloads

```shell
# uncomment ParallelDownloads = 5 line in pacman.conf
sudo vim /etc/pacman.conf
```

Better TTY Fonts

```shell
paru -S powerline-fonts-git
sudo vim /etc/vconsole.conf

# Add this line:
FONT=ter-powerline-v20n
```

Gnome Files Thumbnails

```shell
sudo pacman -S --needed tumbler poppler-glib ffmpegthumbnailer freetype2 libgsf raw-thumbnailer totem evince
```

Wayland w/NVIDIA

```shell
sudo pacman -S --needed xorg-xwayland xorg-xlsclients glfw-wayland
```
