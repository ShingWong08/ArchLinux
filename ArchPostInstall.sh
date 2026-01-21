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
touch ~/.bash_profile
touch ~/.bashrc

echo "alias ls='ls -F --color=always'" >> ~/.bashrc
echo "alias ll='ls -l -a'" >> ~/.bashrc
echo "alias vi='vim'" >> ~/.bashrc
echo "alias psyu='pacman -Syyu --noconfirm'" >> ~/.bashrc
echo "alias taskmgr='htop'" >> ~/.bashrc
echo "alias move='mv'" >> ~/.bashrc
echo "alias copy='cp'" >> ~/.bashrc
echo "alias remove='rm'" >> ~/.bashrc

echo "source ~/.bashrc" >> ~/.bash_profile

# 配置 vim
touch ~/.vimrc

echo "set number" >> ~/.vimrc
echo "set wrap" >> ~/.vimrc
echo "set ruler" >> ~/.vimrc
echo "set showcmd" >> ~/.vimrc
echo "set showmatch" >> ~/.vimrc
echo "set backspace=indent,eol,start" >> ~/.vimrc

echo "set tabstop=4" >> ~/.vimrc
echo "set shiftwidth=4" >> ~/.vimrc
echo "set expandtab" >> ~/.vimrc

echo "set smartindent" >> ~/.vimrc
echo "set autoindent" >> ~/.vimrc
echo "set smarttab" >> ~/.vimrc

echo "syntax on" >> ~/.vimrc
echo "filetype on" >> ~/.vimrc
