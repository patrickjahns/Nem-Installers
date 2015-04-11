#!/bin/bash
# This script will attempt to install NEM dependencies and other software on Ubuntu 14.04. 
# No guarantees that it will even work. Use at your own risk.
# It was written to easily configure on a free Amazon EC2 VPS
# NEVER EVER expose your private keys on a VPS
# Use a VPS server for secure remote harvesting only


read -p "Do you want to create swap space? Recommended for free EC2 instances [Y or N] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
# Make some additional swap memory
sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048
sudo chown root:root /var/swap.1
sudo chmod 600 /var/swap.1
sudo /sbin/mkswap /var/swap.1
sudo /sbin/swapon /var/swap.1
sudo sed -i -e '$i \/var/swap.1 swap swap defaults 0 0' /etc/fstab    
fi

# Update the software packages
sudo apt-get update
sudo apt-get upgrade -y

# Then add some dependencies in order to add java
sudo apt-get install software-properties-common -y
sudo apt-get install python-software-properties -y

# Add Java PPA
sudo add-apt-repository ppa:webupd8team/java -y

#Install Java 8
sudo apt-get update
sudo apt-get install oracle-java8-installer -y

# Add NTP for time synchronization
sudo apt-get install ntp -y

# Add Fail2ban for ssh security
sudo apt-get install fail2ban -y

# Install some other useful programs
sudo apt-get install nano -y
sudo apt-get install iptraf -y
sudo apt-get install netstat -y
sudo apt-get install htop -y
sudo apt-get install unzip -y
sudo apt-get install iftop -y


# Install dnscrypt 
# Remove bind if it exists
sudo apt-get remove bind9 -y
sudo add-apt-repository ppa:anton+/dnscrypt -y
sudo apt-get update
sudo apt-get install dnscrypt-proxy -y
sudo mkdir /run/dnscrypt
sudo chown foobar2234: /run/dnscrypt
sudo adduser --system --quiet --home /run/dnscrypt --shell /bin/false --group --disabled-password --disabled-login foobar2234
sudo sed -i -e '$i \dnscrypt-proxy --daemonize --user=foobar2234\n' /etc/rc.local
sudo restart dnscrypt-proxy


# Setup firewall, allow port 22, 123, 53, and port 7890, 
sudo iptables -F
sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -m connlimit --connlimit-above 20 -j DROP
sudo iptables -A INPUT -m hashlimit --hashlimit-name LIMIT --hashlimit-burst 20 --hashlimit-above 1/second --hashlimit-mode srcip --hashlimit-htable-expire 10000 -j DROP
sudo iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 7890 -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
sudo iptables -A INPUT -p udp --sport 123 -j ACCEPT
sudo iptables -A OUTPUT -p udp -o eth0 --dport 53 -j ACCEPT
sudo iptables -A INPUT -p udp -i eth0 --sport 53 -j ACCEPT
sudo iptables -N LOGGING
sudo iptables -A INPUT -j LOGGING
sudo iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables Packet Dropped: " --log-level 7
sudo iptables -A LOGGING -j DROP
sudo iptables -A INPUT -j DROP

# Edit sysctl configuration file to add additional ddos protecton
sudo sed -i -e '$i \net.ipv4.tcp_syn_retries = 3\n' /etc/sysctl.conf
sudo sed -i -e '$i \net.ipv4.tcp_max_orphans = 16384\n' /etc/sysctl.conf
sudo sed -i -e '$i \net.ipv4.tcp_max_tw_buckets = 16384\n' /etc/sysctl.conf
sudo sed -i -e '$i \net.ipv4.tcp_retries2 = 10\n' /etc/sysctl.conf
sudo sed -i -e '$i \net.ipv4.tcp_tw_reuse = 1\n' /etc/sysctl.conf
sudo sed -i -e '$i \net.ipv4.ip_local_port_range = 16384 65535\n' /etc/sysctl.conf
sudo sysctl -p


