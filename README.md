# ansible-openstack-vcenter
Ansible playbooks to create a openstack vcenter.



Steps:
* Install compute node (Ubuntu 14.04) with qemu-kvm, bridge-utils and virt-manager 
* You need two network interfaces configured as external (ose) and management (osm). For a development environment osm interface does not need to be "connected" to any physical device and maybe ose can be connected to physical network as follows (use your network manager managed wlan interface to access internet):
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# "public" network
auto ose
iface ose inet manual
	up ip link set dev $IFACE up
        down ip link set dev $IFACE down
        bridge_ports eth0
        bridge_maxwait 0


# openstack management network
auto osm
iface osm inet static
    address 10.42.84.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    up iptables -t nat -A POSTROUTING -s 10.42.84.0/24 ! -d 10.42.84.0/24 -j MASQUERADE
    down iptables -t nat -D POSTROUTING -s 10.42.84.0/24! -d 10.42.84.0/24 -j MASQUERADE
```

* Create vcenter machine as a KVM virtual machine (Ubuntu 14.04) with two network interfaces attached to ose and osm bridges. Configuration example in /etc/libvirt/qemu/OpenStack-vCenter.xml
```
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh edit OpenStack-vCenter
or other application using the libvirt API.
-->

<domain type='kvm'>
  <name>OpenStack-vCenter</name>
  <uuid>e1342eb2-91a4-c80b-3898-6585c6d198af</uuid>
  <memory unit='KiB'>1583104</memory>
  <currentMemory unit='KiB'>1583104</currentMemory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/kvm-spice</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/images/OpenStack-vCenter.img'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </disk>
    <disk type='block' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='1' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <mac address='52:54:00:45:07:07'/>
      <source bridge='osm'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:40:97:3a'/>
      <source bridge='ose'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </memballoon>
  </devices>
</domain>
```
* Install bridge-utils, git and ansible
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
	address 192.168.84.3
	netmask 255.255.255.0
	gateway 192.168.84.1
	bridge_ports eth0
	bridge_stp off
	bridge_fd 0
	dns-nameservers 172.18.0.1

auto ose
iface ose inet manual
	up ip link set dev $IFACE up
	down ip link set dev $IFACE down
	bridge_ports eth1
	bridge_maxwait 0
```
* /etc/hosts in compute an vcenter must have this lines:
```
192.168.84.2	openstack-vcenter
192.168.84.1	openstack-compute
```
* In vcenter virtual machine generate ssh key with "ssh-keygen -t rsa"
* Copy key to os-kvm-01 and os-vcenter-01: ssh-copy-id root@os-kvm-01;ssh-copy-id root@os-vcenter-01
* Clone repository with "git clone https://github.com/elmanytas/ansible-openstack-vcenter.git"
* Change vars in etc_ansible/group_vars/all/vars_file.yml
* Configure hosts in etc_ansible/hosts
* Run ansible-playbook -i hosts site.yml

After finishing the ansible playbook remember to create initial networks: http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-initial-networks.html
With network configuration described above run as root:
* source admin-openrc.sh 
* neutron net-create ext-net --router:external   --provider:physical_network external --provider:network_type flat
* neutron subnet-create ext-net 10.10.10.0/24 --name ext-subnet --allocation-pool start=10.10.10.10,end=10.10.10.100 --disable-dhcp --gateway 10.10.10.1
* neutron net-create demo-net
* neutron subnet-create demo-net 192.168.1.0/24   --name demo-subnet --gateway 192.168.1.1
* neutron router-create demo-router
* neutron router-interface-add demo-router demo-subnet
* neutron router-gateway-set demo-router ext-net

Restoring:
* In KVM node:
  * apt-get -y remove --purge neutron-plugin-ml2 neutron-plugin-openvswitch-agent nova-compute neutron-plugin-openvswitch-agent python-neutron python-neutronclient neutron-common openvswitch-common openvswitch-switch
  * apt-get -y autoremove --purge
  * rm -rf /var/log/neutron /var/lib/neutron/lock /var/log/openvswitch /var/log/nova /var/lib/nova/instances /etc/iscsi /etc/openvswitch

If this KVM node is hosting vcenter, destroy vcenter virtual machine with virt-manager or restore disk backup in /var/lib/libvirt/images .
