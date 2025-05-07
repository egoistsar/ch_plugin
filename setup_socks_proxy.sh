#!/bin/bash

# This is a wrapper script that will execute the SOCKS5 Proxy Server installer
# It includes improved progress indication, error handling, and user interaction

# Ensure script is run in interactive mode
if [ ! -t 0 ]; then
    echo "This script must be run in interactive mode. Please download and run it directly."
    echo "Use these commands:"
    echo "wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh"
    echo "chmod +x setup_socks_proxy.sh"
    echo "sudo ./setup_socks_proxy.sh"
    exit 1
fi

# Ensure stdin is a terminal
exec < /dev/tty

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "\n${BLUE}>> $1${NC}"
}

print_success() {
    echo -e "\n${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "\n${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "\n${YELLOW}! $1${NC}"
}

# Function to display animated progress
show_progress() {
    local duration=$1
    local message=$2
    
    echo -en "\n${BLUE}>> $message${NC} "
    
    local end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        for (( i=0; i<8; i++ )); do
            echo -en "\b${chars:$i:1}"
            sleep 0.1
        done
    done
    
    echo -e "\b ${GREEN}✓${NC}"
}

# Function to handle errors and clean up
handle_error() {
    print_error "An error occurred during the installation"
    print_status "Cleaning up temporary files..."
    rm -f socks5_proxy_installer.sh 2>/dev/null
    exit 1
}

# Set trap for error handling
trap handle_error ERR

# Clear screen
clear

# Display ASCII art banner with colorful output
echo -e "${CYAN}"
cat << "EOF"
 ____   ___   ____ _  _____ _____ 
/ ___| / _ \ / ___| |/ / / / ____|
\___ \| | | | |   | ' / | | |     
 ___) | |_| | |___| . \ | | |____ 
|____/ \___/ \____|_|\_\ | \_____|
                        |_|       
 ____                          ____                            
|  _ \ _ __ _____  ___   _    / ___|  ___ _ ____   _____ _ __ 
| |_) | '__/ _ \ \/ / | | |   \___ \ / _ \ '__\ \ / / _ \ '__|
|  __/| | | (_) >  <| |_| |    ___) |  __/ |   \ V /  __/ |   
|_|   |_|  \___/_/\_\\__, |   |____/ \___|_|    \_/ \___|_|   
                     |___/                                     
EOF
echo -e "${NC}"

echo -e "\n${BOLD}SOCKS5 Proxy Server Interactive Installer${NC}\n"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    echo -e "\nPlease run this script with root privileges. For example:"
    echo -e "  ${CYAN}sudo bash setup_socks_proxy.sh${NC}"
    echo
    exit 1
fi

# Initialize variables with defaults to prevent "unbound variable" errors
lang_choice="1"
action_choice="1"
port_choice="1080"

# Ask user for language preference
echo -e "${YELLOW}Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:${NC}"
echo "1) English"
echo "2) Русский"

read -r -p "Enter your choice (1/2): " lang_choice
echo

LANG_PARAM=""
case $lang_choice in
    2)
        LANG_PARAM="-l ru"
        print_success "Выбран русский язык"
        ;;
    *)
        LANG_PARAM="-l en"
        print_success "English language selected"
        ;;
esac

# Ask for operation type
if [ "$lang_choice" == "2" ]; then
    echo -e "\n${YELLOW}Выберите действие:${NC}"
    echo "1) Установить SOCKS5 прокси-сервер"
    echo "2) Удалить SOCKS5 прокси-сервер"
    
    read -r -p "Введите ваш выбор (1/2): " action_choice
else
    echo -e "\n${YELLOW}Select operation:${NC}"
    echo "1) Install SOCKS5 proxy server"
    echo "2) Uninstall SOCKS5 proxy server"
    
    read -r -p "Enter your choice (1/2): " action_choice
fi
echo

ACTION_PARAM=""
case $action_choice in
    2)
        ACTION_PARAM="-a uninstall"
        if [ "$lang_choice" == "2" ]; then
            print_success "Выбрано: Удаление SOCKS5 прокси-сервера"
        else
            print_success "Selected: Uninstall SOCKS5 proxy server"
        fi
        ;;
    *)
        ACTION_PARAM="-a install"
        if [ "$lang_choice" == "2" ]; then
            print_success "Выбрано: Установка SOCKS5 прокси-сервера"
        else
            print_success "Selected: Install SOCKS5 proxy server"
        fi
        ;;
esac

# Ask for port if installing
PORT_PARAM=""
if [ "$action_choice" != "2" ]; then
    if [ "$lang_choice" == "2" ]; then
        read -r -p "Введите номер порта для SOCKS5 прокси-сервера [1080]: " port_choice
    else
        read -r -p "Enter port number for SOCKS5 proxy server [1080]: " port_choice
    fi
    
    # If port is not provided, use default
    if [ -z "$port_choice" ]; then
        port_choice="1080"
    fi
    
    PORT_PARAM="-p $port_choice"
    if [ "$lang_choice" == "2" ]; then
        print_success "Порт установлен: $port_choice"
    else
        print_success "Port set to: $port_choice"
    fi
fi

# Show selected parameters summary (without confirmation)
echo
if [ "$lang_choice" == "2" ]; then
    echo -e "${BOLD}Выбранные параметры:${NC}"
    echo -e "  Язык: $([ "$lang_choice" == "2" ] && echo "Русский" || echo "English")"
    echo -e "  Действие: $([ "$action_choice" == "2" ] && echo "Удаление" || echo "Установка")"
    [ "$action_choice" != "2" ] && echo -e "  Порт: $port_choice"
else
    echo -e "${BOLD}Selected parameters:${NC}"
    echo -e "  Language: $([ "$lang_choice" == "2" ] && echo "Russian" || echo "English")"
    echo -e "  Action: $([ "$action_choice" == "2" ] && echo "Uninstall" || echo "Install")"
    [ "$action_choice" != "2" ] && echo -e "  Port: $port_choice"
fi

# Small delay to allow user to see the parameters
sleep 1

# Download the installer script with progress indication
print_status "Downloading installer script..."

# Use curl with progress bar if available
if command -v curl &>/dev/null; then
    if [ "$lang_choice" == "2" ]; then
        echo -e "Загрузка скрипта установки..."
    else
        echo -e "Downloading installation script..."
    fi
    
    curl -# -o socks5_proxy_installer.sh https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/socks5_proxy_installer.sh
    chmod +x socks5_proxy_installer.sh
    
    print_success "Скрипт успешно загружен"
else
    # Fallback to wget if curl is not available
    if command -v wget &>/dev/null; then
        wget -q --show-progress -O socks5_proxy_installer.sh https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/socks5_proxy_installer.sh
        chmod +x socks5_proxy_installer.sh
    else
        print_error "Neither curl nor wget is installed. Cannot download the installer script."
        exit 1
    fi
fi

# Run the installer script with user-selected parameters
if [ "$lang_choice" == "2" ]; then
    print_status "Запуск установки с выбранными параметрами..."
    echo -e "Выполняется: ./socks5_proxy_installer.sh $LANG_PARAM $ACTION_PARAM $PORT_PARAM"
else
    print_status "Starting installation with selected parameters..."
    echo -e "Executing: ./socks5_proxy_installer.sh $LANG_PARAM $ACTION_PARAM $PORT_PARAM"
fi

echo -e "\n${YELLOW}--------------------------------------------------------${NC}"
./socks5_proxy_installer.sh $LANG_PARAM $ACTION_PARAM $PORT_PARAM
echo -e "${YELLOW}--------------------------------------------------------${NC}\n"

# Clean up
if [ "$lang_choice" == "2" ]; then
    print_status "Очистка временных файлов..."
else
    print_status "Cleaning up temporary files..."
fi

rm -f socks5_proxy_installer.sh 2>/dev/null

# Final message
if [ "$action_choice" == "2" ]; then
    if [ "$lang_choice" == "2" ]; then
        print_success "SOCKS5 прокси-сервер был успешно удален!"
    else
        print_success "SOCKS5 proxy server has been successfully uninstalled!"
    fi
else
    if [ "$lang_choice" == "2" ]; then
        print_success "SOCKS5 прокси-сервер был успешно установлен!"
        echo -e "\nДля управления пользователями используйте команду: ${CYAN}sudo proxy-users${NC}"
    else
        print_success "SOCKS5 proxy server has been successfully installed!"
        echo -e "\nTo manage users, use the command: ${CYAN}sudo proxy-users${NC}"
    fi
fi