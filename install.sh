#!/usr/bin/bash
# run which bash and replace it with /usr/bin/bash

# Author: progamerrox@github
# Date created: December 22, 2021
# A bash script to setup a Secure Ubuntu Server from scratch
# Features: Pi-Hole + Unbound + Tailscale + Fail2ban + Searx 


# Update and Upgrade
sudo apt update -y
sudo apt upgrade -y

# Install Docker for Searx
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce -y

# Install docker-compose for searx
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Install Pi-Hole from pi-hole.net bash script. Instructions from website.
curl -sSL https://install.pi-hole.net | bash

# change port from 80 to 85 if user wants to add Nginx later
sudo sed -i 's/server.port                 = .*/server.port                 = 85/' /etc/lighttpd/lighttpd.conf
5/admin/
sudo systemctl restart lighttpd

# Let user change Pi-Hole admin password
pihole -a -p 

# Make docker use UFW
# NOTE: Does not always work. Do not expose port 80 or 443 if you want to keep your Searx instance private
sudo sed -i -e '$aDOCKER_OPTS="--iptables=false"' /etc/default/docker

sudo systemctl restart docker. 

# Install unbound
sudo apt install unbound -y
apt show dns-root-data

touch /etc/unbound/unbound.conf.d/pi-hole.conf

# Unbound config file with port at 5335
echo "server:
    # If no logfile is specified, syslog is used
    # logfile: \"/var/log/unbound/unbound.log\"
    verbosity: 0

    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # May be set to yes if you have IPv6 connectivity
    do-ip6: no

    # You want to leave this to no unless you have *native* IPv6. With 6to4 and
    # Terredo tunnels your web browser should favor IPv4 for the same reasons
    prefer-ip6: no

    # Use this only when you downloaded the list of primary root servers!
    # If you use the default dns-root-data package, unbound will find it automatically
    #root-hints: \"/var/lib/unbound/root.hints\"

    # Trust glue only if it is within the server's authority
    harden-glue: yes

    # Require DNSSEC data for trust-anchored zones, if such data is absent, the zone becomes BOGUS
    harden-dnssec-stripped: yes

    # Don't use Capitalization randomization as it known to cause DNSSEC issues sometimes
    # see https://discourse.pi-hole.net/t/unbound-stubby-or-dnscrypt-proxy/9378 for further details
    use-caps-for-id: no

    # Reduce EDNS reassembly buffer size.
    # Suggested by the unbound man page to reduce fragmentation reassembly problems
    edns-buffer-size: 1472

    # Perform prefetching of close to expired message cache entries
    # This only applies to domains that have been frequently queried
    prefetch: yes

    # One thread should be sufficient, can be increased on beefy machines. In reality for most users running on small networks or on a single machine, it should be unnecessary to seek performance enhancement by increasing num-threads above 1.
    num-threads: 1

    # Ensure kernel buffer is large enough to not lose messages in traffic spikes
    so-rcvbuf: 1m

    # Ensure privacy of local IP ranges
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10" | sudo tee --append /etc/unbound/unbound.conf.d/pi-hole.conf 

sudo service unbound restart

# Stop system resolver
sudo systemctl stop systemd-resolved

# Make Cloudflare the default and fallback DNS
sudo sed -i 's/#DNS=.*/DNS=1.1.1.1/' /etc/systemd/resolved.conf
sudo sed -i 's/#FallbackDNS=.*/FallbackDNS=1.0.0.1/' /etc/systemd/resolved.conf
sudo sed -i -e '$aDNSStubListener=no' /etc/systemd/resolved.conf

sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Install Tailscale from bash script. Instructions from website.
curl -fsSL https://tailscale.com/install.sh | sh

curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list

sudo apt-get update
sudo apt-get install tailscale -y

# Start tailscale
sudo tailscale up

# SearxNG Setup
mkdir searx
cd searx
export PORT=8080
sudo docker pull searxng/searxng
sudo docker run --rm \
             -d -p ${PORT}:8080 \
             -v "${PWD}/searxng:/etc/searxng" \
             -e "BASE_URL=http://localhost:$PORT/" \
             -e "INSTANCE_NAME=Searx" \
             searxng/searxng

# Securing server

# Change port from 22 to 476
sudo sed -i 's/Port .*/Port 476/' /etc/ssh/sshd_config

sudo service sshd restart

# Install and setup ufw
sudo apt install ufw -y

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 comment 'Tailscale'
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw enable

sudo ufw status

# Disable ping requests
sudo sed -i 's/--icmp-type echo-request -j .*/--icmp-type echo-request -j DROP/' /etc/ufw/before.rules

sudo ufw reload

# Disable password authentication and root login
sudo sed -i 's/PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config

sudo service sshd restart

# Install fail2ban and setup SSH jail
sudo apt install fail2ban -y

sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local

echo "[sshd]
enabled = true
port = 476
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 604800" | sudo tee --append /etc/fail2ban/fail2ban.local  

sudo service fail2ban restart

echo "	"
echo "Connect your device to the Tailscale Network. Instructions at https://tailscale.com/download"
echo "Pi-Hole Web portal login at http://$(tailscale ip -4):85/admin"
echo "Searx search engine at http://$(tailscale ip -4):8080"
echo "SSH access: ssh -p 476 $(whoami)@$(tailscale ip -4)"
