#!/bin/bash
source $HOME/admin-openrc.sh
echo "Creating base image ..."
exists=$(glance image-list | grep ubuntu-trusty-x86_64 | wc -l)
if [ "$exists" = "0" ]; then
  wget -c https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img \
       -O /tmp/trusty-server-cloudimg-amd64-disk1.qcow2
  openstack image create "ubuntu-trusty-x86_64" \
  --file /tmp/trusty-server-cloudimg-amd64-disk1.qcow2 \
  --disk-format qcow2 --container-format bare \
  --public
fi

echo "Creating keypair ..."
exists=$(openstack keypair list | grep test_key | wc -l)
if [ "$exists" = "0" ]; then
  openstack keypair create --public-key $HOME/.ssh/id_rsa.pub test_key
fi

echo "Deploying template"
heat stack-delete -y test
sleep 5s
public_id=$(openstack network list | grep public | awk '{print $2}')
sed -i "s/__public_net_id__/$public_id/g" check_installation.yaml
heat stack-create test --template-file=check_installation.yaml
