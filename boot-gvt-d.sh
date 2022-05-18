#!/bin/bash
export WORKSPACE=/home/rikka/Desktop/i915dev/
export PCILOC=0000:00:02.0
export PCIID=8086:1912

cd $WORKSPACE

# In my case, the EFIFB uses the iGPU, so we have to unbind it.
# Check `cat /proc/iomem`, look for PCILOC and assigned driver.
echo "efi-framebuffer.0" > /sys/bus/platform/devices/efi-framebuffer.0/driver/unbind

echo $PCIID > /sys/bus/pci/drivers/vfio-pci/new_id
echo $PCILOC> /sys/bus/pci/devices/$PCILOC/driver/unbind
echo $PCILOC > /sys/bus/pci/drivers/vfio-pci/bind

# OS install:
# -device qxl-vga,bus=pci.0,addr=0x3 \
# Normal use with looking-glass:
# -vga none \
qemu-system-x86_64 -k en-us -name uefitest,debug-threads=on \
-vga none \
-chardev stdio,id=char0,logfile=serial.log,signal=off \
-serial chardev:char0 \
-device e1000,netdev=net0,mac=DE:AD:BE:EF:C3:42,bus=pci.0,addr=0x6 -netdev tap,id=net0 \
-smp 4,sockets=1,cores=2,threads=2 \
-m 8192 -M pc -cpu host -global PIIX4_PM.disable_s3=1 -global PIIX4_PM.disable_s4=1 -machine kernel_irqchip=on -nodefaults -rtc base=localtime,driftfix=slew -no-hpet -global kvm-pit.lost_tick_policy=discard -enable-kvm \
-device qemu-xhci,p2=8,p3=8,bus=pci.0,addr=0x9 -device usb-kbd -device usb-tablet -usb \
-device ivshmem-plain,memdev=ivshmem,bus=pci.0,addr=0x7 \
-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=32M \
-boot menu=on,strict=on \
-blockdev '{"driver":"file","filename":"/var/lib/libvirt/images/win10-intel.qcow2","node-name":"libvirt-1-storage","auto-read-only":true,"discard":"unmap"}' \
-blockdev '{"node-name":"libvirt-1-format","read-only":false,"driver":"qcow2","file":"libvirt-1-storage","backing":null}' \
-device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x8,drive=libvirt-1-format,id=virtio-disk0,bootindex=1 \
-device vfio-pci,host=$PCILOC,id=hostdev0,bus=pci.0,addr=0x2,x-igd-gms=1,x-igd-opregion=on \
-fw_cfg name=opt/igd-opregion,file=opregion.bin \
-fw_cfg name=opt/igd-bdsm-size,file=bdsmSize.bin \
-device ich9-intel-hda,id=sound0,bus=pci.0,addr=0x1b \
-device hda-micro,audiodev=snd0 \
-audiodev pa,id=snd0,server=unix\:/tmp/pulseaudio.sock \
-device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0 \
-spice port=5900,addr=127.0.0.1,disable-ticketing,image-compression=off,seamless-migration=on
