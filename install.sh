#!/usr/bin/env bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log" >&2)

# read .env
while read line; do export $line; done < .env

script_name="$(basename "$0")"
dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

copy() {
    orig_file="$dotfiles_dir/$1"
    dest_file="/mnt/$1"

    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"

    rm -rf "$dest_file"

    cp -R "$orig_file" "$dest_file"
    echo "$dest_file <= $orig_file"
}

systemctl_enable() {
    echo "systemctl enable "$1""
    arch-chroot /mnt systemctl enable "$1"
}

echo -e "\n### checking network"

ping -c 1 8.8.8.8

echo -e "\n### checking boot mode"

if [ ! -f /sys/firmware/efi/fw_platform_size ]; then
    echo >&2 "Only support UEFI mode"
    exit 2
fi

echo -e "\n### setting up clock"

timedatectl set-ntp true
hwclock --systohc --utc

echo -e "\n### change mirror"

echo -e ${MIRROR} >/etc/pacman.d/mirrorlist

echo -e "\n### setting up partitions"

umount -R /mnt 2> /dev/null || true

lsblk -plnx size -o name "${DEVICE}" | xargs -n1 wipefs --all
sgdisk --clear "${DEVICE}" --new 1::-551MiB "${DEVICE}" --new 2::0 --typecode 2:ef00 "${DEVICE}"
sgdisk --change-name=1:ARCH --change-name=2:ESP "${DEVICE}"

PART_ROOT="$(ls ${DEVICE}* | grep -E "^${DEVICE}p?1$")"
PART_BOOT="$(ls ${DEVICE}* | grep -E "^${DEVICE}p?2$")"

echo -e "\n### formatting partitions"

mkfs.vfat -n "EFI" -F 32 "${PART_BOOT}"

mkfs.ext4 -L "ARCH" "${PART_ROOT}"

echo -e "\n### mounting partitions"

mount -o noatime,nodiratime "${PART_ROOT}" /mnt/

mkdir -p /mnt/boot/
mount  "${PART_BOOT}" /mnt/boot/

echo -e "\n### installing base system"

pacstrap /mnt base linux-zen linux-zen-headers linux-firmware zram-generator openssh iwd autoconf automake binutils fakeroot make pkgconf which sudo

genfstab -L /mnt >> /mnt/etc/fstab
echo "${HOSTNAME}" > /mnt/etc/hostname

echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "zh_CN.GB18030 GB18030" >> /mnt/etc/locale.gen
echo "zh_CN.GBK GBK" >> /mnt/etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "zh_CN GB2312" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

copy "etc/docker/daemon.json"
copy "etc/iwd/main.conf"
copy "etc/profile.d/10-xdg-base.sh"
copy "etc/profile.d/20-path.sh"
copy "etc/profile.d/30-gpg-agent.sh"
copy "etc/ssh/sshd_config.d/override"
copy "etc/sudoers.d/override"
copy "etc/systemd/journald.conf.d/override.conf"
copy "etc/systemd/network/20-wireless.network"
copy "etc/systemd/network/50-wired.network"
copy "etc/systemd/resolved.conf.d/default_dns.conf"
copy "etc/systemd/resolved.conf.d/fallback_dns.conf"
copy "etc/systemd/zram-generator.conf"
copy "etc/environment"
copy "etc/hosts"
copy "etc/locale.conf"
copy "etc/vconsole.conf"

echo s/{{HOSTNAME}}/${HOSTNAME}/ | xargs -n1 sed -i /mnt/etc/hosts -e

arch-chroot /mnt mkinitcpio -p linux-zen

echo -e "\n### install systemd-boot"

arch-chroot /mnt bootctl install
copy "boot/loader/loader.conf"
copy "boot/loader/entries/arch.conf"
copy "boot/loader/entries/arch-fallback.conf"
echo s/{{CPU}}/${CPU}/ | xargs -n1 sed -i /mnt/boot/loader/entries/arch.conf -e
echo s/{{CPU}}/${CPU}/ | xargs -n1 sed -i /mnt/boot/loader/entries/arch-fallback.conf -e

arch-chroot /mnt pacman -Sy --noconfirm ${CPU}-ucode

echo -e "\n### user specific"

arch-chroot /mnt useradd -m "$USERNAME"
for GROUP in wheel network video input docker; do
    arch-chroot /mnt groupadd -rf "$GROUP"
    arch-chroot /mnt gpasswd -a "$USERNAME" "$GROUP"
done
echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd
echo "root:$PASSWORD" | arch-chroot /mnt chpasswd

echo -e "\n### installing needed software"
arch-chroot /mnt pacman -Sy --noconfirm docker git git-delta starship zoxide fzf exa ripgrep pigz yadm bat neovim bash-completion

echo -e "\n### enabling useful systemd-module"

systemctl_enable "systemd-boot-update.service"
systemctl_enable "fstrim.timer"
systemctl_enable "docker.service"
systemctl_enable "iwd.service"
systemctl_enable "systemd-resolved.service"
systemctl_enable "systemd-networkd.socket"

echo -e "\n### installing user configurations"

arch-chroot /mnt sudo -u ${USERNAME} bash -c 'yadm clone https://github.com/oliverdding/dotfiles.archlinux.git --bootstrap'

echo -e "\n### Congratulations! Everythings are done! You can exec install-extra.sh on you favour"
