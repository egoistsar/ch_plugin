#!/bin/bash

# SOCKS5 Proxy Server Uninstall Script
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display banner
display_banner() {
    echo -e "${BLUE}"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║       SOCKS5 Proxy Server Uninstaller        ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ Author: GitHub - egoistsar                   ║"
    echo -e "║ Repository: github.com/egoistsar/s5proxyserver ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (or with sudo)${NC}" 
   exit 1
fi

display_banner

echo -e "${YELLOW}This script will uninstall the SOCKS5 proxy server and remove all its configurations.${NC}"
echo -e "${RED}Warning: This action cannot be undone!${NC}"
read -p "Do you want to continue? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo -e "${BLUE}Starting uninstallation process...${NC}"

# Stop and disable Dante service
systemctl stop sockd 2>/dev/null || true
systemctl disable sockd 2>/dev/null || true

# Remove Dante package and dependencies
apt-get remove --purge -y dante-server libpam-pwdfile 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# Remove configuration files
rm -rf /etc/dante 2>/dev/null || true
rm -rf /etc/sockd 2>/dev/null || true
rm -f /etc/pam.d/sockd 2>/dev/null || true
rm -f /etc/systemd/system/sockd.service 2>/dev/null || true
rm -f /usr/local/bin/proxy-users 2>/dev/null || true

# Remove log files
rm -rf /var/log/sockd 2>/dev/null || true

# Remove firewall rules if possible
iptables -D INPUT -p tcp --dport 1080 -j ACCEPT 2>/dev/null || true
# Try for custom port if it exists
iptables -D INPUT -p tcp --dport 1081 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p tcp --dport 1082 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p tcp --dport 8888 -j ACCEPT 2>/dev/null || true

# Clean up systemd
systemctl daemon-reload 2>/dev/null || true

echo -e "${GREEN}SOCKS5 proxy server has been successfully uninstalled!${NC}"
echo "Thank you for using our software."

exit 0
