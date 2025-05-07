# Безопасный SOCKS5 прокси-сервер с авторизацией

Этот проект предоставляет простой способ установки и настройки безопасного SOCKS5 прокси-сервера с авторизацией пользователя по логину и паролю на Ubuntu/Debian серверах.

## Особенности

- Установка SOCKS5 прокси-сервера с одной команды
- Поддержка авторизации по логину и паролю
- Интерактивная настройка на русском или английском языках
- Простое управление пользователями
- Автоматический запуск прокси-сервера при загрузке системы
- Настройка брандмауэра
- Пользователи не получают административный доступ к серверу

## Установка

Установка производится одной командой:

```bash
curl -s https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/socks5_proxy_installer.sh | sudo bash
```

Скрипт установки проведет вас через процесс настройки, задавая необходимые вопросы на выбранном вами языке (русский или английский).

## Управление пользователями

После установки вы можете управлять пользователями с помощью следующих команд:

```bash
# Добавить пользователя
sudo proxy-users add USERNAME PASSWORD

# Удалить пользователя
sudo proxy-users remove USERNAME

# Показать список пользователей
sudo proxy-users list
```

## Подключение к прокси

Для подключения к прокси используйте следующие параметры:

- **Хост**: IP-адрес вашего сервера
- **Порт**: 1080 (по умолчанию, может быть изменен при установке)
- **Тип прокси**: SOCKS5
- **Аутентификация**: Логин/Пароль (настроенные через команду proxy-users)

## Безопасность

- Сервис работает с авторизацией пользователя
- Пароли хранятся в зашифрованном виде
- Настроен брандмауэр, открывающий только необходимые порты
- Пользователи прокси не получают административный доступ к серверу

---

# Secure SOCKS5 Proxy Server with Authentication

This project provides an easy way to install and configure a secure SOCKS5 proxy server with username/password authentication on Ubuntu/Debian servers.

## Features

- One-command SOCKS5 proxy server installation
- Username/password authentication support
- Interactive setup in Russian or English
- Simple user management
- Automatic proxy server startup on system boot
- Firewall configuration
- Users don't get administrative access to the server

## Installation

Installation is done with a single command:

```bash
curl -s https://raw.githubusercontent.com/egoistsar/s5proxyserver/main/socks5_proxy_installer.sh | sudo bash
```

The installation script will guide you through the setup process, asking necessary questions in your chosen language (Russian or English).

## User Management

After installation, you can manage users with the following commands:

```bash
# Add a user
sudo proxy-users add USERNAME PASSWORD

# Remove a user
sudo proxy-users remove USERNAME

# List all users
sudo proxy-users list
```

## Connecting to the Proxy

To connect to your proxy, use the following parameters:

- **Host**: Your server IP address
- **Port**: 1080 (default, can be changed during installation)
- **Proxy Type**: SOCKS5
- **Authentication**: Username/Password (configured via proxy-users command)

## Security

- The service runs with user authentication
- Passwords are stored in encrypted form
- Firewall is configured to open only necessary ports
- Proxy users don't get administrative access to the server