# ansible vxlan configuration
Ansible playbooks to create a openstack vcenter.

Liberty Release

Steps:
* Install compute and controller node (Ubuntu 14.04) with two plain network interfaces. Configure eth0 as management network and eth1 as external network as is:
```
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.42.84.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

auto eth1
iface eth1 inet manual
    up ip link set dev $IFACE up
    down ip link set dev $IFACE down
    bridge_ports none
    bridge_maxwait 0
```
* Install git and ansible on controller node
* In controller machine generate ssh key with "ssh-keygen"
* Copy .ssh/id_rsa.pub key to root@compute:.ssh/authorized_keys and root@controller.ssh/authorized_keys
* Clone repository with "git clone https://github.com/elmanytas/ansible-openstack-vcenter.git"
* Change vars in etc_ansible/group_vars/all/vars_file.yml
* Configure hosts in etc_ansible/hosts
* Run ansible-playbook -i hosts site.yml

* After finishing the ansible playbook remember to create initial networks: http://docs.openstack.org/liberty/install-guide-ubuntu/launch-instance.html#create-virtual-networks

# WARNING!!!!!!
Today bridges created with "brctl" on the fly does not work with kvm machines.

Workaround: Create a virtual machine (it will fail) and run "brctl show" in compute node:
```
sistemas@os-vcenter:~$ brctl show
bridge name	bridge id		STP enabled	interfaces
brqc3331dfb-59		8000.a4badbf94dd5	no		eth1
							tap882a3ffd-60
sistemas@os-vcenter:~$
```
The bridge name is brqc3331dfb-59 so configure the same bridge in compute:/etc/network/interfaces
```
auto brqc3331dfb-59
iface brqc3331dfb-59 inet manual
	bridge_ports eth1
	bridge_stp off
```
And reboot.
