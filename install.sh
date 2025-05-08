#!/bin/bash

# Simple installer script to get the main script
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display the banner in English
display_banner_en() {
    echo -e "${BLUE}"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║       SOCKS5 Proxy Server Installer          ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ Author: GitHub - egoistsar                   ║"
    echo -e "║ Repository: github.com/egoistsar/s5proxyserver ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to display the banner in Russian
display_banner_ru() {
    echo -e "${BLUE}"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║       Установщик SOCKS5 Прокси-Сервера       ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ Автор: GitHub - egoistsar                    ║"
    echo -e "║ Репозиторий: github.com/egoistsar/s5proxyserver ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (or with sudo)${NC}" 
   echo -e "${RED}Этот скрипт должен быть запущен от имени root (или с sudo)${NC}"
   exit 1
fi

# Detect language based on system locale
if [[ $(locale | grep LANG | cut -d= -f2 | cut -d_ -f1) == "ru" ]]; then
    display_banner_ru
    echo -e "${GREEN}Загрузка скрипта установки SOCKS5 прокси-сервера...${NC}"
else
    display_banner_en
    echo -e "${GREEN}Downloading SOCKS5 proxy server installation script...${NC}"
fi

# Download the main script
curl -s -L https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/debian_ubuntu_setup_proxy.sh -o debian_ubuntu_setup_proxy.sh

# Make the script executable
chmod +x debian_ubuntu_setup_proxy.sh

# Execute the main script
./debian_ubuntu_setup_proxy.sh

# Exit
exit 0
