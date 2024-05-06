#!/bin/env bash

# Installs packages from one or more package list text files. Use this after the system has been instsalled
# and rebooted.

if [ $# -eq 0 ]; then
	echo "Error: No package list(s) provided. Please provide at least one package list that you want to install."
	exit 1
fi

paru -S --needed $(cat $@ | sed -e 's/#.*//' | sort | uniq)
