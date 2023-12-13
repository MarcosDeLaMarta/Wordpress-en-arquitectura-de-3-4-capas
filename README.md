# Wordpress-en-arquitectura-de-3-4-capas
 
## Índice
1. [Introducción](#introducción)
2. [Vagrantfile y Configuraciones](#vagrantfile-y-configuraciones)
    1. [Balanceador NGINX](#balanceador-nginx)
    2. [Servidor NFS](#servidor-nfs)
    3. [Servidor web 1](#servidor-web-1)
    4. [Servidor web 2](#servidor-web-2)
    5. [Servidor de Base de datos](#servidor-de-base-de-datos)
3. [Acceder al servidor](#acceder-al-servidor)
4. [Screencash](#Screencash)


<br/>
<br/>

# Introducción.

En esta practica se va a desplegar un CMS Wordpress en una infraestructura en alta disponibilidad de 4 capas basada en una pila LEMP.

Para ello en elegido la sigueinte infrestructura:

* RED 1 : 192.168.2.0
    * Balanceador Web: 192.168.2.10
    * Servidor web 1: 192.168.2.100
    * Servidor web 2: 192.168.2.101
<br/>
<br/>

* RED 2 : 192.168.3.0
    * Servidor NFS: 192.168.3.200
    * Servidor web 1: 192.168.3.100
    * Servidor web 2: 192.168.3.101
    * Servidor de datos: 192.168.3.150
<br/>
<br/>

# Vagrantfile.

```
Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  # BALANCEADOR
  config.vm.define "balanceadorMarcos" do |app|
    app.vm.hostname = "balanceadorMarcos"
    app.vm.network "private_network", ip: "192.168.2.10"
    app.vm.network "forwarded_port", guest: 80, host:9000
    app.vm.provision "shell", path: "balanceador.sh"
  end

  #serverNFS
  config.vm.define "serverNFSMarcos" do |app|
    app.vm.hostname = "serverNFSMarcos"
    app.vm.network "private_network", ip: "192.168.3.200"
    app.vm.provision "shell", path: "NFS.sh"
  end

  #serverweb1
  config.vm.define "serverweb1Marcos" do |app|
    app.vm.hostname = "serverweb1Marcos"
    app.vm.network "private_network", ip: "192.168.2.100"
    app.vm.network "private_network", ip: "192.168.3.100"
    app.vm.provision "shell", path: "serverweb1.sh"
  end

  #serverweb2
  config.vm.define "serverweb2Marcos" do |app|
    app.vm.hostname = "serverweb2Marcos"
    app.vm.network "private_network", ip: "192.168.2.101"
    app.vm.network "private_network", ip: "192.168.3.101"
    app.vm.provision "shell", path: "serverweb2.sh"
  end

  # Serverdatos1
  config.vm.define "ServerdatosMarcos" do |app|
    app.vm.hostname = "ServerdatosMarcos"
    app.vm.network "private_network", ip: "192.168.3.150"
    app.vm.provision "shell", path: "BBDD2.sh"
  end

  config.ssh.insert_key = false
  config.ssh.forward_agent = false

end

```

# Configuraciones.

<br/>
<br/>

## Balanceador NGINX.

```
# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}
# Instala Nginx y verifica el éxito de la operación
echo "Instalando Nginx."
sudo apt install -y nginx
check_success

# Inicia y habilita el servicio Nginx, luego verifica el éxito de las operaciones
echo "Iniciando el servicio Nginx."
sudo systemctl start nginx
sudo systemctl enable nginx
check_success

# Elimina el archivo de configuración predeterminado de Nginx y crea uno nuevo
echo "Borrando el archivo por defecto y creando uno nuevo."
sudo rm -rf /etc/nginx/sites-enabled/default
sudo touch /etc/nginx/conf.d/load-balancing.conf

# Añade la configuración upstream y del servidor al nuevo archivo.
sudo cat <<EOF | sudo tee /etc/nginx/conf.d/load-balancing.conf
upstream nginx {
    server 192.168.2.100;
    server 192.168.2.101;
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

# Reinicia Nginx para aplicar los cambios y verifica el éxito de la operación
sudo systemctl restart nginx
check_success

# Muestra un mensaje indicando que la configuración de balanceo de carga se ha completado con éxito.
echo "Configuración de load balancing completada con éxito."

```

<br/>
<br/>

## Servidor NFS.

```
#!/bin/bash

# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}

# Instala el servidor NFS y verifica el éxito de la operación
echo "Instalando el servidor NFS."
sudo apt install -y nfs-kernel-server
check_success

# Crea carpetas y asigna permisos, luego verifica el éxito de las operaciones
echo "Creando carpetas y asignando permisos."
sudo mkdir -p /var/nfs/general
ls -la /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general
check_success

# Crea el archivo de configuración y añade las exportaciones NFS, luego verifica el éxito
echo "Creando archivo de configuración."
sudo touch /etc/exports
sudo echo "/var/nfs/general 192.168.3.100(rw,sync,no_subtree_check) 192.168.3.101(rw,sync,no_subtree_check)" >> /etc/exports
check_success

# Reinicia el servicio NFS y verifica el éxito de la operación
echo "Reiniciando servicio NFS."
sudo systemctl restart nfs-kernel-server
check_success

# Instala PHP y verifica el éxito de la operación
echo "Instalando PHP."
sudo apt install -y php-fpm php-mysql
check_success

# Configura PHP-FPM y verifica el éxito de la operación
echo "Configurando PHP-FPM."
sudo sed -i 's|listen = /run/php/php7.3-fpm.sock|listen = 192.168.3.200:9000|' /etc/php/7.3/fpm/pool.d/www.conf
check_success

# Instala WordPress, da permisos y verifica el éxito de las operaciones
echo "Instalando WordPress."
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress/* /var/nfs/general
check_success

echo "Dando permisos."
sudo chown -R www-data:www-data /var/nfs/general
sudo chmod -R 755 /var/nfs/general
check_success

# Cambia la configuración de wp-config.php y verifica el éxito de las operaciones
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
check_success

# Reinicia el servicio PHP-FPM y verifica el éxito de la operación
echo "Reinicio del servicio PHP-FPM."
sudo systemctl restart php7.3-fpm
check_success

# Muestra un mensaje indicando que la configuración se ha completado con éxito
echo "Configuración completada con éxito."
```

<br/>
<br/>


## Servidor web 1.

```
#!/bin/bash

# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}

# Instala nginx, php y el cliente NFS
echo "Instalando nginx y php."
sudo apt install -y nginx
sudo apt install -y php-fpm
sudo apt install -y php-mysql
echo "Instalando cliente NFS"
sudo apt install -y nfs-common

# Crea carpetas y monta la carpeta NFS
echo "Creando carpetas y montando."
sudo mkdir -p /var/nfs/general
sudo mount 192.168.3.200:/var/nfs/general /var/nfs/general
check_success

# Configura WordPress
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

# Escribe la configuración de WordPress en el archivo correspondiente
echo "$wordpress_config_content" | sudo tee "$wordpress_config_path" > /dev/null

# Elimina el archivo de configuración por defecto y crea un enlace simbólico
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s "$wordpress_config_path" "/etc/nginx/sites-enabled/$wordpress_config"

# Reinicia el servicio nginx y verifica el éxito de la operación
sudo systemctl restart nginx
check_success

# Instala el cliente MariaDB
sudo apt-get install -y mariadb-client 

# Muestra un mensaje indicando que la configuración de WordPress se ha completado
echo "Configuración de WordPress completada"

```
<br/>
<br/>

## Servidor web 2.

```
#!/bin/bash

# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}

# Instala nginx, php y el cliente NFS
echo "Instalando nginx y php."
sudo apt install -y nginx
sudo apt install -y php-fpm
sudo apt install -y php-mysql
echo "Instalando cliente NFS"
sudo apt install -y nfs-common

# Crea carpetas y monta la carpeta NFS
echo "Creando carpetas y montando."
sudo mkdir -p /var/nfs/general
sudo mount 192.168.3.200:/var/nfs/general /var/nfs/general
check_success

# Configura WordPress
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

# Escribe la configuración de WordPress en el archivo correspondiente
echo "$wordpress_config_content" | sudo tee "$wordpress_config_path" > /dev/null

# Elimina el archivo de configuración por defecto y crea un enlace simbólico
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s "$wordpress_config_path" "/etc/nginx/sites-enabled/$wordpress_config"

# Reinicia el servicio nginx y verifica el éxito de la operación
sudo systemctl restart nginx
check_success

# Instala el cliente MariaDB
sudo apt-get install -y mariadb-client 

# Muestra un mensaje indicando que la configuración de WordPress se ha completado
echo "Configuración de WordPress completada"

```
<br/>
<br/>

## Servidor de Base de datos

```
#!/bin/bash

# Función para verificar el éxito de la última ejecución
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: La última operación ha fallado. Verifica el script y vuelve a intentarlo."
        exit 1
    fi
}

# Instalación de MariaDB-server
echo "Instalando MariaDB-server"
sudo apt update
sudo apt install -y mariadb-server
check_success

# Configuración de la base de datos
echo "Configurando la base de datos."
# Archivo de configuración
config_file="/etc/mysql/mariadb.conf.d/50-server.cnf"

# Nueva configuración
new_config="bind-address = 0.0.0.0"

# Cambia la dirección de enlace a 0.0.0.0
sudo sed -i 's/^bind-address.*$/bind-address = 0.0.0.0/' "$config_file"
check_success

# Verifica si el archivo existe
if [ -e "$config_file" ]; then
    # Realiza una copia de seguridad del archivo original
    cp "$config_file" "$config_file.bak"
    
    # Reemplaza o añade la nueva configuración
    if grep -q "bind_address" "$config_file"; then
        sudo sed -i "s/bind_address.*/$new_config/" "$config_file"
    else
        sudo echo "$new_config" >> "$config_file"
    fi

    echo "Configuración automatizada exitosamente."
else
    echo "El archivo de configuración no existe: $config_file"
fi
sudo systemctl restart mariadb
check_success

# Creación de la base de datos y usuario
echo "Creando la base de datos."
sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS wp_db;"
sudo mysql -u root -e "CREATE USER IF NOT EXISTS 'wp_user'@'192.168.3.%' IDENTIFIED BY '1234';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON wp_db.* TO 'wp_user'@'192.168.3.%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
check_success

echo "Configuración de MariaDB completada con éxito."

```
# Acceder al servidor
Por Ultimo para acedder a nuestro servidor debemos porner:

```
http://localhost:9000/
```

# Screencash

https://youtu.be/zjZEFKBkmck
