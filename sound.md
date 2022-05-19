By default, pulseaudio will only be available to the current login user. If running the QEMU as the root user, the audio will not be available.
The common error thrown by QEMU looks like this: `Could not init 'pa' audio driver`.
The following step sets up a globally accessible Unix socket for the other users to access the audio interface.
__Note that any user on this PC will be able to use it, hence if you really worry about the security issue,
please consider assigning an user group to the socket and restrict its access(`load-module module-native-protocol-unix auth-group=sharepulse socket=/tmp/pulseaudio.sock`)__.

1. Edit `/etc/pulse/default.pa`. Look for a line starts with `load-module module-native-protocol-unix` and change it to `load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulseaudio.sock`.
2. Edit `/etc/pulse/client.conf`. Change/add: `default-server = unix:/tmp/pulseaudio.sock` and `autospawn = no`.
3. Copy `/home/CURRENT_USER/.config/pulse/cookie` to `/root/.config/pulse/cookie`, create any folder if they are not there.

# QEMU Command line
In you QEMU command line, add/modify:
```
-device hda-micro,audiodev=hda \
-audiodev pa,id=hda,server=unix\:/tmp/pulseaudio.sock \
-device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0 \
```
# Libvirt
1. Edit XML config, add to `<domain>`:
```
  <qemu:commandline>
.........
    <qemu:arg value="-device"/>
    <qemu:arg value="hda-micro,audiodev=snd0"/>
    <qemu:arg value="-audiodev"/>
    <qemu:arg value="pa,id=snd0,server=unix:/tmp/pulseaudio.sock"/>
  </qemu:commandline>
```
2. Append to `/etc/apparmor.d/abstractions/libvirt-qemu`:
```
  /etc/pulse/client.conf r,
  /etc/pulse/client.conf.d/ r,
  /etc/pulse/client.conf.d/* r,
  /tmp/pulseaudio.sock rw,
  /root/.config/pulse/* r,
  /root/.config/pulse/cookie k,
```
