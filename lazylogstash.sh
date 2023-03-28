#!/bin/bash
# author : @shanekhantaun9

if [ "$EUID" -ne 0 ];then
    echo "[-] Please run this script as a root user"
    exit 1
fi

echo "[*] Updating your os, it can take some times..."
sudo apt update &> /dev/null
sudo apt upgrade -y &> /dev/null

echo "[*] Installing Timezone & Set to Asia-Yangon"
sudo timedatectl set-timezone Asia/Yangon 

echo "[*] Installing Java"
sudo apt install default-jdk -y &> /dev/null

echo "[*] Installing the Public Signing Key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add &> /dev/null
sudo apt-get install apt-transport-https &> /dev/null

echo "[*] Saving the repository definition to /etc/apt/sources.list.d/elastic-8.x.list"
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list &> /dev/null

echo "[*] Reupdating"
sudo apt-get update &> /dev/null

echo "[*] Installing logstash"
sudo apt-get install logstash &> /dev/null

echo "[*] Enabling Logstash Service"
sudo systemctl enable logstash.service 


echo "[*] Installing Logstash Plugin & Loganalystics, wait a few minute..."
sudo /usr/share/logstash/bin/logstash-plugin install microsoft-sentinel-logstash-output-plugin &> /dev/null
sudo /usr/share/logstash/bin/logstash-plugin install microsoft-logstash-output-azure-loganalytics &> /dev/null

echo "[*] Configuring pipeline"
read -p "[+] Enter .config file name: " FILENAME
read -p "[+] Enter port number: " PORT 
read -p "[+] Enter your sentinal's workspace_id: " WORKSPACE_ID 
read -p "[+] Enter your sentinal's workspace_key: " WORKSPACE_KEY 
read -p "[+] Enter table name: " TABLENAME

sudo cat <<EOF > /etc/logstash/conf.d/$FILENAME.conf
input {
      tcp {
          port => "$PORT"
          type => syslog 
      }
  }
  filter {
  }
  output {
      	microsoft-logstash-output-azure-loganalytics {
	workspace_id => "$WORKSPACE_ID"
        workspace_key => "$WORKSPACE_KEY"
        custom_log_table_name => "$TABLENAME"
      }
  }
EOF

echo "[*] Configuring Logstash Pipeline"
sudo cat <<EOF > /etc/logstash/pipelines.yml
- pipeline.id: main
  path.config: "/etc/logstash/conf.d/$FILENAME.conf"
EOF


echo "[*] Restarting Logstash Service"
sudo systemctl restart logstash.service


read -p "[*] Do you want to restart the machine? (y/n): " choice
case "$choice" in 
  y|Y ) sudo systemctl reboot -i ;;
  n|N ) exit & echo "[+] Done!";;
  * ) echo "[-] Just type only y or n";;
esac
