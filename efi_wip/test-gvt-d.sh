#!/bin/bash
export WORKSPACE=/home/rikka/Desktop/i915dev/
export PCILOC=0000:00:02.0
export PCIID=8086:1912

cd $WORKSPACE

echo "efi-framebuffer.0" > /sys/bus/platform/devices/efi-framebuffer.0/driver/unbind

cd ./i915_simple

# Create an UEFI disk that immediately shuts down the VM when booted
#mkdir -p tmpfat
#mount disk tmpfat
#mkdir -p tmpfat/EFI/BOOT
#umount tmpfat
#rmdir tmpfat
#systemctl stop display-manager.service
     echo $PCIID > /sys/bus/pci/drivers/vfio-pci/new_id
     echo $PCILOC> /sys/bus/pci/devices/$PCILOC/driver/unbind
     echo $PCILOC > /sys/bus/pci/drivers/vfio-pci/bind
#qemu-system-x86_64 -k en-us -name uefitest,debug-threads=on -nographic -vga none -serial stdio -m 2048 -M pc -cpu host -global PIIX4_PM.disable_s3=1 -global PIIX4_PM.disable_s4=1 -machine kernel_irqchip=on -nodefaults -rtc base=localtime,driftfix=slew -no-hpet -global kvm-pit.lost_tick_policy=discard -enable-kvm -bios $WORKSPACE/OVMF_CODE.fd -device vfio-pci,host=$PCILOC,romfile=`pwd`/i915ovmf.rom -device qemu-xhci,p2=8,p3=8 -device usb-kbd -device usb-tablet -drive format=raw,file=disk -usb  
# -device vfio-pci,host=$PCILOC,romfile=`pwd`/i915ovmf.rom \
# -hda /var/lib/libvirt/images/win10-intel.qcow2 \
# -device qxl-vga,bus=pci.0,addr=0x3 \
qemu-system-x86_64 -k en-us -name uefitest,debug-threads=on \
-vga none \
-chardev stdio,id=char0,logfile=serial.log,signal=off \
-serial chardev:char0 \
-device e1000,netdev=net0,mac=DE:AD:BE:EF:C3:42,bus=pci.0,addr=0x6 -netdev tap,id=net0 \
-m 2048 -M pc -cpu host -global PIIX4_PM.disable_s3=1 -global PIIX4_PM.disable_s4=1 -machine kernel_irqchip=on -nodefaults -rtc base=localtime,driftfix=slew -no-hpet -global kvm-pit.lost_tick_policy=discard -enable-kvm -bios $WORKSPACE/OVMF_CODE.fd \
-device vfio-pci,host=$PCILOC,id=hostdev0,bus=pci.0,addr=0x2,romfile="/usr/share/vgabios/i915ovmf.rom" \
-device qemu-xhci,p2=8,p3=8 -device usb-kbd -device usb-tablet -usb \
-fw_cfg name=opt/igd-opregion,file=../opregion.bin \
-fw_cfg name=opt/igd-bdsm-size,file=../bdsmSize.bin \
-device ivshmem-plain,memdev=ivshmem,bus=pci.0,addr=0x7 \
-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M \
-spice port=5900,addr=127.0.0.1,disable-ticketing,image-compression=off,seamless-migration=on
