# Wordpress-en-arquitectura-de-3-4-capas
 

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
