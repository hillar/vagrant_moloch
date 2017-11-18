#!/bin/bash

#
#
#

XENIAL=$(lsb_release -c | cut -f2)
if [ "$XENIAL" != "xenial" ]; then
    echo "sorry, tested only with xenial ;("; 1>&2
    exit1;
fi

if [ "$(id -u)" != "0" ]; then
   echo "ERROR - This script must be run as root" 1>&2
   exit 1
fi

echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
export DEBIAN_FRONTEND=noninteractive

THEPASSWORD="admin"
ELASTICSEARCH="elasticsearch-5.6.4.deb"

cd /vagrant/

echo "$(date) installing java"
add-apt-repository ppa:webupd8team/java >> /vagrant/provision.log 2>&1
apt-get update >> /vagrant/provision.log 2>&1
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get -y --allow-unauthenticated install oracle-java8-installer >> /vagrant/provision.log 2>&1
java -version

echo "$(date) installing Elasticsearch"
[[ -f $ELASTICSEARCH ]] || wget  -q -4 https://artifacts.elastic.co/downloads/elasticsearch/$ELASTICSEARCH
dpkg -i $ELASTICSEARCH >> /vagrant/provision.log 2>&1
sed -i -e 's,-Xms2g,-Xms256m,g' /etc/elasticsearch/jvm.options
sed -i -e 's,-Xmx2g,-Xmx256m,g' /etc/elasticsearch/jvm.options
systemctl enable elasticsearch >> /vagrant/provision.log 2>&1
systemctl start elasticsearch

echo "$(date) installing nodejs"
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - >> /vagrant/provision.log 2>&1
sudo apt-get install -y nodejs >> /vagrant/provision.log 2>&1

echo "$(date) installing moloch depes"
apt-get -y install libwww-perl libjson-perl libyaml-dev >> /vagrant/provision.log 2>&1

echo "$(date) installing moloch"
[ -f moloch-nightly_amd64.deb ] || wget -q -4 https://files.molo.ch/builds/ubuntu-16.04/moloch-nightly_amd64.deb
dpkg -i moloch-nightly_amd64.deb >> /vagrant/provision.log 2>&1
echo -en "enp0s3;enp0s8;\nno\nhttp://localhost:9200\ns2spassword\n" | /data/moloch-nightly/bin/Configure >> /vagrant/provision.log 2>&1
# TODO wise
# sed -i -e 's,#wiseHost=127.0.0.1,wiseHost=127.0.0.1\nplugins=wise.so\nviewerPlugins=wise.js\nwiseTcpTupleLookups=true\nwiseUdpTupleLookups=true\n,g' /data/moloch-nightly/etc/config.ini

until curl -sS 'http://127.0.0.1:9200/_cluster/health?wait_for_status=yellow&timeout=5s' >> /vagrant/provision.log 2>&1
do
  sleep 1
done
echo -en "INIT" | /data/moloch-nightly/db/db.pl http://localhost:9200 init >> /vagrant/provision.log 2>&1
/data/moloch-nightly/bin/moloch_add_user.sh admin "Admin User" $THEPASSWORD --admin
systemctl enable molochviewer.service
systemctl start molochviewer.service
curl -s localhost:9200/_cat/indices?v
# no need to start capture
#ethtool -K enp0s3 tx off sg off gro off gso off lro off tso off >> /vagrant/provision.log 2>&1
#ethtool -K enp0s8 tx off sg off gro off gso off lro off tso off >> /vagrant/provision.log 2>&1
#systemctl start molochcapture.service

#get some sample traffic
#apt-get -y install unzip >> /vagrant/provision.log 2>&1
#[ -f 2017-09-19-traffic-analysis-exercise.pcap.zip ] || wget -q -4 http://www.malware-traffic-analysis.net/2017/09/19/2017-09-19-traffic-analysis-exercise.pcap.zip
#[ -f 2017-09-19-traffic-analysis-exercise.pcap ] || unzip -P infected /vagrant/2017-09-19-traffic-analysis-exercise.pcap.zip
#/data/moloch-nightly/bin/moloch-capture -c /data/moloch-nightly/etc/config.ini -r 2017-09-19-traffic-analysis-exercise.pcap -t MISSION_POSSIBLE >> /vagrant/provision.log 2>&1

#sleep 10
#curl -s localhost:9200/_cat/indices?v

# do some numbers...
ethtool -K enp0s8 tx off sg off gro off gso off lro off tso off
ethtool -K enp0s3 tx off sg off gro off gso off lro off tso off

/data/moloch-nightly/bin/moloch-capture -c /data/moloch-nightly/etc/config.ini > /tmp/moloch-capture.log 2>&1 &

curl -i -XPOST http://192.168.10.12:8086/query --data-urlencode "q=CREATE DATABASE molouniqs"
curl -s -XPOST --user admin:admin 192.168.10.12:3000/api/datasources -H "Content-Type: application/json" -d '{
    "name": "moloch",
    "type": "influxdb",
    "access": "proxy",
    "url": "http://localhost:8086",
    "database": "molouniqs",
    "isDefault": true
}'

mkdir /data/moloch-nightly/stats
cd /data/moloch-nightly/stats
wget -q https://raw.githubusercontent.com/hillar/atoll.js/master/lib/atoll.js
echo '{}' > package.json
npm install --save influx
wget -q https://raw.githubusercontent.com/hillar/vagrant_moloch/master/moloUniq2influx.js
wget -q https://raw.githubusercontent.com/hillar/vagrant_moloch/master/moloUniq2influx.bash
