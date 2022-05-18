This repo contains the instructions on how to set up Intel GPU passthrough (GVT-d only), where the entire integrated GPU (iGPU) is isolated from the host and used by the guest VM.

# Prepare your iGPU
1. In your BIOS(called firmware settings nowadays), make sure that the iGPU is enabled and __used as the primary output device__.
2. Edit GRUB config to assign the iGPU for the passthrough driver, edit `/etc/default/grub`:
    1. Change GRUB_CMDLINE_LINUX_DEFAULT to:
    `GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on i915.enable_gvt=1 i915.enable_guc=0 iommu=pt earlymodules=vfio-pci vfio-pci.ids=8086:1912 video=vesafb:off,efifb:off,simplefb:off nofb nomodeset gfxpayload=text"`
    2. Some of the above changes are not necessary, try this:
    `GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt earlymodules=vfio-pci vfio-pci.ids=8086:1912"`
    3. I also added these:
    `GRUB_TERMINAL=console` and `GRUB_GFXPAYLOAD_LINUX=text`
3. Blacklist i915 driver, add the following lines to the begining of `/etc/modprobe.d/blacklist.conf`:
```
#blacklist snd_hda_intel
blacklist snd_hda_codec_hdmi
blacklist i915
options vfio-pci ids=8086:5916
install i915 /usr/bin/false
install intel_agp /usr/bin/false
```
4. Create `/etc/modules-load.d/kvm-gvt-d.conf` with the following content:
```
vfio-iommu-type1
vfio-mdev
vfio_pci
```
5. Update GRUB and initramfs with `update-grub` and `update-initramfs -u`.
6. Reboot.

# VM Creation
1. Install libvirt and QEMU, Google it if you are unsure about this!
2. Launch "Virtual Machine Manager", create a new virtual machine. (Step 2 of 5) The operating system should be "Windows 10". If it is not available, check "Include end of life operating systems" below.
3. (Step 3 of 5) Set the memory to 4GB or above, assign at least 2 cores. (Step 4 of 5) optionally create a virtual hard drive, 40GB or greater.
4. (Step 5 of 5) Name the VM, e.g. `win11-intel`, check the box "Customize configuration before install", then click on "Finish" button.
5. In the "Overview" section, make sure you change `Chipset` to `i440FX` and `Firmware` to `BIOS`. __SUPER IMPORTANT!__
6. Optionally change boot drive to `virtio` for a better performance
7. Optionally add a virtual optical drive or setup PXE for system installation.
8. Click on `Begin Installation` and install your Windows guest system.
9. Install iGPU driver inside the VM.
10. Shutdown.

# Add iGPU
1. In "Details" view, Click on "Add Hardware" button, choose "PCI Host Device", then your iGPU.
2. In console, type `virsh edit win11-intel`, to edit the XML configuration, you may replace `win11-intel` with your vm name.
3. Change the first line to `<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">`
4. Add these just before `</domain>`:
```
  <qemu:commandline>
    <qemu:arg value="-set"/>
    <qemu:arg value="device.hostdev0.x-igd-opregion=on"/>
    <qemu:arg value="-set"/>
    <qemu:arg value="device.hostdev0.x-igd-gms=1"/>
  </qemu:commandline>
```
5. Search for `hostdev`, make sure domain is `0x0000`, bus is `0x00`, slot is `0x02`, function is `0x00`, __each zero matters__! Example:
```
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </hostdev>
```
6. It is likely that iGPU clashes with the QXL virtual graphics, the solution is to assign a different slot to it, e.g. 0x09:
```
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'/>
    </video>
```
7. Boot VM and install the iGPU driver. Now you should have video output to your external physical monitor attached to the iGPU.
8. Now you can set the video in the Virtual Machine Manager to `none`, if you prefer Looking-glass (Display on the current monitor rather than a dedicated physical one).

# Optional steps (May help)
1. Follow https://github.com/patmagauran/i915ovmfPkg/wiki/Qemu-FwCFG-Workaround to get `opregion.bin` and [bdsmSize.bin](https://github.com/patmagauran/i915ovmfPkg/raw/master/bdsmSize.bin).
2. Copy both to `/usr/share/vgabios` with `sudo cp`.
3. Add these to `<qemu:commandline>` section of your XML configuration:
```
    <qemu:arg value="-fw_cfg"/>
    <qemu:arg value="name=opt/igd-opregion,file=/usr/share/vgabios/opregion.bin"/>
    <qemu:arg value="-fw_cfg"/>
    <qemu:arg value="name=opt/igd-bdsm-size,file=/usr/share/vgabios/bdsmSize.bin"/>
```

# Test Platform
1. `QEMU emulator version 4.2.1 (Debian 1:4.2-3ubuntu6.21)`
2. `Linux i7-6700 5.13.0-41-generic #46~20.04.1-Ubuntu SMP Wed Apr 20 13:16:21 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux`
3. Asus B150M-PLUS D3 with 32G 1600MHz DDR3 Ram
4. i7-6700 (HD530 Graphics)
5. GTX970

# References
1. https://github.com/patmagauran/i915ovmfPkg
2. https://wiki.archlinux.org/title/Intel_GVT-g
3. https://looking-glass.io/docs/B5.0.1/install
4. git@github.com:vivekmiyani/OSX_GVT-D.git
