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