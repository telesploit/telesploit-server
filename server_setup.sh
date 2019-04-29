#!/bin/bash
source ./server.cfg
echo 'WARNING - This script should be run as root only on a new Kali Xfce installation. Any existing files or settings may be lost. You have been warned!'
echo
echo 'The following steps MUST be completed before running this script'
echo
echo 'Step 1: Setup a Telesploit relay using the relay_setup.sh script, and creating a DNS record for the relay'
echo 'Step 2: Copy the folder containing this script to the /root directory of the Telesploit server, i.e. /root/telesploit-server/server_setup.sh'
echo 'Step 3: Perform an apt-get update, apt-get upgrade and apt-get dist-upgrade prior to running this script'
echo 'Step 4: Insert a USB flash drive for storing configs and logs'
echo "Step 5: Format the USB flash drive to FAT32 and label it $usb_label (case sensitive)"
echo "Step 6: Mount the USB flash drive (default $usb_directory - case sensitive). Simply right click on the $usb_label drive on the desktop and select mount"
echo 'Step 7: Verify the variables below from server.cfg are correct'
echo
echo 'The first three variables (relay_fqdn, tester_pub_key, usb_drive) MUST be changed to reflect the installation envrionment'
echo 'The fourth variable, working_directory, as well as the source file location in scripts within the /scripts directory should be changed if the telesploit-server folder is placed anywhere other than directly under /root/'
echo 'The fifth variable, gpg_key, should be changed for security reasons (no single quotes)'
echo 'The remaining variables can safely be left with their default values'
echo
cat ./server.cfg
echo
read -n1 -rsp $'If any of these requirements have not been met then press Ctrl+C to exit, otherwise hit any key to continue...\n'
echo
echo "validating that the relay, $relay_fqdn, can be resolved and that the connection is trusted"
echo
echo 'checking DNS resolution'
echo
nslookup $relay_fqdn
echo
echo 'If the relay does not resolve then exit now and check the network connection and DNS entry for the relay'
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
echo
echo '________________________________________________________________'
echo
echo 'setting up required directories on the server'
# creating directory /root/.ssh/
mkdir /root/.ssh/ > /dev/null 2>&1
# setting permissions on /root/.ssh/ directory
chmod 700 /root/.ssh/
# creating directory /root/.vnc/
mkdir /root/.vnc/ > /dev/null 2>&1
# setting permissions on /root/.vnc/ directory
chmod 700 /root/.vnc/
echo 'completed setting up folders on the server'
echo
echo '________________________________________________________________'
echo
echo "retrieving trusted fingerprint from https://$relay_fqdn/trusted"
wget -q -O /root/.ssh/trusted https://$relay_fqdn/trusted
echo
echo "retrieving ssh fingerprint from $relay_fqdn"
ssh-keyscan -t rsa $relay_fqdn > /root/.ssh/tested
echo
echo 'running diff against trusted and tested'
echo
echo '________________________________________________________________'
diff -s /root/.ssh/trusted /root/.ssh/tested
echo '________________________________________________________________'
echo
echo 'identical files indicate a secure connection'
echo 'non-matching files may indicate an active man-in-the-middle attack, review the files /root/.ssh/trusted and /root/.ssh/tested before continuing'
read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
echo
echo '________________________________________________________________'
echo
echo "setting the hostname to $server"
hostname $server
echo "$server" > /etc/hostname
echo 'completed setting the hostname'
echo
echo '________________________________________________________________'
echo
echo 'installing ncat for establishing TLS tunnels'
echo
apt-get install ncat -y
echo
echo 'completed installing ncat'
echo
echo '________________________________________________________________'
echo
echo 'setting up SSH client related files'
echo
# deleting any pre-existing SSH keys, authorized_keys, and known_hosts
rm -f /root/.ssh/$server_ssh_key > /dev/null 2>&1
rm -f /root/.ssh/$server_ssh_key.pub > /dev/null 2>&1
rm -f $usb_directory/$server_ssh_key.pub > /dev/null 2>&1
rm -f /root/.ssh/authorized_keys > /dev/null 2>&1
rm -f /root/.ssh/$known_hosts > /dev/null 2>&1
# creating new SSH key
ssh-keygen -t rsa -f /root/.ssh/$server_ssh_key -N ''
# copying server public key to the root of the USB drive
cp /root/.ssh/$server_ssh_key.pub $usb_directory
# adding server and tester public keys to authorized_keys
cat /root/.ssh/$server_ssh_key.pub > /root/.ssh/authorized_keys
echo $tester_pub_key >> /root/.ssh/authorized_keys
# setting permissions on authorized_keys
chmod 600 /root/.ssh/authorized_keys
# setting ProxyCommand to /usr/bin/ncat --ssl-verify $relay_fqdn 443
ProxyCommand="/usr/bin/ncat --ssl-verify $relay_fqdn 443"
# connecting to relay via SSL and populating known_hosts
ssh -q -i /root/.ssh/$server_ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/$known_hosts -o ProxyCommand="$ProxyCommand" $relay_user@localhost
# connecting to relay via SSH and populating known_hosts
ssh -q -i /root/.ssh/$server_ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/$known_hosts $relay_user@$relay_fqdn
echo
echo 'completed setting up SSH client related files'
echo
echo '________________________________________________________________'
echo
echo 'setting up the server connection to the relay'
echo
echo 'What type of connection should the Telesploit server use?'
echo '[D]irect TLS - No proxy is required. Certificate checking is enabled. SSH host-based verification is enabled.'
echo '[U]nsafe TLS - No proxy is required. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[P]lain - Simple proxy. No password required. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[B]asic - Proxy uses BASIC authentication. Certificate checking is disabled. SSH host-based verification is enabled.'
echo '[N]TLM - Proxy uses NTLM authentication. Certificate checking is disabled. SSH host-based verification is enabled.'
read -p 'Choose the Telesploit server connection type [D/U/P/B/N]: ' connection_type
echo
set_proxy_variables () {
    read -p 'Enter the IP address or FQDN of the proxy server, e.g. 192.168.1.69 or proxy.corp.com: ' proxy_server
    echo
    read -p 'Enter the port used by the proxy server, e.g. 3128: ' proxy_port
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
    echo 'The entered option was not understood. A default Direct TLS configuration will be used'
    proxy_command="/usr/bin/ncat --ssl-verify $relay_fqdn 443"
fi
echo 'creating custom config file'
echo "Host $service_name" > ./configs/connection.conf
echo ' HostName localhost' >> ./configs/connection.conf
echo ' AddressFamily inet' >> ./configs/connection.conf
echo " User $relay_user" >> ./configs/connection.conf
echo ' Port 22' >> ./configs/connection.conf
echo " IdentityFile /root/.ssh/$server_ssh_key" >> ./configs/connection.conf
echo " ProxyCommand $proxy_command" >> ./configs/connection.conf
echo ' ServerAliveInterval 10' >> ./configs/connection.conf
echo ' ServerAliveCountMax 3' >> ./configs/connection.conf
echo ' ExitOnForwardFailure yes' >> ./configs/connection.conf
echo ' StrictHostKeyChecking yes' >> ./configs/connection.conf
echo " UserKnownHostsFile /root/.ssh/$known_hosts" >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo "Host $service_ssh" >> ./configs/connection.conf
echo " $forward_ssh" >> ./configs/connection.conf
echo " $forward_irc"  >> ./configs/connection.conf
echo " $forward_collab"  >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo "Host $service_vnc" >> ./configs/connection.conf
echo " $forward_vnc" >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo "Host $service_rdp" >> ./configs/connection.conf
echo " $forward_rdp" >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo "Host $service_squid" >> ./configs/connection.conf
echo " $forward_squid" >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo "Host $service_socks" >> ./configs/connection.conf
echo " $forward_socks" >> ./configs/connection.conf
echo >> ./configs/connection.conf
echo 'Host client' >> ./configs/connection.conf
echo ' HostName localhost' >> ./configs/connection.conf
echo ' AddressFamily inet' >> ./configs/connection.conf
echo ' User root' >> ./configs/connection.conf
echo ' Port 22' >> ./configs/connection.conf
echo " IdentityFile /root/.ssh/$server_ssh_key" >> ./configs/connection.conf
echo " LocalForward $local_socks_port $local_socks_target" >> ./configs/connection.conf
echo ' ServerAliveInterval 10' >> ./configs/connection.conf
echo ' ServerAliveCountMax 3' >> ./configs/connection.conf
echo ' ExitOnForwardFailure yes' >> ./configs/connection.conf
echo ' NoHostAuthenticationForLocalhost yes' >> ./configs/connection.conf
echo 'finished creating custom config file'
echo
echo 'completed updating relay information'
echo
echo '________________________________________________________________'
echo
echo 'updating the server network settings'
echo
read -p 'Configure the Telesploit server for DHCP or STATIC? [D/S]: ' dhcp_or_static
echo
if echo "$dhcp_or_static" | grep -iq "^s" ; then
    echo 'The Telesploit server will be set to use a static IP address.'
    read -p 'Enter the static IP address and CIDR, e.g. 192.168.1.68/24: ' static_ip_cidr
    echo
    read -p 'Enter the default gateway, e.g. 192.168.1.1: ' static_gw
    echo
    read -p 'Enter the primary DNS server, e.g. 8.8.8.8: ' static_dns1
    echo
    read -p 'Enter the secondary DNS server, e.g. 8.8.8.4: ' static_dns2
    echo
    # creating custom config file ./configs/network.conf
    echo "nmcli con add con-name telesploit ifname eth0 type ethernet ip4 $static_ip_cidr gw4 $static_gw" > ./configs/network.conf
    echo "nmcli con mod telesploit ipv4.dns $static_dns1" >> ./configs/network.conf
    echo "nmcli con mod telesploit +ipv4.dns $static_dns2" >> ./configs/network.conf
elif echo "$dhcp_or_static" | grep -iq "^d" ; then
    echo 'The telesploit server will be set to use a DHCP assigned IP address.'
    # creating custom config file ./configs/network.conf
    echo 'nmcli con add con-name telesploit ifname eth0 type ethernet' > ./configs/network.conf
else
    echo 'The entered option was not understood. A default DHCP configuration will be used.'
    # creating custom config file ./configs/network.conf
    echo 'nmcli con add con-name telesploit ifname eth0 type ethernet' > ./configs/network.conf
fi
echo
echo 'finished updating the server network settings'
echo
echo '________________________________________________________________'
echo
echo 'setting up required directories and files on the USB'
echo
# creating configs directory
mkdir $usb_directory/configs/
# creating logs directory
mkdir $usb_directory/logs/
# encrypting configs with the gpg_key and copying to the USB drive
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/authorized.conf.gpg -c /root/.ssh/authorized_keys
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/network.conf.gpg -c ./configs/network.conf
gpg --yes --no-tty --batch --passphrase $gpg_key -o $usb_directory/configs/connection.conf.gpg -c ./configs/connection.conf
echo
echo 'completed setting up required directories and files'
echo
echo '________________________________________________________________'
echo
echo 'installing and configuring the squid web proxy'
echo
apt-get install squid3 -y
# moving squid configuration file from /etc/squid/squid.conf to /etc/squid/squid.conf.old
mv /etc/squid/squid.conf /etc/squid/squid.conf.old
# creating new squid configuration file
echo -e "http_port 127.0.0.1:3128\nhttp_access allow all" > /etc/squid/squid.conf
echo
echo 'completed installing and configuring the squid web proxy'
echo
echo '________________________________________________________________'
echo
echo 'setting up the vnc server'
echo
echo $vnc_password | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
echo
echo 'completed setting up the vnc server'
echo
echo '________________________________________________________________'
echo
echo 'setting up SSH server related files'
echo
# making directory /etc/ssh/oldkeys
mkdir /etc/ssh/oldkeys/
# moving current ssh server keys from /etc/ssh/ to /etc/ssh/oldkeys/
mv /etc/ssh/ssh_host* /etc/ssh/oldkeys/
# copying ssh server config file from setup directory to /etc/ssh/sshd_config"
cp ./configs/sshd_config /etc/ssh/sshd_config
# reconfiguring OpenSSH server
dpkg-reconfigure openssh-server
# enabling SSH server to start automatically
systemctl enable ssh
echo
echo 'completed setting up SSH server related files'
echo
echo '________________________________________________________________'
echo
echo 'creating service for vnc to start automatically'
echo '[Unit]' >> /etc/systemd/system/tightvncserver.service
echo 'Description=TightVNC remote desktop server' >> /etc/systemd/system/tightvncserver.service
echo 'After=sshd.service' >> /etc/systemd/system/tightvncserver.service
echo  >> /etc/systemd/system/tightvncserver.service
echo '[Service]' >> /etc/systemd/system/tightvncserver.service
echo 'Type=dbus' >> /etc/systemd/system/tightvncserver.service
echo 'ExecStart=/usr/bin/tightvncserver -localhost -nolisten tcp :1' >> /etc/systemd/system/tightvncserver.service
echo 'User=root' >> /etc/systemd/system/tightvncserver.service
echo 'Type=forking' >> /etc/systemd/system/tightvncserver.service
echo >> /etc/systemd/system/tightvncserver.service
echo '[Install]' >> /etc/systemd/system/tightvncserver.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/tightvncserver.service
echo 'completed creating vnc service'
echo
echo '________________________________________________________________'
echo
echo 'creating service files to maintain tunnels'
echo
echo "creating $service_ssh.service"
echo '[Unit]' > /etc/systemd/system/$service_ssh.service
echo "Description=Create tunnel for SSH connection" >> /etc/systemd/system/$service_ssh.service
echo 'After=network.target' >> /etc/systemd/system/$service_ssh.service
echo >> /etc/systemd/system/$service_ssh.service
echo '[Service]' >> /etc/systemd/system/$service_ssh.service
echo 'User=root' >> /etc/systemd/system/$service_ssh.service
echo "ExecStart=/usr/bin/ssh -NT -F /root/.ssh/config $service_ssh" >> /etc/systemd/system/$service_ssh.service
echo 'RestartSec=10' >> /etc/systemd/system/$service_ssh.service
echo 'Restart=always' >> /etc/systemd/system/$service_ssh.service
echo >> /etc/systemd/system/$service_ssh.service
echo '[Install]' >> /etc/systemd/system/$service_ssh.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$service_ssh.service
echo "completed creating $service_ssh.service"
echo
echo "creating $service_vnc.service"
echo '[Unit]' > /etc/systemd/system/$service_vnc.service
echo "Description=Create tunnel for VNC connection" >> /etc/systemd/system/$service_vnc.service
echo 'After=network.target' >> /etc/systemd/system/$service_vnc.service
echo >> /etc/systemd/system/$service_vnc.service
echo '[Service]' >> /etc/systemd/system/$service_vnc.service
echo 'User=root' >> /etc/systemd/system/$service_vnc.service
echo "ExecStart=/usr/bin/ssh -NT -F /root/.ssh/config $service_vnc" >> /etc/systemd/system/$service_vnc.service
echo 'RestartSec=10' >> /etc/systemd/system/$service_vnc.service
echo 'Restart=always' >> /etc/systemd/system/$service_vnc.service
echo >> /etc/systemd/system/$service_vnc.service
echo '[Install]' >> /etc/systemd/system/$service_vnc.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$service_vnc.service
echo "completed creating $service_vnc.service"
echo
echo "creating $service_rdp.service"
echo '[Unit]' > /etc/systemd/system/$service_rdp.service
echo "Description=Create tunnel for RDP connection" >> /etc/systemd/system/$service_rdp.service
echo 'After=network.target' >> /etc/systemd/system/$service_rdp.service
echo >> /etc/systemd/system/$service_rdp.service
echo '[Service]' >> /etc/systemd/system/$service_rdp.service
echo 'User=root' >> /etc/systemd/system/$service_rdp.service
echo "ExecStart=/usr/bin/ssh -NT -F /root/.ssh/config $service_rdp" >> /etc/systemd/system/$service_rdp.service
echo 'RestartSec=10' >> /etc/systemd/system/$service_rdp.service
echo 'Restart=always' >> /etc/systemd/system/$service_rdp.service
echo >> /etc/systemd/system/$service_rdp.service
echo '[Install]' >> /etc/systemd/system/$service_rdp.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$service_rdp.service
echo "completed creating $service_rdp.service"
echo
echo "creating $service_squid.service"
echo '[Unit]' > /etc/systemd/system/$service_squid.service
echo "Description=Create tunnel for SQUID proxy" >> /etc/systemd/system/$service_squid.service
echo 'After=network.target' >> /etc/systemd/system/$service_squid.service
echo >> /etc/systemd/system/$service_squid.service
echo '[Service]' >> /etc/systemd/system/$service_squid.service
echo 'User=root' >> /etc/systemd/system/$service_squid.service
echo "ExecStart=/usr/bin/ssh -NT -F /root/.ssh/config $service_squid" >> /etc/systemd/system/$service_squid.service
echo 'RestartSec=10' >> /etc/systemd/system/$service_squid.service
echo 'Restart=always' >> /etc/systemd/system/$service_squid.service
echo >> /etc/systemd/system/$service_squid.service
echo '[Install]' >> /etc/systemd/system/$service_squid.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$service_squid.service
echo "completed creating $service_squid.service"
echo
echo "creating $service_socks.service"
echo '[Unit]' > /etc/systemd/system/$service_socks.service
echo "Description=Create tunnel for SOCKS proxy" >> /etc/systemd/system/$service_socks.service
echo 'After=network.target' >> /etc/systemd/system/$service_socks.service
echo >> /etc/systemd/system/$service_socks.service
echo '[Service]' >> /etc/systemd/system/$service_socks.service
echo 'User=root' >> /etc/systemd/system/$service_socks.service
echo "ExecStart=/usr/bin/ssh -NT -F /root/.ssh/config $service_socks" >> /etc/systemd/system/$service_socks.service
echo 'RestartSec=10' >> /etc/systemd/system/$service_socks.service
echo 'Restart=always' >> /etc/systemd/system/$service_socks.service
echo >> /etc/systemd/system/$service_socks.service
echo '[Install]' >> /etc/systemd/system/$service_socks.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/$service_socks.service
echo "completed creating $service_socks.service"
echo
echo 'completed creating all service files to maintain tunnels'
echo
echo '________________________________________________________________'
echo
echo 'setting up the newly installed services'
echo
# reloading sytemd daemon
systemctl daemon-reload
# enabling squid server to start automatically
systemctl enable squid.service
# enabling tightvnc service to start automatically
systemctl enable tightvncserver.service
# enabling ssh tunnel to start automatically
systemctl enable $service_ssh.service
# enabling vnc tunnel to start automatically
systemctl enable $service_vnc.service
# enabling rdp tunnel to start automatically
systemctl enable $service_rdp.service
# enabling squid tunnel to start automatically
systemctl enable $service_squid.service
# enabling socks tunnel to start automatically
systemctl enable $service_socks.service
echo
echo 'completed setting up the newly installed services'
echo
echo '________________________________________________________________'
echo
echo 'setting up metasploit'
echo
# starting postgresql metasploit database setup
systemctl start postgresql
echo 'initializing the metasploit database'
echo 'this may take a minute...'
msfdb init
echo
echo 'completed setting up metasploit'
echo
echo '________________________________________________________________'
echo
echo 'adding @reboot command to the root crontab'
echo "@reboot $working_directory/scripts/launcher.sh" > $working_directory/telesploit-crontab
chmod 600 $working_directory/telesploit-crontab
crontab $working_directory/telesploit-crontab
echo 'completed adding @reboot command to the root crontab'
echo
echo '________________________________________________________________'
echo
echo 'updating /etc/fstab with USB information'
usb_blkid=$(blkid $usb_drive -sPARTUUID -ovalue)
echo
echo 'old fstab'
echo
cat /etc/fstab
echo "/dev/disk/by-partuuid/$usb_blkid $usb_directory/ vfat defaults 0 0" >> /etc/fstab
echo
echo 'new fstab'
echo
cat /etc/fstab
echo
echo 'completed updating /etc/fstab'
echo
echo 'ATTENTION: Review the new fstab. If there is no partition UUID after /dev/disk/by-partuuid/, e.g. 153959ed-01, then manually add it by running the following command:'
echo
echo "blkid $usb_drive -sPARTUUID -ovalue"
echo
echo 'If no partition UUID is returned then verify the value for usb_drive in server.cfg'
echo 'If a partition UUID is returned then manually add it to /etc/fstab, e.g. /dev/disk/by-partuuid/153959ed-01'
echo 'If the partition UUID cannot be obtained then delete the entire last line in /etc/fstab. The Telesploit server will not function, but the system will boot'
echo 'Failure to properly configure /etc/fstab will cause the server to boot into maintenance mode' 
echo
echo '________________________________________________________________'
echo
echo 'Setup has completed'
echo
echo "Copy the server public key, $server_ssh_key.pub, on the USB drive into the authorized_key file for the user, $relay_user, on the relay"
echo
echo 'Reboot to complete configuration'
echo
