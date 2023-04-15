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

install_package sway vulkan-validation-layers swaybg swayimg swayidle swaylock waybar bemenu bemenu-wayland clipman wlogout mako jq wl-clipboard grim slurp swappy xdg-desktop-portal-wlr xdg-user-dirs
install_package pipewire wireplumber pulsemixer
install_package alacritty qutebrowser
