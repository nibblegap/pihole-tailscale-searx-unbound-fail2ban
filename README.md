# Secure Pi-Hole + Unbound + Tailscale + Searx + Fail2Ban on an Ubuntu Server
Installation script for a secured Pi-Hole + Unbound + Tailscale + Searx + Fail2Ban on an Ubuntu Server

#### Installation instructions are in the [installation instructions file](installation_instructions.txt) file.
#### Installation script: install.sh file.

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

# Web portal locations:

Pi-Hole Web portal: "http://(tailscale_ip):85/admin/"

Searx search engine: "http://(tailscale_ip):8080"

SSH access: "ssh -p 476 username@(tailscale_ip)"
