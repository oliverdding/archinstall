#!/usr/bin/env bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.gui.log")
exec 2> >(tee "stderr.gui.log" >&2)

# read .env
while read line; do export $line; done < .env

install_package() {
    arch-chroot /mnt pacman -Sy --needed --noconfirm "$@"
}

install_package gdm gnome-shell gnome-shell-extensions gnome-backgrounds gnome-bluetooth-3.0 gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-console gnome-control-center d-spy dconf-editor 
install_package firefox foliate newsflash motrix mission-center element-desktop 
install_package papirus-icon-theme 
install_package fcitx5-configtool-git fcitx5-git fcitx5-gtk-git fcitx5-qt5-git fcitx5-qt6-git fcitx5-rime-git
install_package pipewire pipewire-audio pipewire-alsa pipewire-pulse gst-plugin-pipewire gstreamer-vaapi wireplumber
install_package qt5-wayland qt6-wayland 
