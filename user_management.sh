#!/bin/bash

# User management functions for SOCKS5 Proxy Server
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver

# Function to add proxy user
add_proxy_user() {
    local username=$1
    local password=$2
    
    display_message "${messages["adding_proxy_user"]}"
    log_message "Adding proxy user: $username"
    
    # Create hashed password entry
    if command -v mkpasswd > /dev/null; then
        local salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)
        local hash=$(mkpasswd -m sha-512 "$password" "$salt")
        echo "$username:$hash" >> /etc/sockd/passwd
    else
        # Install whois package which provides mkpasswd
        apt-get install -y whois > /dev/null
        local salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)
        local hash=$(mkpasswd -m sha-512 "$password" "$salt")
        echo "$username:$hash" >> /etc/sockd/passwd
    fi
    
    chmod 600 /etc/sockd/passwd
}

# Function to install user management script
install_user_management_script() {
    display_message "${messages["installing_user_script"]}"
    log_message "Installing user management script"
    
    # Create proxy-users script
    cat > /usr/local/bin/proxy-users << 'EOF'
#!/bin/bash

# SOCKS5 Proxy User Management Script
# Author: GitHub - egoistsar
# Repository: https://github.com/egoistsar/s5proxyserver

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (or with sudo)${NC}" 
   exit 1
fi

# Password file path
PASSWD_FILE="/etc/sockd/passwd"

# Function to display usage
usage() {
    echo -e "${BLUE}SOCKS5 Proxy User Management${NC}"
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  list               - List all proxy users"
    echo "  add <user> <pass>  - Add a new proxy user"
    echo "  remove <user>      - Remove a proxy user"
    echo "  help               - Display this help message"
    echo ""
    exit 1
}

# Function to list users
list_users() {
    echo -e "${BLUE}SOCKS5 Proxy Users:${NC}"
    if [ -f "$PASSWD_FILE" ]; then
        users=$(cut -d: -f1 "$PASSWD_FILE")
        if [ -z "$users" ]; then
            echo "No users found."
        else
            for user in $users; do
                echo " - $user"
            done
        fi
    else
        echo "Password file not found. No users configured."
    fi
}

# Function to add user
add_user() {
    local username=$1
    local password=$2
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo -e "${RED}Error: Username and password required${NC}"
        usage
    fi
    
    # Check if user already exists
    if grep -q "^$username:" "$PASSWD_FILE" 2>/dev/null; then
        echo -e "${YELLOW}User '$username' already exists. Updating password...${NC}"
        remove_user "$username" > /dev/null
    fi
    
    # Create hashed password entry
    if ! command -v mkpasswd > /dev/null; then
        apt-get install -y whois > /dev/null
    fi
    
    local salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)
    local hash=$(mkpasswd -m sha-512 "$password" "$salt")
    echo "$username:$hash" >> "$PASSWD_FILE"
    chmod 600 "$PASSWD_FILE"
    
    echo -e "${GREEN}User '$username' added successfully.${NC}"
    
    # Restart sockd service
    systemctl restart sockd
}

# Function to remove user
remove_user() {
    local username=$1
    
    if [ -z "$username" ]; then
        echo -e "${RED}Error: Username required${NC}"
        usage
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$PASSWD_FILE" 2>/dev/null; then
        echo -e "${RED}User '$username' does not exist.${NC}"
        exit 1
    fi
    
    # Remove user from password file
    sed -i "/^$username:/d" "$PASSWD_FILE"
    echo -e "${GREEN}User '$username' removed successfully.${NC}"
    
    # Restart sockd service
    systemctl restart sockd
}

# Main logic
if [ $# -lt 1 ]; then
    usage
fi

case "$1" in
    list)
        list_users
        ;;
    add)
        add_user "$2" "$3"
        ;;
    remove)
        remove_user "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        ;;
esac

exit 0
EOF
    
    # Make the script executable
    chmod +x /usr/local/bin/proxy-users
}
