# ZBolt L32

use kiauh

# Config

# KlipperScreen installation

Additional packages:
```sh
sudo apt install xserver-xorg-video-fbturbo
```

Add to `/boot/cmdline.txt` (rotate display):
```
video=DSI-1:800x480@60,rotate=180
```

Add to `/etc/udev/rules.d/51-touchscreen.rules` (rotate touchscreen):
```
ACTION=="add", ATTRS{name}=="10-0038generic ft5x06 (79)", ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1 1 0 0 1"
```

# Crowsnest

Instruction here:
https://crowsnest.mainsail.xyz/faq/how-to-setup-a-raspicam

Uncoment `dtoverlay=vc4-kms-v3d` in `/boot/config.txt`

List cameras:
```
$ libcamera-hello --list-cameras
```
