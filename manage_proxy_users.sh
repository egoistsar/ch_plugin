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
    echo "Usage: $0 [add|remove|list] [username] [password]"
    echo
    echo "Commands:"
    echo "  add USERNAME PASSWORD  - Add a new proxy user"
    echo "  remove USERNAME        - Remove an existing proxy user"
    echo "  list                   - List all proxy users"
    echo
    echo "Example:"
    echo "  $0 add myuser mypassword"
}

# List all proxy users
function list_users() {
    echo "Current proxy users:"
    echo "--------------------"
    if [ -s "$USER_DB" ]; then
        cat "$USER_DB" | cut -d: -f1
    else
        echo "No users found."
    fi
}

# Add a new proxy user
function add_user() {
    local username="$1"
    local password="$2"
    
    # Validate input
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "Error: Username and password are required" >&2
        show_usage
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^$username:" "$USER_DB" 2>/dev/null; then
        echo "User '$username' already exists. Remove it first or use a different username."
        return 1
    fi
    
    # Create password hash
    local hashed_password=$(mkpasswd -m sha-512 "$password")
    
    # Add user to the database
    echo "$username:$hashed_password" >> "$USER_DB"
    
    echo "User '$username' has been added successfully."
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    echo "Dante service restarted."
}

# Remove a proxy user
function remove_user() {
    local username="$1"
    
    # Validate input
    if [ -z "$username" ]; then
        echo "Error: Username is required" >&2
        show_usage
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$USER_DB" 2>/dev/null; then
        echo "User '$username' does not exist."
        return 1
    fi
    
    # Remove user from the database
    sed -i "/^$username:/d" "$USER_DB"
    
    echo "User '$username' has been removed successfully."
    
    # Restart the Dante service to apply changes
    systemctl restart dante-server.service
    echo "Dante service restarted."
}

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
