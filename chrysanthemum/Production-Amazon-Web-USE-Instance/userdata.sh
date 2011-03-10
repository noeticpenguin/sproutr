#!/bin/bash

set -e
set -x

function userdata() {
        exec 2>&1

    echo "+++ Installing support packages that are not properly listed as cookbook dependencies"
    sudo apt-get -y install build-essential libmysqlclient-dev libcurl4-openssl-dev libssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev

    echo "+++ Configuring Chef"
    sudo mkdir -p /etc/chef
    cp /root/userdata/packet/solo.rb /etc/chef/

    echo "+++ Downloading, unzipping and prepparing Cookbooks"
    sudo chmod +x /root/userdata/packet/fetch_cookbooks.rb
    sudo /root/userdata/packet/fetch_cookbooks.rb apache2 mongodb mysql memcached passenger_apache2 openssl build-essential runit

    echo "+++ Running Chef-solo"
    sudo chef-solo -j /root/userdata/packet/node.json

    echo "+++ Installing packages that no cookbook yet exists for"
    sudo gem install passenger
    sudo passenger-install-apache2-module -a
}

userdata > /var/log/userdata.log


