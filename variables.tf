variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
    sensitive = true
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_ip" {
  type = string
}

variable "priv_key" {
  type = string
  sensitive = true
  description = "Path to private ssh key file to use for connecting to remote VMs."
}

variable "sshkeys" {
  type = string
  sensitive = true
  description = "SSH key of local host, i.e. the host which connects to VMs using Ansible."
}

variable "storage_disk_size" {
  type = string
  description = "Disk size for the storage server. Can be increased, but not decreased."
}
variable "cp_count" {
  type = number
  description = "Desired number of K8s control planes."
}

variable "wn_count" {
  type = number
  description = "Desired number of K8s worker nodes."
}

variable "network_prefix" {
  type = string
  description = "Network prefix which will be used when determining IP addresses of K8s control planes and workers."
}
variable "subnet" {
  type = number
  description = "Local subnet to which VM IP addresses are assigned."
}

variable "nameserver" {
  type = string
  description = "DNS server to use on all VMs."
}

variable "gateway" {
  type = string
  description = "Local IP address of gateway for all VMs."
}

variable "storage_ip" {
  type = string
  description = "Static local IP address for the storage server."
}

variable "endpoint_ip" {
  type = string
  description = "Static local IP address for the endpoint server."
}

variable "cp_starting_ip" {
  type = number
  description = "Starting static local IP address for K8s control plane servers."
}

variable "wn_starting_ip" {
  type = number
  description = "Starting static local IP address for K8s worker nodes."
}