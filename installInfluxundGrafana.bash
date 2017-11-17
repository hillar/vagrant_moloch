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


cd /vagrant/
echo "$(date) installing influx"
[ -f influxdb_1.4.2_amd64.deb ] || wget -q https://dl.influxdata.com/influxdb/releases/influxdb_1.4.2_amd64.deb
sudo dpkg -i influxdb_1.4.2_amd64.deb
systemctl start influxdb.service 

echo "$(date) installing grafana"
apt-get install -y adduser libfontconfig
[ -f grafana_4.6.2_amd64.deb ] || wget -q https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.6.2_amd64.deb 
sudo dpkg -i grafana_4.6.2_amd64.deb 
systemctl start grafana-server.service 


