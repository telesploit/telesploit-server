#!/bin/bash
source /root/telesploit-server/server.cfg
CONF=$(gpg --decrypt --batch --passphrase=$gpg_key -q $usb_directory/configs/connection.conf.gpg)
echo "$CONF" > /root/.ssh/config
sleep 1
systemctl restart $service_ssh
sleep 1
systemctl restart $service_vnc
sleep 1
systemctl restart $service_rdp
sleep 1
systemctl restart $service_squid
sleep 1
systemctl restart $service_socks
