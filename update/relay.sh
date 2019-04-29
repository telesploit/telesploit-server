#!/bin/bash
source ../server.cfg
relay_current=$relay_fqdn
echo 'This script will move a Telesploit server from its current relay to a new relay'
echo 'Verify that the server public key has been added to the authorized_keys of the new relay'
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
echo
read -p 'Enter the new relay FQDN, e.g. relay-os.telesploit.com: ' relay_fqdn
echo
echo
echo '________________________________________________________________'
echo
echo 'removing existing custom known_hosts, tested, and trusted fingerprint files'
rm /root/.ssh/$known_hosts
rm /root/.ssh/tested
rm /root/.ssh/trusted
echo 'files removed'
echo
echo '________________________________________________________________'
echo
echo "retrieving trusted fingerprint from https://$relay_fqdn/trusted"
wget -q -O /root/.ssh/trusted https://$relay_fqdn/trusted
echo "retrieving ssh fingerprint from $relay_fqdn"
ssh-keyscan -t rsa $relay_fqdn > /root/.ssh/tested
echo 'running diff against trusted and tested'
echo
echo '________________________________________________________________'
diff -s /root/.ssh/trusted /root/.ssh/tested
echo '________________________________________________________________'
echo
echo 'identical files indicate a secure connection'
echo 'non-matching files may indicate an active man-in-the-middle attack, review the files /root/.ssh/trusted and /root/.ssh/tested before continuing'
echo
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
echo
echo '________________________________________________________________'
echo
echo 'populating known_hosts file with new setting'
# setting ProxyCommand to /usr/bin/ncat --ssl-verify $relay_fqdn 443
ProxyCommand="/usr/bin/ncat --ssl-verify $relay_fqdn 443"
# connecting to relay via SSL and populating known_hosts
ssh -i /root/.ssh/$server_ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/$known_hosts -o ProxyCommand="$ProxyCommand" $relay_user@localhost
# connecting to relay via SSH and populating known_hosts
ssh -i /root/.ssh/$server_ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/$known_hosts $relay_user@$relay_fqdn
echo 'completed updating known_hosts file'
echo
echo '________________________________________________________________'
echo
echo 'updating SSH config, connection.conf, and server.cfg with new setting'
sed -i "s/relay_fqdn=.*/relay_fqdn=\x27$relay_fqdn\x27/g" ../server.cfg
sed -i "s/$relay_current/$relay_fqdn/g" /root/.ssh/config
cp /root/.ssh/config ../configs/connection.conf
echo 'completed updating settings'
echo
echo '________________________________________________________________'
echo
echo "encrypting new config file and copying to $usb_directory/configs/connection.conf.gpg"
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/connection.conf.gpg -c ../configs/connection.conf
echo 'completed encrypting and copying file'
echo
echo '________________________________________________________________'
echo
echo 'The new settings will take effect on the next reboot'
echo

