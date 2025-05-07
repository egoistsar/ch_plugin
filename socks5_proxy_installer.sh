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
    
    # Ждем пользовательский ввод перед переходом к следующему шагу
    if [ "$LANGUAGE" == "ru" ]; then
        read -r -p "Нажмите Enter для продолжения..." -t 5 continue_key
    else
        read -r -p "Press Enter to continue..." -t 5 continue_key
    fi
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
function install_prerequisites() {
    local message_en="Preinstalling necessary packages..."
    local message_ru="Предварительная установка необходимых пакетов..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Update package lists
    apt-get update -qq
    
    # Install essential packages first
    apt-get install -y apt-utils curl wget iproute2 net-tools openssl
    
    echo_success "$(lang_text "Essential prerequisites installed" "Основные предварительные пакеты установлены")"
}

# Function to update system and install required packages
function install_packages() {
    local message_en_update="Updating system packages..."
    local message_ru_update="Обновление системных пакетов..."
    
    echo_status "$(lang_text "$message_en_update" "$message_ru_update")"
    
    # Update package lists
    apt-get update
    
    # Full upgrade or just install/upgrade required packages based on flag
    if [ "$FULL_UPGRADE" = true ]; then
        log "Performing full system upgrade (dist-upgrade)"
        apt-get dist-upgrade -y
    else
        log "Upgrading only required packages"
        apt-get install --only-upgrade -y dante-server libpam-pwdfile
    fi
    
    # Install required packages
    local message_en="Installing required packages..."
    local message_ru="Установка необходимых пакетов..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Install all possible packages that might be needed
    # First install perl dependencies that might be required for dante-server
    apt-get install -y perl libperl5.32 perl-modules perl-base libperl-dev debhelper 2>/dev/null || true
    
    # Install dante-server and other required packages
    if ! apt-get install -y dante-server; then
        echo_warning "$(lang_text "Failed to install dante-server from repositories. Trying alternative installation methods..." "Не удалось установить dante-server из репозиториев. Пробуем альтернативные методы установки...")"
        
        # Try to install from direct .deb file if apt-get fails
        if [ ! -f /tmp/dante-server.deb ]; then
            echo_status "$(lang_text "Downloading dante-server package..." "Загрузка пакета dante-server...")"
            if wget -q -O /tmp/dante-server.deb http://ftp.debian.org/debian/pool/main/d/dante/dante-server_1.4.2+dfsg-7+b3_amd64.deb; then
                echo_success "$(lang_text "Downloaded dante-server package" "Загружен пакет dante-server")"
            else
                echo_error "$(lang_text "Failed to download dante-server package" "Не удалось загрузить пакет dante-server")"
                exit 1
            fi
        fi
        
        # Install the downloaded package
        echo_status "$(lang_text "Installing dante-server from downloaded package..." "Установка dante-server из загруженного пакета...")"
        if ! dpkg -i /tmp/dante-server.deb; then
            apt-get -f install -y
            if ! dpkg -i /tmp/dante-server.deb; then
                echo_error "$(lang_text "Failed to install dante-server" "Не удалось установить dante-server")"
                exit 1
            fi
        fi
    fi
    
    # Install remaining packages
    apt-get install -y libpam-pwdfile sudo whois iptables systemd python3 gcc make
    
    echo_success "$(lang_text "Required packages installed successfully" "Необходимые пакеты успешно установлены")"
}

# Function to configure firewall
function configure_firewall() {
    local message_en="Configuring firewall..."
    local message_ru="Настройка брандмауэра..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Check if ufw is available
    if ! command_exists "ufw"; then
        echo_warning "$(lang_text "UFW firewall not available. Trying alternative firewall configuration." "Брандмауэр UFW недоступен. Пробуем альтернативную настройку брандмауэра.")"
        
        # Try to use iptables directly if available
        if command_exists "iptables"; then
            echo_status "$(lang_text "Using iptables for firewall configuration..." "Используем iptables для настройки брандмауэра...")"
            
            # Save current iptables rules
            if command_exists "iptables-save"; then
                iptables-save > /tmp/iptables.rules.bak
            fi
            
            # Allow SSH and proxy port
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
            
            echo_success "$(lang_text "Firewall (iptables) configured successfully" "Брандмауэр (iptables) успешно настроен")"
            return 0
        else
            echo_warning "$(lang_text "No firewall tools available. Skipping firewall configuration." "Нет доступных инструментов брандмауэра. Пропускаем настройку брандмауэра.")"
            return 0
        fi
    fi
    
    # Add rules more safely
    ufw --force allow ssh
    ufw --force allow $PORT/tcp
    
    # Only enable if not already active
    if ufw status | grep -qw inactive; then
        log "Enabling UFW firewall"
        ufw --force enable
    else
        log "UFW firewall already active"
    fi
    
    echo_success "$(lang_text "Firewall configured successfully" "Брандмауэр успешно настроен")"
}

# Function to add a proxy user
function add_proxy_user() {
    local username="$1"
    local password="$2"
    
    local message_en="Adding proxy user..."
    local message_ru="Добавление пользователя прокси..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
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
    
    # If all else fails, try whois package's mkpasswd
    if [ -z "$hashed_password" ] && command -v mkpasswd &>/dev/null; then
        hashed_password=$(mkpasswd -m sha-512 "$password")
    fi
    
    # If all methods fail, store plain password (temporary, for testing only)
    if [ -z "$hashed_password" ]; then
        echo_warning "$(lang_text "Warning: Could not hash password. Using plain text password temporarily." "Предупреждение: Не удалось хешировать пароль. Временно используется пароль в открытом виде.")"
        hashed_password="$password"
    fi
    
    # Add user to the database
    echo "$username:$hashed_password" >> /etc/dante-users/users.pwd
    
    echo_success "$(lang_text "User '$username' has been added successfully" "Пользователь '$username' был успешно добавлен")"
}

# Function to ask for proxy username
function ask_proxy_username() {
    local username_en="Enter a username for proxy authentication:"
    local username_ru="Введите имя пользователя для аутентификации в прокси:"
    
    read -p "$(lang_text "$username_en" "$username_ru") " proxy_username
    
    if [ -z "$proxy_username" ]; then
        echo_error "$(lang_text "Username cannot be empty" "Имя пользователя не может быть пустым")"
        ask_proxy_username
    else
        echo "$proxy_username"
    fi
}

# Function to ask for proxy password
function ask_proxy_password() {
    local password_en="Enter a password for proxy authentication:"
    local password_ru="Введите пароль для аутентификации в прокси:"
    
    read -s -p "$(lang_text "$password_en" "$password_ru") " proxy_password
    echo
    
    if [ -z "$proxy_password" ]; then
        echo_error "$(lang_text "Password cannot be empty" "Пароль не может быть пустым")"
        ask_proxy_password
    else
        echo "$proxy_password"
    fi
}

# Function to manage proxy user credentials
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
            read -r -p "Введите имя пользователя или нажмите Enter для использования значения по умолчанию [$default_username]: " proxy_username
        else
            echo -e "\nUsername cannot be empty."
            read -r -p "Enter a username or press Enter to use default [$default_username]: " proxy_username
        fi
        
        # Если пользователь снова ввел пустое значение, используем значение по умолчанию
        if [ -z "$proxy_username" ]; then
            proxy_username="$default_username"
            if [ "$LANGUAGE" == "ru" ]; then
                echo -e "\nИспользуется имя пользователя по умолчанию: $proxy_username\n"
            else
                echo -e "\nUsing default username: $proxy_username\n"
            fi
        fi
    else
        # Явное подтверждение выбранного имени пользователя
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nВыбранное имя пользователя: $proxy_username\n"
        else
            echo -e "\nSelected username: $proxy_username\n"
        fi
    fi
    
    log "Username set to: $proxy_username"
    sleep 2 # Пауза перед следующим шагом
    
    # --- PASSWORD SECTION ---
    # Запрашиваем пароль без таймаута
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "Шаг 2: Введите пароль для пользователя '$proxy_username'.\n"
        read -r -p "Пароль: " proxy_password
    else
        echo -e "Step 2: Enter a password for user '$proxy_username'.\n"
        read -r -p "Password: " proxy_password
    fi
    
    # Проверка и обработка ввода пароля
    if [ -z "$proxy_password" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nПароль не может быть пустым."
            read -r -p "Введите пароль или нажмите Enter для использования значения по умолчанию: " proxy_password
        else
            echo -e "\nPassword cannot be empty."
            read -r -p "Enter a password or press Enter to use default: " proxy_password
        fi
        
        # Если пользователь снова ввел пустое значение, используем значение по умолчанию
        if [ -z "$proxy_password" ]; then
            proxy_password="$default_password"
            if [ "$LANGUAGE" == "ru" ]; then
                echo -e "\nИспользуется пароль по умолчанию\n"
            else
                echo -e "\nUsing default password\n"
            fi
        fi
    else
        # Подтверждение ввода пароля без отображения самого пароля
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nПароль успешно введен\n"
        else
            echo -e "\nPassword successfully entered\n"
        fi
    fi
    
    log "Password has been set" # не логируем пароль в открытом виде
    sleep 2 # Пауза перед следующим шагом
    
    # --- CONFIRMATION SECTION ---
    # Запрашиваем подтверждение перед созданием пользователя
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "Шаг 3: Подтверждение создания пользователя.\n"
        echo -e "Имя пользователя: $proxy_username"
        echo -e "Пароль: [СКРЫТ]\n"
        read -r -p "Создать пользователя с указанными учетными данными? (y/n): " confirm_creation
    else
        echo -e "Step 3: Confirm user creation.\n"
        echo -e "Username: $proxy_username"
        echo -e "Password: [HIDDEN]\n"
        read -r -p "Create user with these credentials? (y/n): " confirm_creation
    fi
    
    # Обработка подтверждения
    if [[ "$confirm_creation" =~ ^[Yy]$ ]]; then
        # Добавляем пользователя
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
    else
        # Если пользователь отказался, предлагаем ввести учетные данные заново
        if [ "$LANGUAGE" == "ru" ]; then
            echo -e "\nСоздание пользователя отменено. Повторный ввод учетных данных...\n"
        else
            echo -e "\nUser creation canceled. Re-entering credentials...\n"
        fi
        sleep 2
        manage_user_credentials
        return
    fi
}

# Function to create user management script
function create_management_script() {
    local message_en="Creating user management script..."
    local message_ru="Создание скрипта управления пользователями..."
    
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
    
    if [ -s "\$USER_DB" ]; then
        cat "\$USER_DB" | cut -d: -f1
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
    local username="\$1"
    local password="\$2"
    
    # Validate input
    if [ -z "\$username" ] || [ -z "\$password" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Ошибка: Требуется имя пользователя и пароль" >&2
        else
            echo "Error: Username and password are required" >&2
        fi
        show_usage
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^\$username:" "\$USER_DB" 2>/dev/null; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Пользователь '\$username' уже существует. Сначала удалите его или используйте другое имя пользователя."
        else
            echo "User '\$username' already exists. Remove it first or use a different username."
        fi
        return 1
    fi
    
    # Create password hash using openssl (more portable than mkpasswd)
    local salt=\$(openssl rand -base64 12)
    local hashed_password=\$(openssl passwd -6 -salt "\$salt" "\$password")
    
    # If openssl fails, try using Python
    if [ -z "\$hashed_password" ]; then
        if command -v python3 &>/dev/null; then
            hashed_password=\$(python3 -c "import crypt; print(crypt.crypt('\$password', '\\\$6\\\$\$salt'))")
        elif command -v python &>/dev/null; then
            hashed_password=\$(python -c "import crypt; print(crypt.crypt('\$password', '\\\$6\\\$\$salt'))")
        fi
    fi
    
    # If all else fails, store plain password (temporary, for testing only)
    if [ -z "\$hashed_password" ]; then
        echo "Warning: Could not hash password. Using plain text password temporarily."
        hashed_password="\$password"
    fi
    
    # Add user to the database
    echo "\$username:\$hashed_password" >> "\$USER_DB"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Пользователь '\$username' был успешно добавлен."
    else
        echo "User '\$username' has been added successfully."
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
    local username="\$1"
    
    # Validate input
    if [ -z "\$username" ]; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Ошибка: Требуется имя пользователя" >&2
        else
            echo "Error: Username is required" >&2
        fi
        show_usage
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^\$username:" "\$USER_DB" 2>/dev/null; then
        if [ "$LANGUAGE" == "ru" ]; then
            echo "Пользователь '\$username' не существует."
        else
            echo "User '\$username' does not exist."
        fi
        return 1
    fi
    
    # Remove user from the database
    sed -i "/^\$username:/d" "\$USER_DB"
    
    if [ "$LANGUAGE" == "ru" ]; then
        echo "Пользователь '\$username' был успешно удален."
    else
        echo "User '\$username' has been removed successfully."
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
    LANGUAGE=\$(cat /etc/dante-language)
fi

# Main script logic
case "\$1" in
    add)
        add_user "\$2" "\$3"
        ;;
    remove)
        remove_user "\$2"
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

# Function to display completion message for installation
function show_completion() {
    local message_en_1="SOCKS5 proxy server setup complete!"
    local message_ru_1="Настройка SOCKS5 прокси-сервера завершена!"
    
    local message_en_2="Your SOCKS5 proxy is now running on port $PORT"
    local message_ru_2="Ваш SOCKS5 прокси-сервер теперь работает на порту $PORT"
    
    local message_en_3="To manage proxy users, use the following command:"
    local message_ru_3="Для управления пользователями прокси используйте следующую команду:"
    
    local message_en_4="Add a user:    sudo proxy-users add USERNAME PASSWORD"
    local message_ru_4="Добавить пользователя:    sudo proxy-users add ИМЯ_ПОЛЬЗОВАТЕЛЯ ПАРОЛЬ"
    
    local message_en_5="Remove a user: sudo proxy-users remove USERNAME"
    local message_ru_5="Удалить пользователя: sudo proxy-users remove ИМЯ_ПОЛЬЗОВАТЕЛЯ"
    
    local message_en_6="List all users: sudo proxy-users list"
    local message_ru_6="Показать всех пользователей: sudo proxy-users list"
    
    local message_en_7="To connect to your proxy:"
    local message_ru_7="Для подключения к вашему прокси:"
    
    local message_en_8="Host: Your server IP"
    local message_ru_8="Хост: IP-адрес вашего сервера"
    
    local message_en_9="Port: $PORT"
    local message_ru_9="Порт: $PORT"
    
    local message_en_10="Type: SOCKS5"
    local message_ru_10="Тип: SOCKS5"
    
    local message_en_11="Authentication: Username/Password"
    local message_ru_11="Аутентификация: Имя пользователя/Пароль"
    
    local message_en_12="Username: $proxy_username"
    local message_ru_12="Имя пользователя: $proxy_username"
    
    local message_en_13="Password: $proxy_password"
    local message_ru_13="Пароль: $proxy_password"
    
    # Get server's public IP address using multiple methods
    local SERVER_IP
    
    # Method 1: Using OpenDNS to get public IP (most reliable for public servers)
    if command -v dig &>/dev/null; then
        SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    elif command -v host &>/dev/null; then
        SERVER_IP=$(host myip.opendns.com resolver1.opendns.com 2>/dev/null | tail -n1 | cut -d' ' -f4-)
    fi
    
    # Method 2: Using curl to external services
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(curl -s icanhazip.com || curl -s ifconfig.me || curl -s api.ipify.org || curl -s ipecho.net/plain)
    fi
    
    # Method 3: Using ip command for local interfaces
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0" | head -1)
    fi
    
    # Method 4: Fallback to hostname command
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
    fi
    
    # If all methods fail, use a placeholder
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="Your server IP"
    fi
    
    echo_status "$(lang_text "$message_en_1" "$message_ru_1")"
    echo "$(lang_text "$message_en_2" "$message_ru_2")"
    echo
    echo "$(lang_text "$message_en_3" "$message_ru_3")"
    echo "  $(lang_text "$message_en_4" "$message_ru_4")"
    echo "  $(lang_text "$message_en_5" "$message_ru_5")"
    echo "  $(lang_text "$message_en_6" "$message_ru_6")"
    echo
    echo "$(lang_text "$message_en_7" "$message_ru_7")"
    if [ "$SERVER_IP" = "Your server IP" ]; then
        echo "  $(lang_text "$message_en_8" "$message_ru_8")"
    else
        echo "  Host: $SERVER_IP"
    fi
    echo "  $(lang_text "$message_en_9" "$message_ru_9")"
    echo "  $(lang_text "$message_en_10" "$message_ru_10")"
    echo "  $(lang_text "$message_en_11" "$message_ru_11")"
    echo "  $(lang_text "$message_en_12" "$message_ru_12")"
    echo "  $(lang_text "$message_en_13" "$message_ru_13")"
    
    # Full connection string
    local conn_en_1="Connection information (copy this to your SOCKS5 client):"
    local conn_ru_1="Информация для подключения (скопируйте это в ваш SOCKS5 клиент):"
    
    echo
    echo_status "$(lang_text "$conn_en_1" "$conn_ru_1")"
    if [ "$SERVER_IP" = "Your server IP" ]; then
        echo "Server: Your server IP"
    else
        echo "Server: $SERVER_IP"
    fi
    echo "Port: $PORT"
    echo "Username: $proxy_username"
    echo "Password: $proxy_password"
    echo "Type: SOCKS5"
}

# Usage information function
function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -a, --action ACTION     Specify action: install or uninstall"
    echo "  -p, --port PORT         Specify proxy server port (1-65535)"
    echo "  -l, --language LANG     Specify language: en or ru"
    echo "  -f, --full-upgrade      Perform full system upgrade"
    echo "  -h, --help              Display this help message"
    echo
    echo "Example:"
    echo "  $0 -a install -p 1080 -l en"
    echo "  $0 --action uninstall"
    exit 1
}

# Parse command line arguments
function parse_arguments() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--action)
                if [[ "$2" == "install" || "$2" == "uninstall" ]]; then
                    ACTION="$2"
                    log "Action set to: $ACTION"
                else
                    echo_error "Invalid action: $2. Use 'install' or 'uninstall'"
                    usage
                fi
                shift 2
                ;;
            -p|--port)
                if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 1 ] && [ "$2" -le 65535 ]; then
                    PORT="$2"
                    log "Port set to: $PORT"
                else
                    echo_error "Invalid port: $2. Must be between 1-65535"
                    usage
                fi
                shift 2
                ;;
            -l|--language)
                if [[ "$2" == "en" || "$2" == "ru" ]]; then
                    LANGUAGE="$2"
                    log "Language set to: $LANGUAGE"
                else
                    echo_error "Invalid language: $2. Use 'en' or 'ru'"
                    usage
                fi
                shift 2
                ;;
            -f|--full-upgrade)
                FULL_UPGRADE=true
                log "Full system upgrade enabled"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Main function to run the script
function main() {
    # Clear screen
    clear
    
    # Display banner
    echo "====================================================="
    echo "       SOCKS5 Proxy Server Interactive Installer     "
    echo "====================================================="
    echo
    
    # Install essential prerequisites right at the beginning
    install_prerequisites
    
    # Parse command line arguments if any
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    fi
    
    # Ask for language preference if not set from command line
    if [[ -z "$LANGUAGE" ]]; then
        # Прямой запрос языка в основной функции вместо вызова ask_language
        echo "Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:"
        echo "1) English"
        echo "2) Русский"
        
        # Ждем ввод пользователя с бесконечным таймаутом
        read -r -p "Enter your choice (1/2): " lang_choice
        
        case $lang_choice in
            2)
                LANGUAGE="ru"
                echo -e "\nВыбран русский язык"
                ;;
            *)
                LANGUAGE="en"
                echo -e "\nEnglish language selected"
                ;;
        esac
        
        # Явная пауза после выбора языка
        sleep 2
    fi
    export LANGUAGE
    
    # Check required dependencies and system information - notice we moved the root check
    # before asking questions to make sure we have privileges
    check_dependencies
    check_system
    sleep 1 # Пауза между шагами
    
    # Check if running as root
    check_root
    
    # Ask for action (install or uninstall) if not set from command line
    if [[ -z "$ACTION" ]]; then
        # Напрямую запрашиваем действие вместо вызова ask_action
        local install_en="Install SOCKS5 proxy server"
        local install_ru="Установить SOCKS5 прокси-сервер"
        
        local uninstall_en="Uninstall SOCKS5 proxy server"
        local uninstall_ru="Удалить SOCKS5 прокси-сервер"
        
        local prompt_en="Select an action:"
        local prompt_ru="Выберите действие:"
        
        echo
        if [ "$LANGUAGE" == "ru" ]; then
            echo "$prompt_ru"
            echo "1) $install_ru"
            echo "2) $uninstall_ru"
            read -r -p "Введите ваш выбор (1/2): " action_choice
        else
            echo "$prompt_en"
            echo "1) $install_en"
            echo "2) $uninstall_en"
            read -r -p "Enter your choice (1/2): " action_choice
        fi
        echo
        
        case $action_choice in
            2)
                ACTION="uninstall"
                if [ "$LANGUAGE" == "ru" ]; then
                    echo "Выбрано: Удаление SOCKS5 прокси-сервера"
                else
                    echo "Selected: Uninstall SOCKS5 proxy server"
                fi
                ;;
            *)
                ACTION="install"
                if [ "$LANGUAGE" == "ru" ]; then
                    echo "Выбрано: Установка SOCKS5 прокси-сервера"
                else
                    echo "Selected: Install SOCKS5 proxy server"
                fi
                ;;
        esac
        
        # Пауза после выбора действия
        sleep 2
    fi
    
    # Добавляем пользователю возможность подтвердить действие перед продолжением
    if [ "$LANGUAGE" == "ru" ]; then
        echo -e "\nВыбранное действие: $([ "$ACTION" == "install" ] && echo "Установка" || echo "Удаление") SOCKS5 прокси-сервера"
        read -r -p "Нажмите Enter для продолжения или Ctrl+C для отмены..." -t 10 continue_key
    else
        echo -e "\nSelected action: $([ "$ACTION" == "install" ] && echo "Install" || echo "Uninstall") SOCKS5 proxy server"
        read -r -p "Press Enter to continue or Ctrl+C to cancel..." -t 10 continue_key
    fi
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
        
        # Подтверждение перед обновлением пакетов
        echo_status "$(lang_text "Starting system update and package installation" "Начало обновления системы и установки пакетов")"
        if [ "$LANGUAGE" == "ru" ]; then
            read -r -p "Продолжить? (Enter для продолжения)" -t 5 continue_key
        else
            read -r -p "Continue? (Press Enter to continue)" -t 5 continue_key
        fi
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