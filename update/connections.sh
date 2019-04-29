#!/bin/bash
source ../server.cfg
echo 'This script allows re-configuration of outbound connections for the Telesploit server'
echo
echo 'What type of connection should the Telesploit server use?'
echo '[D]irect TLS - No proxy is required. Certificate checking is enabled. SSH host-based verification is enabled.'
echo '[U]nsafe TLS - No proxy is required. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[P]lain - Simple proxy. No password required. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[B]asic - Proxy uses BASIC authentication. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[N]TLM - Proxy uses NTLM authentication. Certificate checking is disabled. SSH host-based verification is enabled.'
read -p "Choose the Telesploit server connection type [D/U/P/B/N]: " connection_type
echo
set_proxy_variables () {
    read -p 'Enter the IP address or FQDN of the proxy server, e.g. 192.168.1.69 or proxy.corp.com: ' proxy_server
    echo
    read -p 'Enter the port used by the proxy server, e.g. 3128: ' proxy_port
    echo
}
set_proxy_credentials () {
    read -p 'Enter the username for the proxy server, e.g. pentester: ' proxy_username
    echo
    read -s -p 'Enter the password for the proxy server, e.g. SquidWard: ' proxy_password
    echo
}
set_proxy_domain () {
    read -p 'Enter the NTLM domain for the account, e.g. CORP: ' proxy_domain
    echo
}
if echo "$connection_type" | grep -iq "^d" ; then
    proxy_command="/usr/bin/ncat --ssl-verify $relay_fqdn 443"
elif echo "$connection_type" | grep -iq "^u" ; then
    proxy_command="/usr/bin/ncat --ssl $relay_fqdn 443"
elif echo "$connection_type" | grep -iq "^p" ; then
    set_proxy_variables
    proxy_command="/usr/bin/proxytunnel -v -p $proxy_server:$proxy_port -d $relay_fqdn:443 -e"
elif echo "$connection_type" | grep -iq "^b" ; then
    set_proxy_variables
    set_proxy_credentials
    proxy_command="/usr/bin/proxytunnel -v -p $proxy_server:$proxy_port -P $proxy_username:$proxy_password -d $relay_fqdn:443 -e"
elif echo "$connection_type" | grep -iq "^n" ; then
    set_proxy_variables
    set_proxy_credentials
    set_proxy_domain
    proxy_command="/usr/bin/proxytunnel -v -p $proxy_server:$proxy_port -N -t $proxy_domain -P $proxy_username:$proxy_password -d $relay_fqdn:443 -e"
else
    echo 'The entered option was not understood, please run the updater again and enter S/D/P/B/N'
    echo 'No changes have been made'
    exit
fi
echo
echo '________________________________________________________________'
echo
echo 'creating custom config file ../configs/connection.conf'
echo "Host $service_name" > ../configs/connection.conf
echo ' HostName localhost' >> ../configs/connection.conf
echo ' AddressFamily inet' >> ../configs/connection.conf
echo " User $relay_user" >> ../configs/connection.conf
echo ' Port 22' >> ../configs/connection.conf
echo " IdentityFile /root/.ssh/$server_ssh_key" >> ../configs/connection.conf
echo " ProxyCommand $proxy_command" >> ../configs/connection.conf
echo ' ServerAliveInterval 10' >> ../configs/connection.conf
echo ' ServerAliveCountMax 3' >> ../configs/connection.conf
echo ' ExitOnForwardFailure yes' >> ../configs/connection.conf
echo ' StrictHostKeyChecking yes' >> ../configs/connection.conf
echo " UserKnownHostsFile /root/.ssh/$known_hosts" >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo "Host $service_ssh" >> ../configs/connection.conf
echo " $forward_ssh" >> ../configs/connection.conf
echo " $forward_irc"  >> ../configs/connection.conf
echo " $forward_collab"  >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo "Host $service_vnc" >> ../configs/connection.conf
echo " $forward_vnc" >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo "Host $service_rdp" >> ../configs/connection.conf
echo " $forward_rdp" >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo "Host $service_squid" >> ../configs/connection.conf
echo " $forward_squid" >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo "Host $service_socks" >> ../configs/connection.conf
echo " $forward_socks" >> ../configs/connection.conf
echo >> ../configs/connection.conf
echo 'Host client' >> ../configs/connection.conf
echo ' HostName localhost' >> ../configs/connection.conf
echo ' AddressFamily inet' >> ../configs/connection.conf
echo ' User root' >> ../configs/connection.conf
echo ' Port 22' >> ../configs/connection.conf
echo " IdentityFile /root/.ssh/$server_ssh_key" >> ../configs/connection.conf
echo " LocalForward $local_socks_port $local_socks_target" >> ../configs/connection.conf
echo ' ServerAliveInterval 10' >> ../configs/connection.conf
echo ' ServerAliveCountMax 3' >> ../configs/connection.conf
echo ' ExitOnForwardFailure yes' >> ../configs/connection.conf
echo ' NoHostAuthenticationForLocalhost yes' >> ../configs/connection.conf
echo 'finished creating custom config file'
echo
echo '________________________________________________________________'
echo
echo "encrypting new config file and copying to $usb_directory/configs/connection.conf.gpg"
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/connection.conf.gpg -c ../configs/connection.conf
echo 'completed encrypting and copying files'
echo
echo '________________________________________________________________'
echo
echo 'Review the following configuration file. If there are errors then rerun the script before rebooting'
echo
cat ../configs/connection.conf
echo
echo 'Changes will take effect upon reboot'
echo

