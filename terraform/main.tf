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
  subnet_name         = var.subnet_name
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

