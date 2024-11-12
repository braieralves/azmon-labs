#!/bin/bash

# Prompt for user inputs
echo "Enter the name for the Azure resource group:"
read RESOURCE_GROUP

echo "Enter the Azure location (e.g., East US):"
read LOCATION

echo "Enter the name for the Log Analytics Workspace:"
read WORKSPACE_NAME

echo "Enter the AKS cluster name:"
read AKS_NAME

echo "Enter the Managed Prometheus workspace name:"
read PROMETHEUS_NAME

echo "Enter the Managed Grafana name:"
read GRAFANA_NAME

# Get Azure Subscription ID from Azure Cloud Shell environment
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Check if subscription_id was retrieved successfully
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Error: Could not retrieve Azure subscription ID."
    exit 1
fi

# Create terraform.tfvars with user inputs
cat <<EOF > terraform.tfvars
resource_group_name = "$RESOURCE_GROUP"
location            = "$LOCATION"
workspace_name      = "$WORKSPACE_NAME"
aks_name            = "$AKS_NAME"
prometheus_name     = "$PROMETHEUS_NAME"
grafana_name        = "$GRAFANA_NAME"
EOF

# Create provider.tf with subscription_id
cat <<EOF > provider.tf
provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
}
EOF

# Define Terraform main configuration
cat <<EOF > main.tf
# Resource group creation
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
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

variable "aks_name" {
  description = "Name of the AKS Cluster"
  type        = string
}

variable "prometheus_name" {
  description = "Name of the Managed Prometheus workspace"
  type        = string
}

variable "grafana_name" {
  description = "Name of the Managed Grafana instance"
  type        = string
}
EOF

# Run Terraform commands
terraform init
terraform apply -auto-approve
