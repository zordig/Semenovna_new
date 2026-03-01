#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}СОЗДАНИЕ ПОДКЛЮЧЕНИЯ 3X-UI${NC}"
echo -e "${BLUE}================================${NC}"

# Проверка root прав
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт должен запускаться с root правами!${NC}"
   exit 1
fi

# Проверка наличия sqlite3
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${BLUE}Устанавливаем sqlite3...${NC}"
    apt update && apt install sqlite3 -y
fi

# Проверка наличия uuidgen
if ! command -v uuidgen &> /dev/null; then
    echo -e "${BLUE}Устанавливаем uuid-runtime...${NC}"
    apt install uuid-runtime -y
fi

# Проверка существования базы данных
if [ ! -f "/etc/x-ui/x-ui.db" ]; then
    echo -e "${RED}Файл базы данных не найден! Убедитесь, что 3x-ui установлен.${NC}"
    exit 1
fi

# Генерация UUID
UUID=$(uuidgen)
echo -e "${GREEN}Сгенерирован UUID:${NC} $UUID"

# Создание бэкапа
BACKUP_FILE="/etc/x-ui/x-ui.db.backup-$(date +%Y%m%d-%H%M%S)"
cp /etc/x-ui/x-ui.db $BACKUP_FILE
echo -e "${BLUE}Создан бэкап:${NC} $BACKUP_FILE"

# Очистка и создание подключения
echo -e "${BLUE}Создаем подключение...${NC}"
sqlite3 /etc/x-ui/x-ui.db "DELETE FROM inbounds; DELETE FROM client_traffics;"

sqlite3 /etc/x-ui/x-ui.db <<EOF
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) 
VALUES (1, 0, 0, 0, '🇳🇱', 1, 0, '', 443, 'vless', 
'{"clients":[{"id":"'$UUID'","flow":"xtls-rprx-vision","email":"mobile","limitIp":0,"totalGB":0,"expiryTime":0,"enable":true,"tgId":0,"subId":"mobile","reset":0}],"decryption":"none","fallbacks":[{"dest":8080}]}', 
'{"network":"tcp","security":"tls","tlsSettings":{"certificates":[{"certificateFile":"/root/cert/ironvault.ru/fullchain.pem","keyFile":"/root/cert/ironvault.ru/privkey.pem"}],"alpn":["http/1.1"]},"tcpSettings":{"header":{"type":"none"}}}', 
'inbound-443', 
'{"enabled":false,"destOverride":["http","tls"]}');

INSERT INTO client_traffics (inbound_id, enable, email, up, down, expiry_time, total, reset) 
VALUES (last_insert_rowid(), 1, 'mobile', 0, 0, 0, 0, 0);
EOF

# Проверка успешности создания
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Подключение успешно создано в базе данных!${NC}"
    
    # Перезапуск сервиса
    echo -e "${BLUE}Перезапускаем X-UI...${NC}"
    systemctl restart x-ui
    
    # Проверка статуса
    if systemctl is-active --quiet x-ui; then
        echo -e "${GREEN}✅ X-UI успешно перезапущен${NC}"
    else
        echo -e "${RED}❌ Ошибка при перезапуске X-UI${NC}"
    fi
    
    # Вывод информации
    echo -e "\n${GREEN}📊 ИНФОРМАЦИЯ О ПОДКЛЮЧЕНИИ:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "UUID: ${GREEN}$UUID${NC}"
    echo -e "Адрес: ${GREEN}139.28.98.91${NC}"
    echo -e "Порт: ${GREEN}443${NC}"
    echo -e "Протокол: ${GREEN}VLESS${NC}"
    echo -e "Транспорт: ${GREEN}TCP${NC}"
    echo -e "Безопасность: ${GREEN}TLS${NC}"
    echo -e "ALPN: ${GREEN}http/1.1${NC}"
    echo -e "Flow: ${GREEN}xtls-rprx-vision${NC}"
    echo -e "SNI: ${GREEN}ironvault.ru${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Строка подключения
    echo -e "\n${GREEN}🔗 СТРОКА ДЛЯ ПОДКЛЮЧЕНИЯ:${NC}"
    echo "vless://$UUID@139.28.98.91:443?security=tls&type=tcp&flow=xtls-rprx-vision&alpn=http%2F1.1&sni=ironvault.ru#🇳🇱"
    
    # Информация о панели
    echo -e "\n${GREEN}🌐 ДОСТУП К ПАНЕЛИ:${NC}"
    WEB_PORT=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webPort';")
    WEB_PATH=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM settings WHERE key='webBasePath';")
    echo "http://139.28.98.91:$WEB_PORT$WEB_PATH"
    
else
    echo -e "${RED}❌ Ошибка при создании подключения${NC}"
    echo -e "${BLUE}Восстанавливаем из бэкапа...${NC}"
    cp $BACKUP_FILE /etc/x-ui/x-ui.db
    systemctl restart x-ui
    exit 1
fi

echo -e "\n${GREEN}✅ ГОТОВО!${NC}"