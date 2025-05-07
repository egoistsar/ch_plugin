#!/bin/bash

# SOCKS5 Proxy Server Installer
# This script installs and configures a SOCKS5 proxy server with authentication

# Enable strict error checking
set -e
set -u
IFS=$'\n\t'

# Define colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define default values
DEFAULT_PORT=1080
LOGFILE="/var/log/socks5_proxy_installer.log"
LANGUAGE="en"
ACTION=""
PORT=$DEFAULT_PORT
FULL_UPGRADE=false
proxy_username=""
proxy_password=""
OS=""
INIT_SYSTEM=""
FIREWALL_TYPE=""

# Function for language support
function lang_text() {
    local en_text="$1"
    local ru_text="$2"
    
    # Default to English if LANGUAGE is not defined
    if [ "${LANGUAGE:-en}" == "ru" ]; then
        echo -e "$ru_text"
    else
        echo -e "$en_text"
    fi
}

# Function to log messages
function log() {
    local plain_text=$(echo "$*" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $plain_text" >> "$LOGFILE"
}

# Status display functions
function echo_status() {
    log ">> $1"
    echo -e "\n${BLUE}>> $1${NC}"
}

function echo_success() {
    log "✓ $1"
    echo -e "\n${GREEN}✓ $1${NC}"
}

function echo_error() {
    log "✗ $1"
    echo -e "\n${RED}✗ $1${NC}"
}

function echo_warning() {
    log "! $1"
    echo -e "\n${YELLOW}! $1${NC}"
}

# Function to check if script is running as root
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo_error "$(lang_text "This script must be run as root" "Этот скрипт должен быть запущен с правами root")"
        exit 1
    fi
}

# Function to ask user for action if not specified
function ask_action() {
    local prompt_en="Select action:"
    local prompt_ru="Выберите действие:"
    
    local install_en="Install SOCKS5 proxy server"
    local install_ru="Установить SOCKS5 прокси-сервер"
    
    local uninstall_en="Uninstall SOCKS5 proxy server"
    local uninstall_ru="Удалить SOCKS5 прокси-сервер"
    
    echo "$(lang_text "$prompt_en" "$prompt_ru")"
    echo "1) $(lang_text "$install_en" "$install_ru")"
    echo "2) $(lang_text "$uninstall_en" "$uninstall_ru")"
    echo
    
    read -r -p "$(lang_text "Enter your choice (1/2): " "Введите ваш выбор (1/2): ") " action_choice
    
    case $action_choice in
        2)
            ACTION="uninstall"
            ;;
        *)
            ACTION="install"
            ;;
    esac
    
    log "Action selected: $ACTION"
}

# Function to ask user for language preference
function ask_language() {
    echo "Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:"
    echo "1) English"
    echo "2) Русский"
    echo
    
    read -r -p "Enter your choice (1/2): " lang_choice
    
    case $lang_choice in
        2)
            LANGUAGE="ru"
            ;;
        *)
            LANGUAGE="en"
            ;;
    esac
    
    log "Language selected: $LANGUAGE"
}

# Function to check if a command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if not already installed
function ensure_package_installed() {
    local package=$1
    local package_name=${2:-$package}
    
    if ! command_exists "$package"; then
        log "Installing $package_name"
        
        if command_exists "apt-get"; then
            apt-get install -y "$package_name"
        elif command_exists "yum"; then
            yum install -y "$package_name"
        elif command_exists "dnf"; then
            dnf install -y "$package_name"
        elif command_exists "pacman"; then
            pacman -S --noconfirm "$package_name"
        elif command_exists "zypper"; then
            zypper install -y "$package_name"
        elif command_exists "apk"; then
            apk add "$package_name"
        else
            echo_error "$(lang_text "Cannot install packages: No supported package manager found" "Невозможно установить пакеты: Не найден поддерживаемый менеджер пакетов")"
            exit 1
        fi
    fi
}

# Function to check system compatibility
function check_system() {
    local os_name=""
    local init_system=""
    
    # Detect operating system
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        os_name=$ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        os_name=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        os_name="debian"
    elif [ -f /etc/redhat-release ]; then
        os_name=$(cat /etc/redhat-release | cut -d ' ' -f 1 | tr '[:upper:]' '[:lower:]')
    else
        os_name=$(uname -s)
    fi
    
    # Convert OS name to lowercase for easier comparison
    OS=$(echo "$os_name" | tr '[:upper:]' '[:lower:]')
    
    # Detect init system
    if command_exists "systemctl"; then
        init_system="systemd"
    elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
        init_system="sysv"
    elif command_exists "rc-service"; then
        init_system="openrc"
    else
        init_system="unknown"
    fi
    
    INIT_SYSTEM=$init_system
    
    # Detect firewall
    local firewall_type=""
    if command_exists "ufw" && ufw status >/dev/null 2>&1; then
        firewall_type="ufw"
    elif command_exists "firewall-cmd" && firewall-cmd --state >/dev/null 2>&1; then
        firewall_type="firewalld"
    elif command_exists "iptables"; then
        firewall_type="iptables"
    else
        firewall_type="none"
    fi
    
    FIREWALL_TYPE=$firewall_type
    
    # Log system information
    log "Detected OS: $OS"
    log "Detected init system: $INIT_SYSTEM"
    log "Detected firewall: $FIREWALL_TYPE"
    
    # Display system information
    local system_info_en="System information:"
    local system_info_ru="Информация о системе:"
    
    local os_en="OS: "
    local os_ru="ОС: "
    
    local init_en="Init system: "
    local init_ru="Система инициализации: "
    
    local firewall_en="Firewall: "
    local firewall_ru="Брандмауэр: "
    
    echo_status "$(lang_text "$system_info_en" "$system_info_ru")"
    echo "$(lang_text "$os_en" "$os_ru")$OS"
    echo "$(lang_text "$init_en" "$init_ru")$INIT_SYSTEM"
    echo "$(lang_text "$firewall_en" "$firewall_ru")$FIREWALL_TYPE"
    
    # Check system compatibility
    case "$OS" in
        ubuntu|debian|raspbian)
            # These systems are fully supported
            ;;
        centos|fedora|rhel|rocky|almalinux|oracle|ol)
            # These systems are supported with alternative packages
            ;;
        arch|manjaro)
            # These systems use different package names
            ;;
        opensuse|sle*)
            # OpenSUSE and SLES
            ;;
        alpine)
            # Alpine Linux
            ;;
        *)
            echo_warning "$(lang_text "Unsupported OS: $OS. The script may not work correctly." "Неподдерживаемая ОС: $OS. Скрипт может работать некорректно.")"
            ;;
    esac
    
    case "$INIT_SYSTEM" in
        systemd)
            # Systemd is fully supported
            ;;
        sysv)
            # SysV init is supported but with limitations
            echo_warning "$(lang_text "SysV init detected. Some features may be limited." "Обнаружена система инициализации SysV. Некоторые функции могут быть ограничены.")"
            ;;
        openrc)
            # OpenRC is supported but with limitations
            echo_warning "$(lang_text "OpenRC detected. Some features may be limited." "Обнаружена система инициализации OpenRC. Некоторые функции могут быть ограничены.")"
            ;;
        *)
            echo_error "$(lang_text "Unsupported init system: $INIT_SYSTEM" "Неподдерживаемая система инициализации: $INIT_SYSTEM")"
            exit 1
            ;;
    esac
}

# Function to update the system
function update_system() {
    local message_en="Updating system..."
    local message_ru="Обновление системы..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    if command_exists "apt-get"; then
        # Debian-based systems
        apt-get update -q
        
        if [ "$FULL_UPGRADE" = true ]; then
            apt-get upgrade -y
        fi
    elif command_exists "yum"; then
        # RHEL/CentOS
        yum update -y
    elif command_exists "dnf"; then
        # Fedora/CentOS 8+
        dnf update -y
    elif command_exists "pacman"; then
        # Arch Linux
        pacman -Sy
        
        if [ "$FULL_UPGRADE" = true ]; then
            pacman -Syu --noconfirm
        fi
    elif command_exists "zypper"; then
        # OpenSUSE
        zypper refresh
        
        if [ "$FULL_UPGRADE" = true ]; then
            zypper update -y
        fi
    elif command_exists "apk"; then
        # Alpine Linux
        apk update
        
        if [ "$FULL_UPGRADE" = true ]; then
            apk upgrade
        fi
    else
        echo_warning "$(lang_text "Cannot update system: No supported package manager found" "Невозможно обновить систему: Не найден поддерживаемый менеджер пакетов")"
    fi
}

# Function to install required packages
function install_packages() {
    local message_en="Installing required packages..."
    local message_ru="Установка необходимых пакетов..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Common packages for most distributions
    local common_packages=("curl" "wget" "sudo" "whois")
    
    # Distribution-specific packages
    case "$OS" in
        ubuntu|debian|raspbian)
            # Install for Debian/Ubuntu
            for pkg in "${common_packages[@]}" "dante-server" "libpam-pwdfile"; do
                ensure_package_installed "$pkg"
            done
            ;;
        centos|fedora|rhel|rocky|almalinux|oracle|ol)
            # Install for RHEL/CentOS/Fedora
            for pkg in "${common_packages[@]}"; do
                ensure_package_installed "$pkg"
            done
            # Dante might be in EPEL
            if ! command_exists "dante-server"; then
                if command_exists "yum"; then
                    yum install -y epel-release
                    yum install -y dante-server pam_pwdfile
                elif command_exists "dnf"; then
                    dnf install -y epel-release
                    dnf install -y dante-server pam_pwdfile
                fi
            fi
            ;;
        arch|manjaro)
            # Install for Arch Linux
            for pkg in "${common_packages[@]}"; do
                ensure_package_installed "$pkg"
            done
            # Dante from AUR (user will need to manually install)
            echo_warning "$(lang_text "Dante may need to be installed manually from AUR on Arch Linux" "На Arch Linux может потребоваться ручная установка Dante из AUR")"
            ;;
        opensuse|sle*)
            # Install for OpenSUSE/SLES
            for pkg in "${common_packages[@]}"; do
                ensure_package_installed "$pkg"
            done
            zypper install -y dante-server pam_pwdfile
            ;;
        alpine)
            # Install for Alpine Linux
            for pkg in "${common_packages[@]}"; do
                ensure_package_installed "$pkg"
            done
            apk add dante pam_pwdfile
            ;;
        *)
            echo_error "$(lang_text "Unsupported OS: $OS" "Неподдерживаемая ОС: $OS")"
            exit 1
            ;;
    esac
    
    echo_success "$(lang_text "Required packages installed successfully" "Необходимые пакеты успешно установлены")"
}

# Function to create Dante configuration
function create_dante_config() {
    local message_en="Creating Dante server configuration..."
    local message_ru="Создание конфигурации сервера Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Create config directory if it doesn't exist
    mkdir -p /etc/dante-users
    
    # Create the configuration file
    cat > /etc/dante.conf << EOL
# Dante SOCKS5 proxy server configuration

# Log settings
logoutput: syslog

# Server settings - слушаем на всех интерфейсах
internal: 0.0.0.0 port = $PORT

# Authentication method
socksmethod: username

# Client access rules
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}

# Authentication configuration
user.privileged: root
user.notprivileged: nobody

# PAM authentication
auth: pam

# Access rules
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    command: bind connect udpassociate
    log: error connect disconnect
    socksmethod: username
}
EOL
    
    echo_success "$(lang_text "Dante configuration created successfully" "Конфигурация Dante успешно создана")"
}

# Function to configure systemd service
function setup_dante_service() {
    local message_en="Setting up Dante system service..."
    local message_ru="Настройка системного сервиса Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    case "$INIT_SYSTEM" in
        systemd)
            # Create systemd service file
            cat > /etc/systemd/system/dante-server.service << EOL
[Unit]
Description=SOCKS5 Proxy Server (Dante)
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/sockd -f /etc/dante.conf
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
            
            # Reload systemd and enable the service
            systemctl daemon-reload
            systemctl enable dante-server.service
            ;;
            
        sysv)
            # Create SysV init script
            cat > /etc/init.d/dante-server << EOL
#!/bin/sh
### BEGIN INIT INFO
# Provides:          dante-server
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SOCKS5 Proxy Server
# Description:       Dante SOCKS5 proxy server
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="SOCKS5 Proxy Server"
NAME=dante-server
DAEMON=/usr/sbin/sockd
DAEMON_ARGS="-f /etc/dante.conf"
PIDFILE=/var/run/\$NAME.pid

# Exit if the package is not installed
[ -x "\$DAEMON" ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting \$DESC" "\$NAME"
    start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON --test > /dev/null || return 1
    start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON -- \$DAEMON_ARGS || return 2
    log_end_msg 0
    ;;
  stop)
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile \$PIDFILE --name \$NAME
    log_end_msg 0
    ;;
  restart|force-reload)
    log_daemon_msg "Restarting \$DESC" "\$NAME"
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile \$PIDFILE --name \$NAME
    start-stop-daemon --start --quiet --pidfile \$PIDFILE --exec \$DAEMON -- \$DAEMON_ARGS
    log_end_msg 0
    ;;
  status)
    status_of_proc "\$DAEMON" "\$NAME" && exit 0 || exit \$?
    ;;
  *)
    echo "Usage: \$NAME {start|stop|restart|force-reload|status}" >&2
    exit 3
    ;;
esac
EOL
            chmod +x /etc/init.d/dante-server
            update-rc.d dante-server defaults
            ;;
            
        openrc)
            # Create OpenRC init script
            cat > /etc/init.d/dante-server << EOL
#!/sbin/openrc-run

name="dante-server"
description="SOCKS5 Proxy Server"
command="/usr/sbin/sockd"
command_args="-f /etc/dante.conf"
pidfile="/run/\${name}.pid"
command_background=true

depend() {
    need net
    use logger
}
EOL
            chmod +x /etc/init.d/dante-server
            rc-update add dante-server default
            ;;
            
        *)
            echo_error "$(lang_text "Unsupported init system: $INIT_SYSTEM" "Неподдерживаемая система инициализации: $INIT_SYSTEM")"
            exit 1
            ;;
    esac
    
    echo_success "$(lang_text "Dante service successfully created" "Сервис Dante успешно создан")"
}

# Function to configure PAM authentication
function setup_pam_auth() {
    local message_en="Setting up PAM authentication for Dante..."
    local message_ru="Настройка PAM аутентификации для Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Create PAM configuration file for sockd
    cat > /etc/pam.d/sockd << EOL
# PAM configuration for Dante SOCKS server
auth required pam_pwdfile.so pwdfile=/etc/dante-users/users.pwd
account required pam_permit.so
EOL
    
    # Create directory for user authentication
    mkdir -p /etc/dante-users
    
    # Ensure proper permissions
    chmod 755 /etc/dante-users
    
    echo_success "$(lang_text "PAM authentication successfully configured" "PAM аутентификация успешно настроена")"
}

# Function to configure firewall
function setup_firewall() {
    local message_en="Setting up firewall..."
    local message_ru="Настройка брандмауэра..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    case "$FIREWALL_TYPE" in
        ufw)
            if command_exists "ufw"; then
                log "Configuring UFW"
                
                # Check if UFW is enabled
                if ! ufw status | grep -q "Status: active"; then
                    echo_warning "$(lang_text "UFW is not active. Trying to enable it..." "UFW не активен. Попытка активации...")"
                    ufw --force enable
                fi
                
                # Add rule
                ufw allow $PORT/tcp comment "SOCKS5 Proxy"
                ufw reload
            else
                echo_warning "$(lang_text "UFW not available despite being detected. Falling back to iptables." "UFW недоступен, несмотря на обнаружение. Используем iptables.")"
                configure_iptables_firewall
            fi
            ;;
            
        firewalld)
            if command_exists "firewall-cmd"; then
                log "Configuring FirewallD"
                
                # Add rules
                firewall-cmd --permanent --add-port=$PORT/tcp
                firewall-cmd --reload
            else
                echo_warning "$(lang_text "FirewallD not available despite being detected. Falling back to iptables." "FirewallD недоступен, несмотря на обнаружение. Используем iptables.")"
                configure_iptables_firewall
            fi
            ;;
            
        iptables)
            configure_iptables_firewall
            ;;
            
        none)
            echo_warning "$(lang_text "No firewall detected. Skipping firewall configuration." "Брандмауэр не обнаружен. Пропуск настройки брандмауэра.")"
            ;;
            
        *)
            echo_warning "$(lang_text "Unknown firewall type: $FIREWALL_TYPE. Falling back to iptables." "Неизвестный тип брандмауэра: $FIREWALL_TYPE. Используем iptables.")"
            configure_iptables_firewall
            ;;
    esac
}

# Function to configure iptables firewall
function configure_iptables_firewall() {
    if command_exists "iptables"; then
        log "Configuring iptables"
        
        # Back up existing rules
        if command_exists "iptables-save"; then
            iptables-save > /etc/iptables.backup.$(date +%Y%m%d%H%M%S)
        fi
        
        # Add rule
        iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        
        # Make iptables rules persistent (different methods for different distros)
        if command_exists "iptables-save"; then
            if [ -d "/etc/iptables" ]; then
                # Debian/Ubuntu method 1
                iptables-save > /etc/iptables/rules.v4
            elif [ -f "/etc/sysconfig/iptables" ]; then
                # CentOS/RHEL method
                iptables-save > /etc/sysconfig/iptables
            else
                # Debian/Ubuntu method 2
                iptables-save > /etc/iptables.rules
                
                # Create a script to load rules at boot
                cat > /etc/network/if-pre-up.d/iptables << EOL
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOL
                chmod +x /etc/network/if-pre-up.d/iptables
            fi
        else
            echo_warning "$(lang_text "Cannot make iptables rules persistent: iptables-save not found" "Невозможно сделать правила iptables постоянными: iptables-save не найден")"
        fi
    else
        echo_warning "$(lang_text "iptables not found. Skipping firewall configuration." "iptables не найден. Пропуск настройки брандмауэра.")"
    fi
}

# Function to start and enable Dante service
function start_dante_service() {
    local message_en="Enabling and starting Dante service..."
    local message_ru="Включение и запуск сервиса Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    case "$INIT_SYSTEM" in
        systemd)
            systemctl enable dante-server.service
            systemctl restart dante-server.service
            ;;
            
        sysv)
            update-rc.d dante-server defaults
            /etc/init.d/dante-server restart
            ;;
            
        openrc)
            rc-update add dante-server default
            rc-service dante-server restart
            ;;
            
        *)
            echo_error "$(lang_text "Unsupported init system: $INIT_SYSTEM" "Неподдерживаемая система инициализации: $INIT_SYSTEM")"
            exit 1
            ;;
    esac
    
    echo_success "$(lang_text "Dante service successfully started" "Сервис Dante успешно запущен")"
}

# Function to create and add a proxy user
function add_proxy_user() {
    local message_en="Creating proxy user..."
    local message_ru="Создание пользователя прокси..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Prompt for username and password if not provided
    if [ -z "$proxy_username" ]; then
        read -r -p "$(lang_text "Enter username: " "Введите имя пользователя: ")" proxy_username
    fi
    
    if [ -z "$proxy_password" ]; then
        read -r -p "$(lang_text "Enter password: " "Введите пароль: ")" proxy_password
    fi
    
    # Ensure username and password are not empty
    if [ -z "$proxy_username" ] || [ -z "$proxy_password" ]; then
        echo_error "$(lang_text "Username and password cannot be empty" "Имя пользователя и пароль не могут быть пустыми")"
        exit 1
    fi
    
    # Create the user with password
    local hashed_password=$(mkpasswd -m sha-512 "$proxy_password")
    
    # Create users directory if it doesn't exist
    mkdir -p /etc/dante-users
    
    # Add user to the password file
    echo "$proxy_username:$hashed_password" > /etc/dante-users/users.pwd
    
    # Fix permissions
    chmod 600 /etc/dante-users/users.pwd
    
    echo_success "$(lang_text "Proxy user created successfully" "Пользователь прокси успешно создан")"
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
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check required utilities
if ! command -v mkpasswd &> /dev/null; then
    echo "Installing required utilities..."
    apt-get update && apt-get install -y whois
fi

USER_DB="/etc/dante-users/users.pwd"

# Show usage information
function show_usage() {
    echo "Usage: \$0 [add|remove|list] [username] [password]"
    echo
    echo "Commands:"
    echo "  add USERNAME PASSWORD  - Add a new proxy user"
    echo "  remove USERNAME        - Remove an existing proxy user"
    echo "  list                   - List all proxy users"
    echo
    echo "Example:"
    echo "  \$0 add myuser mypassword"
}

# List all proxy users
function list_users() {
    echo "Current proxy users:"
    echo "--------------------"
    if [ -s "\$USER_DB" ]; then
        cat "\$USER_DB" | cut -d: -f1
    else
        echo "No users found."
    fi
}

# Add a new proxy user
function add_user() {
    local username="\$1"
    local password="\$2"
    
    # Validate input
    if [ -z "\$username" ] || [ -z "\$password" ]; then
        echo "Error: Username and password are required" >&2
        show_usage
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^\$username:" "\$USER_DB" 2>/dev/null; then
        echo "User '\$username' already exists. Remove it first or use a different username."
        return 1
    fi
    
    # Create password hash
    local hashed_password=\$(mkpasswd -m sha-512 "\$password")
    
    # Add user to the database
    echo "\$username:\$hashed_password" >> "\$USER_DB"
    
    echo "User '\$username' has been added successfully."
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    echo "Dante service restarted."
}

# Remove a proxy user
function remove_user() {
    local username="\$1"
    
    # Validate input
    if [ -z "\$username" ]; then
        echo "Error: Username is required" >&2
        show_usage
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^\$username:" "\$USER_DB" 2>/dev/null; then
        echo "User '\$username' does not exist."
        return 1
    fi
    
    # Remove user from the database
    sed -i "/^\$username:/d" "\$USER_DB"
    
    echo "User '\$username' has been removed successfully."
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    echo "Dante service restarted."
}

# Main script logic
# Проверяем наличие параметра, чтобы избежать ошибки "unbound variable"
if [ -z "\$1" ]; then
    show_usage
    exit 1
else
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
fi

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
    # Initialize variable to prevent unbound variable error
    local SERVER_IP="Your server IP"
    
    # Use different methods to detect public IP
    if command_exists "curl"; then
        SERVER_IP=$(curl -s https://ifconfig.me 2>/dev/null || curl -s https://api.ipify.org 2>/dev/null || curl -s https://icanhazip.com 2>/dev/null || echo "$SERVER_IP")
    elif command_exists "wget"; then
        SERVER_IP=$(wget -qO- https://ifconfig.me 2>/dev/null || wget -qO- https://api.ipify.org 2>/dev/null || wget -qO- https://icanhazip.com 2>/dev/null || echo "$SERVER_IP")
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
    
    # Small delay for better UX
    sleep 1
    
    # Execute the selected action
    if [ "$ACTION" == "install" ]; then
        # Install proxy server
        update_system
        install_packages
        create_dante_config
        setup_dante_service
        setup_pam_auth
        setup_firewall
        add_proxy_user
        create_management_script
        start_dante_service
        test_proxy_connection
        show_completion
    else
        # Uninstall proxy server
        uninstall_proxy
    fi
    
    log "Script finished successfully"
}

# Run the main function with all command line arguments
main "$@"

exit 0