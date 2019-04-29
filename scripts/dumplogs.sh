#!/bin/bash
source /root/telesploit-server/server.cfg
PROXYCOMMAND="/usr/bin/ncat --ssl $relay_fqdn 443"
INTIP=$(hostname -I)
EXTIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
NCATSSL=$(echo 'HEAD / HTTP1.0' | ncat -vv -w 5 --ssl $relay_fqdn 443 2>&1)
NCATSSLVERIFY=$(echo 'HEAD / HTTP1.0' | ncat -vv -w 5 --ssl-verify $relay_fqdn 443 2>&1)
TRUSTED=$(wget -t 1 -T 5 -q -O - https://$relay_fqdn/trusted 2>&1)
TRUSTEDNOSSLVERIFY=$(wget --no-check-certificate -t 1 -T 5 -q -O - https://$relay_fqdn/trusted 2>&1)
TESTED=$(ssh-keyscan -t rsa $relay_fqdn 2>&1)
SSLYZE=$(sslyze --certinfo=full $relay_fqdn 2>&1)
SSHCONNECT=$(ssh -vv -i /root/.ssh/$server_ssh_key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oConnectTimeout=10 $relay_user@$relay_fqdn "whoami" 2>&1)
SSHCONNECTPROXY=$(ssh -vv -i /root/.ssh/$server_ssh_key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oConnectTimeout=10 -oProxyCommand="$PROXYCOMMAND" $relay_user@localhost "whoami" 2>&1)
HOST=$(hostname)
NOW=$(date +"%Y%m%d%H%M")
LOGDIR=$working_directory/logs
FILENAME=$HOST.$NOW.log
touch $LOGDIR/$FILENAME
echo "$HOST $NOW Logs" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "ethtool eth0" >> $LOGDIR/$FILENAME
/sbin/ethtool eth0 >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "Internal IP: $INTIP" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "External IP: $EXTIP" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "nmcli device show" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/usr/bin/nmcli device show >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "nslookup $relay_fqdn" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/usr/bin/nslookup $relay_fqdn >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "TRUSTED" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo $TRUSTED >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "TRUSTEDNOSSLVERIFY" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo $TRUSTEDNOSSLVERIFY >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "TESTED" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo $TESTED >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "SSLYZE" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
while read -r command; do
 echo "$command" >> $LOGDIR/$FILENAME
done <<< "$SSLYZE"
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "NCATSSL" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
while read -r command; do
 echo "$command" >> $LOGDIR/$FILENAME
done <<< "$NCATSSL"
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "NCATSSLVERIFY" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
while read -r command; do
 echo "$command" >> $LOGDIR/$FILENAME
done <<< "$NCATSSLVERIFY"
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "SSHCONNECT" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
while read -r command; do
 echo "$command" >> $LOGDIR/$FILENAME
done <<< "$SSHCONNECT"
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "SSHCONNECTPROXY" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
while read -r command; do
 echo "$command" >> $LOGDIR/$FILENAME
done <<< "$SSHCONNECTPROXY"
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "cat /root/.ssh/config" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
cat /root/.ssh/config >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "cat /root/.ssh/authorized_keys" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
cat /root/.ssh/authorized_keys >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "cat /root/.ssh/known_hosts" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
cat /root/.ssh/known_hosts >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "netstat -plant" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/bin/netstat -plant >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "systemctl status --no-pager" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/bin/systemctl status --no-pager >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "journalctl -b --no-pager" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/bin/journalctl -b --no-pager >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
echo "traceroute $relay_fqdn" >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
/usr/bin/traceroute $relay_fqdn >> $LOGDIR/$FILENAME
echo "------------------------------------------------------------------------------" >> $LOGDIR/$FILENAME
gpg --yes --batch --passphrase=$gpg_key -c $LOGDIR/$FILENAME
cp $LOGDIR/$FILENAME.gpg $usb_directory/logs/
