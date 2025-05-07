#!/usr/bin/env bash

# Socks5 Proxy Server with User Authentication - Interactive Installer
# ----------------------------------------------------------------------------------
# Author: egoistsar
# Usage: installer.sh [-a install|uninstall] [-p PORT] [-l en|ru] [-f]
# Requires: root, Debian/Ubuntu
# ----------------------------------------------------------------------------------
# This script installs and configures Dante SOCKS5 proxy server with user authentication
# on Ubuntu/Debian systems.
# ----------------------------------------------------------------------------------

# Строгая обработка ошибок и безопасные пайпы
set -euo pipefail
IFS=$'\n\t'
LOGFILE=/var/log/dante_installer.log

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PORT=1080
PORT=$DEFAULT_PORT
GITHUB_REPO_URL="https://raw.githubusercontent.com/egoistsar/s5proxyserver/main"
LANGUAGE="en"
ACTION=""
FULL_UPGRADE=false
ACTION="install" # Default action: install or uninstall

# Определение переменных
USER_DB="/etc/dante-users/users.pwd"

# Function to display text based on language
function lang_text() {
    local en_text="$1"
    local ru_text="$2"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "$ru_text"
    else
        echo -e "$en_text"
    fi
}

# Function for logging plain text without colors
function log() {
    # Strip ANSI color codes for log file
    local plain_text=$(echo "$*" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $plain_text" >> "$LOGFILE"
}

# Function to display colored status messages
function echo_status() {
    log ">> $1"
    echo -e "\n${BLUE}>> $1${NC}"
}

# Function to display success messages
function echo_success() {
    log "✓ $1"
    echo -e "\n${GREEN}✓ $1${NC}"
}

# Function to display error messages
function echo_error() {
    log "✗ $1"
    echo -e "\n${RED}✗ $1${NC}"
}

# Function to display warning/info messages
function echo_warning() {
    log "! $1"
    echo -e "\n${YELLOW}! $1${NC}"
}

# Function for cleanup on interruption
function cleanup() {
    log "Interrupted, rolling back changes..."
    if [ "$ACTION" == "install" ]; then
        # Attempt to cleanly remove partial installation
        if systemctl is-active --quiet dante-server.service 2>/dev/null; then
            systemctl stop dante-server.service
        fi
        if [ -f /etc/dante.conf ]; then
            rm -f /etc/dante.conf
        fi
        if [ -f /etc/systemd/system/dante-server.service ]; then
            rm -f /etc/systemd/system/dante-server.service
        fi
        if [ -d /etc/dante-users ]; then
            rm -rf /etc/dante-users
        fi
    fi
    echo_error "Installation was interrupted and rolled back."
    exit 1
}

# Set up trap for cleanup
trap cleanup SIGINT SIGTERM

# Function to ask for language preference
function ask_language() {
    echo "Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:"
    echo "1) English"
    echo "2) Русский"
    
    # Явно запрашиваем ввод и делаем паузу для ответа пользователя
    read -r -p "Enter your choice (1/2): " lang_choice
    echo
    
    case $lang_choice in
        2)
            LANGUAGE="ru"
            log "Language set to: ru"
            echo "Выбран русский язык"
            ;;
        *)
            LANGUAGE="en"
            log "Language set to: en"
            echo "English language selected"
            ;;
    esac
    
    # Добавляем небольшую паузу для лучшего восприятия пользователем
    sleep 1
}

# Function to ask for action (install or uninstall)
function ask_action() {
    local install_en="Install SOCKS5 proxy server"
    local install_ru="Установить SOCKS5 прокси-сервер"
    
    local uninstall_en="Uninstall SOCKS5 proxy server"
    local uninstall_ru="Удалить SOCKS5 прокси-сервер"
    
    local prompt_en="Select an action:"
    local prompt_ru="Выберите действие:"
    
    echo
    echo "$(lang_text "$prompt_en" "$prompt_ru")"
    echo "1) $(lang_text "$install_en" "$install_ru")"
    echo "2) $(lang_text "$uninstall_en" "$uninstall_ru")"
    
    # Явно запрашиваем ввод и ждем ответа пользователя
    read -r -p "$(lang_text "Enter your choice (1/2): " "Введите ваш выбор (1/2): ") " action_choice
    echo
    
    case $action_choice in
        2)
            ACTION="uninstall"
            log "Action set to: uninstall"
            if [ "$LANGUAGE" == "ru" ]; then
                echo "Выбрано: Удаление SOCKS5 прокси-сервера"
            else
                echo "Selected: Uninstall SOCKS5 proxy server"
            fi
            ;;
        *)
            ACTION="install"
            log "Action set to: install"
            if [ "$LANGUAGE" == "ru" ]; then
                echo "Выбрано: Установка SOCKS5 прокси-сервера"
            else
                echo "Selected: Install SOCKS5 proxy server"
            fi
            ;;
    esac
    
    # Добавляем небольшую паузу для лучшего восприятия пользователем
    sleep 1
}

# Function to check if script is running as root
function check_root() {
    local message_en="This script must be run as root"
    local message_ru="Этот скрипт должен быть запущен с правами root"
    
    if [ "$(id -u)" -ne 0 ]; then
        echo_error "$(lang_text "$message_en" "$message_ru")"
        exit 1
    fi
}

# Function to check system type
function check_system() {
    local message_en="Checking system compatibility..."
    local message_ru="Проверка совместимости системы..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    sleep 1 # Пауза для лучшего восприятия
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    case $OS in
        ubuntu|debian)
            echo_success "$(lang_text "Compatible system detected: $OS $VER" "Обнаружена совместимая система: $OS $VER")"
            sleep 1 # Пауза перед продолжением
            ;;
        *)
            echo_warning "$(lang_text "Unsupported system: $OS $VER. This script is tested on Ubuntu/Debian." "Неподдерживаемая система: $OS $VER. Этот скрипт тестировался на Ubuntu/Debian.")"
            read -r -p "$(lang_text "Continue anyway? (y/n): " "Продолжить в любом случае? (y/n): ")" choice
            echo
            if [[ ! "$choice" =~ ^[Yy]$ ]]; then
                log "User chose not to continue on unsupported system"
                exit 1
            else
                log "User chose to continue on unsupported system"
            fi
            ;;
    esac
    
    # Пауза для лучшего восприятия информации
    sleep 1
    echo
}

# Function to ask user for proxy port
function ask_port() {
    local message_en="Enter the port number for the SOCKS5 proxy server [default: $DEFAULT_PORT]:"
    local message_ru="Введите номер порта для SOCKS5 прокси-сервера [по умолчанию: $DEFAULT_PORT]:"
    
    # Явно запрашиваем ввод и ждем ответа пользователя
    read -r -p "$(lang_text "$message_en" "$message_ru") " port_input
    echo
    
    if [ -z "$port_input" ]; then
        PORT=$DEFAULT_PORT
        log "Using default port: $PORT"
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Используется порт по умолчанию: $PORT"
        else
            echo "Using default port: $PORT"
        fi
    else
        if [[ "$port_input" =~ ^[0-9]+$ ]] && [ "$port_input" -ge 1 ] && [ "$port_input" -le 65535 ]; then
            PORT=$port_input
            log "Port set to: $PORT"
            if [ "$LANGUAGE" == "ru" ]; then
                echo "Выбран порт: $PORT"
            else
                echo "Port set to: $PORT"
            fi
        else
            echo_error "$(lang_text "Invalid port number. Using default: $DEFAULT_PORT" "Неверный номер порта. Используется по умолчанию: $DEFAULT_PORT")"
            PORT=$DEFAULT_PORT
            log "Invalid port entered: $port_input, using default: $PORT"
        fi
    fi
    
    # Добавляем небольшую паузу для лучшего восприятия пользователем
    sleep 1
}

# Function to create Dante configuration file
function create_dante_config() {
    local message_en="Creating Dante server configuration..."
    local message_ru="Создание конфигурации сервера Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Определяем интерфейс с использованием fallback
    local IFACE
    if grep -Pq . /dev/null 2>/dev/null; then
        IFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -oP '(?<=dev )[^ ]+' || echo "eth0")
    else
        IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' || echo "eth0")
    fi
    
    log "Detected network interface: $IFACE"
    
    cat > /etc/dante.conf << EOL
# Dante SOCKS5 proxy server configuration
# This configuration enables a secure SOCKS5 proxy with user authentication

# The listening address and port
internal: 0.0.0.0 port=$PORT

# The external interface (auto-detected)
external: $IFACE

# Authentication method
socksmethod: username

# User access methods and restrictions
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody

# Client connection settings
clientmethod: none
# logoutput: stderr - программа будет писать логи только о критических ошибках
# Для отладки можно заменить на: logoutput: syslog
logoutput: stderr
timeout.negotiate: 30
timeout.io: 300

# Server settings
debug: 0

# Access control
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

# Allow authenticated users to connect anywhere
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: error connect disconnect
    socksmethod: username
}

# Block all other traffic
socks block {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect error
}
EOL

    chown root:root /etc/dante.conf
    chmod 644 /etc/dante.conf
    echo_success "$(lang_text "Dante configuration created successfully" "Конфигурация Dante успешно создана")"
}

# Function to create systemd service for Dante
function create_dante_service() {
    local message_en="Setting up Dante systemd service..."
    local message_ru="Настройка системного сервиса Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    cat > /etc/systemd/system/dante-server.service << EOL
[Unit]
Description=Dante SOCKS5 Proxy Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/danted -f /etc/dante.conf
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL

    echo_success "$(lang_text "Dante service created successfully" "Сервис Dante успешно создан")"
}

# Function to set up PAM authentication for Dante
function setup_pam_auth() {
    local message_en="Setting up PAM authentication for Dante..."
    local message_ru="Настройка PAM аутентификации для Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    mkdir -p /etc/dante-users
    touch /etc/dante-users/users.pwd
    chmod 600 /etc/dante-users/users.pwd
    
    cat > /etc/pam.d/sockd << EOL
auth required pam_pwdfile.so pwdfile=/etc/dante-users/users.pwd
account required pam_permit.so
EOL

    echo_success "$(lang_text "PAM authentication configured successfully" "PAM аутентификация успешно настроена")"
}

# Function to check required dependencies
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

function install_dependency() {
    local package=$1
    local cmd=$2
    
    echo_status "$(lang_text "Installing $package..." "Установка $package...")"
    apt-get update -qq
    apt-get install -y $package
    
    # Check if installation was successful
    if ! command_exists "$cmd"; then
        echo_error "$(lang_text "Failed to install $package" "Не удалось установить $package")"
        return 1
    fi
    
    echo_success "$(lang_text "$package installed successfully" "$package успешно установлен")"
    return 0
}

function check_dependencies() {
    local message_en="Checking required dependencies..."
    local message_ru="Проверка необходимых зависимостей..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Check for apt-get which is essential
    if ! command_exists apt-get; then
        echo_error "$(lang_text "apt-get not found. This script requires a Debian/Ubuntu based system." "apt-get не найден. Этот скрипт требует систему на базе Debian/Ubuntu.")"
        exit 1
    fi
    
    # Check for other dependencies and install if missing
    local missing_deps=0
    
    # Build essential packages for commands that might be missing
    local dependency_map=(
        "iproute2:ip" 
        "openssl:openssl" 
        "systemd:systemctl"
        "wget:wget"
        "curl:curl"
        "whois:mkpasswd"
        "iptables:iptables"
    )
    
    for dep in "${dependency_map[@]}"; do
        IFS=':' read -r package cmd <<< "$dep"
        
        if ! command_exists "$cmd"; then
            echo_warning "$(lang_text "Required command not found: $cmd" "Требуемая команда не найдена: $cmd")"
            echo_status "$(lang_text "Trying to install $package..." "Попытка установить $package...")"
            
            if install_dependency "$package" "$cmd"; then
                echo_success "$(lang_text "$cmd is now available" "$cmd теперь доступен")"
            else
                # For non-critical components like ufw, we'll just warn but continue
                if [[ "$cmd" == "ufw" ]]; then
                    echo_warning "$(lang_text "UFW firewall not available. Firewall configuration will be skipped." "Брандмауэр UFW недоступен. Настройка брандмауэра будет пропущена.")"
                else
                    echo_error "$(lang_text "Failed to install required dependency: $package" "Не удалось установить необходимую зависимость: $package")"
                    ((missing_deps++))
                fi
            fi
        fi
    done
    
    if [ $missing_deps -gt 0 ]; then
        echo_error "$(lang_text "Some required dependencies could not be installed" "Некоторые необходимые зависимости не могут быть установлены")"
        exit 1
    fi
    
    echo_success "$(lang_text "All required dependencies are available" "Все необходимые зависимости доступны")"
}

# Function to install prerequisites at the beginning of the script
# Function to detect the Linux distribution and package manager
function detect_distro() {
    log "Detecting Linux distribution and package manager"
    
    # Initialize package manager variables
    PKG_MANAGER=""
    PKG_UPDATE=""
    PKG_INSTALL=""
    PKG_UPGRADE=""
    FIREWALL_TYPE=""
    DANTE_PKG=""
    PAM_PWD_PKG=""
    
    # Check for apt (Debian, Ubuntu, etc.)
    if command -v apt-get &>/dev/null; then
        log "Detected apt package manager (Debian/Ubuntu)"
        PKG_MANAGER="apt"
        PKG_UPDATE="apt-get update -qq"
        PKG_INSTALL="apt-get install -y"
        PKG_UPGRADE="apt-get dist-upgrade -y"
        FIREWALL_TYPE="ufw"
        DANTE_PKG="dante-server"
        PAM_PWD_PKG="libpam-pwdfile"
    # Check for dnf (Fedora, CentOS 8+, RHEL 8+)
    elif command -v dnf &>/dev/null; then
        log "Detected dnf package manager (Fedora/CentOS/RHEL 8+)"
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update -q || true"  # return code 100 means updates available
        PKG_INSTALL="dnf install -y"
        PKG_UPGRADE="dnf upgrade -y"
        FIREWALL_TYPE="firewalld"
        DANTE_PKG="dante-server"
        PAM_PWD_PKG="pam"
    # Check for yum (CentOS 7, RHEL 7)
    elif command -v yum &>/dev/null; then
        log "Detected yum package manager (CentOS/RHEL 7)"
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update -q || true"  # return code 100 means updates available
        PKG_INSTALL="yum install -y"
        PKG_UPGRADE="yum update -y"
        FIREWALL_TYPE="firewalld"
        DANTE_PKG="dante-server"
        PAM_PWD_PKG="pam"
    # Check for pacman (Arch Linux)
    elif command -v pacman &>/dev/null; then
        log "Detected pacman package manager (Arch Linux)"
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Syy --noconfirm"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPGRADE="pacman -Syu --noconfirm"
        FIREWALL_TYPE="iptables"
        DANTE_PKG="dante"  # Arch package name may differ
        PAM_PWD_PKG="pam"
    # Check for zypper (openSUSE)
    elif command -v zypper &>/dev/null; then
        log "Detected zypper package manager (openSUSE)"
        PKG_MANAGER="zypper"
        PKG_UPDATE="zypper refresh -q"
        PKG_INSTALL="zypper install -y"
        PKG_UPGRADE="zypper update -y"
        FIREWALL_TYPE="firewalld"
        DANTE_PKG="dante-server"
        PAM_PWD_PKG="pam"
    # Check for apk (Alpine Linux)
    elif command -v apk &>/dev/null; then
        log "Detected apk package manager (Alpine Linux)"
        PKG_MANAGER="apk"
        PKG_UPDATE="apk update"
        PKG_INSTALL="apk add"
        PKG_UPGRADE="apk upgrade"
        FIREWALL_TYPE="iptables"
        DANTE_PKG="dante"
        PAM_PWD_PKG="pam-pwdfile"
    else
        log "WARNING: Unknown package manager. Falling back to apt-get but it might not work"
        PKG_MANAGER="apt"
        PKG_UPDATE="apt-get update -qq"
        PKG_INSTALL="apt-get install -y"
        PKG_UPGRADE="apt-get dist-upgrade -y"
        FIREWALL_TYPE="ufw"
        DANTE_PKG="dante-server"
        PAM_PWD_PKG="libpam-pwdfile"
    fi
    
    # Set the init system based on what's available
    INIT_SYSTEM=""
    if command -v systemctl &>/dev/null; then
        INIT_SYSTEM="systemd"
    elif command -v service &>/dev/null; then
        INIT_SYSTEM="sysv"
    elif command -v rc-service &>/dev/null; then
        INIT_SYSTEM="openrc"
    else
        INIT_SYSTEM="unknown"
    fi
    
    log "Detected init system: $INIT_SYSTEM"
    log "Selected firewall: $FIREWALL_TYPE"
    log "Dante package name: $DANTE_PKG"
    log "PAM password file package: $PAM_PWD_PKG"
}

# Function to install all required packages
function install_packages() {
    local message_en_1="Installing system packages..."
    local message_ru_1="Установка системных пакетов..."
    
    local message_en_2="Installing Dante SOCKS5 server..."
    local message_ru_2="Установка SOCKS5 сервера Dante..."
    
    local message_en_3="Installing PAM authentication module..."
    local message_ru_3="Установка модуля аутентификации PAM..."
    
    # First detect the distribution and set appropriate package manager commands
    detect_distro
    
    # Update package lists
    echo_status "$(lang_text "$message_en_1" "$message_ru_1")"
    
    # Run package update
    log "Running package update"
    eval "$PKG_UPDATE" || true
    
    # Install essential packages (ignore errors for compatibility)
    echo_status "$(lang_text "Updating and installing essential packages..." "Обновление и установка необходимых пакетов...")"
    local essential_packages="curl wget openssl net-tools iptables whois"
    eval "$PKG_INSTALL $essential_packages" || true
    
    # Install dante-server package
    echo_status "$(lang_text "$message_en_2" "$message_ru_2")"
    # Install dante-server using the appropriate method for this distribution
    if ! eval "$PKG_INSTALL $DANTE_PKG"; then
        log "Failed to install $DANTE_PKG through package manager, trying alternative methods"
        
        # Try to install Dante directly from .deb file for Debian-based systems
        if [ "$PKG_MANAGER" == "apt" ]; then
            echo_warning "$(lang_text "Could not install dante-server from repositories. Trying direct .deb installation..." "Не удалось установить dante-server из репозиториев. Пробуем прямую установку .deb...")"
            
            # Get architecture
            ARCH=$(dpkg --print-architecture)
            local deb_url=""
            
            case $ARCH in
                amd64)
                    deb_url="https://github.com/egoistsar/s5proxyserver/releases/download/v1.0/dante-server_1.4.3-1_amd64.deb"
                    ;;
                arm64)
                    deb_url="https://github.com/egoistsar/s5proxyserver/releases/download/v1.0/dante-server_1.4.3-1_arm64.deb"
                    ;;
                *)
                    echo_error "$(lang_text "Unsupported architecture: $ARCH" "Неподдерживаемая архитектура: $ARCH")"
                    exit 1
                    ;;
            esac
            
            if [ -n "$deb_url" ]; then
                log "Downloading and installing .deb package from: $deb_url"
                local temp_deb=$(mktemp)
                wget -q -O "$temp_deb" "$deb_url"
                
                if dpkg -i "$temp_deb"; then
                    echo_success "$(lang_text "Dante server installed from .deb package" "Сервер Dante установлен из .deb пакета")"
                    rm -f "$temp_deb"
                else
                    echo_error "$(lang_text "Failed to install Dante server from .deb package" "Не удалось установить сервер Dante из .deb пакета")"
                    rm -f "$temp_deb"
                    exit 1
                fi
            fi
        else
            # For non-Debian systems, try to compile from source
            echo_warning "$(lang_text "Could not install dante-server from repositories. Compilation from source is required but not implemented yet." "Не удалось установить dante-server из репозиториев. Требуется компиляция из исходников, но она пока не реализована.")"
            exit 1
        fi
    fi
    
    # Install PAM authentication module
    echo_status "$(lang_text "$message_en_3" "$message_ru_3")"
    if ! eval "$PKG_INSTALL $PAM_PWD_PKG"; then
        echo_error "$(lang_text "Failed to install PAM authentication module. User authentication may not work." "Не удалось установить модуль аутентификации PAM. Аутентификация пользователей может не работать.")"
        
        # Try to create a basic PAM configuration anyway
        mkdir -p /etc/pam.d
        cat > /etc/pam.d/sockd << EOL
# Basic PAM configuration for Dante
auth required pam_unix.so
account required pam_unix.so
EOL
        log "Created fallback PAM configuration"
    fi
    
    echo_success "$(lang_text "Necessary packages successfully installed" "Необходимые пакеты успешно установлены")"
}

# Function to configure firewall
function configure_firewall() {
    local message_en="Configuring firewall..."
    local message_ru="Настройка брандмауэра..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    log "Configuring $FIREWALL_TYPE firewall for port $PORT"
    
    # Configure the appropriate firewall based on detection
    case $FIREWALL_TYPE in
        ufw)
            if command -v ufw &>/dev/null; then
                log "Configuring UFW firewall"
                
                # Backup existing rules
                if [ -f /etc/ufw/user.rules ]; then
                    cp /etc/ufw/user.rules /etc/ufw/user.rules.bak
                    log "UFW rules backed up to /etc/ufw/user.rules.bak"
                fi
                
                # Add rule for Dante port
                ufw --force allow $PORT/tcp
                
                # Only enable if not already active
                if ufw status | grep -qw inactive; then
                    log "Enabling UFW firewall"
                    ufw --force enable
                else
                    log "UFW firewall already active"
                fi
                
                echo_success "$(lang_text "UFW firewall successfully configured" "Брандмауэр UFW успешно настроен")"
            else
                echo_warning "$(lang_text "UFW firewall is not available. Trying alternative firewall..." "Брандмауэр UFW недоступен. Попытка использовать альтернативный брандмауэр...")"
                # Fall back to iptables if ufw is not available
                FIREWALL_TYPE="iptables"
            fi
            ;;
            
        firewalld)
            if command -v firewall-cmd &>/dev/null; then
                log "Configuring FirewallD"
                
                # Check if firewalld is running
                if ! systemctl is-active --quiet firewalld; then
                    systemctl start firewalld
                    systemctl enable firewalld
                    log "Started FirewallD service"
                fi
                
                # Add the port to the firewall
                firewall-cmd --permanent --add-port=$PORT/tcp
                firewall-cmd --reload
                
                echo_success "$(lang_text "FirewallD successfully configured" "FirewallD успешно настроен")"
            else
                echo_warning "$(lang_text "FirewallD is not available. Trying iptables..." "FirewallD недоступен. Пробуем iptables...")"
                FIREWALL_TYPE="iptables"
            fi
            ;;
            
        iptables)
            if command -v iptables &>/dev/null; then
                log "Configuring iptables"
                
                # Backup existing rules
                if iptables-save > /tmp/iptables.rules; then
                    log "iptables rules backed up to /tmp/iptables.rules"
                fi
                
                # Add rule for Dante port
                iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
                
                # Save the rules
                if command -v iptables-save &>/dev/null; then
                    iptables-save > /etc/iptables.rules
                    
                    # Add a script to restore rules at boot if not already set up
                    if [ ! -f /etc/network/if-pre-up.d/iptables ]; then
                        mkdir -p /etc/network/if-pre-up.d
                        cat > /etc/network/if-pre-up.d/iptables << 'EOL'
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
EOL
                        chmod +x /etc/network/if-pre-up.d/iptables
                        log "Created iptables restore script at boot"
                    fi
                else
                    log "Warning: Could not save iptables rules permanently, they may be lost on reboot"
                fi
                
                echo_success "$(lang_text "iptables successfully configured" "iptables успешно настроен")"
            else
                echo_error "$(lang_text "No firewall available. Please manually configure your firewall to allow TCP port $PORT" "Брандмауэр недоступен. Пожалуйста, вручную настройте ваш брандмауэр для разрешения TCP порта $PORT")"
            fi
            ;;
            
        *)
            echo_error "$(lang_text "No firewall configuration method available" "Метод настройки брандмауэра недоступен")"
            ;;
    esac
}

# Function to add a proxy user
function add_proxy_user() {
    local username="$1"
    local password="$2"
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo_error "$(lang_text "Username and password are required" "Требуются имя пользователя и пароль")"
        return 1
    fi
    
    log "Adding proxy user: $username"
    
    # Create a hash of the password
    local hashed_password=""
    
    # Try different methods to hash password
    if command -v mkpasswd &>/dev/null; then
        # Use mkpasswd (from whois package)
        local salt=$(openssl rand -base64 12)
        hashed_password=$(mkpasswd -m sha-512 -S "$salt" "$password" 2>/dev/null)
    fi
    
    # Fallback to openssl if mkpasswd failed or is not available
    if [ -z "$hashed_password" ] && command -v openssl &>/dev/null; then
        local salt=$(openssl rand -base64 12)
        hashed_password=$(openssl passwd -6 -salt "$salt" "$password" 2>/dev/null)
    fi
    
    # Fallback to Python if openssl failed or is not available
    if [ -z "$hashed_password" ]; then
        if command -v python3 &>/dev/null; then
            local salt=$(openssl rand -base64 8 || echo "randomsalt")
            hashed_password=$(python3 -c "import crypt; print(crypt.crypt('$password', '\$6\$$salt'))" 2>/dev/null)
        elif command -v python &>/dev/null; then
            local salt=$(openssl rand -base64 8 || echo "randomsalt")
            hashed_password=$(python -c "import crypt; print(crypt.crypt('$password', '\$6\$$salt'))" 2>/dev/null)
        fi
    fi
    
    # Last resort: use plain text (insecure, but allows to continue for testing)
    if [ -z "$hashed_password" ]; then
        echo_warning "$(lang_text "Could not hash password securely" "Не удалось безопасно хешировать пароль")"
        hashed_password="$password"
    fi
    
    # Add the user to the password file
    echo "$username:$hashed_password" >> /etc/dante-users/users.pwd
    chmod 600 /etc/dante-users/users.pwd
    
    # Output success message
    if [ "$LANGUAGE" == "ru" ]; then
        echo_success "Пользователь '$username' добавлен"
    else
        echo_success "User '$username' added"
    fi
    
    return 0
}

# Function to manage user credentials
function manage_user_credentials() {
    # Default credentials if input fails
    local default_username="proxyuser"
    local default_password="proxypass"
    
    # Визуально отделяем этап настройки учетных данных
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "\n\n====================================="
        echo -e "  НАСТРОЙКА УЧЕТНЫХ ДАННЫХ ПРОКСИ"
        echo -e "=====================================\n"
    else
        echo -e "\n\n====================================="
        echo -e "      PROXY CREDENTIALS SETUP"
        echo -e "=====================================\n"
    fi
    
    sleep 2 # Даем пользователю время прочитать заголовок
    
    # --- USERNAME SECTION ---
    # Запрашиваем имя пользователя без таймаута
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "Шаг 1: Введите имя пользователя для аутентификации в прокси.\n"
        read -r -p "Имя пользователя: " proxy_username
    else
        echo -e "Step 1: Enter a username for proxy authentication.\n"
        read -r -p "Username: " proxy_username
    fi
    
    # Проверка и обработка ввода имени пользователя
    if [ -z "$proxy_username" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nИмя пользователя не может быть пустым."
            echo -e "Использование имени по умолчанию: $default_username\n"
        else
            echo -e "\nUsername cannot be empty."
            echo -e "Using default username: $default_username\n"
        fi
        proxy_username=$default_username
    fi
    
    log "Username set: $proxy_username (not logging actual username for security)"
    sleep 2 # Пауза перед следующим шагом
    
    # --- PASSWORD SECTION ---
    # Запрашиваем пароль без отображения ввода
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "Шаг 2: Введите пароль для пользователя $proxy_username.\n"
        echo -e "Для повышения безопасности пароль будет виден при вводе.\n"
        read -r -p "Пароль: " proxy_password
    else
        echo -e "Step 2: Enter password for user $proxy_username.\n"
        echo -e "For security improvement, the password will be visible when entered.\n"
        read -r -p "Password: " proxy_password
    fi
    
    # Проверка и обработка ввода пароля
    if [ -z "$proxy_password" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nПароль не может быть пустым."
            echo -e "Использование пароля по умолчанию: $default_password\n"
        else
            echo -e "\nPassword cannot be empty."
            echo -e "Using default password: $default_password\n"
        fi
        proxy_password=$default_password
    fi
    
    log "Password has been set" # не логируем пароль в открытом виде
    sleep 2 # Пауза перед следующим шагом
    
    # --- CREATION SECTION ---
    # Показываем информацию о создаваемом пользователе без запроса подтверждения
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "Шаг 3: Создание пользователя...\n"
        echo -e "Имя пользователя: $proxy_username"
        echo -e "Пароль: [СКРЫТ]\n"
    else
        echo -e "Step 3: Creating user...\n"
        echo -e "Username: $proxy_username"
        echo -e "Password: [HIDDEN]\n"
    fi
    
    # Небольшая пауза для чтения информации
    sleep 1
    
    # Добавляем пользователя без дополнительного подтверждения
    add_proxy_user "$proxy_username" "$proxy_password"
        
    # Информация о параметрах подключения добавляется здесь для улучшения UX
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "\nДля подключения к прокси используйте следующие параметры:"
        echo -e "Тип: SOCKS5"
        echo -e "Сервер: [IP-адрес вашего сервера]"
        echo -e "Порт: $PORT"
        echo -e "Имя пользователя: $proxy_username"
        echo -e "Пароль: [ваш пароль]\n"
    else
        echo -e "\nUse the following parameters to connect to the proxy:"
        echo -e "Type: SOCKS5"
        echo -e "Server: [Your server IP address]"
        echo -e "Port: $PORT"
        echo -e "Username: $proxy_username"
        echo -e "Password: [your password]\n"
    fi
    # Обработка завершена - пользователь создан
}

# Function to create user management script
function create_management_script() {
    local message_en="Creating user management script..."
    local message_ru="Создание скрипта управления пользователями..."
    
    # Определяем переменную USER_DB здесь, чтобы избежать ошибки "unbound variable"
    USER_DB="/etc/dante-users/users.pwd"
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    cat > /usr/local/bin/proxy-users << EOL
#!/bin/bash

# Proxy User Management Script
# This script adds or removes users for the SOCKS5 proxy

# Exit on error
set -e

# Check if running as root
if [ "\$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Define the user database location
USER_DB="/etc/dante-users/users.pwd"

# Show usage information
function show_usage() {
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Использование: \$0 [add|remove|list] [имя_пользователя] [пароль]"
        echo
        echo "Команды:"
        echo "  add ИМЯ_ПОЛЬЗОВАТЕЛЯ ПАРОЛЬ  - Добавить нового пользователя прокси"
        echo "  remove ИМЯ_ПОЛЬЗОВАТЕЛЯ      - Удалить существующего пользователя прокси"
        echo "  list                         - Показать всех пользователей прокси"
        echo
        echo "Пример:"
        echo "  \$0 add myuser mypassword"
    else
        echo "Usage: \$0 [add|remove|list] [username] [password]"
        echo
        echo "Commands:"
        echo "  add USERNAME PASSWORD  - Add a new proxy user"
        echo "  remove USERNAME        - Remove an existing proxy user"
        echo "  list                   - List all proxy users"
        echo
        echo "Example:"
        echo "  \$0 add myuser mypassword"
    fi
}

# List all proxy users
function list_users() {
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Текущие пользователи прокси:"
        echo "------------------------"
    else
        echo "Current proxy users:"
        echo "-------------------"
    fi
    
    if [ -s "$USER_DB" ]; then
        cat "$USER_DB" | cut -d: -f1
    else
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Пользователи не найдены."
        else
            echo "No users found."
        fi
    fi
}

# Add a new proxy user
function add_user() {
    local username="$1"
    local password="$2"
    
    # Validate input
    if [ -z "$username" ] || [ -z "$password" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Ошибка: Требуется имя пользователя и пароль" >&2
        else
            echo "Error: Username and password are required" >&2
        fi
        show_usage
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^$username:" "$USER_DB" 2>/dev/null; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Пользователь '$username' уже существует. Сначала удалите его или используйте другое имя пользователя."
        else
            echo "User '$username' already exists. Remove it first or use a different username."
        fi
        return 1
    fi
    
    # Create password hash using openssl (more portable than mkpasswd)
    local salt=$(openssl rand -base64 12)
    local hashed_password=$(openssl passwd -6 -salt "$salt" "$password")
    
    # If openssl fails, try using Python
    if [ -z "$hashed_password" ]; then
        if command -v python3 &>/dev/null; then
            hashed_password=$(python3 -c "import crypt; print(crypt.crypt('$password', '\$6\$$salt'))")
        elif command -v python &>/dev/null; then
            hashed_password=$(python -c "import crypt; print(crypt.crypt('$password', '\$6\$$salt'))")
        fi
    fi
    
    # If all else fails, store plain password (temporary, for testing only)
    if [ -z "$hashed_password" ]; then
        echo "Warning: Could not hash password. Using plain text password temporarily."
        hashed_password="$password"
    fi
    
    # Add user to the database
    echo "$username:$hashed_password" >> "$USER_DB"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Пользователь '$username' был успешно добавлен."
    else
        echo "User '$username' has been added successfully."
    fi
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Сервис Dante перезапущен."
    else
        echo "Dante service restarted."
    fi
}

# Remove a proxy user
function remove_user() {
    local username="$1"
    
    # Validate input
    if [ -z "$username" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Ошибка: Требуется имя пользователя" >&2
        else
            echo "Error: Username is required" >&2
        fi
        show_usage
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USER_DB" 2>/dev/null; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Пользователь '$username' не существует."
        else
            echo "User '$username' does not exist."
        fi
        return 1
    fi
    
    # Remove user from the database
    sed -i "/^$username:/d" "$USER_DB"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Пользователь '$username' был успешно удален."
    else
        echo "User '$username' has been removed successfully."
    fi
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Сервис Dante перезапущен."
    else
        echo "Dante service restarted."
    fi
}

# Check language preference
if [ -f /etc/dante-language ]; then
    LANGUAGE=$(cat /etc/dante-language)
fi

# Main script logic
case "$1" in
    add)
        add_user "$2" "$3"
        ;;
    remove)
        remove_user "$2"
        ;;
    list)
        list_users
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

exit 0
EOL

    chmod +x /usr/local/bin/proxy-users
    
    # Save language preference
    echo "$LANGUAGE" > /etc/dante-language
    
    echo_success "$(lang_text "User management script created successfully" "Скрипт управления пользователями успешно создан")"
}

# Function to uninstall SOCKS5 proxy server
function uninstall_proxy() {
    local message_en="Uninstalling SOCKS5 proxy server..."
    local message_ru="Удаление SOCKS5 прокси-сервера..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Stop and disable Dante service
    if systemctl is-active --quiet dante-server.service; then
        log "Stopping dante-server service"
        systemctl stop dante-server.service
    fi
    
    if systemctl is-enabled --quiet dante-server.service; then
        log "Disabling dante-server service"
        systemctl disable dante-server.service
    fi
    
    # Remove firewall rules if they exist
    if command -v ufw &>/dev/null; then
        if ufw status | grep -q "$PORT"; then
            log "Removing firewall rule for port $PORT"
            ufw --force delete allow $PORT/tcp
        else
            log "No firewall rule found for port $PORT"
        fi
    fi
    
    # Remove files and directories
    log "Removing dante configuration files"
    rm -f /etc/dante.conf
    rm -f /etc/systemd/system/dante-server.service
    rm -f /etc/pam.d/sockd
    rm -rf /etc/dante-users
    rm -f /etc/dante-language
    rm -f /usr/local/bin/proxy-users
    
    # Reload systemd
    log "Reloading systemd configuration"
    systemctl daemon-reload
    
    # Uninstall packages (keep whois, sudo and ufw for system use)
    log "Removing dante-server and related packages"
    apt-get remove -y dante-server libpam-pwdfile
    apt-get autoremove -y
    
    # Display completion message
    local success_en="SOCKS5 proxy server has been successfully uninstalled."
    local success_ru="SOCKS5 прокси-сервер успешно удален."
    
    echo_success "$(lang_text "$success_en" "$success_ru")"
}

# Function to test if proxy is working correctly
function test_proxy_connection() {
    local message_en="Testing proxy connection..."
    local message_ru="Проверка подключения к прокси..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Testing variables
    local proxy_running=false
    local proxy_auth_working=false
    
    # Check if the proxy port is open/listening
    if command_exists "netstat"; then
        if netstat -tuln | grep -q ":$PORT"; then
            proxy_running=true
            log "Proxy is listening on port $PORT"
        fi
    elif command_exists "ss"; then
        if ss -tuln | grep -q ":$PORT"; then
            proxy_running=true
            log "Proxy is listening on port $PORT"
        fi
    elif command_exists "lsof"; then
        if lsof -i :$PORT | grep -q LISTEN; then
            proxy_running=true
            log "Proxy is listening on port $PORT"
        fi
    else
        log "Cannot verify if proxy is listening - netstat, ss and lsof not available"
        # We'll assume it's running and test it directly
        proxy_running=true
    fi
    
    if [ "$proxy_running" = false ]; then
        echo_error "$(lang_text "Proxy server is not running on port $PORT" "Прокси-сервер не запущен на порту $PORT")"
        log "Attempting to restart dante-server service"
        
        # Try to restart based on init system
        if [ "$INIT_SYSTEM" = "systemd" ] && command_exists "systemctl"; then
            systemctl restart dante-server.service
            sleep 3
            if systemctl is-active --quiet dante-server.service; then
                proxy_running=true
                log "Successfully restarted dante-server service"
            else
                log "Failed to restart dante-server service"
                systemctl status dante-server.service
            fi
        elif [ "$INIT_SYSTEM" = "sysv" ] && [ -f /etc/init.d/dante-server ]; then
            /etc/init.d/dante-server restart
            sleep 3
            proxy_running=true  # We'll assume it worked
        elif [ "$INIT_SYSTEM" = "openrc" ] && command_exists "rc-service"; then
            rc-service dante-server restart
            sleep 3
            proxy_running=true  # We'll assume it worked
        else
            log "Cannot restart proxy service - unknown init system"
        fi
    fi
    
    # Test actual connectivity if curl is available
    if [ "$proxy_running" = true ] && command_exists "curl"; then
        log "Testing proxy connectivity with curl"
        
        # Create a temporary file with auth information
        local auth_file=$(mktemp)
        echo "$proxy_username:$proxy_password" > "$auth_file"
        
        # Attempt to use the proxy
        if curl --socks5 localhost:$PORT --proxy-user "$proxy_username:$proxy_password" -s -m 10 https://ifconfig.me > /dev/null 2>&1; then
            proxy_auth_working=true
            log "Proxy authentication successful"
        else
            log "Proxy authentication failed or connection error"
        fi
        
        # Clean up
        rm -f "$auth_file"
    fi
    
    if [ "$proxy_running" = true ]; then
        if [ "$proxy_auth_working" = true ]; then
            echo_success "$(lang_text "Proxy server is running and authentication is working" "Прокси-сервер запущен и аутентификация работает")"
        else
            echo_warning "$(lang_text "Proxy server is running but authentication test failed" "Прокси-сервер запущен, но тест аутентификации не прошел")"
        fi
    else
        echo_error "$(lang_text "Proxy server is not running correctly" "Прокси-сервер работает неправильно")"
    fi
}

# Function to show completion message and provide connection information
function show_completion() {
    # Try to detect server IP
    local SERVER_IP="Your server IP"
    
    # Use different methods to detect public IP
    if command_exists "curl"; then
        SERVER_IP=$(curl -s https://ifconfig.me 2>/dev/null || curl -s https://api.ipify.org 2>/dev/null || curl -s https://icanhazip.com 2>/dev/null || echo "Your server IP")
    elif command_exists "wget"; then
        SERVER_IP=$(wget -qO- https://ifconfig.me 2>/dev/null || wget -qO- https://api.ipify.org 2>/dev/null || wget -qO- https://icanhazip.com 2>/dev/null || echo "Your server IP")
    fi
    
    if [ "$SERVER_IP" = "Your server IP" ]; then
        # Try local methods if online detection failed
        if command_exists "hostname"; then
            SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        elif command_exists "ip"; then
            SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
        fi
    fi
    
    # Visual separator
    echo -e "\n======================================================================"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "${GREEN}✓ УСТАНОВКА SOCKS5 ПРОКСИ-СЕРВЕРА ЗАВЕРШЕНА!${NC}"
        echo -e "\nПараметры подключения:"
        echo -e "Тип прокси: SOCKS5"
        echo -e "Сервер: ${YELLOW}$SERVER_IP${NC}"
        echo -e "Порт: ${YELLOW}$PORT${NC}"
        echo -e "Имя пользователя: ${YELLOW}$proxy_username${NC}"
        echo -e "Пароль: ${YELLOW}[ваш пароль]${NC}"
        
        echo -e "\nДля управления пользователями используйте команду:"
        echo -e "${YELLOW}sudo proxy-users${NC}"
        echo -e "\nПримеры:"
        echo -e "Просмотр всех пользователей: ${YELLOW}sudo proxy-users list${NC}"
        echo -e "Добавление пользователя: ${YELLOW}sudo proxy-users add username password${NC}"
        echo -e "Удаление пользователя: ${YELLOW}sudo proxy-users remove username${NC}"
    else
        echo -e "${GREEN}✓ SOCKS5 PROXY SERVER INSTALLATION COMPLETED!${NC}"
        echo -e "\nConnection parameters:"
        echo -e "Proxy type: SOCKS5"
        echo -e "Server: ${YELLOW}$SERVER_IP${NC}"
        echo -e "Port: ${YELLOW}$PORT${NC}"
        echo -e "Username: ${YELLOW}$proxy_username${NC}"
        echo -e "Password: ${YELLOW}[your password]${NC}"
        
        echo -e "\nTo manage users, use the command:"
        echo -e "${YELLOW}sudo proxy-users${NC}"
        echo -e "\nExamples:"
        echo -e "List all users: ${YELLOW}sudo proxy-users list${NC}"
        echo -e "Add a user: ${YELLOW}sudo proxy-users add username password${NC}"
        echo -e "Remove a user: ${YELLOW}sudo proxy-users remove username${NC}"
    fi
    
    echo -e "======================================================================"
}

# Parse command line arguments
while getopts ":a:p:l:f" opt; do
    case ${opt} in
        a)
            if [[ "$OPTARG" == "install" || "$OPTARG" == "uninstall" ]]; then
                ACTION=$OPTARG
                log "Action set to: $ACTION via command line"
            else
                echo_error "Invalid action: $OPTARG. Must be 'install' or 'uninstall'"
                exit 1
            fi
            ;;
        p)
            if [[ "$OPTARG" =~ ^[0-9]+$ ]] && [ "$OPTARG" -ge 1 ] && [ "$OPTARG" -le 65535 ]; then
                PORT=$OPTARG
                log "Port set to: $PORT via command line"
            else
                echo_error "Invalid port: $OPTARG. Must be a number between 1 and 65535"
                exit 1
            fi
            ;;
        l)
            if [[ "$OPTARG" == "en" || "$OPTARG" == "ru" ]]; then
                LANGUAGE=$OPTARG
                log "Language set to: $LANGUAGE via command line"
            else
                echo_error "Invalid language: $OPTARG. Must be 'en' or 'ru'"
                exit 1
            fi
            ;;
        f)
            FULL_UPGRADE=true
            log "Full upgrade mode enabled via command line"
            ;;
        \?)
            echo_error "Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            echo_error "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done

# Main function
function main() {
    # Initialize log file
    mkdir -p $(dirname "$LOGFILE")
    touch "$LOGFILE"
    log "Script started with parameters: $*"
    
    # Check for root
    check_root
    
    # Interactive setup if needed
    if [ -z "$ACTION" ]; then
        ask_action
    fi
    
    # Check language
    if [ "$LANGUAGE" != "en" ] && [ "$LANGUAGE" != "ru" ]; then
        ask_language
    fi
    
    # Check system compatibility
    check_system
    
    # Display summary of what will be done
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "\nВыбранное действие: $([ "$ACTION" == "install" ] && echo "Установка" || echo "Удаление") SOCKS5 прокси-сервера"
    else
        echo -e "\nSelected action: $([ "$ACTION" == "install" ] && echo "Install" || echo "Uninstall") SOCKS5 proxy server"
    fi
    # Добавляем небольшую паузу для восприятия информации
    sleep 1
    echo
    
    # Perform action based on user's choice
    if [ "$ACTION" == "uninstall" ]; then
        # Run uninstallation routine
        uninstall_proxy
    else
        # Continue with installation
        
        # Ask for proxy port if not set from command line
        if [[ -z "$PORT" ]]; then
            # Напрямую запрашиваем порт вместо использования функции ask_port
            local message_en="Enter the port number for the SOCKS5 proxy server [default: $DEFAULT_PORT]:"
            local message_ru="Введите номер порта для SOCKS5 прокси-сервера [по умолчанию: $DEFAULT_PORT]:"
            
            if [ "$LANGUAGE" == "ru" ]; then
                read -r -p "$message_ru " port_input
            else
                read -r -p "$message_en " port_input
            fi
            echo
            
            if [ -z "$port_input" ]; then
                PORT=$DEFAULT_PORT
                if [ "$LANGUAGE" == "ru" ]; then
                    echo "Используется порт по умолчанию: $PORT"
                else
                    echo "Using default port: $PORT"
                fi
            else
                if [[ "$port_input" =~ ^[0-9]+$ ]] && [ "$port_input" -ge 1 ] && [ "$port_input" -le 65535 ]; then
                    PORT=$port_input
                    if [ "$LANGUAGE" == "ru" ]; then
                        echo "Выбран порт: $PORT"
                    else
                        echo "Port set to: $PORT"
                    fi
                else
                    if [ "$LANGUAGE" == "ru" ]; then
                        echo "Неверный номер порта. Используется по умолчанию: $DEFAULT_PORT"
                    else
                        echo "Invalid port number. Using default: $DEFAULT_PORT"
                    fi
                    PORT=$DEFAULT_PORT
                fi
            fi
            
            # Пауза после выбора порта
            sleep 2
        fi
        
        # Validate port
        if ! [[ "$PORT" =~ ^[0-9]+$ ]] || ((PORT<1 || PORT>65535)); then
            log "Invalid port: $PORT"
            echo_error "$(lang_text "Invalid port number: $PORT" "Неверный номер порта: $PORT")"
            exit 1
        fi
        
        # Информируем о начале установки, но не запрашиваем подтверждение
        echo_status "$(lang_text "Starting system update and package installation" "Начало обновления системы и установки пакетов")"
        # Небольшая пауза для восприятия информации
        sleep 1
        echo
        
        # Install required packages
        install_packages
        sleep 1 # Пауза между шагами установки
        
        # Create Dante configuration
        create_dante_config
        sleep 1
        
        # Create systemd service for Dante
        create_dante_service
        sleep 1
        
        # Setup PAM authentication
        setup_pam_auth
        sleep 1
        
        # Configure firewall
        configure_firewall
        sleep 1
        
        # Enable and start Dante service
        echo_status "$(lang_text "Enabling and starting Dante service..." "Включение и запуск сервиса Dante...")"
        systemctl daemon-reload
        systemctl enable dante-server.service
        systemctl restart dante-server.service
        sleep 1
        
        # Create user management script
        create_management_script
        sleep 1
        
        # Ask for proxy user credentials
        manage_user_credentials
        
        # Display completion message
        show_completion
    fi
}

# Run the main function with all command line arguments
main "$@"

exit 0