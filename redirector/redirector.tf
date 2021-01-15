#provider configuration
provider "vsphere" {
  vim_keep_alive = 30
  user           = "vsphere user@vsphere domain"
  password       = "vsphere password"
  vsphere_server = "vsphere IP"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}
#vsphere datacenter
data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}
#vsphere pool
data "vsphere_resource_pool" "pool" {
  name          = "pool1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#vsphere datastore
data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#vsphere network
data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "Esxi IP"
  datacenter_id = data.vsphere_datacenter.dc.id
}
#Instance Initialization
resource "vsphere_virtual_machine" "redirect" {
  #Instance details
  name             = "redirector"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  datacenter_id = data.vsphere_datacenter.dc.id
  num_cpus = 1
  memory   = 2048
  wait_for_guest_net_timeout = -1
  guest_id = "ubuntu64Guest"
  #path to ovf file
    ovf_deploy {
    local_ovf_path       = "C:\\path to ovf\\ubun.ovf"
    #local_ovf_path       = "[datastore1] ISO\\ubun.ovf"
    disk_provisioning = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
        "VM Network" = data.vsphere_network.network.id
    }
  }
  #path to disk
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
    host_name = "redirect"
    domain    = "redirect.local"
  }
    connection {
      type = "ssh"
      user = "root"
      private_key = file("C:\\path to key\\.ssh\\id_rsa")
      host = "192.168.9.245"
    }
    provisioner "file" {
    source      = "redirect.ovpn"
    destination = "/tmp/redirect.ovpn"
  }
    provisioner "file" {
    source      = "redirector.sh"
    destination = "/tmp/redirector.sh"
  }
    provisioner "file" {
    source      = "nginx.conf"
    destination = "/tmp/nginx.conf"
  }
  provisioner "remote-exec" {
    inline = [
          "chmod +x /tmp/redirector.sh",
          "/bin/bash /tmp/redirector.sh",
    ]
  }
  provisioner "local-exec" {
   command="echo \"192.168.9.245 redirect.local\" >> C:\\Windows\\System32\\drivers\\etc\\hosts"
  }
}
