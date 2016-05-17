#!/bin/bash
wget -c https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img -O /tmp/trusty-server-cloudimg-amd64-disk1.qcow2
source /root/admin-openrc.sh
openstack image create "ubuntu-trusty-x86_64" \
 --file /tmp/trusty-server-cloudimg-amd64-disk1.qcow2 \
 --disk-format qcow2 --container-format bare \
 --public

heat stack-delete -y test
heat stack-create -n test check_installation.yaml
