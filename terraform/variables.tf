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
