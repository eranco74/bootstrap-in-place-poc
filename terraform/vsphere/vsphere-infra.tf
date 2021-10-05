# Getting vSphere infrastructure
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter_name
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "Resources"   # can be hardcoded for now
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}


# Uploading the embedded.iso file
resource "vsphere_file" "embedded_iso_upload" {
  datacenter       = data.vsphere_datacenter.dc.name
  datastore        = data.vsphere_datastore.datastore.name
  source_file      = "../../${var.sno_workdir}/embedded.iso"
  destination_file = "${var.sno_vm_name}-artifacts/embedded.iso"
}


# Instantiating SNO cluster
resource "vsphere_virtual_machine" "sno" {
  name             = var.sno_vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  memory            = 32768    # 32 GB
  num_cpus          = 8
  guest_id          = "other4xLinux64Guest"
  nested_hv_enabled = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "sno-disk"
    size  = 120
  }

  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = vsphere_file.embedded_iso_upload.destination_file
  }

  depends_on = [vsphere_file.embedded_iso_upload]
}
