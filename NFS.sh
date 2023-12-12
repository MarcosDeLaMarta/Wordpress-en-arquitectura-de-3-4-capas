echo "Instalando el servidor NFS."
sudo apt install -y nfs-kernel-server
echo "Creando carpetas y asignando permisos."
sudo mkdir /var/nfs/general -p
ls -la /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general
echo "Creando archivo configuracion"
sudo touch /etc/exports

sudo echo "/var/nfs/cms     192.168.3.100(rw,sync,no_subtree_check) 192.168.3.101(rw,sync,no_subtree_check)">>/etc/exports

echo "reiniciando servicio"
sudo systemctl restart nfs-kernel-server

echo "Instalando php."
sudo apt install -y php-fpm
sudo apt install -y php-mysql

sudo sed -i 's|listen = /run/php/php7.3-fpm.sock|listen = 192.168.2.200:9000|' /etc/php/7.3/fpm/pool.d/www.conf

echo "Instalando wordpress."
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress/* /var/nfs/general

echo "Dando permisos"
sudo chown -R www-data:www-data /var/nfs/general
sudo chmod -R 755 /var/nfs/general
sudo cp wp-config-sample.php wp-config.php
echo "Cambiando la configuracion de config.php"
config_file="/var/nfs/general/wp-config.php"


sudo cp /var/nfs/general/wp-config-sample.php "$config_file"

declare -A replacements=(
    ["database_name_here"]="wp_db"
    ["username_here"]="wp_user"
    ["password_here"]="1234"
    ["localhost"]="192.168.3.201"
)

for key in "${!replacements[@]}"; do
    sudo sed -i "s/define( '$key', .* );/define( '$key', '${replacements[$key]}' );/" "$config_file"
done

sudo chown -R www-data:www-data /var/nfs/general/
sudo chmod -R 755 /var/nfs/cms

echo "Reinicio del servicio"
sudo systemctl restart php7.3-fpm