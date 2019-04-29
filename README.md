# telesploit-server
Scripts to create an open source Telesploit server

These scripts have only been tested on Kali Xfce rolling release.

From the Kali server open a console and verify the current working directory is /root.

Download the files or run 'git clone https://github.com/telesploit/telesploit-server.git'

Navigate to the telesploit-server directory.

server_setup.sh should be run as root only on a new Kali Xfce installation. Any existing files or settings may be lost. You have been warned!

Prior to running the setup script, the following actions MUST be taken.

1) Setup a Telesploit relay and assign an FQDN
2) Fully update the Kali Xfce install (update/upgrade/dist-upgrade)
3) Update the relay_fqdn, tester_pub_key, usb_drive variables in telesploit-server/server.cfg
3) Insert a USB flash drive (SanDisk Ultra Fit or other small form factor USBs recommended as this must stay connected to the system)
4) Format the USB flash drive to FAT32 and label it TELESPLOIT (default)
5) Mount the USB flash drive, /media/root/TELESPLOIT (default). Simply right click on the TELESPLOIT drive on the desktop and select mount
