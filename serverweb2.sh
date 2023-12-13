echo "Instalando nginx y php."
sudo apt install -y nginx
sudo apt install -y php-fpm
sudo apt install -y php-mysql
echo "Instalando cliente NFS"
sudo apt install -y nfs-common
echo "Creando carpetas y montando."
sudo mkdir -p /var/nfs/general
sudo mount 192.168.3.200:/var/nfs/general /var/nfs/general

#!/bin/bash

echo "Configurando WordPress"

nginx_config_dir="/etc/nginx/sites-available"

wordpress_config="wordpress"

wordpress_config_path="$nginx_config_dir/$wordpress_config"

wordpress_config_content=$(cat <<EOL
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/nfs/general;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass 192.168.3.200:9000;
        }
        location ~ /\.ht {
                deny all;
        }
}
EOL
)


echo "$wordpress_config_content" | sudo tee "$wordpress_config_path" > /dev/null

sudo rm -f /etc/nginx/sites-enabled/default

sudo ln -s "$wordpress_config_path" "/etc/nginx/sites-enabled/$wordpress_config"

sudo systemctl restart nginx
sudo apt-get install -y mariadb-client
echo "Configuración de WordPress completada"
