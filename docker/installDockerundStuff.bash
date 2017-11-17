#!/bin/bash

#
# prepares xenial box for docker
# and builds moloch docker image
# and runs elastic & moloch
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

export DEBIAN_FRONTEND=noninteractive
echo "$(date) installing docker"
# install docker
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh >> /vagrant/provision.log 2>&1
echo "$(date) building moloch"
cd /vagrant
docker build --tag="moloch" ./ >> /vagrant/provision.log 2>&1

echo "$(date) installing docker-compose"
apt-get -y install python-pip >> /vagrant/provision.log 2>&1
pip install --upgrade pip >> /vagrant/provision.log 2>&1
pip install docker-compose >> /vagrant/provision.log 2>&1
# sample yml