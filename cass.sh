#!/bin/sh
# Update System
pacman -Syy                                                                     # update package index
pacman -S archlinux-keyring                                                     # update keyring
pacman -Syu sudo                                                                # update the whole system

# Questions for installing the right SW
echo ""
echo "*******************************************************"
echo "Following are a few questions for setting up the system"
echo ""
echo "Enter Username for user creation: "
read uid
echo ""
echo "Are you using a mobile device or desktop?"
echo "1 = mobile, 2 = desktop: "
read device
echo ""
echo "Do you want to setup dualboot?"
echo "[y/N]: "
read boot
echo ""
echo "Do you want to install a vpn?"
echo "[y/N]: "
read vpn
echo ""
echo "Do you want to change the shell to zsh?"
echo "[y/N]: "
read shell
echo ""
echo "Do you want to install and setup a vm?"
echo "[y/N]: "
read vm
echo "*******************************************************"
echo ""

# Create a user
useradd -m $uid                                                                 # create user with a homedir
echo ""
echo "*******************************************************"
echo "Give the user $uid a password."
passwd $uid                                                                     # give the user a pw
echo "*******************************************************"
echo ""
usergroups='wheel,power,storage,audio,video,optical'
usermod -aG $usergroups $uid                                                    # add user to different groups
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers    # give wheel group sudo privleges

# Setup dualboot
if [ $boot == 'y' ]
then
    pacman -S os-prober ntfs-3g
    dualbootcfg='s/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/'
    sed -i $dualbootcfg /etc/default/grub
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
pacman -S $(awk -F ',' '{print $1}' sw.csv | awk 'NR!=1 {print}')               # read first column of SW list, pipe into awk & print rest without frist line

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
    sudo pacman -S tlp python-iwlib                                             # Power Management
fi

# Install and setup QEMU/KVM
if [ $vm == 'y' ]
then
    pacman -Syu qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils
                openbsd-netcat ebtables iptables libgeustfs
    usermod -aG libvirt $uid
    systemctl enable libvirtd.service                                               # Enable Virtualisation for Virtualbox
    systemctl start libvirtd.service
fi

# Start services
systemctl enable cups.service                                                   # Enable Printing Server (Start Service on every startup)
systemctl start cups.service                                                    # Start Printing Server now

systemctl enable ntpd.service
systemctl start ntpd.service

# Setup services and options for mobile devices
if [ $typ == '1' ]
then
    systemctl enable tlp.service                                                # Enable Powermanagement
    systemctl start tlp.service
    # Config for "touch" to click the touchpad
    echo -e "Section \"InputClass\"
        Identifier \"touchpad\"
        Driver \"libinput\"
        MatchIsTouchpad \"on\"
        Option \"Tapping\" \"on\"
        Option \"TappingButtonMap\" \"lmr\"
        Option \"NaturalScrolling\" \"true\"
    EndSection" >> /etc/X11/xorg.conf.d/30-touchpad.conf
fi

echo "Setup Finished, exiting now...\n"
exit 0
