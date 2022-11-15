resource "proxmox_vm_qemu" "worker" {
  count = "${var.wn_count}"
  
  name        = "kwn-${count.index}"
  vmid        = "${500 + count.index}"
  target_node = "pve-01"
  desc        = "Kubernetes worker nodes."
  
  clone = "debian-template"
  onboot = true

  cpu      = "host"
  cores    = 2
  sockets  = 1
  memory   = 2048
  bootdisk = "scsi0"

  network {
    bridge = "vmbr0"
    model = "virtio"
    firewall = true
  }
  
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "local"
  ciuser                  = "root"
  sshkeys                 = "${var.sshkeys}"
  nameserver              = "${var.nameserver}"
  ipconfig0               = "ip=${var.network_prefix}${var.wn_starting_ip + count.index}/24,gw=${var.gateway}"
  
  provisioner "remote-exec" {
    connection {
      host        = "${var.network_prefix}${var.wn_starting_ip + count.index}"
      type        = "ssh"
      user        = "root"
      private_key = file(var.priv_key)
    }

    inline = [
      "sleep 30",
      "echo Done!"
    ]
  }

  provisioner "local-exec" {
    when = create
    
    environment = {
      VMID       = "${self.vmid}"
      PVE_IP     = "${var.proxmox_ip}"
      VM_IP      = "${var.network_prefix}${var.wn_starting_ip + count.index}"
    }
    
    command = <<EOT
      cd ansible/
      ansible-playbook -i $PVE_IP, playbooks/pve_vm_conf.yml --extra-vars="vmid=$VMID vm_type=worker"
      ansible-playbook playbooks/inventory.yml --extra-vars="host_type=new_worker host_ip=$VM_IP host_state=present"
    EOT
  }

  lifecycle {
    ignore_changes = [
      disk,
      agent
    ]
  }

  depends_on = [
    proxmox_vm_qemu.storage,
    proxmox_vm_qemu.endpoint,
    proxmox_vm_qemu.control_plane
  ]
}

resource "null_resource" "worker-pre-destroy" {
  count = "${var.wn_count}"

  triggers = {
    vmid           = "${proxmox_vm_qemu.worker[count.index].vmid}"
    name           = "${proxmox_vm_qemu.worker[count.index].name}"
    storage_ip     = "${var.storage_ip}"
    endpoint_ip    = "${var.endpoint_ip}"
    network_prefix = "${var.network_prefix}"
    wn_starting_ip = "${var.wn_starting_ip}"
  }
  
  provisioner "local-exec" {
    when = destroy

    environment = {
      NAME        = "${self.triggers.name}"
      STORAGE_IP  = "${self.triggers.storage_ip}"
      ENDPOINT_IP = "${self.triggers.endpoint_ip}"
      VM_IP       = "${self.triggers.network_prefix}${self.triggers.wn_starting_ip + count.index}"
    }

    command = <<EOT
        cd ansible/
        ansible-playbook -i $ENDPOINT_IP, playbooks/endpoint_hosts.yml --extra-vars="host_ip=$VM_IP host_type=worker host_name=$NAME host_state=absent"
        kubectl drain $NAME --ignore-daemonsets --delete-emptydir-data
        kubectl delete node $NAME
        ansible-playbook -i $STORAGE_IP, playbooks/storage_hosts.yml --extra-vars="host_ip=$VM_IP host_type=k8s host_state=absent"
        ansible-playbook playbooks/inventory.yml --extra-vars="host_type=worker host_ip=$VM_IP host_state=absent"
    EOT
  }
}