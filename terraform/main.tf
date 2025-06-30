terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}


module "resource_group" {
  source              = "./modules/resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_name      = var.workspace_name
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=json"
}

locals {
  my_ip = jsondecode(data.http.my_public_ip.response_body).ip
}

module "network" {
  source              = "./modules/network"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_name         = "vmss_subnet"  # <-- explicitly assign her
  my_ip               = local.my_ip
}



module "vmss_windows" {
  source              = "./modules/vmss_windows"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_id
  backend_pool_id     = module.network.backend_pool_id
  workspace_id        = module.log_analytics.workspace_id
  vmss_name           = var.vmss_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password
}


module "dcr" {
  source              = "./modules/dcr"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.log_analytics.workspace_id
  target_resource_id  = module.vmss_windows.vmss_id
}

# Network Interface for Ubuntu VM
resource "azurerm_public_ip" "ubuntu_vm_public_ip" {
  name                = "${var.ubuntu_vm_name}-public-ip"
  location            = var.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Ubuntu VM"
  }
}

resource "azurerm_network_interface" "ubuntu_vm_nic" {
  name                = "${var.ubuntu_vm_name}-nic"
  location            = var.location
  resource_group_name = module.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu_vm_public_ip.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Ubuntu VM"
  }
}

# Network Security Group for Ubuntu VM (SSH access)
resource "azurerm_network_security_group" "ubuntu_vm_nsg" {
  name                = "${var.ubuntu_vm_name}-nsg"
  location            = var.location
  resource_group_name = module.resource_group.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_http"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_https"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Ubuntu VM"
  }
}

resource "azurerm_network_interface_security_group_association" "ubuntu_vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.ubuntu_vm_nic.id
  network_security_group_id = azurerm_network_security_group.ubuntu_vm_nsg.id
}

# Ubuntu VM Module
module "vm_ubuntu" {
  source              = "./modules/vm_ubuntu"
  vm_name             = var.ubuntu_vm_name
  resource_group_name = module.resource_group.name
  location            = var.location
  vm_size             = var.ubuntu_vm_size
  admin_username      = var.ubuntu_admin_username
  admin_password      = var.ubuntu_admin_password
  nic_id              = azurerm_network_interface.ubuntu_vm_nic.id

  tags = {
    Environment = "Lab"
    Purpose     = "Ubuntu VM"
    Project     = "Azure Monitoring"
  }
}

