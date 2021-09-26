#!/bin/bash

# Read in secrets from file
source /vagrant/.secrets

# echo "Update host"
# yum -y update

echo "Install docker, wget, epel-release, jq, openldap-clients"
yum -y install epel-release
yum -y install docker wget jq openldap-clients

echo "Starting Docker"
systemctl start docker

echo "Install and set up Docker Compose"
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Run docker-compose"
/usr/local/bin/docker-compose -f /vagrant/docker-compose.yml up -d

echo "Download Mattermost version $MATTERMOST_VERSION"
wget -q https://releases.mattermost.com/$MATTERMOST_VERSION/mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz

echo "Install Mattermost"
tar -xzf mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz
mv mattermost /opt
mkdir /opt/mattermost/data

echo "Create Mattermost config file"
mv /opt/mattermost/config/config.json /opt/mattermost/config/config.json.bak
DATA_SOURCE="$MYSQL_USER:$MYSQL_PASSWORD@tcp(127.0.0.1:3306)/mattermost?charset=utf8mb4,utf8&writeTimeout=30s"
jq '.SqlSettings.DataSource |= "'"$DATA_SOURCE"'"' /vagrant/config.json > /opt/mattermost/config/config.json

echo "Create Mattermost user"
useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

echo "Install Mattermost systemd file"
cp /vagrant/mattermost.service /etc/systemd/system/mattermost.service
chmod 644 /etc/systemd/system/mattermost.service
systemctl daemon-reload

echo "Create Mattermost admin user and team"
# Should migrate to mmctl soon
/opt/mattermost/bin/mattermost user create --email admin@planetexpress.com --username $MM_ADMIN --password $MM_ADMIN_PASSWORD --system_admin
/opt/mattermost/bin/mattermost team create --name planet-express --display_name "Planet Express" --email "admin@planetexpress.com"
/opt/mattermost/bin/mattermost team add planet-express admin@planetexpress.com

echo "Starting Mattermost"
systemctl start mattermost.service

# # Clean Up Files
# rm -f .secrets
# rm -f mattermost-$MATTERMOST_VERSION-linux-amd64.tar.gz

#debugging only
echo $MYSQL_ROOT_PASSWORD
echo $MYSQL_DATABASE
echo $MYSQL_USER
echo $MYSQL_PASSWORD
echo $MATTERMOST_VERSION
echo $DATA_SOURCE