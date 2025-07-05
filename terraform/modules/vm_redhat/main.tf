resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false  # Allow password authentication
  computer_name                   = var.computer_name != null ? var.computer_name : var.vm_name
  custom_data                     = var.custom_data
  network_interface_ids           = [var.nic_id]

  # Patch management
  patch_mode                  = var.patch_mode
  provision_vm_agent         = true
  allow_extension_operations = true

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb        = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = var.redhat_sku
    version   = var.redhat_version
  }

  tags = var.tags
}

# Azure Monitor Agent Extension for Red Hat VM
resource "azurerm_virtual_machine_extension" "ama_linux" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  settings = jsonencode({
    workspaceId = var.workspace_id
  })

  tags = var.tags
}
