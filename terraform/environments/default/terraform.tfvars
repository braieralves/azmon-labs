# Default environment variables
# Core Configuration
resource_group_name = "rg-azmon-lab"
location            = "East US"
workspace_name      = "azmon-workspace"
subscription_id     = ""
user_timezone       = "1900"
aks_name            = "aks-azmon"
grafana_name        = "managed-gf"
prom_name           = "managed-pm"

# Network Configuration
subnet_name = "vmss_subnet"

# VMSS Configuration
vmss_name      = "vmss-windows-lab"
admin_username = "adminuser"
admin_password = "P@ssw0rd123!"

# Ubuntu VM Configuration
ubuntu_vm_name         = "vm-ubuntu-lab"
ubuntu_admin_username  = "azureuser"
ubuntu_vm_size         = "Standard_B2s"
ubuntu_admin_password  = "P@ssw0rd123!"

# Windows VM Configuration
windows_vm_name         = "vm-windows-lab"
windows_admin_username  = "adminuser"
windows_admin_password  = "P@ssw0rd123!"
windows_vm_size         = "Standard_B2s"

# Red Hat VM Configuration
redhat_vm_name         = "vm-redhat-lab"
redhat_admin_username  = "azureuser"
redhat_admin_password  = "P@ssw0rd123!"
redhat_vm_size         = "Standard_B2s"
