# Crowsnest + CSI-камера (OV5647) на Raspberry Pi 3B+ / DietPi (Debian 13 trixie)

Инструкция собрана по реальной настройке. Стек: **libcamera → camera-streamer (raspi-вариант) → crowsnest**.
Старый режим `raspicam`/MMAL не используется.

Проверено на: Raspberry Pi 3 Model B+ Rev 1.3, DietPi на Debian 13 (trixie), arm64, ядро `6.18.x+rpt-rpi-v8`, камера Pi Camera v1 (OV5647).

---

## Известные подводные камни (коротко)

| Симптом | Причина | Решение |
|---|---|---|
| `rpicam-hello`: *only supports the Raspberry Pi platforms* | Не загружен модуль `bcm2835-isp` | Шаг 3 |
| `/boot/config.txt: No such file` | На новых DietPi конфиг лежит в `/boot/firmware/` | Шаг 1 |
| `/snapshot` отдаёт `Server Error`, в `camera-streamer` лог: `libcamera is not supported` | crowsnest поставил `generic`-сборку (только USB) | Шаг 5 |
| crowsnest ставит generic, хотя это Pi | Проверка `is_dietpi` ищет `/boot/config.txt` | Шаг 5 |

---

## 1. Конфигурация загрузки

На DietPi (Bookworm и новее) файл находится здесь: `/boot/firmware/config.txt`.

```bash
sudo nano /boot/firmware/config.txt
```

Должны быть строки:

```ini
camera_auto_detect=1
dtoverlay=vc4-kms-v3d
gpu_mem=128
```

Строки `start_x=1` быть **не должно** (старый стек конфликтует с libcamera).

Если камера не определяется автоматически, можно прописать оверлей явно:

| Камера | Оверлей |
|---|---|
| v1 (OV5647) | `dtoverlay=ov5647` |
| v2 (IMX219) | `dtoverlay=imx219` |
| v3 (IMX708) | `dtoverlay=imx708` |
| HQ (IMX477) | `dtoverlay=imx477` |

Подключать шлейф нужно **только при выключенном питании**, в CSI-разъём (не в DSI).

```bash
sudo reboot
```

---

## 2. Проверка на уровне ядра

```bash
uname -a                      # ядро должно быть родное: ...+rpt-rpi-v8
lsmod | grep -Ei "unicam|ov5647"
v4l2-ctl --list-devices       # должен быть unicam (/dev/video0, /dev/media0)
```

Если пакетов нет: `sudo apt install v4l-utils`.

В `media-ctl -d /dev/media0 -p` должен быть сенсор `ov5647` со связью `ENABLED,IMMUTABLE` к `unicam-image`.

---

## 3. Модуль ISP (`bcm2835-isp`) и автозагрузка

Без этого модуля `rpicam-*` не работают, а ошибка вводит в заблуждение.

```bash
sudo modprobe bcm2835-isp
lsmod | grep bcm2835_isp
v4l2-ctl --list-devices       # должен появиться bcm2835-isp (/dev/video13-16, 20-23)
```

Сделайте загрузку постоянной:

```bash
echo bcm2835-isp | sudo tee /etc/modules-load.d/bcm2835-isp.conf
```

Проверка камеры:

```bash
sudo apt install -y rpicam-apps      # если ещё не установлен
rpicam-hello --list-cameras
```

Ожидаемый вывод (путь понадобится для crowsnest):

```
0 : ov5647 [2592x1944 10-bit GBRG] (/base/soc/i2c0mux/i2c@1/ov5647@36)
```

Тест кадра:

```bash
rpicam-still -t 1000 -o /tmp/test.jpg && ls -l /tmp/test.jpg
```

---

## 4. Права пользователя

```bash
sudo usermod -aG video,render dietpi
```

Замените `dietpi` на своего пользователя. Группы применятся после перелогина или перезагрузки.

---

## 5. Установка crowsnest (с обходом проверки DietPi)

### Почему нужен обход

Скрипт crowsnest определяет DietPi функцией `is_dietpi`, которая проверяет наличие **`/boot/config.txt`** и каталога `/boot/dietpi`. На trixie конфиг лежит в `/boot/firmware/`, проверка не проходит, и ставится `mainsail-camera-streamer-generic` (только USB, без libcamera).

### Обход: символическая ссылка

```bash
ls -d /boot/dietpi                                   # должен существовать
sudo ln -s /boot/firmware/config.txt /boot/config.txt
ls -l /boot/config.txt
```

> Если каталога `/boot/dietpi` нет, вместо ссылки можно создать маркер Raspberry Pi OS: `sudo touch /etc/rpi-issue`.
> Побочный эффект: crowsnest будет считать систему Raspberry Pi OS.

### Установка

```bash
cd ~
git clone https://github.com/mainsail-crew/crowsnest.git   # если ещё не склонирован
cd crowsnest
sudo systemctl stop crowsnest 2>/dev/null
sudo apt remove -y mainsail-camera-streamer-generic camera-streamer-generic 2>/dev/null
sudo make config
sudo make install
```

Если `crowsnest.conf` уже настроен, при вопросах не перезаписывайте его.

### Проверка, что поставился raspi-вариант

```bash
cat /etc/apt/sources.list.d/mainsail.sources | head
dpkg -l | grep -i camera-streamer
ldd /usr/bin/camera-streamer | grep -i libcamera
```

Ожидаемо:

- в имени пакета есть `raspi` (`mainsail-camera-streamer-raspi`);
- в `ldd` есть строка с `libcamera.so`.

> **Ссылку `/boot/config.txt` не удаляйте**, иначе при обновлении crowsnest снова выберет generic-пакет.

---

## 6. Конфигурация crowsnest

Файл: `~/printer_data/config/crowsnest.conf`.

```ini
[crowsnest]
log_path: ~/printer_data/logs/crowsnest.log
log_level: verbose
delete_log: false
no_proxy: false

[cam 1]
mode: camera-streamer
port: 8080
device: /base/soc/i2c0mux/i2c@1/ov5647@36
resolution: 1280x720
max_fps: 15
```

Замечания:

- Путь в `device` берите из вывода `rpicam-hello --list-cameras`.
- Строки `enable_rtsp` и `rtsp_port` в этой конфигурации не нужны (в логе было предупреждение, что параметр не поддерживается).
- Для Pi 3B+ разумные значения: 1280x720 при 15 fps. 1080p возможен, но лучше не выше 15 fps.
- `no_proxy: false` означает, что camera-streamer слушает только `127.0.0.1` и доступен через nginx по `/webcam/`.

Перезапуск:

```bash
sudo systemctl restart crowsnest
tail -f ~/printer_data/logs/crowsnest.log
```

В логе нет сообщений об ошибках стримера, поэтому работоспособность проверяйте напрямую (шаг 7).

---

## 7. Проверка потока

```bash
pgrep -a camera-streamer
curl -s -o /tmp/snap.jpg http://localhost:8080/snapshot; file /tmp/snap.jpg
```

Ожидаемо: процесс запущен, `file` показывает `JPEG image data`.

> Проверять нужно обычным GET-запросом. `curl -I` (HEAD) у встроенного сервера camera-streamer возвращает 404, это не признак поломки.

Если `Server Error`, запустите стример вручную и смотрите его собственные сообщения:

```bash
sudo systemctl stop crowsnest
/usr/bin/camera-streamer \
  --camera-path=/base/soc/i2c0mux/i2c@1/ov5647@36 \
  --http-listen=127.0.0.1 --http-port=8080 \
  --camera-fps=15 --camera-width=1280 --camera-height=720 \
  --camera-type=libcamera --camera-format=YUYV \
  --log-debug 2>&1 | head -50
```

Сообщение `libcamera is not supported` означает, что стоит generic-сборка (вернитесь к шагу 5).

---

## 8. Подключение в Mainsail / Fluidd

Через nginx (рекомендуется), относительные адреса:

| Параметр | Значение |
|---|---|
| Stream URL | `/webcam/?action=stream` (или `/webcam/stream`) |
| Snapshot URL | `/webcam/?action=snapshot` (или `/webcam/snapshot`) |
| WebRTC (camera-streamer) | `/webcam/webrtc` |

В конфиге nginx должен быть блок:

```nginx
location /webcam/ {
    postpone_output 0;
    proxy_buffering off;
    proxy_ignore_headers X-Accel-Buffering;
    access_log off;
    error_log off;
    proxy_pass http://127.0.0.1:8080/;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/webcam/snapshot   # ожидается 200
```

Если nginx не используется, можно открыть порт напрямую: в секции `[crowsnest]` поставьте `no_proxy: true`, перезапустите сервис и используйте `http://IP_ПРИНТЕРА:8080/stream` и `http://IP_ПРИНТЕРА:8080/snapshot`.

---

## 9. Проверка после перезагрузки

```bash
sudo reboot
```

После загрузки:

```bash
lsmod | grep bcm2835_isp
rpicam-hello --list-cameras
systemctl status crowsnest
curl -s -o /tmp/snap.jpg http://localhost:8080/snapshot; file /tmp/snap.jpg
```

Если камера пропала после ребута, проверьте файл `/etc/modules-load.d/bcm2835-isp.conf` и вывод `journalctl -b | grep -i isp`.

---

## Чек-лист

- [ ] `/boot/firmware/config.txt`: `camera_auto_detect=1`, `dtoverlay=vc4-kms-v3d`, `gpu_mem=128`
- [ ] Ядро родное (`+rpt-rpi-v8`), `/dev/media0` и сенсор на месте
- [ ] `bcm2835-isp` загружен и прописан в `/etc/modules-load.d/`
- [ ] `rpicam-hello --list-cameras` показывает камеру
- [ ] Ссылка `/boot/config.txt` → `/boot/firmware/config.txt` создана
- [ ] Установлен `mainsail-camera-streamer-raspi`, `ldd` показывает `libcamera.so`
- [ ] `crowsnest.conf`: `mode: camera-streamer`, верный `device`
- [ ] `/snapshot` возвращает JPEG
- [ ] Камера добавлена в Mainsail/Fluidd

## Запасной вариант

Если `raspi`-сборка camera-streamer не работает с вашей версией libcamera (она линкуется под конкретную версию), камеру можно стримить без crowsnest: `rpicam-vid` + mediamtx. Камера и ISP при этом работают так же.
