###### Author: orange-tin@github

###### Creation date: 12/22/2021

# Installation script for a Secure Pi-Hole + Unbound + Tailscale + Searx + Fail2Ban on an Ubuntu Server

#### Installation script: [install.sh](install.sh) file.

#### This script installs:
1. Docker
2. Docker-Compose
3. Pi-Hole
4. Unbound
5. Tailscale
6. Searx
7. UFW
8. Fail2Ban

#### It also:
1. Disables Password Authentication and Root login
2. Changes the Pi-Hole web portal port from 80 to 85 allowing the user to install Nginx/Web-server if needed
3. Tries to make docker use UFW rules (does not always work)
4. Configures unbound
5. Stops systemd-resolved to force the system to use unbound
6. Changes default SSH port to 476
7. Sets up UFW rules to allow only tailscale devices
8. Enables ping request dropping
9. Sets up Fail2Ban SSH jail (maxretry=3 and bantime=604800 (1 week))

# Installation Instructions:

## READ ALL THE INSTRUCTIONS TILL THE END TO NOT MISS SOMETHING CRUCIAL

## Notes: 
1. These steps are for creating a new server from scratch. If you are using an existing server for this script, you may skip to Step 2. Read through the installation script to ensure that there are no conflicts.
2. We'll be using a VPS server for this example, but it should work fine on any server.
3. Bash commands will have a $ before them.

## Steps:
### 1. Create a new Ubuntu 20.04 LTS server (Basic setup + creating new user):

```
$ ssh root@IP                             #(accept the fingerprint)
$ apt update -y
$ apt upgrade -y
$ adduser username                        #(change username to anything else)
$ usermod -aG sudo username
$ cd /home/username
$ mkdir .ssh
$ nano .ssh/authorized_keys               #(add your device's public key to authorize SSH)
$ exit
```

### 2. SSH into the instance using the new user (First step for users installing this on an existing server):

```
$ ssh username@IP
```

### 3. Installation process:
```
$ cd $HOME
$ nano install.sh                         #(Copy the instructions from the install.sh file) (CTRL+O and ENTER and CTRL+X to save and exit)
$ chmod +x install.sh
$ ./install.sh
```

#### Additional information:
1. Login to your tailscale account through the outputted link to connect your server
2. Follow instructions on Pi-Hole setup. Select tailscale0 as your interface, and select Cloudflare (or any other provider) as your DNS and enable web portal.

### 4. Disable Cloudflare and Enable Unbound in Pi-Hole:
1. Connect your device to the tailscale network. Instructions can be found at https://tailscale.com/download
2. Log in to the Pi-Hole admin portal (Address should have been outputted at the end of the bash script: <br/>http://(tailscale_ip):85/admin) -> Settings -> DNS -> De-select cloudflare and select custom ip = 127.0.0.1#5335 (You can also enable DNSSEC if you want to)

### 5. NOTE:
1. Searx search engine: https://(tailscale_ip):8080/
2. The server's SSH port has been changed. New SSH port = 476. SSH Access command:<br/>```ssh -p 476 username@tailscale_IP```
3. (UFW Rule prevents users from accessing SSH outside the tailscale network for security reasons) (This can be changed with ```sudo ufw allow 476/tcp```)<br/>(Port 476 was chosen at random. You may choose any port and change it to your liking in the installation script. Be sure to change all instances of "476" in the script.)
4. Pi-Hole will, by default, only listen on the interface that you selected in the installation process. If you did not select tailscale0 as your interface, you have to: <br/>Go to your Pi-Hole's settings -> DNS -> Interface listening behavior -> Select "Listen on all interfaces, permit all origins".

### IMPORTANT:
Commands to run after reboot to start searx:

```
$ cd searx
$ export PORT=8080
$ sudo docker run --rm \
             -d -p ${PORT}:8080 \
             -v "${PWD}/searxng:/etc/searxng" \
             -e "BASE_URL=http://localhost:$PORT/" \
             -e "INSTANCE_NAME=Searx" \
             searxng/searxng
```

## Web portal locations:

Pi-Hole Web portal: ```http://(tailscale_ip):85/admin/```

Searx search engine: ```http://(tailscale_ip):8080```

SSH access: ```ssh -p 476 username@(tailscale_ip)```

