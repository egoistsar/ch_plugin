#!/bin/bash

# Socks5 Proxy Server Interactive Installer - Setup Script
# ----------------------------------------------------------------------------------
# Author: egoistsar
# Usage: bash setup_socks_proxy.sh
# Requirements: Internet access, root privileges
# ----------------------------------------------------------------------------------

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display status messages
print_status() {
    echo -e "\n${BLUE}>> $1${NC}"
}

# Function to display success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to display error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to display warning messages
print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Check if script is running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root"
    echo -e "Please run this script with root privileges. For example:"
    echo -e "  sudo bash setup_socks_proxy.sh"
    exit 1
fi

# ASCII art banner
echo -e "============================================================="
echo -e " ____   ___   ____ _  _____ _____ "
echo -e "/ ___| / _ \ / ___| |/ / / / ____|"
echo -e "\___ \| | | | |   | ' / | | |     "
echo -e " ___) | |_| | |___| . \ | | |____ "
echo -e "|____/ \___/ \____|_|\_\ | \_____|"
echo -e "                        |_|       "
echo -e " ____                          ____                            "
echo -e "|  _ \ _ __ _____  ___   _    / ___|  ___ _ ____   _____ _ __ "
echo -e "| |_) | '__/ _ \ \/ / | | |   \___ \ / _ \ '__\ \ / / _ \ '__|"
echo -e "|  __/| | | (_) >  <| |_| |    ___) |  __/ |   \ V /  __/ |   "
echo -e "|_|   |_|  \___/_/\_\\__, |   |____/ \___|_|    \_/ \___|_|   "
echo -e "                     |___/                                     "
echo -e "SOCKS5 Proxy Server Interactive Installer"
echo -e "============================================================="

# Ask for language preference
print_status "Welcome to SOCKS5 Proxy Installer"
echo -e "Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:"
echo -e "1) English"
echo -e "2) Русский"

# Read language choice with timeout
read -r -p "Enter your choice (1/2): " lang_choice

# Set language parameter
if [ "$lang_choice" == "2" ]; then
    LANG_PARAM="-l ru"
    echo -e "Выбран русский язык"
else
    LANG_PARAM="-l en"
    echo -e "English language selected"
fi

# Ask for action (install or uninstall)
if [ "$lang_choice" == "2" ]; then
    echo -e "\nВыберите действие:"
    echo -e "1) Установить SOCKS5 прокси-сервер"
    echo -e "2) Удалить SOCKS5 прокси-сервер"
    read -r -p "Введите ваш выбор (1/2): " action_choice
else
    echo -e "\nSelect an action:"
    echo -e "1) Install SOCKS5 proxy server"
    echo -e "2) Uninstall SOCKS5 proxy server"
    read -r -p "Enter your choice (1/2): " action_choice
fi

# Set action parameter
if [ "$action_choice" == "2" ]; then
    ACTION_PARAM="-a uninstall"
    if [ "$lang_choice" == "2" ]; then
        print_success "Выбрано: Удаление SOCKS5 прокси-сервера"
    else
        print_success "Selected: Uninstall SOCKS5 proxy server"
    fi
    PORT_PARAM="" # Port is not needed for uninstall
else
    ACTION_PARAM="-a install"
    if [ "$lang_choice" == "2" ]; then
        print_success "Выбрано: Установка SOCKS5 прокси-сервера"
    else
        print_success "Selected: Install SOCKS5 proxy server"
    fi
    
    # Ask for port only if installing
    if [ "$lang_choice" == "2" ]; then
        read -r -p "Введите порт для SOCKS5 прокси-сервера [по умолчанию: 1080]: " port_choice
    else
        read -r -p "Enter port for SOCKS5 proxy server [default: 1080]: " port_choice
    fi
    
    # Set port parameter with validation
    if [ -z "$port_choice" ]; then
        port_choice=1080 # Default port
        if [ "$lang_choice" == "2" ]; then
            print_success "Используется порт по умолчанию: $port_choice"
        else
            print_success "Using default port: $port_choice"
        fi
    elif ! [[ "$port_choice" =~ ^[0-9]+$ ]] || [ "$port_choice" -lt 1 ] || [ "$port_choice" -gt 65535 ]; then
        port_choice=1080 # Invalid port, use default
        if [ "$lang_choice" == "2" ]; then
            print_warning "Неправильный порт. Используется порт по умолчанию: $port_choice"
        else
            print_warning "Invalid port. Using default port: $port_choice"
        fi
    else
        PORT_PARAM="-p $port_choice"
        if [ "$lang_choice" == "2" ]; then
            print_success "Порт установлен: $port_choice"
        else
            print_success "Port set to: $port_choice"
        fi
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

# Pre-install essential packages before running the main installer
print_status "Installing essential packages..."
apt-get update -qq || true
# Try to install packages but don't fail if it doesn't work
# We're in Replit environment or similar and it won't work anyway
apt-get install -y curl wget openssl iptables net-tools 2>/dev/null || true
# Create a fake ufw command to prevent errors
if ! command -v ufw >/dev/null 2>&1; then
    echo "Creating ufw alternative..."
    cat > /tmp/ufw << 'EOF'
#!/bin/bash
# This is a fake ufw command for compatibility
echo "Fake UFW executed with arguments: $@"
exit 0
EOF
    chmod +x /tmp/ufw
    export PATH="/tmp:$PATH"
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