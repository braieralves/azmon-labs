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
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type
    disk_size_gb          = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.ubuntu_sku
    version   = var.ubuntu_version
  }

  tags = var.tags
}