# SOCKS5 Proxy Server для VPS

Этот проект предоставляет скрипты для быстрой и простой установки SOCKS5 прокси-сервера с аутентификацией по логину и паролю на ваш VPS сервер с Ubuntu/Debian.

## Возможности

- Быстрая установка SOCKS5 прокси-сервера (Dante)
- Настройка аутентификации по логину и паролю
- Автоматическое определение сетевого интерфейса
- Настройка брандмауэра (поддержка UFW, FirewallD, iptables)
- Создание сервиса systemd для автозапуска
- Поддержка нескольких систем инициализации (systemd, SysV, OpenRC)
- Удобное управление пользователями
- Интерфейс на русском и английском языках

## Требования

- Ubuntu, Debian или другие Linux-системы на основе Debian
- Права root или доступ к sudo
- Подключение к интернету для загрузки пакетов

## Быстрая установка

Скопируйте и вставьте эту команду в терминал вашего VPS:

```bash
wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh && chmod +x setup_socks_proxy.sh && sudo ./setup_socks_proxy.sh
```

## Процесс установки

1. Скрипт запросит предпочитаемый язык интерфейса (русский или английский)
2. Выберите действие (установка или удаление прокси-сервера)
3. Укажите номер порта для прокси-сервера (по умолчанию 1080)
4. Введите имя пользователя и пароль для прокси-сервера
5. Скрипт автоматически:
   - Обновит систему
   - Установит необходимые пакеты
   - Настроит сервер Dante
   - Создаст и настроит пользователя
   - Настроит брандмауэр
   - Запустит и включит сервис

## Управление пользователями

После установки вы можете управлять пользователями с помощью скрипта `proxy-users`:

```bash
# Просмотр списка пользователей
sudo proxy-users list

# Добавление нового пользователя
sudo proxy-users add username password

# Удаление пользователя
sudo proxy-users remove username
```

## Подключение к прокси

После установки вы получите параметры для подключения:

- **Сервер**: IP-адрес вашего сервера
- **Порт**: указанный вами порт (по умолчанию 1080)
- **Тип прокси**: SOCKS5
- **Аутентификация**: Имя пользователя и пароль
- **Имя пользователя**: указанное вами имя пользователя
- **Пароль**: указанный вами пароль

## Удаление прокси-сервера

Чтобы удалить SOCKS5 прокси-сервер, выполните команду:

```bash
sudo ./setup_socks_proxy.sh
```

И выберите опцию "Удалить SOCKS5 прокси-сервер".

---

# SOCKS5 Proxy Server for VPS

This project provides scripts for fast and easy installation of a SOCKS5 proxy server with username/password authentication on your Ubuntu/Debian VPS.

## Features

- Quick installation of SOCKS5 proxy server (Dante)
- Username/password authentication setup
- Automatic network interface detection
- Firewall configuration (supports UFW, FirewallD, iptables)
- Systemd service creation for auto-start
- Support for multiple init systems (systemd, SysV, OpenRC)
- Convenient user management
- Interface in Russian and English languages

## Requirements

- Ubuntu, Debian, or other Debian-based Linux systems
- Root privileges or sudo access
- Internet connection to download packages

## Quick Installation

Copy and paste this command in your VPS terminal:

```bash
wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh && chmod +x setup_socks_proxy.sh && sudo ./setup_socks_proxy.sh
```

## Installation Process

1. The script will ask for your preferred interface language (Russian or English)
2. Select an action (install or remove proxy server)
3. Specify the port number for the proxy server (default is 1080)
4. Enter username and password for the proxy server
5. The script will automatically:
   - Update the system
   - Install required packages
   - Configure Dante server
   - Create and set up a user
   - Configure the firewall
   - Start and enable the service

## User Management

After installation, you can manage users with the `proxy-users` script:

```bash
# View user list
sudo proxy-users list

# Add a new user
sudo proxy-users add username password

# Remove a user
sudo proxy-users remove username
```

## Connecting to the Proxy

After installation, you'll receive connection parameters:

- **Server**: Your server's IP address
- **Port**: The port you specified (default is 1080)
- **Proxy type**: SOCKS5
- **Authentication**: Username and password
- **Username**: The username you specified
- **Password**: The password you specified

## Removing the Proxy Server

To remove the SOCKS5 proxy server, run:

```bash
sudo ./setup_socks_proxy.sh
```

And select the "Uninstall SOCKS5 proxy server" option.