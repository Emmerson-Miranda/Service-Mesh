echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

sudo bash /vagrant/scripts/shell/agent_provision_script.sh

sudo apt-get update
sudo apt-get install -y default-jre

MYHOSTNAME=`cat /etc/hostname`
echo "Machine hostname: $MYHOSTNAME"

sudo mkdir /var/rabbitmq-client
sudo cp /vagrant/configs/$MYHOSTNAME/files/rabbitmq-client-0.0.2.jar /var/rabbitmq-client/rabbitmq-client.jar
sudo ln -s /var/rabbitmq-client/rabbitmq-client.jar /etc/init.d/rabbitmq-client

echo "Register rabbitmq-client syslog log router..."
sudo touch /var/log/rabbitmq-client.log
chown root:adm /var/log/rabbitmq-client.log
sudo cp /vagrant/configs/$MYHOSTNAME/rsyslog.d/rabbitmq-client.conf /etc/rsyslog.d/rabbitmq-client.conf
sudo systemctl restart rsyslog

echo "Register linux service"
sudo cp /vagrant/configs/$MYHOSTNAME/files/rabbitmq-client.service /etc/systemd/system/rabbitmq-client.service

echo "Starting rabbitmq-client linux service"
sudo chown --recursive consul:consul /var/rabbitmq-client
sudo systemctl start rabbitmq-client
sudo systemctl status rabbitmq-client.service
sudo systemctl enable rabbitmq-client

echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
