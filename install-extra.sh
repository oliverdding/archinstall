#!/usr/bin/env bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.extra.log")
exec 2> >(tee "stderr.extra.log" >&2)

# read .env
while read line; do export $line; done < .env

install_package() {
    arch-chroot /mnt pacman -Sy --needed --noconfirm "$@"
}

install_package gcc gdb cmake ninja clang llvm lldb
install_package go gopls gofumpt
install_package lua luarocks lua-language-server
install_package helix taplo yaml-language-server bash-language-server marksman vscode-json-languageserver vscode-html-languageserver vscode-css-languageserver typescript-language-server
install_package nodejs npm prettier
install_package python python-setuptools python-pip python-lsp-server
install_package rustup cargo-update
install_package gopass bottom miniserve xplr neomutt ncmpcpp proxychains-ng jq tidy
install_package wqy-microhei wqy-bitmapfont wqy-zenhei adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts noto-fonts noto-fonts-cjk ttf-jetbrains-mono-nerd

echo -e "\n### adding archlinuxcn"
echo -e '[archlinuxcn]\nServer = https://mirrors.cloud.tencent.com/archlinuxcn/$arch' >>/mnt/etc/pacman.conf
install_package archlinuxcn-keyring
rm -fr /mnt/etc/pacman.d/gnupg
arch-chroot /mnt pacman-key --init
arch-chroot /mnt pacman-key --populate archlinux
arch-chroot /mnt pacman-key --populate archlinuxcn
install_package paru
install_package ttf-maple-sc-nerd
