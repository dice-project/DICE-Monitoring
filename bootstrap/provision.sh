#!/bin/bash

# Obtain chef client
wget https://packages.chef.io/files/stable/chef/12.18.31/ubuntu/14.04/chef_12.18.31-1_amd64.deb
dpkg -i chef_12.18.31-1_amd64.deb

# Obtain chef cookbooks
wget https://github.com/dice-project/DICE-Chef-Repository/archive/develop.tar.gz
tar -xf develop.tar.gz

# Run chef
cd DICE-Chef-Repository-develop
cp /vagrant/dmon.json .
chef-client -z \
  -j dmon.json \
  -o recipe[dice_common::host],recipe[apt::default],recipe[java::default],recipe[dmon::default],recipe[dmon::elasticsearch],recipe[dmon::kibana],recipe[dmon::logstash]
