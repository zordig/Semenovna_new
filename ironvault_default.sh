export domain=ironvault.ru
export subscription_path=Ess5Ac26
export panel_path=0TQjECQj0TNRLcLPJY
export subscription_port=38947
export panel_port=35327

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

    # Прокси для подписок на порт $subscription_port (HTTPS!)
    location /$subscription_path/ {
        proxy_pass https://127.0.0.1:$subscription_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # Важно: отключаем проверку SSL для локального подключения
        proxy_ssl_verify off;
        proxy_ssl_session_reuse off;
    }

    # Прокси для ПАНЕЛИ (порт $panel_port) с путём /$panel_path/
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

# Переименовываем индексный файл если он существует
if [ -f /var/www/html/index.nginx-debian.html ]; then
    mv /var/www/html/index.nginx-debian.html /var/www/html/index.html
fi

# Перезапускаем nginx
systemctl restart nginx