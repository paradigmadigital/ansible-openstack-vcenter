# ansible-openstack-vcenter
Ansible playbooks to create a openstack vcenter.



Steps:
* Install compute node (Ubuntu 14.04) with qemu-kvm, bridge-utils and virt-manager 
* You need two network interfaces configured as external (ose) and management (osm).
** For a development environment osm and ose network interfaces interface does not need to be "connected" to any physical device so you can use your physical network interfaces with network manager. Supose you are using a 10.42.84.0/24 management network and a 10.10.10.0/24 external network:
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# OpenStack External network
auto ose
iface ose inet static
    address 10.10.10.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    bridge_maxwait 0
    up iptables -t nat -o ose -A POSTROUTING -s 10.10.10.0/24 ! -d 10.10.10.0/24 -j MASQUERADE
    down iptables -t nat -o ose -D POSTROUTING -s 10.10.10.0/24 ! -d 10.10.10.0/24 -j MASQUERADE

# OpenStack Management network
auto osm
iface osm inet static
    address 10.42.84.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0
    up iptables -t nat -o osm -A POSTROUTING -s 10.42.84.0/24 ! -d 10.42.84.0/24 -j MASQUERADE
    down iptables -t nat -o osm -D POSTROUTING -s 10.42.84.0/24 ! -d 10.42.84.0/24 -j MASQUERADE

```
** For a production environment you will need a server with two network interfaces (all servers I know have them) and connect both interfaces to the physical interfaces with "bridge_ports". Remember that the physical server is not the gateway so you don't need to NAT:
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# "public" network
auto ose
iface ose inet static
	up ip link set dev $IFACE up
        down ip link set dev $IFACE down
        bridge_ports eth0
        bridge_maxwait 0


# openstack management network
auto osm
iface osm inet static
    address 10.42.84.11
    netmask 255.255.255.0
    bridge_ports eth1
    bridge_stp off
    bridge_fd 0
```

* Create vcenter machine as a KVM virtual machine (Ubuntu 14.04) with two network interfaces attached to ose and osm bridges. Configuration example in /etc/libvirt/qemu/OpenStack-vCenter.xml. You can download the appliance to /var/lib/libvirt/images/OpenStack-vCenter.qcow2 and load this configuration with "virsh define configuration.xml":
```
<domain type='kvm' id='6'>
  <name>OpenStack-vCenter</name>
  <uuid>82df7c7b-39a8-b11c-b659-f723fb4eedb0</uuid>
  <memory unit='KiB'>2097152</memory>
  <currentMemory unit='KiB'>2097152</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-trusty'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
    <bootmenu enable='yes'/>
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
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/OpenStack-vCenter.qcow2'/>
      <backingStore/>
      <target dev='vdb' bus='virtio'/>
      <alias name='virtio-disk1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/images/ubuntu-14.04.2-server-amd64.iso'/>
      <backingStore/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
      <alias name='ide0-1-0'/>
      <address type='drive' controller='0' bus='1' target='0' unit='0'/>
    </disk>
    <controller type='ide' index='0'>
      <alias name='ide0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <mac address='52:54:00:c6:31:71'/>
      <source bridge='osm'/>
      <target dev='vnet0'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:c0:f7:4d'/>
      <source bridge='ose'/>
      <target dev='vnet1'/>
      <model type='virtio'/>
      <alias name='net1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/19'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/19'>
      <source path='/dev/pts/19'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='5900' autoport='yes'/>
    <video>
      <model type='cirrus' vram='16384' heads='1'/>
      <alias name='video0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='apparmor' relabel='yes'>
    <label>libvirt-82df7c7b-39a8-b11c-b659-f723fb4eedb0</label>
    <imagelabel>libvirt-82df7c7b-39a8-b11c-b659-f723fb4eedb0</imagelabel>
  </seclabel>
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
	dns-nameservers 192.168.84.1

auto ose
iface ose inet manual
	up ip link set dev $IFACE up
	down ip link set dev $IFACE down
	bridge_ports eth1
	bridge_maxwait 0
```
* /etc/hosts in compute an vcenter must have this lines:
```
192.168.84.3	os-vcenter-01
192.168.84.1	os-kvm-01
```
* In vcenter virtual machine generate ssh key with "ssh-keygen -t rsa"
* Copy key to os-kvm-01 and os-vcenter-01: ssh-copy-id root@os-kvm-01;ssh-copy-id root@os-vcenter-01
* Clone repository with "git clone https://github.com/elmanytas/ansible-openstack-vcenter.git"
* Change vars in etc_ansible/group_vars/all/vars_file.yml
* Configure hosts in etc_ansible/hosts
* Run ansible-playbook -i hosts site.yml

* After finishing the ansible playbook remember to create initial networks: http://docs.openstack.org/kilo/install-guide/install/apt/content/neutron-initial-networks.html


Restoring:
* In KVM node:
..* apt-get -y remove --purge neutron-plugin-ml2 neutron-plugin-openvswitch-agent nova-compute neutron-plugin-openvswitch-agent python-neutron python-neutronclient neutron-common openvswitch-common openvswitch-switch
..* apt-get -y autoremove --purge
..* rm -rf /var/log/neutron /var/lib/neutron/lock /var/log/openvswitch /var/log/nova /var/lib/nova/instances /etc/iscsi 

If this KVM node is hosting vcenter, destroy vcenter virtual machine with virt-manager.
