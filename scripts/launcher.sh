#!/bin/bash
source /root/telesploit-server/server.cfg
sleep 60
$working_directory/scripts/auth.sh
sleep 5
$working_directory/scripts/netset.sh
sleep 10
$working_directory/scripts/connection.sh
sleep 5
/usr/bin/systemctl reload ssh.service
sleep 5
/usr/bin/systemctl reload squid.service
sleep 60
$working_directory/scripts/dumplogs.sh
