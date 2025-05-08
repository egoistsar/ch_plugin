#!/bin/bash

# SOCKS5 Proxy Server Installer for Debian/Ubuntu
# This script installs and configures a SOCKS5 proxy server with authentication

# Enable strict error checking
set -e
set -u

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
proxy_username=""
proxy_password=""

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
    echo -e "${BLUE}>> $1${NC}"
    log "STATUS: $1"
}

function echo_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
}

function echo_error() {
    echo -e "${RED}✗ $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

function echo_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "WARNING: $1"
}

# Check if a command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check root privileges
function check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo_error "$(lang_text "This script must be run as root" "Этот скрипт должен быть запущен от имени root")"
        echo "$(lang_text "Please run this script with root privileges. For example:" "Пожалуйста, запустите этот скрипт с привилегиями root. Например:")"
        echo "  sudo bash $0"
        exit 1
    fi
}

# Function to detect system
function detect_system() {
    # Check if we're on Debian/Ubuntu
    if [ -f /etc/debian_version ]; then
        log "Detected Debian/Ubuntu system"
    else
        echo_error "$(lang_text "This script only supports Debian/Ubuntu distributions" "Этот скрипт поддерживает только дистрибутивы Debian/Ubuntu")"
        exit 1
    fi
    
    # Init system is always systemd on modern Debian/Ubuntu
    log "Using systemd init system"
    
    # Default firewall is UFW on Debian/Ubuntu
    if command_exists "ufw"; then
        log "Using UFW firewall"
    else
        log "UFW not found, will use iptables directly"
    fi
}

# Function to update the system
function update_system() {
    local message_en="Updating system packages..."
    local message_ru="Обновление пакетов системы..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Update package lists
    apt-get update -q
    
    echo_success "$(lang_text "System packages updated successfully" "Пакеты системы успешно обновлены")"
}

# Function to install required packages
function install_packages() {
    local message_en="Installing required packages..."
    local message_ru="Установка необходимых пакетов..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Install required packages
    apt-get -y install dante-server libpam-pwdfile whois net-tools procps curl
    
    echo_success "$(lang_text "Required packages installed successfully" "Необходимые пакеты успешно установлены")"
}

# Function to create Dante configuration
function create_dante_config() {
    local message_en="Creating Dante server configuration..."
    local message_ru="Создание конфигурации сервера Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Create config directory if it doesn't exist
    mkdir -p /etc/dante-users
    
    # Автоматическое определение интерфейса
    # Пытаемся определить основной сетевой интерфейс
    MAIN_INTERFACE=""
    
    # Метод 1: используя ip route
    if command_exists "ip"; then
        MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    fi
    
    # Метод 2: используя route
    if [ -z "$MAIN_INTERFACE" ] && command_exists "route"; then
        MAIN_INTERFACE=$(route -n | grep '^0.0.0.0' | awk '{print $8}' | head -n1)
    fi
    
    # Метод 3: используя ifconfig
    if [ -z "$MAIN_INTERFACE" ] && command_exists "ifconfig"; then
        MAIN_INTERFACE=$(ifconfig | grep -v lo | grep -E '^[a-zA-Z0-9]+' | awk '{print $1}' | sed 's/://' | head -n1)
    fi
    
    # Если интерфейс не найден, используем eth0 как запасной вариант
    if [ -z "$MAIN_INTERFACE" ]; then
        MAIN_INTERFACE="eth0"
        echo_warning "$(lang_text "Could not detect network interface, using eth0 as default" "Не удалось определить сетевой интерфейс, используем eth0 по умолчанию")"
    else
        log "Detected network interface: $MAIN_INTERFACE"
    fi
    
    # Create the configuration file
    cat > /etc/dante.conf << EOL
# Dante SOCKS5 proxy server configuration

# Basic server settings
logoutput: stderr

# Внутренний интерфейс - слушаем на всех сетевых интерфейсах и указанном порту
internal: 0.0.0.0 port=$PORT

# Внешний интерфейс - используем автоматически определенный интерфейс
external: $MAIN_INTERFACE

# Используем аутентификацию по логину/паролю
method: username

# Настройки доступа
user.privileged: root
user.notprivileged: nobody

# Правила для клиентов - разрешаем всем аутентифицированным пользователям подключаться
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

# Правила для SOCKS - разрешаем все типы соединений через прокси
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    method: username
}

# Используем PAM для аутентификации
auth: pam
EOL

    # Создаем очень минималистичный конфиг как запасной вариант
    cat > /etc/dante.conf.minimal << EOL
logoutput: stderr
internal: 0.0.0.0 port=$PORT
method: none
user.privileged: root
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOL

    echo_success "$(lang_text "Dante configuration created successfully using interface $MAIN_INTERFACE" "Конфигурация Dante успешно создана с использованием интерфейса $MAIN_INTERFACE")"
}

# Function to configure systemd service
function setup_dante_service() {
    local message_en="Setting up Dante system service..."
    local message_ru="Настройка системного сервиса Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Находим точный путь к бинарному файлу (проверяем оба имени - sockd и danted)
    SOCKD_BIN=""
    
    # Проверяем оба варианта имени в PATH
    if command -v sockd >/dev/null 2>&1; then
        SOCKD_BIN=$(command -v sockd)
        log "Found sockd in PATH: $SOCKD_BIN"
    elif command -v danted >/dev/null 2>&1; then
        SOCKD_BIN=$(command -v danted)
        log "Found danted in PATH: $SOCKD_BIN"
    fi
    
    # Если бинарный файл не найден в PATH, ищем его в стандартных местах
    if [ -z "$SOCKD_BIN" ]; then
        if [ -x "/usr/sbin/sockd" ]; then
            SOCKD_BIN="/usr/sbin/sockd"
            log "Found sockd in /usr/sbin"
        elif [ -x "/usr/sbin/danted" ]; then
            SOCKD_BIN="/usr/sbin/danted"
            log "Found danted in /usr/sbin"
        elif [ -x "/usr/bin/sockd" ]; then
            SOCKD_BIN="/usr/bin/sockd"
            log "Found sockd in /usr/bin"
        elif [ -x "/usr/bin/danted" ]; then
            SOCKD_BIN="/usr/bin/danted"
            log "Found danted in /usr/bin"
        else
            # Если ничего не найдено, пробуем использовать danted, так как это имя используется в некоторых версиях Ubuntu
            echo_warning "$(lang_text "Dante binary not found, trying default path /usr/sbin/danted" "Бинарный файл Dante не найден, пробуем путь по умолчанию /usr/sbin/danted")"
            SOCKD_BIN="/usr/sbin/danted"
        fi
    fi
    
    log "Using Dante binary: $SOCKD_BIN"
    
    # Create systemd service file
    cat > /etc/systemd/system/dante-server.service << EOL
[Unit]
Description=SOCKS5 Proxy Server (Dante)
After=network.target

[Service]
Type=simple
ExecStart=$SOCKD_BIN -f /etc/dante.conf
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
    
    # Reload systemd and enable the service
    systemctl daemon-reload
    systemctl enable dante-server.service
    
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
    
    # Try to use UFW first, fallback to iptables
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
        log "Configuring iptables"
        
        # Back up existing rules
        if command_exists "iptables-save"; then
            iptables-save > /etc/iptables.backup.$(date +%Y%m%d%H%M%S)
        fi
        
        # Add rule
        iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        
        # Make iptables rules persistent
        if command_exists "iptables-save"; then
            if [ -d "/etc/iptables" ]; then
                # Debian/Ubuntu method 1
                iptables-save > /etc/iptables/rules.v4
            else
                # Debian/Ubuntu method 2
                iptables-save > /etc/iptables.rules
                
                # Create a script to load rules at boot
                mkdir -p /etc/network/if-pre-up.d/
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
    fi
    
    echo_success "$(lang_text "Firewall configured successfully" "Брандмауэр успешно настроен")"
}

# Function to start and enable Dante service
function start_dante_service() {
    local message_en="Enabling and starting Dante service..."
    local message_ru="Включение и запуск сервиса Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Start and enable the service
    systemctl enable dante-server.service
    systemctl restart dante-server.service
    
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
    
    cat > /usr/local/bin/manage_proxy_users << EOL
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
    
    # Fix permissions
    chmod 600 "\$USER_DB"
    
    echo "User '\$username' added successfully."
    
    # Restart the Dante service to apply changes
    if systemctl is-active --quiet dante-server; then
        systemctl restart dante-server
        echo "Dante service restarted."
    else
        echo "Warning: Dante service is not running. Please start it manually."
    fi
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
    
    # Create temp file
    local temp_file=\$(mktemp)
    
    # Write all users except the one to be removed
    grep -v "^\$username:" "\$USER_DB" > "\$temp_file"
    
    # Replace the original file
    mv "\$temp_file" "\$USER_DB"
    
    # Fix permissions
    chmod 600 "\$USER_DB"
    
    echo "User '\$username' removed successfully."
    
    # Restart the Dante service to apply changes
    if systemctl is-active --quiet dante-server; then
        systemctl restart dante-server
        echo "Dante service restarted."
    else
        echo "Warning: Dante service is not running. Please start it manually."
    fi
}

# Check for command
if [ \$# -lt 1 ]; then
    show_usage
    exit 1
fi

# Process commands
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
        echo "Unknown command: \$1" >&2
        show_usage
        exit 1
        ;;
esac
EOL

    chmod +x /usr/local/bin/manage_proxy_users
    
    # Create a symlink for convenience
    ln -sf /usr/local/bin/manage_proxy_users /usr/local/bin/proxy-users
    
    echo_success "$(lang_text "User management script created successfully" "Скрипт управления пользователями успешно создан")"
}

# Function to test the proxy
function test_proxy() {
    local message_en="Testing proxy connection..."
    local message_ru="Проверка подключения к прокси..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    # Wait for the service to start properly
    sleep 2
    
    # Check if the process is running
    if pgrep -x "$(basename "$SOCKD_BIN")" > /dev/null; then
        log "Dante process is running"
    else
        log "Dante process is not running"
    fi
    
    # Check if the port is open
    if netstat -tuln | grep -q ":$PORT "; then
        echo_success "$(lang_text "Proxy server is running on port $PORT" "Прокси-сервер запущен на порту $PORT")"
    else
        echo_error "$(lang_text "Proxy server is not running on port $PORT" "Прокси-сервер не запущен на порту $PORT")"
        
        # Display service status for debugging
        log "Service status: $(systemctl status dante-server.service)"
    fi
}

# Function to display connection information
function display_connection_info() {
    # Get the server's public IP address
    local public_ip=$(curl -s https://ipinfo.io/ip || curl -s https://api.ipify.org || curl -s https://icanhazip.com)
    
    if [ -z "$public_ip" ]; then
        public_ip="<your-server-ip>"
    fi
    
    echo
    echo "╔══════════════════════════════════════════════╗"
    echo "║  $(lang_text "SOCKS5 Proxy Connection Information" "Информация о подключении к SOCKS5 прокси")  ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║ $(lang_text "Server:" "Сервер:") $public_ip"
    echo "║ $(lang_text "Port:" "Порт:") $PORT"
    echo "║ $(lang_text "Username:" "Имя пользователя:") $proxy_username"
    echo "║ $(lang_text "Password:" "Пароль:") $proxy_password"
    echo "╚══════════════════════════════════════════════╝"
    echo
    echo "$(lang_text "You can manage proxy users with the following command:" "Вы можете управлять пользователями прокси с помощью следующей команды:")"
    echo "sudo proxy-users [add|remove|list] [username] [password]"
    echo
}

# Function to install the proxy server
function install_proxy() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOGFILE")"
    touch "$LOGFILE"
    
    # Set permissions for log file
    chmod 644 "$LOGFILE"
    
    echo
    echo " ____   ___   ____ _  _____ _____ "
    echo "/ ___| / _ \\ / ___| |/ / / / ____|"
    echo "\\___ \\| | | | |   | ' / | | |     "
    echo " ___) | |_| | |___| . \\ | | |____ "
    echo "|____/ \\___/ \\____|_|\\_\\ | \\_____|"
    echo "                        |_|       "
    echo " ____                          ____                            "
    echo "|  _ \\ _ __ _____  ___   _    / ___|  ___ _ ____   _____ _ __ "
    echo "| |_) | '__/ _ \\ \\/ / | | |   \\___ \\ / _ \\ '__\\ \\ / / _ \\ '__|"
    echo "|  __/| | | (_) >  <| |_| |    ___) |  __/ |   \\ V /  __/ |   "
    echo "|_|   |_|  \\___/_/\\_\\\\__, |   |____/ \\___|_|    \\_/ \\___|_|   "
    echo "                     |___/                                     "
    echo
    echo "$(lang_text "SOCKS5 Proxy Server Installer for Debian/Ubuntu" "Установщик SOCKS5 прокси-сервера для Debian/Ubuntu")"
    echo
    
    detect_system
    update_system
    install_packages
    create_dante_config
    setup_dante_service
    setup_pam_auth
    setup_firewall
    add_proxy_user
    create_management_script
    start_dante_service
    test_proxy
    display_connection_info
    
    echo_success "$(lang_text "Installation completed successfully" "Установка успешно завершена")"
}

# Function to uninstall the proxy server
function uninstall_proxy() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOGFILE")"
    touch "$LOGFILE"
    
    # Set permissions for log file
    chmod 644 "$LOGFILE"
    
    echo
    echo "$(lang_text "SOCKS5 Proxy Server Uninstaller" "Удаление SOCKS5 прокси-сервера")"
    echo
    
    echo_status "$(lang_text "Stopping Dante service..." "Остановка сервиса Dante...")"
    systemctl stop dante-server.service 2>/dev/null || true
    systemctl disable dante-server.service 2>/dev/null || true
    
    echo_status "$(lang_text "Removing Dante service..." "Удаление сервиса Dante...")"
    rm -f /etc/systemd/system/dante-server.service
    systemctl daemon-reload
    
    echo_status "$(lang_text "Removing Dante configuration files..." "Удаление файлов конфигурации Dante...")"
    rm -f /etc/dante.conf
    rm -f /etc/dante.conf.minimal
    rm -rf /etc/dante-users
    rm -f /etc/pam.d/sockd
    
    echo_status "$(lang_text "Removing proxy user management script..." "Удаление скрипта управления пользователями прокси...")"
    rm -f /usr/local/bin/manage_proxy_users
    rm -f /usr/local/bin/proxy-users
    
    echo_status "$(lang_text "Uninstalling Dante package..." "Удаление пакета Dante...")"
    apt-get -y remove dante-server
    apt-get -y autoremove
    
    echo_success "$(lang_text "Uninstallation completed successfully" "Удаление успешно завершено")"
}

# Main function
function main() {
    # Check if running as root
    check_root
    
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --language=*)
                LANGUAGE="${1#*=}"
                shift
                ;;
            --action=*)
                ACTION="${1#*=}"
                shift
                ;;
            --port=*)
                PORT="${1#*=}"
                shift
                ;;
            --username=*)
                proxy_username="${1#*=}"
                shift
                ;;
            --password=*)
                proxy_password="${1#*=}"
                shift
                ;;
            *)
                echo_error "$(lang_text "Unknown parameter: $1" "Неизвестный параметр: $1")"
                exit 1
                ;;
        esac
    done
    
    # Prompt for language if not provided
    if [ -z "$LANGUAGE" ]; then
        echo "Select language / Выберите язык:"
        echo "1. English"
        echo "2. Русский"
        read -r -p "Enter your choice [1-2]: " lang_choice
        
        case "$lang_choice" in
            1|"")
                LANGUAGE="en"
                ;;
            2)
                LANGUAGE="ru"
                ;;
            *)
                echo "Invalid choice. Using English as default."
                LANGUAGE="en"
                ;;
        esac
    fi
    
    # Save language preference for later use
    echo "$LANGUAGE" > /etc/dante-language
    
    # Prompt for action if not provided
    if [ -z "$ACTION" ]; then
        echo
        echo "$(lang_text "Select action:" "Выберите действие:")"
        echo "$(lang_text "1. Install SOCKS5 proxy server" "1. Установить SOCKS5 прокси-сервер")"
        echo "$(lang_text "2. Uninstall SOCKS5 proxy server" "2. Удалить SOCKS5 прокси-сервер")"
        read -r -p "$(lang_text "Enter your choice [1-2]: " "Введите ваш выбор [1-2]: ")" action_choice
        
        case "$action_choice" in
            1|"")
                ACTION="install"
                ;;
            2)
                ACTION="uninstall"
                ;;
            *)
                echo_error "$(lang_text "Invalid choice" "Неверный выбор")"
                exit 1
                ;;
        esac
    fi
    
    # Prompt for port if not provided and installing
    if [ "$ACTION" == "install" ] && [ "$PORT" == "$DEFAULT_PORT" ]; then
        read -r -p "$(lang_text "Enter port number [$DEFAULT_PORT]: " "Введите номер порта [$DEFAULT_PORT]: ")" port_input
        
        if [ -n "$port_input" ]; then
            # Validate port number
            if [[ "$port_input" =~ ^[0-9]+$ ]] && [ "$port_input" -ge 1 ] && [ "$port_input" -le 65535 ]; then
                PORT="$port_input"
            else
                echo_error "$(lang_text "Invalid port number. Port must be between 1 and 65535." "Неверный номер порта. Порт должен быть между 1 и 65535.")"
                exit 1
            fi
        fi
    fi
    
    # Execute requested action
    case "$ACTION" in
        install)
            install_proxy
            ;;
        uninstall)
            uninstall_proxy
            ;;
        *)
            echo_error "$(lang_text "Invalid action: $ACTION" "Неверное действие: $ACTION")"
            exit 1
            ;;
    esac
}

# Execute main function with all command-line arguments
main "$@"