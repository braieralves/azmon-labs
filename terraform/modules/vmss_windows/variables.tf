# vmss_windows/variables.tf
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "backend_pool_id" {
  type = string
}

variable "workspace_id" {
  type = string
}

variable "vmss_name" {
  type    = string
  default = "vmss-tjf"
}

variable "admin_username" {
  description = "Admin username for the VMSS instances"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VMSS instances"
  type        = string
  default     = "P@ssw0rd123!"  # You can override it securely via tfvars or environment variable
}
