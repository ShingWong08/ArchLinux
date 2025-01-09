# 更新系統 Pacman

pacman -Syyu --noconfirm

# 安裝基本軟件
pacman -S vim unzip wget curl htop openssh --noconfirm

# SSH 配置文件
rm -rf /etc/ssh/sshd_config
touch /etc/ssh/sshd_config

echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
echo "Port 22" >> /etc/ssh/sshd_config
echo "AddressFamily any" >> /etc/ssh/sshd_config
echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PrintMotd no" >> /etc/ssh/sshd_config
echo "PrintLastLog no" >> /etc/ssh/sshd_config
echo "Subsystem sftp /usr/lib/ssh/sftp-server" >> /etc/ssh/sshd_config

# 開機啟動  
systemctl restart sshd
systemctl enable sshd

# 配置 bashrc
touch /root/.bash_profile
touch /root/.bashrc

echo "alias ls='ls -F --color=always'" >> /root/.bashrc
echo "alias ll='ls -l -a'" >> /root/.bashrc
echo "alias vi='vim'" >> /root/.bashrc
echo "alias psyu='pacman -Syyu --noconfirm'" >> /root/.bashrc
echo "alias taskmgr='htop'" >> /root/.bashrc
echo "alias move='mv'" >> /root/.bashrc
echo "alias copy='cp'" >> /root/.bashrc
echo "alias remove='rm'" >> /root/.bashrc

echo "source /root/.bashrc" >> /root/.bash_profile

# 配置 vim
touch /root/.vimrc

echo "set number" >> /root/.vimrc
echo "set wrap" >> /root/.vimrc
echo "set ruler" >> /root/.vimrc
echo "set showcmd" >> /root/.vimrc
echo "set showmatch" >> /root/.vimrc
echo "set backspace=indent,eol,start" >> /root/.vimrc

echo "set tabstop=4" >> /root/.vimrc
echo "set shiftwidth=4" >> /root/.vimrc
echo "set expandtab" >> /root/.vimrc

echo "set smartindent" >> /root/.vimrc
echo "set autoindent" >> /root/.vimrc
echo "set smarttab" >> /root/.vimrc

echo "syntax on" >> /root/.vimrc
echo "filetype on" >> /root/.vimrc


# 重新啟動
reboot