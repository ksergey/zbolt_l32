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


