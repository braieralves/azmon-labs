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
  default     = "vmss_subnet"
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


variable "ubuntu_vm_size" {
  description = "Size of the Ubuntu VM"
  type        = string
  default     = "Standard_B2s"
}

variable "ubuntu_admin_password" {
  description = "Admin password for the Ubuntu VM"
  type        = string
  default     = "P@ssw0rd123!"  # Default for labs; consider using environment variables for production
  sensitive   = true
}


# Windows VM Configuration
variable "windows_vm_name" {
  description = "Name of the Windows Virtual Machine"
  type        = string
  default     = "vm-windows-lab"
}

variable "windows_admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  default     = "adminuser"
}

variable "windows_admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  default     = "P@ssw0rd123!"  # Default for labs; consider using environment variables for production
  sensitive   = true
}

variable "windows_vm_size" {
  description = "Size of the Windows VM"
  type        = string
  default     = "Standard_B2s"
}

# Red Hat VM Configuration
variable "redhat_vm_name" {
  description = "Name of the Red Hat Virtual Machine"
  type        = string
  default     = "vm-redhat-lab"
}

variable "redhat_admin_username" {
  description = "Admin username for the Red Hat VM"
  type        = string
  default     = "azureuser"
}

variable "redhat_admin_password" {
  description = "Admin password for the Red Hat VM"
  type        = string
  default     = "P@ssw0rd123!"  # Default for labs; consider using environment variables for production
  sensitive   = true
}

variable "redhat_vm_size" {
  description = "Size of the Red Hat VM"
  type        = string
  default     = "Standard_B2s"
}


