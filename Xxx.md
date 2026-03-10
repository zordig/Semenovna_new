
Данная инструкция описывает процесс установки панели управления Xray (3x-ui) за реверс-прокси Nginx с использованием сертификатов Cloudflare для максимальной безопасности и скрытия серверного IP.

## 📋 Предварительные требования
* Сервер с ОС Ubuntu 20.04/22.04/24.04.
* Домен, добавленный в Cloudflare.
* Запись типа `A`, указывающая на IP вашего сервера (статус: **Proxied** 🧡).

---

## 1. Подготовка системы
Обновите пакеты и установите необходимые утилиты:
```bash
apt update && apt upgrade -y
apt install curl socat git wget nginx -y

2. Установка панели 3x-ui
Выполните скрипт установки:
bash <(curl -Ls [https://raw.githubusercontent.com/mprospector/3x-ui/main/install.sh](https://raw.githubusercontent.com/mprospector/3x-ui/main/install.sh))

> Во время установки укажите порт (например, 2053), логин и пароль.
> 
3. Настройка сертификатов Cloudflare
 * В панели Cloudflare: SSL/TLS -> Origin Server -> Create Certificate.
 * Выберите тип RSA (2048) и срок 15 лет. Нажмите Create.
 * Создайте директорию на сервере:
   mkdir -p /etc/3x-ui/certs

 * Создайте файл сертификата и вставьте туда код из окна Origin Certificate:
   nano /etc/3x-ui/certs/fullchain.pem

 * Создайте файл ключа и вставьте код из окна Private Key:
   nano /etc/3x-ui/certs/private.key

4. Настройка Nginx
Удалите стандартный конфиг и создайте новый:
rm /etc/nginx/sites-enabled/default
nano /etc/nginx/sites-available/3x-ui

Вставьте следующий конфиг (замените yourdomain.com на ваш домен):
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/3x-ui/certs/fullchain.pem;
    ssl_certificate_key /etc/3x-ui/certs/private.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+CHACHA20:EECDH+AESGCM:EDH+AESGCM;

    location / {
        proxy_pass [http://127.0.0.1:2053](http://127.0.0.1:2053); # Порт панели 3x-ui
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Поддержка WebSocket для работы панели и соединений
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

Активируйте конфигурацию:
ln -s /etc/nginx/sites-available/3x-ui /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

5. Настройка Cloudflare (Важно!)
В панели управления Cloudflare:
 * SSL/TLS -> Overview: установите режим Full (Strict).
 * DNS: убедитесь, что включено "оранжевое облако" (Proxy status: Proxied).
6. Безопасность и Web Base Path
Для защиты от сканеров:
 * Зайдите в панель через браузер: https://yourdomain.com.
 * Перейдите в Panel Settings.
 * Установите Web Base Path (например, /secret-path/).
 * Нажмите Save и Restart Panel.
 * Теперь панель доступна только по адресу: https://yourdomain.com/secret-path/.
Полезные команды
 * x-ui — меню управления панелью через терминал.
 * systemctl restart nginx — перезапуск веб-сервера.
 * journalctl -u x-ui -f — просмотр логов панели.
