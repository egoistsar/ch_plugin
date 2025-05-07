# SOCKS5 Proxy Server Installer

## About

This is a complete SOCKS5 proxy server solution for Ubuntu/Debian servers. The script installs and configures Dante SOCKS5 proxy server with username/password authentication, allows you to manage users, and sets up all necessary configurations with a single command.

## Features

- One-command installation via curl
- User-friendly interface in English and Russian
- Username/password authentication
- Automatic IP detection with multiple fallback methods
- Secure password storage
- Automatic firewall configuration
- System service setup for automatic start on boot
- User management tool

## Installation

To install the SOCKS5 proxy server, download and run the script manually:

```bash
# Download the script
wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh

# Make it executable
chmod +x setup_socks_proxy.sh

# Run the script with root privileges
sudo ./setup_socks_proxy.sh
```

> **Important**: The script requires interactive input and must be run directly from your terminal, not through a pipe (curl | bash).

## User Management

After installation, you can manage users with the `proxy-users` command:

```bash
# Add a new user
sudo proxy-users add USERNAME PASSWORD

# Remove a user
sudo proxy-users remove USERNAME

# List all users
sudo proxy-users list
```

## Connection Details

After installation, you can connect to your SOCKS5 proxy using:

- **Protocol**: SOCKS5
- **Server**: Your server's IP address
- **Port**: 1080 (default, can be customized during installation)
- **Authentication**: Username/password as configured

## Uninstallation

To uninstall the SOCKS5 proxy server, run:

```bash
curl -s -L https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh | sudo bash
```

And select the "Uninstall" option when prompted.

## Requirements

- Ubuntu or Debian server
- Root access
- Internet connection for downloading packages

---

# Установщик SOCKS5 прокси-сервера

## О проекте

Это полное решение SOCKS5 прокси-сервера для серверов Ubuntu/Debian. Скрипт устанавливает и настраивает Dante SOCKS5 прокси-сервер с аутентификацией по имени пользователя/паролю, позволяет управлять пользователями и выполняет все необходимые настройки одной командой.

## Возможности

- Установка одной командой через curl
- Удобный интерфейс на английском и русском языках
- Аутентификация по имени пользователя/паролю
- Автоматическое определение IP с несколькими методами резервного копирования
- Безопасное хранение паролей
- Автоматическая настройка брандмауэра
- Настройка системного сервиса для автоматического запуска при загрузке
- Инструмент управления пользователями

## Установка

Для установки SOCKS5 прокси-сервера выполните следующую команду на вашем сервере Ubuntu/Debian:

```bash
curl -s -L https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh | sudo bash
```

Или загрузите и запустите вручную:

```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh

# Сделать его исполняемым
chmod +x setup_socks_proxy.sh

# Запустить скрипт с правами root
sudo ./setup_socks_proxy.sh
```

## Управление пользователями

После установки вы можете управлять пользователями с помощью команды `proxy-users`:

```bash
# Добавить нового пользователя
sudo proxy-users add ИМЯ_ПОЛЬЗОВАТЕЛЯ ПАРОЛЬ

# Удалить пользователя
sudo proxy-users remove ИМЯ_ПОЛЬЗОВАТЕЛЯ

# Показать всех пользователей
sudo proxy-users list
```

## Детали подключения

После установки вы можете подключиться к вашему SOCKS5 прокси, используя:

- **Протокол**: SOCKS5
- **Сервер**: IP-адрес вашего сервера
- **Порт**: 1080 (по умолчанию, можно настроить во время установки)
- **Аутентификация**: Имя пользователя/пароль, как настроено

## Удаление

Для удаления SOCKS5 прокси-сервера загрузите и запустите скрипт:

```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/setup_socks_proxy.sh

# Сделать его исполняемым
chmod +x setup_socks_proxy.sh

# Запустить скрипт с правами root
sudo ./setup_socks_proxy.sh
```

И выберите опцию "Удалить" при появлении запроса.

> **Важно**: Скрипт требует интерактивного ввода и должен запускаться непосредственно из вашего терминала, а не через конвейер (curl | bash).

## Требования

- Сервер Ubuntu или Debian
- Доступ root
- Интернет-соединение для загрузки пакетов