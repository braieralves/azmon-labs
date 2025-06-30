variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "workspace_name" {
  description = "Log Analytics Workspace name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
  default     = "vmss-tjf"  # or remove `default` if you want to require it in tfvars
}

variable "admin_username" {
  description = "Admin username for the VMSS"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VMSS"
  type        = string
  default     = "P@ssw0rd123!"  # for labs; consider using environment variables or secret management
}

# Ubuntu VM Configuration
variable "ubuntu_vm_name" {
  description = "Name of the Ubuntu Virtual Machine"
  type        = string
  default     = "vm-ubuntu-lab"
}

variable "ubuntu_admin_username" {
  description = "Admin username for the Ubuntu VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for Ubuntu VM authentication"
  type        = string
  # Example: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... or file("~/.ssh/id_rsa.pub")
}

variable "ubuntu_vm_size" {
  description = "Size of the Ubuntu VM"
  type        = string
  default     = "Standard_B2s"
}


