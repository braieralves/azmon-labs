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


