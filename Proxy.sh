echo "Instalando nginx"
sudo apt install -y nginx

echo "Inicia el servicio Nginx"
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Borrando archivo por defecto y creando uno nuevo"
sudo rm -rf /etc/nginx/sites-enabled/default
sudo touch /etc/nginx/conf.d/load-balancing.conf


sudo cat <<EOF | sudo tee /etc/nginx/conf.d/load-balancing.conf
upstream nginx {
    server 192.168.3.100:3306;
    server 192.168.3.101:3306;
}

server {
    listen 3306;
    proxy_pass servidoresdb;
    proxy_connect_timeout 3s;
    proxy_timeout 10s;
    
}
EOF

sudo systemctl restart nginx

echo "Configuración completada"