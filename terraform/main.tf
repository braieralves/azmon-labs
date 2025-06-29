terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
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

/*
module "network" {
  source              = "./modules/network"
  resource_group_name = module.resource_group.name
  location            = var.location
}

module "vmss_windows" {
  source              = "./modules/vmss_windows"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_id
  backend_pool_id     = module.network.backend_pool_id
  workspace_id        = module.log_analytics.workspace_id
}

module "dcr" {
  source              = "./modules/dcr"
  resource_group_name = module.resource_group.name
  location            = var.location
  workspace_id        = module.log_analytics.workspace_id
  target_resource_id  = module.vmss_windows.vmss_id
}
*/