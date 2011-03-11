#!/bin/bash

set -e
set -x

function userdata() {
        exec 2>&1

    echo "+++ Installing Ruby1.9.1(but it's really 1.9.2)"
#    sudo add-apt-repository ppa:pratikmsinha/ruby192+bindings
    sudo apt-get update
    sudo apt-get -y install rubygems ruby1.8-dev ruby
    echo "++++ Setting up system links"
    # this is totally hacky and should be replaced with some find fu.
#    sudo ln -s /usr/bin/erb1.9.1 /usr/bin/erb
#    sudo ln -s /usr/bin/gem1.9.1 /usr/bin/gem
#    sudo ln -s /usr/bin/irb1.9.1 /usr/bin/irb
#    sudo ln -s /usr/bin/rake1.9.1 /usr/bin/rake
#    sudo ln -s /usr/bin/rdoc1.9.1 /usr/bin/rdoc
#    sudo ln -s /usr/bin/testrb1.9.1 /usr/bin/testrb
#    sudo ln -s /usr/bin/ruby1.9.1 /usr/bin/ruby
    echo "+++ Installing Chef gem version 0.9.12"
    sudo gem install chef -v=0.9.12 --no-rdoc --no-ri
    sudo ln -s /var/lib/gems/1.8/bin/* /usr/local/bin/
}

userdata > /var/log/userdata.log


