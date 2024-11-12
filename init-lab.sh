#!/bin/bash

# Ask for user input
echo "Enter the name for the Azure resource group:"
read RESOURCE_GROUP

echo "Enter the Azure location (e.g., East US):"
read LOCATION

echo "Enter the name for the Log Analytics Workspace:"
read WORKSPACE_NAME

# Create terraform.tfvars file with user input
cat <<EOF > terraform.tfvars
resource_group_name = "$RESOURCE_GROUP"
location            = "$LOCATION"
workspace_name      = "$WORKSPACE_NAME"
EOF

# Terraform configuration
cat <<EOF > main.tf
# Provider configuration for Azure
provider "azurerm" {
  features {}
}

# Resource group creation
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace creation
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"  # Billing tier (adjust as necessary)
  retention_in_days   = 30           # Data retention period in days
}
EOF

# Define variables for the Terraform configuration
cat <<EOF > variables.tf
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}
EOF

# Run Terraform commands
terraform init
terraform apply -auto-approve
