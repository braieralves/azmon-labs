# terraform/outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.name
}

output "log_analytics_workspace_id" {
  description = "The full resource ID of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_name
}

# VM Names
output "ubuntu_vm_name" {
  description = "The name of the Ubuntu Virtual Machine"
  value       = module.vm_ubuntu.vm_name
}

/*
output "windows_vm_name" {
  description = "The name of the Windows Virtual Machine"
  value       = module.vm_windows.vm_name
}

*/
output "redhat_vm_name" {
  description = "The name of the Red Hat Virtual Machine"
  value       = module.vm_redhat.vm_name
}

