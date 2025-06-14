#!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "=== Arch Linux Full Setup Script ==="
read -p "Enter your desired username: " USERNAME
read -p "Enter hostname for your machine: " HOSTNAME
read -sp "Set password for root user: " ROOTPASS
echo
read -sp "Set password for user $USERNAME: " USERPASS
echo

# Variables
TIMEZONE="Asia/Kolkata"
ROOT_DISK="/dev/sda"
BOOT_PART="${ROOT_DISK}1"
ROOT_PART="${ROOT_DISK}2"

# Clean disk
sgdisk --zap-all $ROOT_DISK
wipefs -a $ROOT_DISK
parted -s $ROOT_DISK mklabel msdos
parted -s $ROOT_DISK mkpart primary ext4 1MiB 300MiB
parted -s $ROOT_DISK mkpart primary ext4 300MiB 100%

# Format and mount
mkfs.ext4 $BOOT_PART
mkfs.ext4 $ROOT_PART
mount $ROOT_PART /mnt
mkdir /mnt/boot
mount $BOOT_PART /mnt/boot

# Install base and packages
pacstrap -K /mnt base linux-lts linux-firmware intel-ucode nano grub networkmanager xorg xorg-xinit qtile alacritty firefox zram-generator sudo

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain $HOSTNAME" > /etc/hosts

echo "root:$ROOTPASS" | chpasswd
useradd -mG wheel $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

grub-install --target=i386-pc $ROOT_DISK
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet mce=ignore_ce"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
echo -e "blacklist snd\nblacklist snd_hda_intel\nblacklist snd_pcm" > /etc/modprobe.d/nosound.conf

# zRAM setup
cat <<ZCONF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
ZCONF

# Autostart Qtile via .xinitrc
echo "exec qtile start" > /home/$USERNAME/.xinitrc
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

EOF

echo "=== Done. Reboot to your new Arch system with Qtile!"
