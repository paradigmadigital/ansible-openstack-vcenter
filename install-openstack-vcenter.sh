#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
else
  workspace=`mktemp -d`
  sleep 1
  cd $workspace
  wget http://elmanytas.es/filesblog/informatica/virtualizacion/20161102-OpenStack/openstack-vcenter.tgz -O $workspace/openstack-vcenter.tgz
  tar --directory /var/lib/libvirt/images -zxvf $workspace/openstack-vcenter.tgz
  sudo service libvirt-bin stop
  sudo mv /var/lib/libvirt/images/etc/libvirt/qemu/openstack-vcenter.xml /etc/libvirt/qemu/openstack-vcenter.xml
  sudo service libvirt-bin start
  sudo mv /var/lib/libvirt/images/etc $workspace
  rm -rf $workspace
  echo "Go to Applications|System Tool|Virtual Machine Manager and start the OpenStack vCenter machine"
  echo "Login: openstack/openstack"
fi
