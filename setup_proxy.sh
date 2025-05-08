#!/bin/bash

# SOCKS5 Proxy Server Setup Script for Debian/Ubuntu

# Function to print colored text
function print_colored() {
    local color="$1"
    local text="$2"
    
    case "$color" in
        "red")
            echo -e "\033[0;31m$text\033[0m"
            ;;
        "green")
            echo -e "\033[0;32m$text\033[0m"
            ;;
        "yellow")
            echo -e "\033[1;33m$text\033[0m"
            ;;
        "blue")
            echo -e "\033[0;34m$text\033[0m"
            ;;
        *)
            echo "$text"
            ;;
    esac
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_colored "red" "✗ This script must be run as root"
    echo "Please run this script with root privileges. For example:"
    echo "  sudo bash $(basename "$0")"
    exit 1
fi

# Function to download and execute the installer
function download_and_execute() {
    local installer_url="https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/debian_ubuntu_socks5_installer.sh"
    local installer_script="/tmp/debian_ubuntu_socks5_installer.sh"
    
    # Download the installer script
    if command -v curl &> /dev/null; then
        print_colored "blue" ">> Downloading installer script using curl..."
        curl -s -o "$installer_script" "$installer_url"
    elif command -v wget &> /dev/null; then
        print_colored "blue" ">> Downloading installer script using wget..."
        wget -q -O "$installer_script" "$installer_url"
    else
        print_colored "red" "✗ Neither curl nor wget is installed"
        echo "Installing curl..."
        apt-get update && apt-get install -y curl
        
        print_colored "blue" ">> Downloading installer script using curl..."
        curl -s -o "$installer_script" "$installer_url"
    fi
    
    # Check if download was successful
    if [ ! -s "$installer_script" ]; then
        print_colored "red" "✗ Failed to download the installer script"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$installer_script"
    
    # Execute the installer script
    bash "$installer_script" "$@"
    
    # Cleanup
    rm -f "$installer_script"
}

# Main script
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
echo "SOCKS5 Proxy Server Interactive Installer for Debian/Ubuntu"
echo

# Pass all arguments to the installer script
download_and_execute "$@"