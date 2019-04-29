#!/bin/bash
source ../server.cfg
echo 'This script allows changing of network connections between DHCP and custom static IP settings'
echo
read -p 'Configure the Telesploit server for DHCP or STATIC? [D/S]: ' dhcp_or_static
echo
if echo "$dhcp_or_static" | grep -iq "^s" ; then
    echo 'The Telesploit server will be set to use a static IP address.'
    echo
    read -p 'Enter the static IP address and CIDR, e.g. 192.168.1.68/24: ' static_ip_cidr
    echo
    read -p 'Enter the default gateway, e.g. 192.168.1.1: ' static_gw
    echo
    read -p 'Enter the primary DNS server, e.g. 8.8.8.8: ' static_dns1
    echo
    read -p 'Enter the secondary DNS server, e.g. 8.8.8.4: ' static_dns2
    echo
    echo 'creating custom config file ../configs/network.conf'
    echo "nmcli con add con-name telesploit ifname eth0 type ethernet ip4 $static_ip_cidr gw4 $static_gw" > ../configs/network.conf
    echo "nmcli con mod telesploit ipv4.dns $static_dns1" >> ../configs/network.conf
    echo "nmcli con mod telesploit +ipv4.dns $static_dns2" >> ../configs/network.conf
elif echo "$dhcp_or_static" | grep -iq "^d" ; then
    echo 'The telesploit server will be set to use a DHCP assigned IP address.'
    echo 'creating custom config file ../configs/network.conf'
    echo 'nmcli con add con-name telesploit ifname eth0 type ethernet' > ../configs/network.conf
else
    echo 'The entered option was not understood, please run the updater again and enter d/D/DHCP or s/S/STATIC'
    echo 'No changes have been made'
    exit
fi
echo
echo '________________________________________________________________'
echo
echo "encrypting new config file and copying to $usb_directory/configs/network.conf.gpg"
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/network.conf.gpg -c ../configs/network.conf
echo 'completed encrypting and copying file'
echo
echo '________________________________________________________________'
echo
echo 'Review the following network configuration. If there are errors then rerun the script before rebooting'
echo
cat ../configs/network.conf
echo
echo '________________________________________________________________'
echo
echo 'Changes will take effect upon reboot'
echo

