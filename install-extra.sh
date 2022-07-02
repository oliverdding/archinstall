#!/bin/sh

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.extra.log")
exec 2> >(tee "stderr.extra.log" >&2)

# read .env
while read line; do export $line; done < .env

install_package() {
    arch-chroot /mnt pacman -Sy --needed --noconfirm "$@"
}

install_package gcc gdb cmake ninja clang lldb
install_package go
install_package lua
install_package python python-setuptools python-pip python-pipenv
install_package jdk17-openjdk jre17-openjdk openjdk17-doc openjdk17-src scala scala-sources scala-docs maven gradle gradle-src gradle-doc sbt
install_package cargo-flamegraph cargo-bloat cargo-edit rust cargo rust-src
install_package pass bandwhich bottom bat dua-cli gitui gping graphviz hexyl oha onefetch xplr procs miniserve
install_package wqy-microhei wqy-bitmapfont wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts noto-fonts noto-fonts-cjk
install_package rust-analyzer yaml-language-server vscode-json-languageserver gopls bash-language-server lua-language-server pyright texlab vscode-css-languageserver deno
install_package python-debugpy delve

echo -e "\n### adding archlinuxcn"
echo -e '[archlinuxcn]\nServer = https://mirrors.cloud.tencent.com/archlinuxcn/$arch' >>/mnt/etc/pacman.conf
install_package archlinuxcn-keyring
rm -fr /mnt/etc/pacman.d/gnupg
arch-chroot /mnt pacman-key --init
arch-chroot /mnt pacman-key --populate archlinux
arch-chroot /mnt pacman-key --populate archlinuxcn
install_package paru
install_package ttf-nerd-fonts-symbols-mono noto-fonts-emoji powerline-fonts nerd-fonts-fira-code nerd-fonts-jetbrains-mono nerd-fonts-source-code-pro nerd-fonts-ubuntu-mono
