echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Installing dependencies ..."
sudo apt-get update
sudo apt-get install -y unzip curl jq dnsutils
sudo apt-get install -y net-tools socat

echo "Determining Consul version to install ..."
CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
if [ -z "$CONSUL_DEMO_VERSION" ]; then
    CONSUL_DEMO_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
fi

echo "Fetching Consul version ${CONSUL_DEMO_VERSION} ..."
cd /tmp/
curl -s https://releases.hashicorp.com/consul/${CONSUL_DEMO_VERSION}/consul_${CONSUL_DEMO_VERSION}_linux_amd64.zip -o consul.zip

echo "Installing Consul version ${CONSUL_DEMO_VERSION} ..."
unzip consul.zip
sudo chown root:root consul
sudo chmod +x consul
sudo mv consul /usr/local/bin/
consul --version

consul -autocomplete-install
complete -C /usr/local/bin/consul consul


echo "Copying consul.d configuration from host machine"
sudo mkdir /etc/consul.d
sudo useradd --system --home /etc/consul.d --shell /bin/false consul

sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

MYHOSTNAME=`cat /etc/hostname`
echo "Machine hostname: $MYHOSTNAME"
sudo cp /vagrant/configs/$MYHOSTNAME/consul.d/* /etc/consul.d/
sudo chmod a+w /etc/consul.d

sudo chown --recursive consul:consul /etc/consul.d

sudo chmod 640 /etc/consul.d/consul.hcl
sudo chmod 640 /etc/consul.d/server.hcl

sudo chmod a+w /etc/consul.d


echo "HAProxy configuration"
echo "deb http://httpredir.debian.org/debian jessie-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt-get install -y aptitude
sudo aptitude update
sudo aptitude install -y -t jessie-backports haproxy

sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.original
sudo cp /vagrant/configs/$MYHOSTNAME/haproxy/haproxy.cfg /etc/haproxy/
sudo systemctl restart haproxy
sudo systemctl status haproxy.service
#sudo systemctl enable HAProxy

echo "NGINX configuration"
sudo apt-get install -y nginx
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
sudo cp /vagrant/configs/$MYHOSTNAME/nginx/nginx.conf /etc/nginx/
sudo systemctl restart nginx
sudo systemctl status nginx.service
sudo systemctl enable nginx


echo "CONSUL SERVER Systemd configuration"
MYIP=$(ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//')
echo "Machine IP: $MYIP"
sudo touch /etc/systemd/system/consul.service
echo "[Unit]" >> /etc/systemd/system/consul.service
echo "Description=\"HashiCorp Consul - A service mesh solution\"" >> /etc/systemd/system/consul.service
echo "Documentation=https://www.consul.io/" >> /etc/systemd/system/consul.service
echo "Requires=network-online.target" >> /etc/systemd/system/consul.service
echo "After=network-online.target" >> /etc/systemd/system/consul.service
echo "ConditionFileNotEmpty=/etc/consul.d/consul.hcl" >> /etc/systemd/system/consul.service
echo "" >> /etc/systemd/system/consul.service
echo "[Service]" >> /etc/systemd/system/consul.service
echo "User=consul" >> /etc/systemd/system/consul.service
echo "Group=consul" >> /etc/systemd/system/consul.service
echo "ExecStart=/usr/local/bin/consul agent -server -bootstrap-expect=1 -data-dir=/tmp/consul -bind=$MYIP -enable-script-checks=true -config-dir=/etc/consul.d/ -ui " >> /etc/systemd/system/consul.service
echo "ExecReload=/usr/local/bin/consul reload" >> /etc/systemd/system/consul.service
echo "KillMode=process" >> /etc/systemd/system/consul.service
echo "Restart=on-failure" >> /etc/systemd/system/consul.service
echo "LimitNOFILE=65536" >> /etc/systemd/system/consul.service
echo "" >> /etc/systemd/system/consul.service
echo "[Install]" >> /etc/systemd/system/consul.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/consul.service

echo "Starting consul server..." 
sudo systemctl restart consul
sudo systemctl status consul.service

sudo systemctl enable consul

echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"


