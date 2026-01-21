# Arch Linux 安裝指南

## A. 設定日期

1. **查看當前日期時間**

   ```bash
   timedatectl status
   ```

2. **設定時區**

   ```bash
   timedatectl set-timezone Asia/Hong_Kong
   ```

3. **設定網絡時間同步**
   ```bash
   timedatectl set-ntp true
   ```

---

## B. 磁盤分區

### 1. 使用 Fdisk 分區

1.1 **查看磁盤**

```bash
fdisk -l
```

1.2 **開始分區**

```bash
fdisk /dev/sda
```

- 創建新的 GPT 分區表:
  ```bash
  g
  ```
- **創建 EFI 系統分區**:

  - 新建分區:
    ```bash
    n
    ```
  - 分區號碼:
    ```bash
    1
    ```
  - 起始扇區:
    ```bash
    2048 (Enter)
    ```
  - 分區大小:
    ```bash
    +300M
    ```
  - 更改分區類型:
    ```bash
    t
    1
    ```

- **創建根分區**:

  - 新建分區:
    ```bash
    n
    ```
  - 分區號碼:
    ```bash
    2
    ```
  - 起始扇區:
    ```bash
    616448 (Enter)
    ```
  - 結束扇區:
    ```bash
    20971486 (Enter)
    ```

- 寫入分區表:

  ```bash
  w
  ```

  1.3 **格式化分區**

  ```bash
  mkfs.fat -F 32 /dev/sda1
  mkfs.ext4 /dev/sda2
  ```

---

## C. 掛載分區

1. **掛載根分區和 EFI 分區**
   ```bash
   mount /dev/sda2 /mnt
   mount --mkdir /dev/sda1 /mnt/boot
   ```

---

## D. 安裝基本系統

1. **安裝基本系統**
   ```bash
   pacstrap -K /mnt base linux linux-firmware
   ```

2. **生成 fstab**
   ```bash
   genfstab -U /mnt >> /mnt/etc/fstab
   ```

3. **複製 Live CD 網絡到新系統**
   ```bash
   cp /etc/resolv.conf /mnt/etc/resolv.conf
   cp /etc/systemd/network/* /mnt/etc/systemd/network/
   ```

## E. 配置系統

1. **進入新系統**

   ```bash
   arch-chroot /mnt
   ```

2. **設置網絡**
   
   ```bash
   systemctl enable systemd-networkd
   systemctl enable systemd-resolved
   ```

3. **設定時區**

   ```bash
   ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
   hwclock --systohc
   timedatectl set-timezone Asia/Hong_Kong
   ```

4. **更新 Pacman**

   ```bash
   pacman -Syyu
   pacman -S vim --noconfirm
   ```

5. **設定語言**

   ```bash
   vim /etc/locale.gen
   ```

   - 取消註解以下兩行:
     ```
     en_HK.UTF-8 UTF-8
     zh_HK.UTF-8 UTF-8
     ```
   - 生成語言:
     ```bash
     locale-gen
     ```
   - 設定語言環境:
     ```bash
     echo LANG=en_HK.UTF-8 > /etc/locale.conf
     ```

6. **設定主機名**

   ```bash
   echo ArchLinux > /etc/hostname
   ```

7. **設定 root 密碼**
   ```bash
   passwd root
   ```
   - 輸入密碼

---

## F. 安裝引導程序 (Systemd-boot)

1. **安裝引導程序**

   ```bash
   bootctl install
   bootctl update
   ```

2. **設定引導程序**

   - 編輯 `loader.conf`:

     ```bash
     vim /boot/loader/loader.conf
     ```

     內容如下:

     ```
     default arch.conf
     timeout 4
     console-mode max
     editor yes
     ```

   - 編輯 `arch.conf`:
     ```bash
     vim /boot/loader/entries/arch.conf
     ```
     內容如下:
     ```
     title Arch Linux
     linux /vmlinuz-linux
     initrd /initramfs-linux.img
     options root=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw
     ```

---

## G. 退出安裝

1. **退出新系統**

   ```bash
   exit
   ```

2. **取消掛載分區**

   ```bash
   umount -R /mnt
   ```

3. **重啟**
   ```bash
   reboot
   ```
