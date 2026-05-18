# 🛡️ VLESS-сервер с 3X-UI, xtls-rprx-vision и маскировкой через Nginx

<p align="center">
  <img src="https://img.shields.io/badge/VLESS-xtls--rprx--vision-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/3X--UI-Panel-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/Nginx-Reverse%20Proxy-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/Cloudflare-SSL-purple?style=for-the-badge">
</p>

## 📋 Оглавление

- [Описание проекта](#-описание-проекта)
- [Требования](#-требования)
- [Архитектура решения](#-архитектура-решения)
- [Пошаговая установка](#-пошаговая-установка)
- [Проверка работоспособности](#-проверка-работоспособности)
- [Безопасность](#-безопасность)
- [Управление сервером](#-управление-сервером)
- [Устранение неполадок](#-устранение-неполадок)

## 🎯 Описание проекта

Полноценное руководство по развертыванию защищенного прокси-сервера с:

- **VLESS** протоколом и технологией **xtls-rprx-vision** для высокой производительности
- **3X-UI** панелью управления для удобного администрирования
- **Nginx** маскировкой трафика под обычный веб-сайт
- **Cloudflare SSL** сертификатами для надежного шифрования

## 📌 Требования

| Компонент | Требование |
|-----------|------------|
| Сервер | Ubuntu 20.04 / 22.04 / 24.04 LTS |
| Домен | Привязан к Cloudflare |
| Доступ | Root права |


# 🔧 Установка VLESS-сервера с 3X-UI, xtls-rprx-vision и маскировкой через Nginx

---

## 📋 Содержание
- [Обновление системы](#обновление-системы)
- [Установка панели 3X-UI](#установка-панели-3x-ui)
- [Получение SSL-сертификата](#получение-ssl-сертификата)
- [Настройка входящего соединения](#настройка-входящего-соединения)
- [Установка и настройка Nginx](#установка-и-настройка-nginx)
- [Проверка работоспособности](#проверка-работоспособности)
- [Полезные команды](#полезные-команды)
- [Важные меры безопасности](#важные-меры-безопасности)

---

## Обновление системы

```bash
apt update && apt upgrade -y
```

---

## Установка панели 3X-UI

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

---

## Получение SSL-сертификата

Запустите меню панели:

```bash
x-ui
```

Выберите пункт 20 Cloudflare SSL Certificate

Параметры сертификата:

· Домен:
  один из вариантов
```bash
ironvault.ru
```
```bash
veilbox.ru
```
```bash
veilbox.online
```
· Тип: Cloudflare API
· Email: 
```bash
setnir@gmail.com
```
· API Токен:
```bash
9d2a6e687a4eee010fd48c598db9e9095f6dd
```

⚠️ ВАЖНО: Указанный API-токен приведен как пример. Обязательно используйте только свой личный API-токен Cloudflare!
Инструкция по созданию токена

---

## Настройка входящего соединения

В панели 3X-UI создайте новое входящее соединение с параметрами:

|Параметр   |Значение
|-----------|------------|
|Протокол   |VLESS       |
Порт | 443
Транспорт | TCP (RAW)
Безопасность  |TLS
ALPN | http/1.1
Flow | xtls-rprx-vision
Сертификат  |/root/cert/ironvault.ru/fullchain.pem
Ключ | /root/cert/ironvault.ru/privkey.pem
Fallbacks → Dest  |8080


```bash
#!/bin/bash
UUID=$(uuidgen)
echo "Используется UUID: $UUID"
sqlite3 /etc/x-ui/x-ui.db "DELETE FROM inbounds; DELETE FROM client_traffics;"
sqlite3 /etc/x-ui/x-ui.db <<EOF
INSERT INTO inbounds (user_id,up,down,total,remark,enable,expiry_time,listen,port,protocol,settings,stream_settings,tag,sniffing) 
VALUES (1,0,0,0,'🇳🇱',1,0,'',443,'vless',
'{"clients":[{"id":"$UUID","flow":"xtls-rprx-vision","email":"mobile","limitIp":0,"totalGB":0,"expiryTime":0,"enable":true,"tgId":0,"subId":"mobile","reset":0}],"decryption":"none","fallbacks":[{"dest":8080}]}',
'{"network":"tcp","security":"tls","tlsSettings":{"certificates":[{"certificateFile":"/root/cert/ironvault.ru/fullchain.pem","keyFile":"/root/cert/ironvault.ru/privkey.pem"}],"alpn":["http/1.1"]},"tcpSettings":{"header":{"type":"none"}}}',
'inbound-443',
'{"enabled":false,"destOverride":["http","tls"]}');
INSERT INTO client_traffics (inbound_id,enable,email,up,down,expiry_time,total,reset) 
VALUES (last_insert_rowid(),1,'mobile',0,0,0,0,0);
EOF
systemctl restart x-ui
echo "✅ ГОТОВО! UUID: $UUID"
echo "🔗 vless://$UUID@139.28.98.91:443?security=tls&type=tcp&flow=xtls-rprx-vision&alpn=http%2F1.1&sni=ironvault.ru#🇳🇱"
```

Остальные параметры оставьте по умолчанию и нажмите Создать.


---

5️⃣ Установка и настройка Nginx

Установка Nginx

```bash
sudo apt install nginx -y
```

Настройка маскировки

Скопируйте и выполните этот блок целиком, предварительно заменив переменные на свои:

```bash
# ⚡ ЗАМЕНИТЕ ЗНАЧЕНИЯ НА СВОИ ⚡
export domain=ironvault.ru                 # Ваш домен
export subscription_path=Ess5Ac26          # Случайный путь для подписок
export panel_path=0TQjECQj0TNRLcLPJY       # Случайный путь для панели
export subscription_port=38947              # Порт для подписок
export panel_port=35327                     # Порт для панели
```

Настройка Nginx:

```bash
cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name $domain;
    return 301 https://\$http_host\$request_uri;
}

server {
    listen 127.0.0.1:8080;
    server_name $domain;
    root /var/www/html/;
    index index.html;
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Прокси для подписок
    location /$subscription_path/ {
        proxy_pass https://127.0.0.1:$subscription_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_ssl_verify off;
        proxy_ssl_session_reuse off;
    }

    # Прокси для панели управления
    location /$panel_path/ {
        proxy_pass https://127.0.0.1:$panel_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_ssl_verify off;
        proxy_ssl_session_reuse off;
    }
}
EOF

# Переименовываем индексный файл
if [ -f /var/www/html/index.nginx-debian.html ]; then
    mv /var/www/html/index.nginx-debian.html /var/www/html/index.html
fi

# Перезапускаем Nginx
systemctl restart nginx
```

---

6️⃣ Проверка работоспособности

✅ Проверка работоспособности

Доступность сервисов

Сервис |URL
|-----|-----|
Сайт-заглушка |https://ironvault.ru/
Панель управления| https://ironvault.ru/0TQjECQj0TNRLcLPJY/
Ссылка на подписку| https://ironvault.ru/Ess5Ac26/|

Проверка портов

```bash
ss -tulpn | grep -E ':(443|8080|35327|38947)'
```

Ожидаемый результат:

· 0.0.0.0:443 — Xray (внешний)
· 127.0.0.1:8080 — Nginx (локальный)
· 127.0.0.1:35327 — 3X-UI (локальный)
· 127.0.0.1:38947 — Подписки (локальный)

🔒 Безопасность

1️⃣ Смена пароля панели

```bash
x-ui
# Выберите пункт смены пароля
```

2️⃣ Создание нового API-токена Cloudflare

1. Войдите в Cloudflare Dashboard
2. Перейдите в My Profile → API Tokens
3. Нажмите Create Token
4. Выберите шаблон Edit zone DNS
5. Настройте разрешения:
   · Zone:SSL:Edit
6. Укажите конкретный домен
7. Сохраните созданный токен

3️⃣ Защита конфигурации

· Регулярно меняйте SUBSCRIPTION_PATH и PANEL_PATH
· Убедитесь, что порты 35327 и 38947 доступны только локально
· Включите файрвол:

```bash
ufw allow 22/tcp
ufw allow 443/tcp
ufw enable
```

📚 Управление сервером

3X-UI команды

```bash
x-ui restart              # Перезапуск
x-ui status               # Статус
x-ui log                  # Логи Xray
x-ui update               # Обновление
```

Nginx команды

```bash
systemctl restart nginx   # Перезапуск
systemctl status nginx    # Статус
nginx -t                  # Проверка конфигурации
journalctl -u nginx -f    # Просмотр логов
```

🔧 Устранение неполадок

Проблема: Сертификат не получен

```bash
# Проверьте доступность API Cloudflare
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer ВАШ_ТОКЕН" \
     -H "Content-Type:application/json"
```

Проблема: Nginx не запускается

```bash
nginx -t  # Проверка конфигурации
systemctl status nginx  # Просмотр ошибок
```

Проблема: Xray не слушает порт 443

```bash
systemctl status x-ui
x-ui log
```

🎯 Результат

После выполнения всех шагов вы получите:

✅ Рабочий VLESS-сервер на порту 443
✅ Шифрование TLS с валидным SSL-сертификатом
✅ xtls-rprx-vision для максимальной производительности
✅ Маскировку под обычный веб-сайт
✅ Закрытую панель управления по секретному пути
✅ Автоматические подписки для клиентов

📌 Важные замечания

💡 Для большей анонимности установите на сайт полноценный HTML-шаблон

🔄 Регулярно обновляйте панель командой x-ui update

🔐 Храните API-токены и пароли в безопасном месте

📝 Лицензия

MIT License — используйте на свой страх и риск. Автор не несет ответственности за неправомерное использование.

---

<p align="center">
  <sub>⭐ Если этот гайд помог, поставьте звезду ⭐</sub>
</p>