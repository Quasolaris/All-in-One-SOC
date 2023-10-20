echo "============================"
echo "All In One SIEM Installation"
echo "============================\n"

echo "Docker and docker-compose installation starting now...\n"
apt install docker docker-compose -y
echo "Shutting down old Docker instances\n"
docker-compose down

echo "Listing Interfaces:\n"
ip a
read -p "Type mirroring interface for Suricata (ex. enp0s1):" interface

# Cleanup of old values from previous runs
sed -i '/ELASTIC_PASSWORD/d' ./.env
sed -i '/KIBANA_PASSWORD/d' ./.env
sed -i '/#============ NO CONTENT UNDER THIS LINE!/q' ./docker-compose.yml
sed -i '/#============ NO CONTENT UNDER THIS LINE!/q' ./filebeat_etc/filebeat.yml

echo "        ${interface}" >> docker-compose.yml
echo "We will need some setup information like Logins for elastic and kibana user"

# SET YOUR IP INFORMATION FOR YOUR NETWORK HERE:
# HOMENET IS THE COMPANY NETWORK
# SRV_NET IS THE SERVER NETWORK
sed -i "s/HOME_NET:.*/HOME_NET: \"[192.168.10.0\/24]\"/"  suricata_etc/suricata.yaml
sed -i "s/SRV_NET:.*/SRV_NET: \"[192.168.20.0\/24]\"/"  suricata_etc/suricata.yaml

read -p "Please enter your desired password for elastic user:" elasticpassword
echo "ELASTIC_PASSWORD=${elasticpassword}" >> .env

read -p "Please enter your desired password for kibana_system user: " kibanapassword
echo "KIBANA_PASSWORD=${kibanapassword}" >> .env

echo "Composing Docker images\n"
docker-compose up -d >> dockercompose.log

echo "Testing and configuring Suricata and Filebeat"

version=$(cat .env | grep -o 'STACK_VERSION.*' | cut -f2- -d=)
docker exec -it suricata bash suricata.sh ${version}

filebeatconfig="${elasticpassword}\""
echo "  password: \"${filebeatconfig}" >> ./filebeat_etc/filebeat.yml

docker exec -it suricata bash start_suricata_services.sh

# WAZUH configuration
echo "Downloading and installing Wazuh\n"
echo "Removing old Wazuh containers and folders"
docker-compose -f wazuh-docker/single-node/docker-compose.yml down
rm -rf wazuh-docker
git clone https://github.com/wazuh/wazuh-docker.git -b v4.4.5
echo "Download complete, now starting installation"
cd wazuh-docker/single-node

# Replacing Port 9200 with 9300 because elasticsearch uses the same port
sed -i 's/INDEXER_URL=.*/INDEXER_URL=https:\/\/wazuh.indexer:9300/' docker-compose.yml
sed -i 's/- "9200.*/- "9300:9200"/' docker-compose.yml

docker-compose -f generate-indexer-certs.yml run --rm generator
docker-compose up -d >> ../../dockercompose.log

hostip=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')

echo "============================"
echo "Installation finished!"
echo "Elastic stack accessible over http://$hostip:5601"
echo "Wazuh server accessible over https://$hostip"
echo "============================"
