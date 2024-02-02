# ZBolt L32

Конфиг моего принтера ZBolt L32 (сток):

* MCU: Fysetc S6 v2
* Host: Raspberry Pi 3B
* Display: какой-то дисплей с тачем
* Camera: какая-то камера


## Установка системы OS

[Инструкция](https://github.com/dw-0/kiauh/#-prerequisites)

Дополнительно ставим пакет `fbturbo` (может и не надо):

```sh
sudo apt install xserver-xorg-video-fbturbo
```

### Настройка дисплея + тач

Дисплей установлен вверх ногами, нужно его повернуть на 180. Для этого добавим в `/boot/cmdline.txt` аргумент:

```
... video=DSI-1:800x480@60,rotate=180 ...
```

Должно получиться что-то похожее на это:

```
console=serial0,115200 console=tty3 root=PARTUUID=ca9ceff5-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=RU logo.nologo consoleblank=0 vt.global_cursor_default=0 quite video=DSI-1:800x480@60,rotate=180
```

Дисплей перевернули, теперь нужно перевернуть тач. Для этого создадим файл `/etc/udev/rules.d/51-touchscreen.rules`:

```
ACTION=="add", ATTRS{name}=="10-0038generic ft5x06 (79)", ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1 1 0 0 1"
```

### Настройка камеры

Инструкция [здесь](https://crowsnest.mainsail.xyz/faq/how-to-setup-a-raspicam), но если вкратце, то необходимо
раскоментировать строку ниже в `/boot/config.txt`:

```
dtoverlay=vc4-kms-v3d
```

После перезагрузки должно появиться устройство:

```sh
/base/soc/i2c0mux/i2c@1/ov5647@36
```

## Установка Klipper

[Инструкция](https://github.com/dw-0/kiauh/#-download-and-use-kiauh)

Уже из `kiauh` ставим `Klipper`, `Moonraker`, `Crowsnest`, `Fluidd`, `KlipperScreen`

## Установка KAMP

[Инструкция](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging)

## Настройка Klipper

Все настройки в директории `config`

## Полезное

### Настройка Input Shaper

gcode:

```gcode
INPUT_SHAPER_X
INPUT_SHAPER_Y

```

после в консоли линукса:

```bash
~/klipper/scripts/calibrate_shaper.py /tmp/calibration_data_x_*.csv -o /tmp/shaper_calibrate_x.png
~/klipper/scripts/calibrate_shaper.py /tmp/calibration_data_y_*.csv -o /tmp/shaper_calibrate_y.png
```

### Калибровка потока

Взято [отсюда](https://github.com/Frix-x/klippain/blob/main/docs/features/flow_calibration.md)

```gcode
FLOW_MULTIPLIER_CALIBRATION PERIMETERS=3 PURGE_MM=0
```

Измеряем среднюю толщину стенки получившейся модели и вводим значение в макрос для получения значения потока:

```gcode
COMPUTE_FLOW_MULTIPLIER MEASURED_THICKNESS=xxx.xxx
```

