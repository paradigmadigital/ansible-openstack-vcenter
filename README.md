# ansible-openstack-vcenter
Ansible playbooks to create a openstack vcenter.

Needs vcenter network configured as follows:

+++
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
	address 10.42.84.2
	netmask 255.255.255.0
	network 10.42.84.0
	broadcast 10.42.84.255
	gateway 10.42.84.1
	# dns-* options are implemented by the resolvconf package, if installed
	dns-nameservers 8.8.8.8
	dns-search ferrergarcia.es

auto eth1
iface eth1 inet manual
	up ip link set dev $IFACE up
        down ip link set dev $IFACE down
+++

Needs compute node network that hosts vcenter kvm vm configured as follows:
+++
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# "public" network
auto br0
iface br0 inet static
	address 10.10.10.10
	netmask 255.255.255.0
	gateway 10.10.10.1
	bridge_ports eth0
	bridge_maxwait 0
	dns-nameservers 10.10.10.1


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
+++

The vcenter virtual machine can be created with virt-manager and must have two network interfaces attached to osm and br0 network devices.

Configuration example in /etc/libvirt/qemu/OpenStack-vCenter.xml
+++
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh edit OpenStack-vCenter
or other application using the libvirt API.
-->

<domain type='kvm'>
  <name>OpenStack-vCenter</name>
  <uuid>4922cf22-da09-dc11-2bd4-b92fbd2b7ee2</uuid>
  <memory unit='KiB'>1572864</memory>
  <currentMemory unit='KiB'>1572864</currentMemory>
  <vcpu placement='static'>1</vcpu>
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
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
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
      <mac address='52:54:00:ac:53:33'/>
      <source bridge='osm'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:7b:53:de'/>
      <source bridge='br0'/>
      <model type='rtl8139'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
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
    <sound model='ich6'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </sound>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </memballoon>
  </devices>
</domain>
+++

/etc/hosts in both nodes must have this lines:
+++
10.42.84.2	openstack-controller	controller	openstack-vcenter	vcenter	openstack-
storage	storage	openstack-network	network
10.42.84.1	openstack-compute	compute
+++
