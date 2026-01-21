DISK="/dev/sda"

parted -s $DISK mklabel gpt \
    mkpart primary fat32 1MiB 301MiB \
    set 1 esp on \
    mkpart primary ext4 301MiB 100% && \
mkfs.fat -F32 ${DISK}1 && \
mkfs.ext4 -F -q ${DISK}2

mount ${DISK}2 /mnt
mount --mkdir ${DISK}1 /mnt/boot

pacstrap -K /mnt linux

genfstab -U /mnt >> /mnt/etc/fstab

UUID=$(blkid -s UUID -o value ${DISK}2)

arch-chroot /mnt bash <<EOF
bootctl --path=/boot install
echo -e "default arch.conf\ntimeout 0\nconsole-mode max\neditor yes" > /boot/loader/loader.conf
echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions root=UUID=$UUID rw" > /boot/loader/entries/arch.conf
EOF

umount -R /mnt
reboot
