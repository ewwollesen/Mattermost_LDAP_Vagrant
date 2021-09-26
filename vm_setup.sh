#!/bin/bash

# Read in secrets and variables from file
source /vagrant/.secrets

echo "Installing docker, wget, epel-release, jq, openldap-clients, nginx..."
yum -y install epel-release
yum -y install docker wget jq openldap-clients nginx

echo "Starting Docker..."
systemctl start docker

echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Starting containers..."
/usr/local/bin/docker-compose -f /vagrant/docker-compose.yml up -d

echo "Configuring nginx proxy..."
setenforce 0 #selinux sucks
cp /vagrant/mattermost.nginx.conf /etc/nginx/conf.d/mattermost
ln -s /etc/nginx/conf.d/mattermost /etc/nginx/conf.d/default.conf
systemctl restart nginx

echo "Downloading Mattermost version $MATTERMOST_VERSION..."
wget -q https://releases.mattermost.com/$MATTERMOST_VERSION/mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz

echo "Installing Mattermost..."
tar -xzf mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz
mv mattermost /opt
mkdir /opt/mattermost/data

echo "Creating Mattermost config file and copying license file..."
mv /opt/mattermost/config/config.json /opt/mattermost/config/config.json.bak
DATA_SOURCE="$MYSQL_USER:$MYSQL_PASSWORD@tcp(127.0.0.1:3306)/$MYSQL_DATABASE?charset=utf8mb4,utf8&writeTimeout=30s"
jq '.SqlSettings.DataSource |= "'"$DATA_SOURCE"'"' /vagrant/config.json > /opt/mattermost/config/config.json
cp /vagrant/mattermost.license /opt/mattermost/config/mattermost.license

echo "Create Mattermost sytem user and setting permissions..."
useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

echo "Installing Mattermost systemd file..."
cp /vagrant/mattermost.service /etc/systemd/system/mattermost.service
chmod 644 /etc/systemd/system/mattermost.service
systemctl daemon-reload

echo "Creating Mattermost admin user and team..."
# Should migrate to mmctl soon
/opt/mattermost/bin/mattermost user create --email admin@planetexpress.com --username $MM_ADMIN --password $MM_ADMIN_PASSWORD --system_admin
/opt/mattermost/bin/mattermost team create --name planet-express --display_name "Planet Express" --email "admin@planetexpress.com"
/opt/mattermost/bin/mattermost team add planet-express admin@planetexpress.com

echo "Starting Mattermost..."
systemctl start mattermost.service

echo "Cleaning Up Files..."
rm -f /vagrant/.secrets
rm -f mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz