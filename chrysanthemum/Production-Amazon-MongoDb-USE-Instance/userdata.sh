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
    sudo /root/userdata/packet/fetch_cookbooks.rb mongodb openssl build-essential mysql runit

    echo "+++ Running Chef-solo"
    sudo chef-solo -j /root/userdata/packet/node.json
}

userdata > /var/log/userdata.log


