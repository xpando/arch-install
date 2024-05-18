#!/bin/env bash

set -e

# validate that the first arg is not an empty string
if [ -z "$1" ]; then
  echo "Usage: $0 <hostname>"
  exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
[[ ! -f "$SCRIPT_DIR/hosts/$1.sh" ]] && echo "Error: No host install script found for $1." && exit 1

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hosts/$1.sh"

# Validate that required functions exist
[[ ! "$(type -t initializeTargetDisk)" == "function" ]] && echo "Error: missing initializeTargetDisk function." && exit 1
[[ ! "$(type -t mountFilesystems)" == "function" ]] && echo "Error: missing mountFilesystems function." && exit 1
[[ ! "$(type -t rateMirrors)" == "function" ]] && echo "Error: missing rateMirrors function." && exit 1
[[ ! "$(type -t bootstrap)" == "function" ]] && echo "Error: missing bootstrap function." && exit 1

initializeTargetDisk
mountFilesystems
rateMirrors
bootstrap

# Copy the installation scripts to the new root
mkdir -p /mnt/arch-install
cp -r . /mnt/arch-install

# Continue the installation in the new root
# arch-chroot /mnt /arch-install/configure.sh $1
arch-chroot /mnt