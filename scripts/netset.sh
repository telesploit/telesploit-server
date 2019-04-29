#!/bin/bash
source /root/telesploit-server/server.cfg
CONF=$(gpg --decrypt --batch --passphrase=$gpg_key -q $usb_directory/configs/network.conf.gpg)
nmcli connection delete id telesploit
sleep 5

while read -r command; do
 $command
 sleep 5
done <<< "$CONF"

nmcli con up telesploit
