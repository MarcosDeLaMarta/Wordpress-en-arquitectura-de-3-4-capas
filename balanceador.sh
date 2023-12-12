#!/bin/bash

echo "Instalando nginx"
sudo apt install -y nginx

echo "Inicia el servicio Nginx"
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Borrando archivo por defecto y creando uno nuevo"
sudo rm -rf /etc/nginx/sites-enabled/default
sudo touch /etc/nginx/conf.d/load-balancing.conf

# Añade la configuración upstream y del servidor al nuevo archivo
sudo cat <<EOF | sudo tee /etc/nginx/conf.d/load-balancing.conf
upstream nginx {
    server 192.168.1.100;
    server 192.168.1.101;
}

server {
    listen 80;
    server_name loadbalancing.example.com;

    location / {
        proxy_redirect off;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_pass http://nginx;
    }
}
EOF

# Reinicia Nginx para aplicar los cambios
sudo systemctl restart nginx

echo "Configuración completada"
