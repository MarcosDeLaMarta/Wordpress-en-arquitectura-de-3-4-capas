#!/bin/bash

# Instalación de MariaDB
echo "Instalando MariaDB-server"
sudo apt update
sudo apt install -y mariadb-server

# Verifica la instalación de MariaDB
if [ $? -ne 0 ]; then
    echo "Error durante la instalación de MariaDB. Verifica el sistema y vuelve a intentarlo."
    exit 1
fi

# Configuración de la base de datos
echo "Configurando la base de datos."
# Archivo de configuración
config_file="/etc/mysql/mariadb.conf.d/50-server.cnf"

# Nueva configuración
new_config="bind_address = 0.0.0.0"

# Verifica si el archivo existe
if [ -e "$config_file" ]; then
    # Realiza una copia de seguridad del archivo original
    cp "$config_file" "$config_file.bak"
    
    # Reemplaza o añade la nueva configuración
    if grep -q "bind_address" "$config_file"; then
        sed -i "s/bind_address.*/$new_config/" "$config_file"
    else
        echo "$new_config" >> "$config_file"
    fi

    echo "Configuración automatizada exitosamente."
else
    echo "El archivo de configuración no existe: $config_file"
fi
sudo systemctl restart mariadb

# Creación de la base de datos y usuario
echo "Creando la base de datos."
sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS wp_db;"
sudo mysql -u root -e "CREATE USER IF NOT EXISTS 'wp_user'@'192.168.3.%' IDENTIFIED BY '1234';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'192.168.3.%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
