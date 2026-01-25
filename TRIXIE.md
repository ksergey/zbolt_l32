# Raspbian trixie

## Display

`sudo vim /boot/firmware/cmdline.txt`

В конец строки (перед quiet или в самом конце) добавьте:

```bash
fbcon=rotate:2
```

Должно быть примерно так:

```bash
console=serial0,115200 console=tty1 root=PARTUUID=08f02beb-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=RU fbcon=rotate:2
```

Для X11:

Добавить в `/etc/X11/xorg.conf.d/90-rotate.conf`:

```
Section "Monitor"
    Identifier "DSI-1"
    Option "Rotate" "inverted"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "DSI-1"
EndSection

Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
```


## NetworkManager для всех юзеров

`sudo vim /etc/polkit-1/rules.d/10-networkmanager.rules`

Добавить:

```
polkit.addRule(function(action, subject) {
    if (action.id.startsWith("org.freedesktop.NetworkManager.")) {
        return polkit.Result.YES;
    }
});
```

Перезапустите polkit:

```
sudo systemctl restart polkit

```

