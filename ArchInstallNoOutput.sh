echo "=== Arch Linux 安裝腳本 ==="

# A. 設置日期和時間
echo "== 設置日期和時間 =="
timedatectl set-ntp true &>/dev/null
timedatectl set-timezone Asia/Hong_Kong &>/dev/null

echo "== 日期和時間設置完成 =="

# B. 磁碟分區
echo "== 分區磁碟 =="
DISK="/dev/sda"

echo "選擇磁碟: $DISK"
echo "刪除舊分區..."
wipefs -a -f -q $DISK &>/dev/null
echo "舊分區已刪除"

echo "創建 GPT 分區表..."
parted -s $DISK mklabel gpt &>/dev/null
echo "GPT 分區表已創建"

echo "創建 EFI 系統分區 (300M)..."
parted -s $DISK mkpart primary fat32 1MiB 301MiB &>/dev/null
parted -s $DISK set 1 esp on &>/dev/null
echo "EFI 分區已創建"

echo "創建根分區 (剩餘空間)..."
parted -s $DISK mkpart primary ext4 301MiB 100% &>/dev/null
echo "根分區已創建"

echo "格式化分區..."
mkfs.fat -F32 ${DISK}1 &>/dev/null
echo "EFI 分區已格式化為 FAT32"
mkfs.ext4 -F -q ${DISK}2 &>/dev/null
echo "根分區已格式化為 EXT4"

echo "掛載分區..."
mount ${DISK}2 /mnt &>/dev/null
echo "根分區已掛載到 /mnt"
mount --mkdir ${DISK}1 /mnt/boot &>/dev/null
echo "EFI 分區已掛載到 /mnt/boot"

echo "== 磁碟分區完成 =="

# C. 安裝基本系統
echo "== 安裝基本系統 =="
echo "開始安裝基本系統套件..."
pacstrap -K /mnt base linux linux-firmware &>/dev/null
echo "基本系統套件安裝完成"

echo "生成 fstab 文件..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab 文件生成完成"

UUID=$(blkid -s UUID -o value ${DISK}2)
echo "根分區的 UUID 為: $UUID"

cp /etc/systemd/network/* /mnt/etc/systemd/network/ &>/dev/null
echo "網絡配置文件已拷貝到新系統"

cp /root/ArchPostInstall.sh /mnt/root/ArchPostInstall.sh &>/dev/null
echo "ArchPostInstall.sh 腳本已拷貝到新系統"

echo "== 基本系統安裝完成 =="

# D. 配置系統
echo "進入 chroot 環境..."
arch-chroot /mnt bash <<EOF

echo "== 配置系統 =="

# 設置網絡
echo "啟用網絡服務..."
systemctl enable systemd-networkd &>/dev/null
systemctl enable systemd-resolved &>/dev/null
echo "網絡服務已啟用"

# 設置時區
echo "設置時區為 Asia/Hong_Kong..."
ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime &>/dev/null
hwclock --systohc &>/dev/null
echo "時區設置完成"

# 配置語言環境
echo "配置語言環境..."
echo "en_HK.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_HK.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen &>/dev/null
echo "語言環境生成完成"
echo "LANG=en_HK.UTF-8" > /etc/locale.conf
echo "語言環境配置完成"

# 設置主機名
echo "設置主機名為 ArchLinux..."
echo "ArchLinux" > /etc/hostname
echo "主機名設置完成"

# 設置 root 密碼
echo "設置 root 密碼..."
echo "root:Password" | chpasswd > /dev/null 2>&1
echo "root 密碼設置完成"

# 安裝 systemd-boot
echo "安裝 systemd-boot..."
bootctl install > /dev/null 2>&1
echo "systemd-boot 安裝完成"

bootctl update > /dev/null 2>&1
echo "systemd-boot 已更新"

# 運行 ArchPostInstall.sh
echo "運行 ArchPostInstall.sh 腳本..."
/root/ArchPostInstall.sh > /dev/null 2>&1
rm -rf /root/ArchPostInstall.sh
echo "ArchPostInstall.sh 腳本執行完成"


# 配置引導程序
echo "配置引導程序..."
cat <<BOOT > /boot/loader/loader.conf
default arch.conf
timeout 5
console-mode max
editor yes
BOOT
echo "loader.conf 配置完成"

cat <<ARCH > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
ARCH
echo "arch.conf 配置完成"

EOF

echo "== 系統配置完成 =="

# E. 退出並重啟
echo "== 完成安裝 =="
echo "卸載分區..."
umount -R /mnt > /dev/null 2>&1
echo "所有分區已卸載"

echo "安裝完成！即將重啟系統..."
reboot