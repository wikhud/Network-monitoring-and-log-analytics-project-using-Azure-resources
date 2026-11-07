sudo su
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/bin/
sudo azcopy login --identity
mkdir /home/adminuser/logs_from_storage
mkdir /home/adminuser/new_logs
cat >> /home/adminuser/extract_new_logs.sh <<EOL
sudo azcopy login --identity
sudo azcopy sync 'https://storage1.blob.core.windows.net/insights-logs-networksecuritygroupflowevent' '/home/adminuser/logs_from_storage' --recursive
/usr/bin/find /home/adminuser/logs_from_storage -type f -mmin -10 | while IFS= read -r f; do cp -v "\$f" "/home/adminuser/new_logs/\${f//\//_}"; done
EOL
chmod +x extract_new_logs.sh
(crontab -l 2>/dev/null; echo "PWD=/home/adminuser") | crontab -
(crontab -l 2>/dev/null; echo "SHELL=/bin/bash") | crontab -
(crontab -l 2>/dev/null; echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * /home/adminuser/extract_new_logs.sh") | crontab -
sudo add-apt-repository ppa:oisf/suricata-stable -y
sudo apt-get update
sudo sudo apt-get install suricata -y
wget https://rules.emergingthreats.net/open/suricata/emerging.rules.tar.gz
tar zxf emerging.rules.tar.gz
sudo cp -r rules /etc/suricata/
sudo apt-get update
sudo apt install default-jre -y
sudo apt-get update
sudo apt install openjdk-8-jre-headless -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo apt install apt-transport-https
sudo apt update
sudo apt install elasticsearch -y
sed  -i '1i network.host: 0.0.0.0' /etc/elasticsearch/elasticsearch.yml
sed  -i '2i http.port: 9200' /etc/elasticsearch/elasticsearch.yml
sudo apt update
systemctl enable elasticsearch
systemctl start elasticsearch
sudo apt install kibana -y
sed  -i '1i server.port: 80' /etc/kibana/kibana.yml
sed  -i '2i server.host: "0.0.0.0"' /etc/kibana/kibana.yml
sed  -i '3i elasticsearch.url: "http://localhost:9200"' /etc/kibana/kibana.yml
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/bin/kibana
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/bin/kibana-plugin
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/bin/kibana-keystore
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node
sudo apt update
sudo systemctl enable kibana
sudo systemctl start kibana
sudo apt update
sudo apt install logstash -y
sudo touch /var/log/suricata/eve.json
sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-azureblob
cat >> /etc/logstash/conf.d/logstash.conf <<EOL
input { 
azureblob 
 { 
     storage_account_name => "storage1" 
     storage_access_key => "actual-key"
     container => "insights-logs-networksecuritygroupflowevent" 
     codec => "json" 
     file_head_bytes => 12 
     file_tail_bytes => 2 
 } 
} 
 
 
filter { 
 split { field => "[records]" } 
 split { field => "[records][properties][flows]"} 
 split { field => "[records][properties][flows][flows]"} 
 split { field => "[records][properties][flows][flows][flowTuples]"} 
 
 
mutate { 
split => { "[records][resourceId]" => "/"} 
add_field => {"Subscription" => "%{[records][resourceId][2]}" 
             "ResourceGroup" => "%{[records][resourceId][4]}" 
             "NetworkSecurityGroup" => "%{[records][resourceId][8]}"} 
convert => {"Subscription" => "string"} 
convert => {"ResourceGroup" => "string"} 
convert => {"NetworkSecurityGroup" => "string"} 
split => { "[records][properties][flows][flows][flowTuples]" => ","} 
add_field => { 
           "unixtimestamp" => "%{[records][properties][flows][flows][flowTuples][0]}" 
           "srcIp" => "%{[records][properties][flows][flows][flowTuples][1]}" 
           "destIp" => "%{[records][properties][flows][flows][flowTuples][2]}" 
           "srcPort" => "%{[records][properties][flows][flows][flowTuples][3]}" 
           "destPort" => "%{[records][properties][flows][flows][flowTuples][4]}" 
           "protocol" => "%{[records][properties][flows][flows][flowTuples][5]}" 
           "trafficflow" => "%{[records][properties][flows][flows][flowTuples][6]}" 
           "traffic" => "%{[records][properties][flows][flows][flowTuples][7]}" 
            } 
convert => {"unixtimestamp" => "integer"} 
convert => {"srcPort" => "integer"} 
convert => {"destPort" => "integer"}         
} 
 
 
date{ 
match => ["unixtimestamp" , "UNIX"] 
} 
} 
 
 
output { 
 elasticsearch { 
   hosts => "localhost" 
   index => "nsg-flow-logs" 
 } 
}
EOL
sudo chmod 775 /var/log/suricata/eve.json
sudo /usr/share/logstash/bin/logstash --config.test_and_exit -f /etc/logstash/conf.d/logstash.conf
sudo apt update
sudo systemctl enable logstash
sudo systemctl start logstash
sudo apt update
