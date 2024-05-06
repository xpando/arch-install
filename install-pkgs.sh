#!/bin/env bash

if [ $# -eq 0 ]; then
	echo "Error: No arguments provided. Please provide at least one package list that you want to install."
	exit 1
fi

paru -S --needed $(cat $@ | sed -e 's/#.*//' | sort | uniq)
