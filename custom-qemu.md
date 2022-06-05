__Replace `~` with your actual path, in my case, is my home folder.__

# Compile:
```
cd ~
sudo apt install ninja-build libglib libpixman-1-dev libspice-server-dev libusbredirparser-dev libusb-1.0-0-dev libpulse-dev libepoxy-dev
git clone https://gitlab.com/qemu-project/qemu.git\
cd qemu
git submodule init
git submodule update --recursive
./configure --enable-kvm --enable-spice --enable-libusb --enable-usb-redir --enable-opengl --enable-pa --audio-drv-list=pa
make -j8
```

# Edit XML:
```
  <devices>
    <emulator>~/qemu/build/qemu-system-x86_64</emulator>
    ....
  </devices>
  ....
  <qemu:commandline>
    <qemu:arg value="-L"/>
    <qemu:arg value="~/qemu/pc-bios"/>
    ....
  </qemu:commandline>
```

# Fix Apparmor:
## `/etc/apparmor.d/usr.sbin.libvirtd`
```
  .....
  ~/qemu/build/* PUx,
  ~/qemu/build/qemu-system-x86_64 rmix,
  ~/qemu/pc-bios/* PUx,
  ~/qemu/pc-bios/* r,
}
```
## `/etc/apparmor.d/abstractions/libvirt-qemu`
```
  ~/qemu/build/* PUx,
  ~/qemu/build/qemu-system-x86_64 rmix,
  ~/qemu/pc-bios/* PUx,
  ~/qemu/pc-bios/* r,
```
## `sudo systemctl restart apparmor.service`
Optional `sudo apt install apparmor-utils`

# Fix home folder permission (Optional):
`sudo setfacl -m u:libvirt-qemu:rx ~`
check with `sudo getfacl -e ~`
