#!/bin/bash

# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}

echo "Instalando el servidor NFS."
sudo apt install -y nfs-kernel-server
check_success

echo "Creando carpetas y asignando permisos."
sudo mkdir -p /var/nfs/general
ls -la /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general
check_success

echo "Creando archivo de configuración."
sudo touch /etc/exports
sudo echo "/var/nfs/general 192.168.3.100(rw,sync,no_subtree_check) 192.168.3.101(rw,sync,no_subtree_check)" >> /etc/exports
check_success

echo "Reiniciando servicio NFS."
sudo systemctl restart nfs-kernel-server
check_success

echo "Instalando PHP."
sudo apt install -y php-fpm php-mysql
check_success

echo "Configurando PHP-FPM."
sudo sed -i 's|listen = /run/php/php7.3-fpm.sock|listen = 192.168.3.200:9000|' /etc/php/7.3/fpm/pool.d/www.conf
check_success

echo "Instalando WordPress."
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress/* /var/nfs/general
check_success

echo "Dando permisos."
sudo chown -R www-data:www-data /var/nfs/general
sudo chmod -R 755 /var/nfs/general
check_success

echo "Cambiando la configuración de wp-config.php"
config_file="/var/nfs/general/wp-config.php"

sudo cp /var/nfs/general/wp-config-sample.php /var/nfs/general/wp-config.php

declare -A replacements=(
    ["database_name_here"]="wp_db"
    ["username_here"]="wp_user"
    ["password_here"]="1234"
    ["localhost"]="192.168.3.150"
)

for key in "${!replacements[@]}"; do
    sudo sed -i "s/define( '$key', .* );/define( '$key', '${replacements[$key]}' );/" "$config_file"
done

sudo chown -R www-data:www-data /var/nfs/general/
sudo chmod -R 755 /var/nfs/general

echo "Reinicio del servicio PHP-FPM."
sudo systemctl restart php7.3-fpm
check_success

echo "Configuración completada con éxito."
