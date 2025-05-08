#!/bin/bash

# Utility functions for SOCKS5 Proxy Server Setup
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
interface=""
declare -A messages

# Function to display banners
display_banner() {
    if [ "$language" = "en" ]; then
        echo -e "${BLUE}"
        echo -e "╔══════════════════════════════════════════════╗"
        echo -e "║       SOCKS5 Proxy Server Setup Script       ║"
        echo -e "╠══════════════════════════════════════════════╣"
        echo -e "║ Author: GitHub - egoistsar                   ║"
        echo -e "║ Repository: github.com/egoistsar/s5proxyserver ║"
        echo -e "╚══════════════════════════════════════════════╝"
        echo -e "${NC}"
    else
        echo -e "${BLUE}"
        echo -e "╔══════════════════════════════════════════════╗"
        echo -e "║       Установка SOCKS5 Прокси-Сервера        ║"
        echo -e "╠══════════════════════════════════════════════╣"
        echo -e "║ Автор: GitHub - egoistsar                    ║"
        echo -e "║ Репозиторий: github.com/egoistsar/s5proxyserver ║"
        echo -e "╚══════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi
}

# Function to load language-specific messages
load_language_messages() {
    if [ "$language" = "ru" ]; then
        # Russian messages
        messages["system_not_supported"]="Система не поддерживается. Требуется Debian 8+ или Ubuntu 16.04+"
        messages["os_release_not_found"]="Не удалось определить операционную систему"
        messages["select_action"]="Выберите действие:"
        messages["install_proxy"]="Установить SOCKS5 прокси-сервер"
        messages["uninstall_proxy"]="Удалить SOCKS5 прокси-сервер"
        messages["enter_choice"]="Введите ваш выбор"
        messages["timeout_default_action"]="Время ожидания истекло. Выбрано действие по умолчанию (установка)."
        messages["invalid_choice_default"]="Неверный выбор. Выбрано действие по умолчанию (установка)."
        messages["port_setup"]="Настройка порта для SOCKS5 прокси-сервера"
        messages["enter_port"]="Введите номер порта"
        messages["invalid_port"]="Неверный порт. Будет использован порт по умолчанию:"
        messages["create_user"]="Создание пользователя прокси"
        messages["enter_username"]="Введите имя пользователя"
        messages["enter_password"]="Введите пароль"
        messages["timeout_default_username"]="Время ожидания истекло. Будет использовано имя пользователя по умолчанию: proxyuser"
        messages["timeout_default_password"]="Время ожидания истекло. Будет использован случайно сгенерированный пароль."
        messages["starting_installation"]="Начинаем установку SOCKS5 прокси-сервера..."
        messages["updating_packages"]="Обновление системных пакетов..."
        messages["update_failed"]="Не удалось обновить системные пакеты"
        messages["installing_packages"]="Установка необходимых пакетов..."
        messages["packages_install_failed"]="Не удалось установить необходимые пакеты"
        messages["detecting_interface"]="Определение сетевого интерфейса..."
        messages["interface_detected"]="Обнаружен сетевой интерфейс:"
        messages["generating_config"]="Генерация конфигурации Dante Server..."
        messages["setting_up_auth"]="Настройка аутентификации..."
        messages["adding_proxy_user"]="Добавление пользователя прокси..."
        messages["creating_service"]="Создание системной службы..."
        messages["configuring_firewall"]="Настройка брандмауэра..."
        messages["installing_user_script"]="Установка скрипта управления пользователями..."
        messages["starting_service"]="Запуск службы SOCKS5 прокси-сервера..."
        messages["installation_completed"]="Установка SOCKS5 прокси-сервера успешно завершена!"
        messages["service_start_failed"]="Не удалось запустить службу прокси-сервера"
        messages["starting_uninstallation"]="Начинаем удаление SOCKS5 прокси-сервера..."
        messages["uninstallation_completed"]="Удаление SOCKS5 прокси-сервера успешно завершено!"
        messages["connection_info_header"]="Информация о подключении к SOCKS5 прокси"
        messages["proxy_type"]="Тип прокси"
        messages["server_address"]="Адрес сервера"
        messages["server_port"]="Порт"
        messages["auth_required"]="Требуется авторизация"
        messages["username"]="Логин"
        messages["password"]="Пароль"
        messages["yes"]="Да"
        messages["manage_users_header"]="Управление пользователями"
        messages["list_users"]="Список пользователей"
        messages["add_user"]="Добавить пользователя"
        messages["remove_user"]="Удалить пользователя"
    else
        # English messages
        messages["system_not_supported"]="System not supported. Required Debian 8+ or Ubuntu 16.04+"
        messages["os_release_not_found"]="Failed to determine operating system"
        messages["select_action"]="Select action:"
        messages["install_proxy"]="Install SOCKS5 proxy server"
        messages["uninstall_proxy"]="Uninstall SOCKS5 proxy server"
        messages["enter_choice"]="Enter your choice"
        messages["timeout_default_action"]="Timeout reached. Default action (installation) selected."
        messages["invalid_choice_default"]="Invalid choice. Default action (installation) selected."
        messages["port_setup"]="Set up port for SOCKS5 proxy server"
        messages["enter_port"]="Enter port number"
        messages["invalid_port"]="Invalid port. Using default port:"
        messages["create_user"]="Create proxy user"
        messages["enter_username"]="Enter username"
        messages["enter_password"]="Enter password"
        messages["timeout_default_username"]="Timeout reached. Using default username: proxyuser"
        messages["timeout_default_password"]="Timeout reached. Using randomly generated password."
        messages["starting_installation"]="Starting SOCKS5 proxy server installation..."
        messages["updating_packages"]="Updating system packages..."
        messages["update_failed"]="Failed to update system packages"
        messages["installing_packages"]="Installing required packages..."
        messages["packages_install_failed"]="Failed to install required packages"
        messages["detecting_interface"]="Detecting network interface..."
        messages["interface_detected"]="Network interface detected:"
        messages["generating_config"]="Generating Dante Server configuration..."
        messages["setting_up_auth"]="Setting up authentication..."
        messages["adding_proxy_user"]="Adding proxy user..."
        messages["creating_service"]="Creating system service..."
        messages["configuring_firewall"]="Configuring firewall..."
        messages["installing_user_script"]="Installing user management script..."
        messages["starting_service"]="Starting SOCKS5 proxy server service..."
        messages["installation_completed"]="SOCKS5 proxy server installation completed successfully!"
        messages["service_start_failed"]="Failed to start proxy server service"
        messages["starting_uninstallation"]="Starting SOCKS5 proxy server uninstallation..."
        messages["uninstallation_completed"]="SOCKS5 proxy server uninstallation completed successfully!"
        messages["connection_info_header"]="SOCKS5 Proxy Connection Information"
        messages["proxy_type"]="Proxy type"
        messages["server_address"]="Server address"
        messages["server_port"]="Port"
        messages["auth_required"]="Authentication required"
        messages["username"]="Username"
        messages["password"]="Password"
        messages["yes"]="Yes"
        messages["manage_users_header"]="User Management"
        messages["list_users"]="List users"
        messages["add_user"]="Add user"
        messages["remove_user"]="Remove user"
    fi
}

# Function to display colored messages
display_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to display success messages
display_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to display error messages
display_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to display warning messages
display_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" >> /var/log/sockd/setup.log
}

# Function to detect network interface
detect_network_interface() {
    display_message "${messages["detecting_interface"]}"
    
    # Try to get the interface with the default route
    interface=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    
    # If not found, try to get the first non-loopback interface
    if [ -z "$interface" ]; then
        interface=$(ip -o -4 addr show | awk '!/^[0-9]*: lo|^[0-9]*: docker/' | head -1 | awk '{print $2}' | cut -d':' -f1)
    fi
    
    # If still not found, use eth0 as fallback
    if [ -z "$interface" ]; then
        interface="eth0"
        display_warning "Could not detect network interface, using 'eth0' as fallback"
        log_message "Network interface detection failed, using eth0 as fallback"
    else
        display_message "${messages["interface_detected"]} $interface"
        log_message "Network interface detected: $interface"
    fi
}

# Function to get public IP address
get_public_ip() {
    ip=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || curl -s -4 ipinfo.io/ip)
    if [ -z "$ip" ]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "$ip"
}

# Function to generate a random password
generate_random_password() {
    local length=$1
    [ -z "$length" ] && length=12
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c "$length"
}

# Function to create a SHA-512 hashed password
create_hashed_password() {
    local username=$1
    local password=$2
    local salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)
    local hash=$(mkpasswd -m sha-512 "$password" "$salt")
    echo "$username:$hash"
}
