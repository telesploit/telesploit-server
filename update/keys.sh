#!/bin/bash
source ../server.cfg
echo 'The following steps MUST be completed before running this script'
echo 'Step 1: Update the /root/.ssh/authorized_keys to reflect the newly added or removed keys'
echo 'Step 2: Verify the /root/.ssh/authorized_keys file contents are properly formatted and proper permissions are set'
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
echo
echo '________________________________________________________________'
echo
echo "backing up $usb_directory/configs/authorized.conf.gpg to $usb_directory/configs/authorized.conf.gpg.bak"
cp  $usb_directory/configs/authorized.conf.gpg $usb_directory/configs/authorized.conf.gpg.bak
echo 'completed back up'
echo
echo '________________________________________________________________'
echo
echo "encrypting current authorized_keys file and copying to $usb_directory/configs/authorized.conf.gpg"
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/authorized.conf.gpg -c /root/.ssh/authorized_keys
echo 'completed encrypting and copying file'
echo
echo '________________________________________________________________'
echo
echo 'Note: the current /root/.ssh/authorized_keys will now survive reboot'
echo
