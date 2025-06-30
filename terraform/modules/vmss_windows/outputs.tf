# vmss_windows/outputs.tf
output "vmss_id" {
  value = azurerm_windows_virtual_machine_scale_set.vmss.id
}