#!/bin/bash

klipperRoot="${HOME}/klipper"
configRoot="${HOME}/printer_data/config"

# stop klipper
sudo systemctl stop klipper.service
sudo systemctl stop klipper-mcu.service

# linux mcu
config="${configRoot}/config.linux_mcu"
make -C "${klipperRoot}" clean KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" menuconfig KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" flash KCONFIG_CONFIG="${config}"

# fysetc s6 mcu
config="${configRoot}/config.fysetc_s6_v2_mcu"
make -C "${klipperRoot}" clean KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" menuconfig KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" KCONFIG_CONFIG="${config}"
make -C "${klipperRoot}" flash KCONFIG_CONFIG="${config}" FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_stm32f446xx_570053000751393038383735-if00

# start klipper
sudo systemctl start klipper.service
sudo systemctl start klipper-mcu.service
