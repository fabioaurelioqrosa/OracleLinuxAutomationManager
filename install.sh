# On the PostgreSQL machine:
# sudo su - postgres -c "createuser -S -P awx"
# sudo su - postgres -c "createdb -O awx awx"

#sudo useradd awx
#AWX_PASSWORD=Senha#01
#sudo passwd awx > /dev/null << EOF
#$AWX_PASSWORD
#$AWX_PASSWORD
#EOF
#sudo usermod -aG wheel awx

echo "Database Host: "
read DATABASE_HOST

echo "Database Port: "
read DATABASE_PORT

echo "Database User: "
read DATABASE_USER

echo "Database Password: "
read DATABASE_PASSWORD

echo "Admin e-mail: "
read ADMIN_EMAIL



## Set firewall rules
sudo firewall-cmd --add-port=27199/tcp --permanent   # Port 27199 provides a TCP listener port for the Oracle Linux Automation Manager service mesh and must be open on each node in the mesh.
sudo firewall-cmd --add-service=http --permanent     # Nginx server
sudo firewall-cmd --add-service=https --permanent    # Nginx server
sudo firewall-cmd --reload

## Enable repositories with the Oracle Linux Yum Server
sudo dnf config-manager --enable ol8_baseos_latest

## Install Oracle Linux Automation Manager - Release 8
sudo dnf install -y oraclelinux-automation-manager-release-el8

## Enable the following yum repositories including the Oracle Linux Automation Manager release 2 repository:
 # ol8_automation2
 # ol8_addons
 # ol8_UEKR6 or ol8_UEKR7
 # ol8_appstream
#sudo dnf config-manager --enable ol8_automation2 ol8_addons ol8_UEKR6 ol8_appstream
sudo dnf config-manager --enable ol8_automation2 ol8_addons ol8_UEKR7 ol8_appstream

## Disable the Oracle Linux Automation Manager release 1 repository
sudo dnf config-manager --disable ol8_automation

## Install Oracle Linux Automation Manager
sudo dnf install -y ol-automation-manager

## Add the following lines to "/etc/redis.conf"
sudo sh -c 'echo "unixsocket /var/run/redis/redis.sock" >> /etc/redis.conf'
sudo sh -c 'echo "unixsocketperm 775" >> /etc/redis.conf'


## Edit the /etc/tower/settings.py file and configure the CLUSTER_HOST_ID field:
sudo sed -i "s/CLUSTER_HOST_ID = \"awx\"/CLUSTER_HOST_ID = \"$HOSTNAME\"/" "/etc/tower/settings.py"
sudo sed -i "s/'USER': os.getenv(\"DATABASE_USER\", None),/'USER': '$DATABASE_USER',/" "/etc/tower/settings.py"
sudo sed -i "s/'PASSWORD': os.getenv(\"DATABASE_PASSWORD\", None),/'PASSWORD': '$DATABASE_PASSWORD',/" "/etc/tower/settings.py"
sudo sed -i "s/'HOST': os.getenv(\"DATABASE_HOST\", None),/'HOST': '$DATABASE_HOST',/" "/etc/tower/settings.py"
sudo sed -i "s/'PORT': os.getenv(\"DATABASE_PORT\", None),/'PORT': $DATABASE_PORT,/" "/etc/tower/settings.py"

## On all hosts, generate SSL certificates for NGINX:
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/tower/tower.key -out /etc/tower/tower.crt > /dev/null << EOF
BR
SP



$HOSTNAME

EOF

## Remove any default configuration for NGINX.
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo sh -c "sed -n '1,36p' /etc/nginx/nginx.conf.bak > /etc/nginx/nginx.conf"
sudo sh -c 'echo "}" >> /etc/nginx/nginx.conf' 


podman system migrate
podman pull container-registry.oracle.com/oracle_linux_automation_manager/olam-ee:latest

awx-manage migrate
awx-manage createsuperuser --username admin --email $ADMIN_EMAIL > /dev/null << EOF
admin
admin
EOF

awx-manage provision_instance --hostname=$HOSTNAME --node_type=hybrid
awx-manage register_default_execution_environments
awx-manage register_queue --queuename=default --hostnames=$HOSTNAME
awx-manage register_queue --queuename=controlplane --hostnames=$HOSTNAME

#exit

## Configure the Receptor
sudo sed -i "s/id\:\ 0\.0\.0\.0/id\:\ $HOSTNAME/" "/etc/receptor/receptor.conf"

## Start the service
sudo systemctl enable --now ol-automation-manager.service


## OPTIONAL
## Run the following command to preload data, such as:
# Demo Project
# Default Galaxy Credentials
# Demo Organization
# Demo Inventory
# Demo Job template
# And so on
#sudo su -l awx -s /bin/bash
#awx-manage create_preload_data
#exit
