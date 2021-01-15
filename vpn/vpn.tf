provider "vsphere" {
  vim_keep_alive = 30
  user           = "vsphere user@vsphere domain"
  password       = "password"
  vsphere_server = "vsphere ip address"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

data "vsphere_resource_pool" "pool" {
  name          = "pool1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "host" {
  name          = "esxi IP address"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#starting instance
resource "vsphere_virtual_machine" "vm" {
  #Instance specs
  name             = "vpn"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  datacenter_id = data.vsphere_datacenter.dc.id
  num_cpus = 1
  memory   = 2048
  wait_for_guest_net_timeout = -1
  guest_id = "ubuntu64Guest"
  #ovf file path
    ovf_deploy {
    local_ovf_path       = "C:\\Users\\path to ovf\\ubun.ovf"
    #local_ovf_path       = "[datastore1] ISO\\ubun.ovf"
    disk_provisioning = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
        "VM Network" = data.vsphere_network.network.id
    }
  }
  #disk path
   disk {
    #label  = "disk-2"
    attach = "true"
    path = "[datastore1] vmdks\\disk-1.vmdk"
    datastore_id     = data.vsphere_datastore.datastore.id
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  linux_options {
    host_name = "vpn"
    domain    = "vpn.local"
  }
  #ssh parameters
      provisioner "remote-exec" {
         connection {
      type = "ssh"
      user = "root"
      private_key = file("C:\\path to ssh\\.ssh\\id_rsa")
      host = "192.168.9.245"
    }
    inline = [
          "sed -i '6s/.*/       - 192.168.9.243\\/24/' /etc/netplan/00-installer-config.yaml",
          "netplan apply"
    ]
  }
    connection {
      type = "ssh"
      user = "root"
      private_key = file("C:\\path tossh\\.ssh\\id_rsa")
      host = "192.168.9.243"
    }
    provisioner "file" {
    source      = "openvpn-install.sh"
    destination = "/tmp/openvpn-install.sh"
  }
    provisioner "file" {
    source      = "config.sh"
    destination = "/tmp/config.sh"
  }
  provisioner "remote-exec" {
    inline = [
          "chmod +x /tmp/config.sh",
          "/bin/bash /tmp/config.sh",
    ]
  }
   provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@192.168.9.243:/root/c2.ovpn ../C2"
  }
   provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@192.168.9.243:/root/redirect.ovpn ."
  }
    provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@192.168.9.243:/root/client.ovpn ../redirector"
  }
    provisioner "local-exec" {
   command="echo \"192.168.9.243 vpn.local\" >> C:\\Windows\\System32\\drivers\\etc\\hosts"
  }
}
