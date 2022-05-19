#!/bin/bash
# Boot your PC with a Live CD (e.g. Ubuntu) in Legacy (BIOS) mode and run this script with sudo to dump the Intel iGPU vBIOS.

echo 1 > /sys/devices/pci0000:00/0000:00:02.0/rom
cat /sys/devices/pci0000:00/0000:00:02.0/rom > vbios.dump
echo 0 > /sys/devices/pci0000:00/0000:00:02.0/rom
