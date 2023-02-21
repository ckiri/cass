#!/bin/sh
# Update System
pacman -Syu sudo 

echo "Following are a few questions for setting up the System\n"

# TODO: Ask questions upfront, then execute choices
echo "[1/6]\n"
echo "Enter Username for user creation: "
read username
echo "\n"

echo "[2/6]\n"
echo "Are you using a mobile device or desktop?\n"
echo "1 = mobile, 2 = desktop: "
read typ
echo "\n"

echo "[3/6]\n"
echo "Do you want to setup dualboot?\n"
echo "[y/N]: "
read dualboot
echo "\n"

echo "[4/6]\n"
echo "Do you want to setup a vpn?\n"
echo "[y/N]: "
read vpn
echo "\n"

if [$vpn == 'y']
then
    echo "[4.1/6]\n"
    echo "As you have decided to setup VPN,
          do you want to also setup a VPN for HHN?\n"
    echo "[y/N]: "
    read univpn
    echo "\n"
fi

echo "[5/6]\n"
echo "Do you want to install suckless software?\n"
echo "[y/N]: "
read suckless
echo "\n"

echo "[6/6]\n"
echo "After Install, do you want to also setup ckiri .dotfiles?\n"
echo "[y/N]: "
read dotfiles
echo "\n"

# Create a User
useradd -m $username                                                            # create user with a homedir
passwd $username                                                                # give the user a pw
usermod -aG wheel,power,storage,audio,video,optical $username                   # add user to different groups
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers    # give wheel group sudo privleges

# setup dualboot
echo "Do want setup dualboot? [y/N]"
read choice
if [$choice == 'y']
then
    pacman -S os-prober ntfs-3g
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/'
    /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Setup NTP and System Time with sync server
pacman -S ntp
systemctl enable ntpd.service
systemctl start ntpd.service
sed -i 'server 0.de.pool.ntp.org\\nserver 1.de.pool.ntp.org\\nserver 2.de.pool.ntp.org\\nserver 3.de.pool.ntp.org\\n'
/etc/ntp.conf

# Switch to non-root user for rest of installation
su $username

# Create .config folder in homedir
mkdir $HOME/.config

# Software Install Script
sudo pacman -S $(awk -F ',' '{print $1}' pacman_sw.csv)                         # print package name as argument for pacman

# Change Shell to zsh
echo "Do you want to change the Shell to zsh? [y/N]"
read choice
if [$choice == 'y']
then
    pacman -S zsh zsh-syntax-highlighting
    chsh -s $(which zsh)
    #TODO:
    #Setup zsh dotfiles (XDG structure)
    #export var with path to zdotdir
fi

# Install Paru (AUR Helper)
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..

# Install Paru Packages
paru -S $(awk -F ',' '{print $1}' paru_sw.csv)                                  # print package names as arguments for paru

# Install Suckless Software
if [$suckless == 'y']
then
    mkdir $HOME
    git clone https://git.suckless.org/dwm $HOME/.config/suckless/dwm           # Dynamic Tiling Winddow Manager
    git clone https://git.suckless.org/slstatus $HOME/.config/suckless/slstatus # Status-Line for DWM
    git clone https://git.suckless.org/dmenu $HOME/.config/suckless/dmenu       # Run Programms & Commands
    git clone https://git.suckless.org/slock $HOME/.config/suckless/slock       # Lockscreen
fi

# Setup VPN
# TODO: for setup with UNI VPN (HHN) download config etc. form hs-heilbronn.de
if [$vpn == 'y']
then
    if [$typ == '1']
    then
        pacman -S openvpn wireguard-tools
    else [$typ == '2']
    then
        pacman -S openvpn
    fi
fi

# Install software for mobile devices
if [$typ == '1']
then
    sudo pacman -S tlp                                                          # Power Management
    echo "Eduroam CAT Installer Download:\n"                                    # Wifi for University (HHN)
    wget "https://cat.eduroam.org/user/API.php?action=downloadInstaller&lang=en&profile=5212&device=linux&generatedfor=user&openroaming=0"
    python eduroam-linux-Hochschule_Heilbronn.py
fi

# Start services
systemctl enable cups.service                                                   # Enable Printing Server (Start Service on every startup)
systemctl start cups.service                                                    # Start Printing Server now

systemctl enable libvirtd.service                                               # Enable Virtualisation for Virtualbox
systemctl start libvirtd.service

if [$typ == '1']
then
    systemctl enable tlp.service                                                # Enable Powermanagement
    systemctl start tlp.service
fi

if [$dotfiles == 'y']
then
    git clone https://github.com/ckiri/.dotfiles $HOME/.dotfiles
    cd $HOME/.dotfiles
    ./setup.sh
fi

echo "Install and/or Setup finished, exiting now...\n"
exit
