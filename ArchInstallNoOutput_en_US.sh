echo "=== Arch Linux Installation Script ==="
echo ""

# A. Set Date and Time
echo "== Setting Date and Time =="
echo "[Action] Enabling NTP..."
timedatectl set-ntp true &>/dev/null
echo "[OK] NTP enabled"

echo "[Action] Setting timezone to Asia/Hong_Kong..."
timedatectl set-timezone Asia/Hong_Kong &>/dev/null
echo "[OK] Timezone set"

echo "== Date and Time Configuration Completed =="
echo "--------------------------------------------------"
echo ""

# B. Disk Partitioning
echo "== Disk Partitioning =="
DISK="/dev/sda"

echo "[Action] Selecting disk: $DISK"
echo "[Action] Removing old partitions..."
wipefs -a -f -q $DISK &>/dev/null
echo "[OK] Old partitions removed"

echo "[Action] Creating GPT partition table..."
parted -s $DISK mklabel gpt &>/dev/null
echo "[OK] GPT partition table created"

echo "[Action] Creating EFI partition (300MB)..."
parted -s $DISK mkpart primary fat32 1MiB 301MiB &>/dev/null
parted -s $DISK set 1 esp on &>/dev/null
echo "[OK] EFI partition created"

echo "[Action] Creating root partition (remaining space)..."
parted -s $DISK mkpart primary ext4 301MiB 100% &>/dev/null
echo "[OK] Root partition created"

echo "[Action] Formatting EFI partition..."
mkfs.fat -F32 ${DISK}1 &>/dev/null
echo "[OK] EFI partition formatted as FAT32"

echo "[Action] Formatting root partition..."
mkfs.ext4 -F -q ${DISK}2 &>/dev/null
echo "[OK] Root partition formatted as EXT4"

echo "[Action] Mounting root partition to /mnt..."
mount ${DISK}2 /mnt &>/dev/null
echo "[OK] Root partition mounted to /mnt"

echo "[Action] Mounting EFI partition to /mnt/boot..."
mount --mkdir ${DISK}1 /mnt/boot &>/dev/null
echo "[OK] EFI partition mounted to /mnt/boot"

echo "== Disk Partitioning Completed =="
echo "--------------------------------------------------"
echo ""

# C. Install Base System
echo "== Installing Base System =="
echo "[Action] Installing base packages..."
pacstrap -K /mnt base linux linux-firmware &>/dev/null
echo "[OK] Base packages installed"

echo "[Action] Generating fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab &>/dev/null
echo "[OK] fstab generated"

UUID=$(blkid -s UUID -o value ${DISK}2)
echo "[Info] Root partition UUID: $UUID"

echo "[Action] Copying network configuration to new system..."
cp /etc/systemd/network/* /mnt/etc/systemd/network/ &>/dev/null
echo "[OK] Network configuration copied"

echo "[Action] Copying ArchPostInstall.sh to new system..."
cp /root/ArchPostInstall.sh /mnt/root/ArchPostInstall.sh &>/dev/null
echo "[OK] ArchPostInstall.sh copied"

echo "== Base System Installation Completed =="
echo "--------------------------------------------------"
echo ""

# D. Configure the New System
echo "Entering chroot environment..."
arch-chroot /mnt bash <<EOF

echo "== Configuring the System =="

echo "[Action] Enabling systemd-networkd service..."
systemctl enable systemd-networkd &>/dev/null
echo "[OK] systemd-networkd enabled"

echo "[Action] Enabling systemd-resolved service..."
systemctl enable systemd-resolved &>/dev/null
echo "[OK] systemd-resolved enabled"

echo "[Action] Setting timezone to Asia/Hong_Kong..."
ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime &>/dev/null
hwclock --systohc &>/dev/null
echo "[OK] Timezone set"

echo "[Action] Configuring locale (generating locales)..."
echo "en_HK.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_HK.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen &>/dev/null
echo "[OK] Locales generated"

echo "[Action] Setting /etc/locale.conf..."
echo "LANG=en_HK.UTF-8" > /etc/locale.conf
echo "[OK] Locale configuration completed"

echo "[Action] Setting hostname to ArchLinux..."
echo "ArchLinux" > /etc/hostname
echo "[OK] Hostname set"

echo "[Action] Setting root password..."
echo "root:Password" | chpasswd &>/dev/null
echo "[OK] Root password set"

echo "[Action] Installing systemd-boot..."
bootctl install &>/dev/null
echo "[OK] systemd-boot installed"

echo "[Action] Updating systemd-boot..."
bootctl update &>/dev/null
echo "[OK] systemd-boot updated"

echo "[Action] Running ArchPostInstall.sh..."
/root/ArchPostInstall.sh &>/dev/null
rm -rf /root/ArchPostInstall.sh
echo "[OK] ArchPostInstall.sh executed"

echo "[Action] Configuring loader.conf..."
cat <<BOOT > /boot/loader/loader.conf
default arch.conf
timeout 5
console-mode max
editor yes
BOOT
echo "[OK] loader.conf configured"

echo "[Action] Configuring arch.conf..."
cat <<ARCH > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
ARCH
echo "[OK] arch.conf configured"

echo "== System Configuration Completed =="
EOF

echo "--------------------------------------------------"
echo ""

# E. Finish and Reboot
echo "== Installation Completed =="
echo "[Action] Unmounting all partitions..."
umount -R /mnt &>/dev/null
echo "[OK] All partitions unmounted"

echo "[Action] Rebooting the system..."
reboot &>/dev/null