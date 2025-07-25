# SOCKS5 Proxy Server Setup Script

This repository contains scripts for automatic installation and configuration of a SOCKS5 proxy server using Dante Server on Debian and Ubuntu systems.

## Features

### 1. Simple Installation
- One-command proxy server installation
- Interactive mode with detailed instructions
- Bilingual interface (Russian and English)

### 2. Security
- Mandatory username/password authentication
- Secure SHA-512 password hashing
- Firewall configuration for server protection

### 3. Flexible Configuration
- Configurable proxy server port
- Convenient user management
- Ability to add and remove users after installation

### 4. Reliable Operation
- Automatic network interface detection
- Automatic Dante binaries detection
- System service creation with auto-start on boot

## Installation Guide

### Requirements
- Server with Debian (8+) or Ubuntu (16.04+) operating system
- Superuser (root) privileges
- Internet connection for package downloads

### Installation

To install the SOCKS5 proxy server, run the following command:

```bash
curl -s -L https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/install.sh | sudo bash
```

## Chrome Extension

To load the custom new tab extension in Chrome 139 or later:

1. Open `chrome://extensions/` in your browser.
2. Enable **Developer mode** using the toggle in the top-right corner.
3. Click **Load unpacked** and select the `chrome_extension` folder from this repository.
4. A new tab page with advice and a random wallpaper will now appear whenever you open a new tab.
