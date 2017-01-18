# ansible-openstack-vcenter
Ansible playbooks to create a openstack vcenter.

Newton Release

# Steps
## Compute node
* Install compute node (Debian Stretch or Ubuntu 16.04) with qemu-kvm, bridge-utils and virt-manager
* You need two network interfaces configured as external (ose) and management (osm).
  * In a development environment osm and ose network interfaces interface does not need to be "connected" to any physical device so you can use your physical network interfaces with network manager. Suppose you are using a 10.42.84.0/24 management network and a 10.20.30.0/24 external network:
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto ose
iface ose inet static
    address 10.20.30.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_maxwait 0
    up iptables -t nat -o ose -A POSTROUTING -s 10.20.30.0/24 ! -d 10.20.30.0/24 -j MASQUERADE
    down iptables -t nat -o ose -D POSTROUTING -s 10.20.30.0/24 ! -d 10.20.30.0/24 -j MASQUERADE

auto osm
iface osm inet static
    address 10.42.84.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    up iptables -t nat -A POSTROUTING -s 10.42.84.0/24 ! -d 10.42.84.0/24 -j MASQUERADE
    down iptables -t nat -D POSTROUTING -s 10.42.84.0/24 ! -d 10.42.84.0/24 -j MASQUERADE
```

  * For a production environment you will need a server with two network interfaces (all servers I know have them) and connect both interfaces to the physical interfaces with "bridge_ports". Remember that the physical server is not the gateway so you don't need to NAT:
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# OpenStack External network
auto ose
iface ose inet manual
	  up ip link set dev $IFACE up
    down ip link set dev $IFACE down
    bridge_ports eth0
    bridge_maxwait 0

# OpenStack Management network
auto osm
iface osm inet static
    address 10.42.84.11
    netmask 255.255.255.0
    bridge_ports eth1
    bridge_stp off
    bridge_fd 0
```

## vCenter virtual node
### Create vCenter machine
#### Alternative 1: Download the appliance
Stop libvirtd:
```
service libvirt-bin stop
```
Download the appliance:
```
cd /var/lib/libvirt/images
wget http://elmanytas.es/filesblog/informatica/virtualizacion/20161102-OpenStack/openstack-vcenter.tgz
```
Uncompress the appliance:
```
tar -zxvf openstack-vcenter.tgz
```
Copy the config file to libvirt:
```
cp etc/libvirt/qemu/openstack-vcenter.xml /etc/libvirt/qemu/
```
Start libvirt:
```
service libvirt-bin start
```
#### Alternative 1: Build the appliance
Create vcenter machine as a KVM virtual machine (Debian Stretch) in compute node with two network interfaces attached to ose and osm bridges. Stop libvirtd, copy the configuration openstack-vcenter.xml in /etc/libvirt/qemu/openstack-vcenter.xml and create disks this way.
```
sudo su -
service libvirt-bin stop
cp openstack-vcenter.xml /etc/libvirt/qemu/openstack-vcenter.xml
chmod 600 /etc/libvirt/qemu/openstack-vcenter.xml
qemu-img create -f qcow2 /var/lib/libvirt/images/openstack-vcenter-root.qcow2 10G
qemu-img create -f qcow2 /var/lib/libvirt/images/openstack-vcenter-glance.qcow2 10G
qemu-img create -f qcow2 /var/lib/libvirt/images/openstack-vcenter-cinder.qcow2 40G
qemu-img create -f qcow2 /var/lib/libvirt/images/openstack-vcenter-swift.qcow2 20G
qemu-img create -f qcow2 /var/lib/libvirt/images/openstack-vcenter-ceilometer.qcow2 20G
chown libvirt-qemu:kvm /var/lib/libvirt/images/*qcow2
chmod 644 /var/lib/libvirt/images/*qcow2
wget http://ftp.de.debian.org/debian-cd/8.7.1/amd64/iso-cd/debian-8.7.1-amd64-netinst.iso -O /var/lib/libvirt/images/debian-8.7.1-amd64-netinst.iso
service libvirt-bin start
```
### Configure vCenter machine
#### Upgrade to Stretch
Change jessie string in /etc/apt/sources.list to stretch and execute:
```sh
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
reboot
```

#### Networking
* Install bridge-utils:
```
sudo apt-get install bridge-utils
```
* Configure vcenter virtual machine network as follows and reboot:
```
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto osm
iface osm inet static
	address 10.42.84.2
	netmask 255.255.255.0
	gateway 10.42.84.1
	bridge_ports eth0
	bridge_stp off
	bridge_fd 0
	dns-nameservers 8.8.8.8

auto ose
iface ose inet manual
	up ip link set dev $IFACE up
	down ip link set dev $IFACE down
	bridge_ports eth1
	bridge_maxwait 0
```
#### Install software
* Install git and ansible:
```
sudo apt-get install git ansible
```
* /etc/hosts in compute an vcenter _must_ have this lines or be DNS resolvable:
```
10.42.84.2	openstack-vcenter
10.42.84.1	openstack-compute
```
* In vcenter virtual machine generate ssh key with "ssh-keygen -t rsa"
* Copy key to root@openstack-compute and openstack-vcenter: ssh-copy-id root@openstack-compute;ssh-copy-id root@openstack-vcenter
* Clone ansible-openstack-vcenter repository:
```
git clone https://github.com/elmanytas/ansible-openstack-vcenter.git
git checkout develop
```
* Change to ansible-openstack-vcenter directory
* Change vars in etc_ansible/group_vars/all/vars_file.yml
* Configure hosts in etc_ansible/hosts
* Run ansible-playbook -i hosts site.yml

* After finishing the ansible playbook remember to create initial networks with *kilo* guide ( http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron_initial-external-network.html ). Suppose a external network CIDR like 10.20.30.0/24:
```
neutron net-create public --router:external --provider:physical_network external --provider:network_type flat
neutron subnet-create public 10.20.30.0/24 --name public --allocation-pool start=10.20.30.10,end=10.20.30.200 --disable-dhcp --gateway 10.20.30.1
```

LXD hypervisor requires special image upload from command line:
```
wget http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-root.tar.gz
glance image-create --name="LXD Ubuntu 14.04 Trusty" --visibility public --progress --container-format=bare --disk-format=root-tar --property architecture="x86_64" --property hypervisor_type=lxc --file /tmp/trusty-server-cloudimg-amd64-root.tar.gz
```

Restoring:
* In Debian/Ubuntu KVM node:
  * apt-get -y remove --purge neutron-plugin-ml2 neutron-plugin-openvswitch-agent nova-compute neutron-plugin-openvswitch-agent python-neutron python-neutronclient neutron-common openvswitch-common openvswitch-switch
  * apt-get -y autoremove --purge
  * rm -rf /var/log/neutron /var/lib/neutron/lock /var/log/openvswitch /var/log/nova /var/lib/nova/instances
* In CentOS KVM node:
  * yum -y remove remove openstack-neutron-common openstack-neutron-openvswith python-neutron python-neutronclient openstack-neutron-ml2 openstack-nova-common openstack-nova-compute python-novaclient python-nova python-openvswitch openvswitch

If this KVM node is hosting vCenter, destroy vCenter virtual machine with virt-manager.

# TODO sorted by importance:
* keystone
* neutron
* glance
* nova
* openstack-dashboard
* heat
* designate
* trove
* cinder
* manila
* swift
* ceilometer
* zaqar
* barbican
* sahara
* magnum
* ironic
* aodh
* congress
* mistral
* murano
* rally
* senlin
* tempest
* watcher
