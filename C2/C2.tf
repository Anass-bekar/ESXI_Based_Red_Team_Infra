#Provider configuration
provider "vsphere" {
  vim_keep_alive = 30
  user           = "your User@your vsphere domain"
  password       = "your vsphere password"
  vsphere_server = "vsphere ip address"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
#DC name
data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}
#Pool name
data "vsphere_resource_pool" "pool" {
  name          = "pool1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Datastore name
data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#network name
data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "host" {
  name          = "your Esxi host"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Starting instance
resource "vsphere_virtual_machine" "c2" {
  #Instance Info
  name             = "c2"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  datacenter_id = data.vsphere_datacenter.dc.id
  num_cpus = 1
  memory   = 2048
  wait_for_guest_net_timeout = -1
  #Os name
  guest_id = "ubuntu64Guest"

    ovf_deploy {
    local_ovf_path       = "C:\\Path to your ovf\\ubun.ovf"
    disk_provisioning = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
        "VM Network" = data.vsphere_network.network.id
    }
  }
  #Disk info
   disk {
    #label  = "disk-2"
    attach = "true"
    #path to disk
    path = "[datastore1] vmdks\\disk-1.vmdk"
    datastore_id     = data.vsphere_datastore.datastore.id
  }
  #network interface
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  linux_options {
    host_name = "c2"
    domain    = "c2.local"
  }
  #ssh parameters
    connection {
      type = "ssh"
      user = "root"
      private_key = file("C:\\Users\\PC\\.ssh\\id_rsa")
      host = "192.168.9.245"
    }
    provisioner "file" {
    source      = "c2.ovpn"
    destination = "/tmp/c2.ovpn"
  }
    provisioner "file" {
    source      = "c2Conf.sh"
    destination = "/tmp/c2Conf.sh"
  }

  provisioner "remote-exec" {
    inline = [
          "chmod +x /tmp/c2Conf.sh",
          "/bin/bash /tmp/c2Conf.sh",
    ]
  }
  provisioner "local-exec" {
   command="echo \"192.168.9.249 c2.local\" >> C:\\Windows\\System32\\drivers\\etc\\hosts"
  }
}
