# Download Elastic Search
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.1-x86_64.rpm
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.1-x86_64.rpm

# Install Elastic Search
rpm -i elasticsearch-8.8.1-x86_64.rpm

# Backup configurations
if [ ! -f /etc/elasticsearch/elasticsearch.yml.bkp ]; then
    cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bkp
fi

if [ ! -f /etc/sysconfig/elasticsearchelasticsearch.bkp ]; then
    cp /etc/sysconfig/elasticsearch /etc/sysconfig/elasticsearch.bkp
fi

# Customize elasticsearch.yml
ip=`hostname -I | xargs`
sed -i "s/#network.host: 192.168.0.1/network.host: ${ip}/g" /etc/elasticsearch/elasticsearch.yml
sed -i 's/#http.port: 9200/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml

# Set JVM memory settings
totalram=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
ramgb=`expr $totalram / 1024 / 1024`
ramgb=`expr $ramgb + 1`
heapsize=`expr $ramgb / 2`
echo "-Xms${heapsize}g" >> /etc/elasticsearch/jvm.options.d/memory.options
echo "-Xmx${heapsize}g" >> /etc/elasticsearch/jvm.options.d/memory.options

# Customize elasticsearch
echo "" >> /etc/sysconfig/elasticsearch
echo "# Memory" >> /etc/sysconfig/elasticsearch
echo "MAX_LOCKED_MEMORY=unlimited" >> /etc/sysconfig/elasticsearch

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch

# Set the password
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i

# Install Kibana
sudo rpm -i kibana-8.8.1-x86_64.rpm

# Backup Kibana config
if [ ! -f /etc/kibana/kibana.yml.bkp ]; then
    cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bkp
fi

# Link ES and Kibana
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana > kibana.enrollment
enrollment=$(cat kibana.enrollment)
sudo /usr/share/kibana/bin/kibana-setup --enrollment-token $enrollment

# Configure Kibana for remote access
sed -i 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml
sed -i 's/#server.host: "0.0.0.0"/server.host: "0.0.0.0"/g' /etc/kibana/kibana.yml

# Start Kibana
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl start kibana

# Firewall settings
# sudo firewall-cmd --permanent --add-port 9200/tcp
# sudo firewall-cmd --permanent --add-port 5601/tcp
# sudo firewall-cmd --reload

echo "You can now access Kibana at http://${ip}:5601 using user:elastic and the password you specified."
echo 'Enjoy!!!'
