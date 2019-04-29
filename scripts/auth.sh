#!/bin/bash
source /root/telesploit-server/server.cfg
CONF=$(gpg --decrypt --batch --passphrase=$gpg_key -q $usb_directory/configs/authorized.conf.gpg)
echo "$CONF" > /root/.ssh/authorized_keys
sleep 5
