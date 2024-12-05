echo "=== Arch Linux 安裝腳本 ==="

# A. 設置日期和時間
echo "== 設置日期和時間 =="
timedatectl set-ntp true
timedatectl set-timezone Asia/Hong_Kong

# B. 磁碟分區
echo "== 分區磁碟 =="
DISK="/dev/sda"

echo "刪除舊分區..."
wipefs -a -f -q $DISK

echo "創建 GPT 分區表..."
parted -s $DISK mklabel gpt

echo "創建 EFI 系統分區 (300M)..."
parted -s $DISK mkpart primary fat32 1MiB 301MiB
parted -s $DISK set 1 esp on

echo "創建根分區 (剩餘空間)..."
parted -s $DISK mkpart primary ext4 301MiB 100%

echo "格式化分區..."
mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F -q ${DISK}2

echo "掛載分區..."
mount ${DISK}2 /mnt
mount --mkdir ${DISK}1 /mnt/boot

# C. 安裝基本系統
echo "== 安裝基本系統 =="
pacstrap -K /mnt base linux linux-firmware

echo "生成 fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

UUID=$(blkid -s UUID -o value ${DISK}2)

cp /etc/systemd/network/* /mnt/etc/systemd/network/

# D. 配置系統
echo "進入 chroot..."
arch-chroot /mnt bash <<EOF

echo "== 配置系統 =="
# 設置網絡
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# 設置時區
ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
hwclock --systohc

# 配置語言環境
echo "en_HK.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_HK.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_HK.UTF-8" > /etc/locale.conf

# 設置主機名
echo "ArchLinux" > /etc/hostname

# 更新 pacman
pacman -Syyu --noconfirm
pacman -S vim --noconfirm

# 設置 root 密碼
echo "設置 root 密碼:"
echo "root:Password" | chpasswd

# 安裝 systemd-boot
bootctl install
bootctl update

# 配置引導程序
cat <<BOOT > /boot/loader/loader.conf
default arch.conf
timeout 5
console-mode max
editor yes
BOOT

cat <<ARCH > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
ARCH

EOF

# E. 退出並重啟
echo "== 完成安裝 =="
umount -R /mnt
echo "安裝完成！"
reboot