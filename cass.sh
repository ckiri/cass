#!/bin/sh
# Update System
pacman -Syu sudo 

echo "Following are a few questions for setting up the system\n"

echo "Enter Username for user creation: "
read uid
echo "\n"

echo "Are you using a mobile device or desktop?\n"
echo "1 = mobile, 2 = desktop: "
read device
echo "\n"

echo "Do you want to setup dualboot?\n"
echo "[y/N]: "
read boot
echo "\n"

echo "Do you want to install a vpn?\n"
echo "[y/N]: "
read vpn
echo "\n"

echo "Do you want to change the shell to zsh?"
echo "[y/N]. "
read shell
echo "\n"

# Create a user
useradd -m $uid                                                                 # create user with a homedir
passwd $uid                                                                     # give the user a pw
usermod -aG wheel,power,storage,audio,video,optical $uid                        # add user to different groups
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers    # give wheel group sudo privleges

# Setup dualboot
if [ $boot == 'y' ]
then
    pacman -S os-prober ntfs-3g
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/'\n
    /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Setup NTP and system time with sync server
pacman -S ntp

i=0
max=4
while [ $i -lt $max ]
do
    echo "server $i.de.pool.ntp.org" >> /etc/ntp.conf
    true $(( i++ ))
done

# locale setup
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /etc/locale.gen
locale-gen

# Install SW from list
pacman -S $(awk -F "\t" '{print $1}' sw.csv | awk 'NR!=1 {print}')                              # print package name as argument for pacman

# Change Shell to zsh
if [ $shell == 'y' ]
then
    pacman -S zsh zsh-syntax-highlighting
    su $username -c "chsh -s $(which zsh)"
fi

# Install VPN
if [$vpn == 'y']
then
    if [ $device == '1' ]
    then
        pacman -S openvpn wireguard-tools
    else if [ $device == '2' ]
    then
        pacman -S openvpn
    fi
fi

# Install software for mobile devices
if [ $typ == '1' ]
then
    sudo pacman -S tlp python-iwlib                                                         # Power Management
fi

# Start services
systemctl enable cups.service                                                   # Enable Printing Server (Start Service on every startup)
systemctl start cups.service                                                    # Start Printing Server now

systemctl enable libvirtd.service                                               # Enable Virtualisation for Virtualbox
systemctl start libvirtd.service

systemctl enable ntpd.service
systemctl start ntpd.service

if [ $typ == '1' ]
then
    systemctl enable tlp.service                                                # Enable Powermanagement
    systemctl start tlp.service
fi

echo "Setup Finished, exiting now...\n"
exit
