#!/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <hostname>"
  exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
[[ ! -f "$SCRIPT_DIR/hosts/$1.sh" ]] && echo "Error: No host install script found for $1." && exit 1

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/hosts/$1.sh"

# Validate that the following required functions exist
[[ ! "$(type -t configureTimezone)" == "function" ]] && echo "Error: missing configureTimezone function." && exit 1
[[ ! "$(type -t configureLocale)" == "function" ]] && echo "Error: missing configureLocale function." && exit 1
[[ ! "$(type -t createDockerGroup)" == "function" ]] && echo "Error: missing createDockerGroup function." && exit 1
[[ ! "$(type -t createMyUser)" == "function" ]] && echo "Error: missing createMyUser function." && exit 1
[[ ! "$(type -t setRootPassword)" == "function" ]] && echo "Error: missing setRootPassword function." && exit 1
[[ ! "$(type -t configureHostName)" == "function" ]] && echo "Error: missing configureHostName function." && exit 1
[[ ! "$(type -t enableSudoForWheelGroup)" == "function" ]] && echo "Error: missing enableSudoForWheelGroup function." && exit 1
[[ ! "$(type -t installGrub)" == "function" ]] && echo "Error: missing installGrub function." && exit 1
[[ ! "$(type -t configureInitCPIOHooks)" == "function" ]] && echo "Error: missing configureInitCPIOHooks function." && exit 1
[[ ! "$(type -t setupAUR)" == "function" ]] && echo "Error: missing setupAUR function." && exit 1
[[ ! "$(type -t rateMirrors)" == "function" ]] && echo "Error: missing rateMirrors function." && exit 1
[[ ! "$(type -t installPackages)" == "function" ]] && echo "Error: missing installPackages function." && exit 1

configureTimezone
configureLocale
createDockerGroup
createMyUser
setRootPassword
configureHostName $HOST_NAME
enableSudoForWheelGroup
installGrub
configureInitCPIOHooks
setupAUR
rateMirrors
installPackages
