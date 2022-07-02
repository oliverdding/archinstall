#!/bin/sh

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.extra.log")
exec 2> >(tee "stderr.extra.log" >&2)

install_package() {
    arch-chroot /mnt pacman -Sy --needed --noconfirm "$@"
}

install_package mesa wayland xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome wl-clipboard
install_package gnome gnome-tweaks
install_package firefox code
