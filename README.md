
🛡 Ubuntu Server Security Guide
Настройка базовой защиты VPS / сервера Ubuntu за несколько минут.
Что настраивается
🔑 SSH-доступ только по ключу
🚫 отключение парольного входа
🛑 защита от брутфорса (Fail2Ban)
🔥 firewall (UFW)
Подходит для:
VPS
Cloud серверов
домашнего Linux сервера
production окружений
📦 Быстрая установка (одной командой)
Можно настроить всё автоматически:
Bash
Копировать код
wget https://raw.githubusercontent.com/zordig/x-ray/main/secure-server.sh
chmod +x secure-server.sh
sudo ./secure-server.sh
⚙️ Ручная настройка
1️⃣ Настройка SSH (только ключ)
Изменить конфигурацию SSH:
Bash
Копировать код
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
Перезапустить SSH:
Bash
Копировать код
sudo systemctl restart ssh
Проверить настройки:
Bash
Копировать код
grep -E "PasswordAuthentication|PubkeyAuthentication|PermitRootLogin" /etc/ssh/sshd_config
Результат должен быть:
Копировать код

PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
2️⃣ Установка Fail2Ban
Bash
Копировать код
sudo apt update
sudo apt install fail2ban -y
Запуск и автозагрузка:
Bash
Копировать код
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
Проверка:
Bash
Копировать код
sudo systemctl status fail2ban
3️⃣ Проверка защиты SSH
Bash
Копировать код
sudo fail2ban-client status sshd
Пример:
Копировать код

Status for the jail: sshd
Currently banned: 3
Banned IP list: ...
Это означает, что боты уже блокируются автоматически.
4️⃣ Усиление Fail2Ban
Создать файл:
Bash
Копировать код
sudo nano /etc/fail2ban/jail.local
Добавить:
Копировать код

[sshd]
enabled = true
maxretry = 3
findtime = 10m
bantime = 24h
Перезапустить:
Bash
Копировать код
sudo systemctl restart fail2ban
5️⃣ Настройка Firewall
Разрешить SSH:
Bash
Копировать код
sudo ufw allow 22/tcp
Включить firewall:
Bash
Копировать код
sudo ufw enable
Проверить:
Bash
Копировать код
sudo ufw status
Результат:
Копировать код

Status: active
22/tcp ALLOW
🔐 Итог
После настройки сервер защищён:
Защита
Описание
SSH ключи
вход только по ключу
Password disabled
пароль отключён
Fail2Ban
блокирует брутфорс
UFW
фильтрация портов
📜 Скрипт автоматической настройки
Создай файл secure-server.sh
Bash
Копировать код
#!/bin/bash

echo "Updating system..."
apt update

echo "Installing Fail2Ban..."
apt install fail2ban -y

echo "Configuring SSH..."

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

systemctl restart ssh

echo "Configuring Fail2Ban..."

cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 3
findtime = 10m
bantime = 24h
EOF

systemctl restart fail2ban
systemctl enable fail2ban

echo "Configuring firewall..."

ufw allow 22/tcp
ufw --force enable

echo "Server security setup complete."
⭐ Результат
После запуска скрипта сервер получает:
защиту от SSH-брутфорса
firewall
безопасный SSH доступ
💡 Если хочешь, я ещё покажу 3 мощных улучшения безопасности, которые используют администраторы production серверов:
изменение SSH порта
защита от порт-сканеров
Cloudflare + Fail2Ban интеграция
Это поднимет безопасность твоего VPS в 5-10 раз.
