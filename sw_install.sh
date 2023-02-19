#!/bin/sh

pacman -Syu sudo 

# Create a User
echo "Create a User:"
read username
useradd -m $username # create user with a homedir
passwd $username # give the user a pw
usermod -aG wheel,power,storage,audio,video,optical $username # add user to different groups
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers # give wheel group sudo privleges

# setup dualboot
echo "Do want setup dualboot? [y/N]"
read choice
if [$choice == 'y']
then
    pacman -S os-prober ntfs-3g
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Switch to non-root user for rest of installation
su $username

# Software Install Script
sudo pacman -S $(awk -F ',' '{print $1}' pacman_sw.csv) # print package name as argument for pacman

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
paru -S $(awk -F ',' '{print $1}' paru_sw.csv) # print package names as arguments for paru

#Start services
systemctl enable cups.service

git clone https://git.suckless.org/dmenu
cd dmenu
sudo make
sed -i '%s/"monospace:size=10"/"Fira Code:size=12"/' config.h
sudo make clean install
cd ..

#TODO:
#Setup the rest of the dotfiles
