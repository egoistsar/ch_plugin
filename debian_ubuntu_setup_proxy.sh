#!/bin/bash

# SOCKS5 Proxy Server Setup Script for Debian/Ubuntu
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver
# This script automates the installation and configuration of a SOCKS5 proxy server
# using Dante Server on Debian and Ubuntu systems.

# Import utility functions
source <(curl -s https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/utils.sh)
source <(curl -s https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/dante_config.sh)
source <(curl -s https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/user_management.sh)

# Constants
DEFAULT_PORT=1080
TIMEOUT=300 # 5 minutes timeout for user input

# Variables
language=""
action=""
port=""
username=""
password=""

# Function to check if the system is supported
check_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            log_message "System detected: $PRETTY_NAME"
            return 0
        else
            display_error "${messages["system_not_supported"]}"
            exit 1
        fi
    else
        display_error "${messages["os_release_not_found"]}"
        exit 1
    fi
}

# Function to select language
select_language() {
    echo ""
    echo "Select language / Выберите язык:"
    echo "1. English"
    echo "2. Русский"
    read -t $TIMEOUT -p "Enter your choice [1-2]: " lang_choice
    
    if [ -z "$lang_choice" ]; then
        language="en"
        echo "Timeout reached. Default language (English) selected."
    elif [ "$lang_choice" = "1" ]; then
        language="en"
    elif [ "$lang_choice" = "2" ]; then
        language="ru"
    else
        language="en"
        echo "Invalid choice. Default language (English) selected."
    fi
    
    load_language_messages
    display_banner
}

# Function to select action (install or uninstall)
select_action() {
    echo ""
    echo "${messages["select_action"]}"
    echo "1. ${messages["install_proxy"]}"
    echo "2. ${messages["uninstall_proxy"]}"
    read -t $TIMEOUT -p "${messages["enter_choice"]} [1-2]: " action_choice
    
    if [ -z "$action_choice" ]; then
        action="install"
        echo "${messages["timeout_default_action"]}"
    elif [ "$action_choice" = "1" ]; then
        action="install"
    elif [ "$action_choice" = "2" ]; then
        action="uninstall"
    else
        action="install"
        echo "${messages["invalid_choice_default"]}"
    fi
}

# Function to set up the proxy port
setup_port() {
    echo ""
    echo "${messages["port_setup"]}"
    read -t $TIMEOUT -p "${messages["enter_port"]} [$DEFAULT_PORT]: " port_choice
    
    if [ -z "$port_choice" ]; then
        port=$DEFAULT_PORT
    else
        # Check if port is a number and in the valid range
        if [[ "$port_choice" =~ ^[0-9]+$ && "$port_choice" -ge 1 && "$port_choice" -le 65535 ]]; then
            port=$port_choice
        else
            port=$DEFAULT_PORT
            echo "${messages["invalid_port"]} $DEFAULT_PORT."
        fi
    fi
}

# Function to create proxy user
create_proxy_user() {
    echo ""
    echo "${messages["create_user"]}"
    read -t $TIMEOUT -p "${messages["enter_username"]}: " username
    
    if [ -z "$username" ]; then
        username="proxyuser"
        echo "${messages["timeout_default_username"]}"
    fi
    
    read -t $TIMEOUT -s -p "${messages["enter_password"]}: " password
    echo ""
    
    if [ -z "$password" ]; then
        password=$(generate_random_password 12)
        echo "${messages["timeout_default_password"]}"
    fi
}

# Main installation function
install_proxy() {
    log_message "Starting installation process..."
    display_message "${messages["starting_installation"]}"
    
    # Update system packages
    display_message "${messages["updating_packages"]}"
    apt-get update -y || { display_error "${messages["update_failed"]}"; exit 1; }
    
    # Install required packages
    display_message "${messages["installing_packages"]}"
    apt-get install -y dante-server libpam-pwdfile curl iptables net-tools || {
        display_error "${messages["packages_install_failed"]}";
        exit 1;
    }
    
    # Create necessary directories
    mkdir -p /etc/dante
    mkdir -p /etc/sockd
    mkdir -p /var/log/sockd
    
    # Detect network interface
    detect_network_interface
    
    # Generate and write Dante configuration
    generate_dante_config "$port" "$interface" > /etc/dante/sockd.conf
    
    # Set up authentication
    setup_authentication
    
    # Add proxy user
    add_proxy_user "$username" "$password"
    
    # Create systemd service
    create_systemd_service
    
    # Configure firewall
    configure_firewall "$port"
    
    # Install user management script
    install_user_management_script
    
    # Start the service
    systemctl daemon-reload
    systemctl enable sockd
    systemctl restart sockd
    
    # Check if the service is running
    if systemctl is-active --quiet sockd; then
        display_success "${messages["installation_completed"]}"
        display_connection_info
    else
        display_error "${messages["service_start_failed"]}"
        log_message "Service start failed. Check logs: journalctl -u sockd"
    fi
}

# Function to uninstall the proxy server
uninstall_proxy() {
    log_message "Starting uninstallation process..."
    display_message "${messages["starting_uninstallation"]}"
    
    # Stop and disable Dante service
    systemctl stop sockd
    systemctl disable sockd
    
    # Remove Dante package and configuration
    apt-get remove -y dante-server libpam-pwdfile
    apt-get autoremove -y
    
    # Remove configuration files
    rm -rf /etc/dante
    rm -rf /etc/sockd
    rm -f /etc/pam.d/sockd
    rm -f /etc/systemd/system/sockd.service
    rm -f /usr/local/bin/proxy-users
    
    # Remove log files
    rm -rf /var/log/sockd
    
    # Reset firewall rules
    iptables -D INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || true
    
    display_success "${messages["uninstallation_completed"]}"
}

# Function to display connection information
display_connection_info() {
    IP_ADDRESS=$(get_public_ip)
    
    echo -e "\n${GREEN}"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║ ${messages["connection_info_header"]} ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ ${messages["proxy_type"]}: SOCKS5              ║"
    echo -e "║ ${messages["server_address"]}: $IP_ADDRESS"
    echo -e "║ ${messages["server_port"]}: $port              ║"
    echo -e "║ ${messages["auth_required"]}: ${messages["yes"]}            ║"
    echo -e "║ ${messages["username"]}: $username"
    echo -e "║ ${messages["password"]}: $password"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ ${messages["manage_users_header"]}:        ║"
    echo -e "║ ${messages["list_users"]}: sudo proxy-users list       ║"
    echo -e "║ ${messages["add_user"]}: sudo proxy-users add [user] [pass] ║"
    echo -e "║ ${messages["remove_user"]}: sudo proxy-users remove [user]  ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main function
main() {
    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root (or with sudo)"
        echo "Этот скрипт должен быть запущен от имени root (или с sudo)"
        exit 1
    fi
    
    # Check if the system is supported
    check_system
    
    # Select language
    select_language
    
    # Select action
    select_action
    
    if [ "$action" = "install" ]; then
        setup_port
        create_proxy_user
        install_proxy
    elif [ "$action" = "uninstall" ]; then
        uninstall_proxy
    fi
}

# Execute main function
main
