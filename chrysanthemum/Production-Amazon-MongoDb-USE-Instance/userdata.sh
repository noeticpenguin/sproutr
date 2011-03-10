#!/bin/bash

set -e
set -x

function configure_drives() {
    echo "--- CONFIGURE DRIVES"
    apt-get install -y mdadm xfsprogs lvm2

    echo "--- creating raid for database cluster"
    for i in /sys/block/sdf{1..4}/queue/scheduler; do
      echo "deadline" > $i
    done
    # a bug with udev conflicts with mdadm
    service udev stop
    mdadm --create /dev/md0 -n 4 -l 0 -c 256 /dev/sdf{1..4}
    mdadm -Es >>/etc/mdadm/mdadm.conf
    service udev start
    echo "blockdev --setra 256 /dev/md0" >> /etc/rc.local
    modprobe dm-mod
    echo dm-mod >> /etc/modules
    pvcreate /dev/md0
    vgcreate vgdb /dev/md0
    lvcreate -n lvdb vgdb -l `/sbin/vgdisplay vgdb | grep Free | awk '{print $5}'`
    mkfs.ext3 -q -L /database /dev/vgdb/lvdb
    echo "/dev/vgdb/lvdb       /data   ext3   noatime,nosuid,nodev" >> /etc/fstab
    mkdir -p /data && mount /data
}

function userdata() {
    exec 2>&1

    echo "+++ Beginning userdata.sh run"
    export DEBIAN_FRONTEND="noninteractive"
    export DEBIAN_PRIORITY="critical"
    echo "" > /etc/rc.local  ## truncate this file - default is 'exit 0' which breaks append ops

    configure_drives

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

    echo "+++ Done!"
}

userdata > /var/log/userdata.log


