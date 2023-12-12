echo "Instalando Mariadb-server"
sudo apt install -y mariadb-server
 

echo "Configurando la base de datos."

galera_config="
[galera]
wsrep_on                 = 1
wsrep_cluster_name       = \"MariaDB_Cluster\"
wsrep_provider           = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_address    = gcomm://192.168.4.100,192.168.4.101
binlog_format            = row
default_storage_engine   = InnoDB
innodb_autoinc_lock_mode = 2

# Allow server to accept connections on all interfaces.
bind-address = 0.0.0.0
wsrep_node_address=192.168.4.100
"

# Detener el servicio MariaDB
sudo systemctl stop mariadb

# Guardar la configuración en el archivo galera.cnf
echo "$galera_config" | sudo tee /etc/mysql/conf.d/galera.cnf > /dev/null

# Iniciar el servicio MariaDB
sudo systemctl start mariadb
