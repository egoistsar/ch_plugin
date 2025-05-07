#!/bin/bash

# Socks5 Proxy Server with User Authentication - Interactive Installer
# ----------------------------------------------------------------------------------
# This script installs and configures Dante SOCKS5 proxy server with user authentication
# on Ubuntu/Debian systems.
# ----------------------------------------------------------------------------------

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

# Function to display colored status messages
function echo_status() {
    echo -e "\n${BLUE}>> $1${NC}"
}

# Function to display success messages
function echo_success() {
    echo -e "\n${GREEN}✓ $1${NC}"
}

# Function to display error messages
function echo_error() {
    echo -e "\n${RED}✗ $1${NC}"
}

# Function to display warning/info messages
function echo_warning() {
    echo -e "\n${YELLOW}! $1${NC}"
}

# Function to ask for language preference
function ask_language() {
    echo "Please select your preferred language / Пожалуйста, выберите предпочитаемый язык:"
    echo "1) English"
    echo "2) Русский"
    read -p "Enter your choice (1/2): " lang_choice
    
    case $lang_choice in
        2)
            LANGUAGE="ru"
            ;;
        *)
            LANGUAGE="en"
            ;;
    esac
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
            ;;
        *)
            echo_warning "$(lang_text "Unsupported system: $OS $VER. This script is tested on Ubuntu/Debian." "Неподдерживаемая система: $OS $VER. Этот скрипт тестировался на Ubuntu/Debian.")"
            read -p "$(lang_text "Continue anyway? (y/n): " "Продолжить в любом случае? (y/n): ")" choice
            if [[ ! "$choice" =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# Function to ask user for proxy port
function ask_port() {
    local message_en="Enter the port number for the SOCKS5 proxy server [default: $DEFAULT_PORT]:"
    local message_ru="Введите номер порта для SOCKS5 прокси-сервера [по умолчанию: $DEFAULT_PORT]:"
    
    read -p "$(lang_text "$message_en" "$message_ru") " port_input
    
    if [ -z "$port_input" ]; then
        PORT=$DEFAULT_PORT
    else
        if [[ "$port_input" =~ ^[0-9]+$ ]] && [ "$port_input" -ge 1 ] && [ "$port_input" -le 65535 ]; then
            PORT=$port_input
        else
            echo_error "$(lang_text "Invalid port number. Using default: $DEFAULT_PORT" "Неверный номер порта. Используется по умолчанию: $DEFAULT_PORT")"
            PORT=$DEFAULT_PORT
        fi
    fi
}

# Function to create Dante configuration file
function create_dante_config() {
    local message_en="Creating Dante server configuration..."
    local message_ru="Создание конфигурации сервера Dante..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    cat > /etc/dante.conf << EOL
# Dante SOCKS5 proxy server configuration
# This configuration enables a secure SOCKS5 proxy with user authentication

# The listening address and port
internal: 0.0.0.0 port=$PORT

# The external interface
external: eth0

# Authentication method
socksmethod: username

# User access methods and restrictions
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody

# Client connection settings
clientmethod: none
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

# Function to install required packages
function install_packages() {
    local message_en="Installing required packages..."
    local message_ru="Установка необходимых пакетов..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    apt-get update
    apt-get install -y dante-server libpam-pwdfile sudo ufw whois
    
    echo_success "$(lang_text "Required packages installed successfully" "Необходимые пакеты успешно установлены")"
}

# Function to configure firewall
function configure_firewall() {
    local message_en="Configuring firewall..."
    local message_ru="Настройка брандмауэра..."
    
    echo_status "$(lang_text "$message_en" "$message_ru")"
    
    ufw allow ssh
    ufw allow $PORT/tcp
    
    if ! ufw status | grep -q "Status: active"; then
        ufw --force enable
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
    
    # Create password hash
    local hashed_password=$(mkpasswd -m sha-512 "$password")
    
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
    # First ask for username (separate question)
    local proxy_username=$(ask_proxy_username)
    
    # Then ask for password (separate question)
    local proxy_password=$(ask_proxy_password)
    
    # Add the user with the provided credentials
    add_proxy_user "$proxy_username" "$proxy_password"
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
    
    # Create password hash
    local hashed_password=\$(mkpasswd -m sha-512 "\$password")
    
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

# Function to display completion message
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
    
    local message_en_11="Authentication: Username/Password (as configured with proxy-users command)"
    local message_ru_11="Аутентификация: Имя пользователя/Пароль (как настроено с помощью команды proxy-users)"
    
    echo_status "$(lang_text "$message_en_1" "$message_ru_1")"
    echo "$(lang_text "$message_en_2" "$message_ru_2")"
    echo
    echo "$(lang_text "$message_en_3" "$message_ru_3")"
    echo "  $(lang_text "$message_en_4" "$message_ru_4")"
    echo "  $(lang_text "$message_en_5" "$message_ru_5")"
    echo "  $(lang_text "$message_en_6" "$message_ru_6")"
    echo
    echo "$(lang_text "$message_en_7" "$message_ru_7")"
    echo "  $(lang_text "$message_en_8" "$message_ru_8")"
    echo "  $(lang_text "$message_en_9" "$message_ru_9")"
    echo "  $(lang_text "$message_en_10" "$message_ru_10")"
    echo "  $(lang_text "$message_en_11" "$message_ru_11")"
}

# Main function to run the installation
function main() {
    # Clear screen
    clear
    
    # Display banner
    echo "====================================================="
    echo "       SOCKS5 Proxy Server Interactive Installer     "
    echo "====================================================="
    echo
    
    # Ask for language preference
    ask_language
    
    # Check if running as root
    check_root
    
    # Check system compatibility
    check_system
    
    # Ask for proxy port
    ask_port
    
    # Install required packages
    install_packages
    
    # Create Dante configuration
    create_dante_config
    
    # Create systemd service for Dante
    create_dante_service
    
    # Setup PAM authentication
    setup_pam_auth
    
    # Configure firewall
    configure_firewall
    
    # Enable and start Dante service
    echo_status "$(lang_text "Enabling and starting Dante service..." "Включение и запуск сервиса Dante...")"
    systemctl daemon-reload
    systemctl enable dante-server.service
    systemctl restart dante-server.service
    
    # Create user management script
    create_management_script
    
    # Ask for proxy user credentials
    manage_user_credentials
    
    # Display completion message
    show_completion
}

# Run the main function
main

exit 0