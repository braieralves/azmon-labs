#!/bin/bash

# Function to register a provider if not already registered
register_provider() {
  local provider_namespace=$1
  local registration_status

  # Check the current registration status of the provider
  registration_status=$(az provider show --namespace "$provider_namespace" --query "registrationState" -o tsv)

  if [ "$registration_status" != "Registered" ]; then
    echo "Registering $provider_namespace provider..."
    az provider register --namespace "$provider_namespace"

    # Wait until the provider is registered
    while [ "$(az provider show --namespace "$provider_namespace" --query "registrationState" -o tsv)" != "Registered" ]; do
      echo "Waiting for $provider_namespace provider registration..."
      sleep 5
    done
    echo "$provider_namespace provider registered successfully."
  else
    echo "$provider_namespace provider is already registered."
  fi
}

# Register required providers
register_provider "Microsoft.Insights"
register_provider "Microsoft.OperationalInsights"
register_provider "Microsoft.SecurityInsights"
register_provider "Microsoft.Monitor"
register_provider "Microsoft.Dashboard"

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

# Log Analytics Workspace creation
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Azure Monitor Workspace (Managed Prometheus) creation
resource "azurerm_monitor_workspace" "prometheus" {
  name                = var.prometheus_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Managed Grafana creation
resource "azurerm_dashboard_grafana" "grafana" {
  name                = var.grafana_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  grafana_major_version = 10
  sku            = "Standard"
  public_network_access_enabled = true
}

# AKS Cluster creation with monitoring enabled
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akslab"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "null_resource" "aks_monitor_update" {
  provisioner "local-exec" {
    command = <<EOT
      # Retrieve required IDs
      workspaceId=$(az monitor log-analytics workspace show --resource-group ${azurerm_resource_group.rg.name} --workspace-name ${azurerm_log_analytics_workspace.law.name} --query id -o tsv)
      prometheusId=$(az monitor account show --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_monitor_workspace.prometheus.name} --query id -o tsv)
      grafanaId=$(az grafana show --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_dashboard_grafana.grafana.name} --query id -o tsv)

      # Update AKS for Prometheus and Grafana
      az aks update --enable-azure-monitor-metrics --name ${azurerm_kubernetes_cluster.aks.name} --resource-group ${azurerm_resource_group.rg.name} --azure-monitor-workspace-resource-id $prometheusId --grafana-resource-id $grafanaId
    EOT
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
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
