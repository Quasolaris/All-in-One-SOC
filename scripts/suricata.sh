wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list
apt update -q && apt upgrade -y

apt-get install filebeat=${1} nano
update-rc.d filebeat defaults 95 10

echo "Testing and configuring Suricata and Filebeat"
# Setting permissions because of Docker defaults
#chown root:root -R /etc/filebeat/
#chmod go-w -R /etc/filebeat/
# Adding Suricata sources
suricata-update update-sources
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection
suricata-update enable-source sslbl/ssl-fp-blacklist
suricata-update enable-source sslbl/ja3-fingerprints
suricata-update enable-source etnetera/aggressive
suricata-update enable-source tgreen/hunting
suricata-update enable-source malsilo/win-malware
suricata-update enable-source stamus/lateral
suricata-update
filebeat setup
filebeat test output
