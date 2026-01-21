echo "=== Arch Linux 安裝腳本 ==="
echo ""

# A. 設置日期和時間
echo "== 設置日期和時間 =="

echo "[Action] 啟用 NTP..."
timedatectl set-ntp true
echo "[OK] NTP 已啟用"

echo "[Action] 設置時區為 Asia/Hong_Kong..."
timedatectl set-timezone Asia/Hong_Kong
echo "[OK] 時區設置完成"

echo "== 日期和時間設置完成 =="
echo "--------------------------------------------------"
echo ""

# B. 磁碟分區
echo "== 分區磁碟 =="
DISK="/dev/sda"

echo "[Action] 選擇磁碟: $DISK"
echo "[Action] 刪除舊分區..."
wipefs -a -f -q $DISK
echo "[OK] 舊分區已刪除"

echo "[Action] 創建 GPT 分區表..."
parted -s $DISK mklabel gpt
echo "[OK] GPT 分區表已創建"

echo "[Action] 創建 EFI 系統分區 (300M)..."
parted -s $DISK mkpart primary fat32 1MiB 301MiB
parted -s $DISK set 1 esp on
echo "[OK] EFI 分區已創建"

echo "[Action] 創建根分區 (剩餘空間)..."
parted -s $DISK mkpart primary ext4 301MiB 100%
echo "[OK] 根分區已創建"

echo "[Action] 格式化 EFI 分區..."
mkfs.fat -F32 ${DISK}1
echo "[OK] EFI 分區格式化為 FAT32"

echo "[Action] 格式化根分區..."
mkfs.ext4 -F -q ${DISK}2
echo "[OK] 根分區格式化為 EXT4"

echo "[Action] 掛載根分區到 /mnt..."
mount ${DISK}2 /mnt
echo "[OK] 根分區已掛載到 /mnt"

echo "[Action] 掛載 EFI 分區到 /mnt/boot..."
mount --mkdir ${DISK}1 /mnt/boot
echo "[OK] EFI 分區已掛載到 /mnt/boot"

echo "== 磁碟分區完成 =="
echo "--------------------------------------------------"
echo ""

# C. 安裝基本系統
echo "== 安裝基本系統 =="

echo "[Action] 開始安裝基本系統套件..."
pacstrap -K /mnt base linux linux-firmware
echo "[OK] 基本系統套件安裝完成"

echo "[Action] 生成 fstab 文件..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "[OK] fstab 文件生成完成"

UUID=$(blkid -s UUID -o value ${DISK}2)
echo "[Info] 根分區的 UUID 為: $UUID"

echo "[Action] 拷貝網絡配置文件到新系統..."
cp /etc/systemd/network/* /mnt/etc/systemd/network/
echo "[OK] 網絡配置文件已拷貝"

echo "[Action] 拷貝 ArchPostInstall.sh 到新系統..."
cp /root/ArchPostInstall.sh /mnt/root/ArchPostInstall.sh
echo "[OK] ArchPostInstall.sh 腳本已拷貝"

echo "== 基本系統安裝完成 =="
echo "--------------------------------------------------"
echo ""

# D. 配置系統
echo "進入 chroot 環境..."
arch-chroot /mnt bash <<EOF

echo "== 配置系統 =="

echo "[Action] 啟用 systemd-networkd 服務..."
systemctl enable systemd-networkd
echo "[OK] systemd-networkd 已啟用"

echo "[Action] 啟用 systemd-resolved 服務..."
systemctl enable systemd-resolved
echo "[OK] systemd-resolved 已啟用"

echo "[Action] 設置時區為 Asia/Hong_Kong..."
ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
hwclock --systohc
echo "[OK] 時區設置完成"

echo "[Action] 配置語言環境 (生成 locale) ..."
echo "en_HK.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_HK.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "[OK] 語言環境生成完成"

echo "[Action] 設置 /etc/locale.conf 文件..."
echo "LANG=en_HK.UTF-8" > /etc/locale.conf
echo "[OK] 語言環境配置完成"

echo "[Action] 設置主機名為 ArchLinux..."
echo "ArchLinux" > /etc/hostname
echo "[OK] 主機名設置完成"

echo "[Action] 設置 root 密碼..."
echo "root:Password" | chpasswd
echo "[OK] root 密碼設置完成"

echo "[Action] 安裝 systemd-boot..."
bootctl install
echo "[OK] systemd-boot 安裝完成"

echo "[Action] 更新 systemd-boot..."
bootctl update
echo "[OK] systemd-boot 已更新"

echo "[Action] 運行 ArchPostInstall.sh 腳本..."
/root/ArchPostInstall.sh
rm -rf /root/ArchPostInstall.sh
echo "[OK] ArchPostInstall.sh 執行完成"

echo "[Action] 配置 loader.conf..."
cat <<BOOT > /boot/loader/loader.conf
default arch.conf
timeout 5
console-mode max
editor yes
BOOT
echo "[OK] loader.conf 配置完成"

echo "[Action] 配置 arch.conf..."
cat <<ARCH > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
ARCH
echo "[OK] arch.conf 配置完成"

echo "== 配置系統完成 =="
EOF

echo "--------------------------------------------------"
echo ""

# E. 退出並重啟
echo "== 完成安裝 =="

echo "[Action] 卸載所有分區..."
umount -R /mnt
echo "[OK] 所有分區已卸載"

echo "[Action] 系統即將重啟..."
reboot