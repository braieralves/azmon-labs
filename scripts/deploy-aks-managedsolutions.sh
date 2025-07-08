#!/bin/bash

# -----------------------------------------------------------------------------
# deploy-aks-managedsolutions.sh
# AKS and managed solutions deployment script for Azure monitoring lab
# 
# Usage: ./deploy-aks-managedsolutions.sh <RESOURCE_GROUP> <WORKSPACE_ID> <WORKSPACE_NAME> <AKS_CLUSTER> <MANAGED_GRAFANA> <PROM_NAME>
# -----------------------------------------------------------------------------

set -e

# Check if required parameters are provided
if [ $# -ne 6 ]; then
    echo "Usage: $0 <RESOURCE_GROUP> <WORKSPACE_ID> <WORKSPACE_NAME> <AKS_CLUSTER> <MANAGED_GRAFANA> <PROM_NAME>"
    echo ""
    echo "Parameters:"
    echo "  RESOURCE_GROUP - Name of the Azure resource group"
    echo "  WORKSPACE_ID   - Full resource ID of the Log Analytics workspace"
    echo "  WORKSPACE_NAME - Name of the Log Analytics workspace"
    exit 1
fi

# Assign input parameters to variables
RESOURCE_GROUP="$1"
WORKSPACE_ID="$2"
WORKSPACE_NAME="$3"
AKS_CLUSTER_NAME="$4"
MANAGED_GRAFANA_NAME="$5"
PROM_NAME="$6"

# Display received parameters
echo "📋 Received parameters:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Workspace ID: $WORKSPACE_ID"
echo "  Workspace Name: $WORKSPACE_NAME"
echo ""

# Start AKS and managed solutions deployment
echo "🚀 Starting AKS and managed solutions deployment..."


# Create a Managed Prometheus (Azure monitor Workspace) in the New Resource Group
az monitor account create -g $1 -n $6 --location eastus2
#
# Create a Managed Grafana in the New Resource Group
az grafana create --resource-group $1 --workspace-name $5--sku-tier Standard --public-network-access Enabled --location eastus2
#
# Create an AKS Cluster in the New Resource Group with Monitoring addon Enabled
#
# The first command retrieves the ID of a specified Log Analytics workspace and stores it in the workspaceId variable.
workspaceId=$(az monitor log-analytics workspace show --resource-group $1 --workspace-name $3 --query id -o tsv)
#
# The second command creates an AKS cluster with monitoring enabled, linking it to the Log Analytics workspace using the retrieved ID. This setup integrates Azure Monitor for containers with the AKS cluster.
az aks create -g $1 -n $4 --node-count 2 --enable-addons monitoring --generate-ssh-keys --workspace-resource-id $workspaceId
#
# The third command retrieves the ID of a specified Managed Prometheus and stores it in the workspaceId variable.
prometheusId=$(az monitor account show --resource-group $1 -n $6 --query id -o tsv)
#
# The fourth command retrieves the ID of a specified Managed Grafana and stores it in the workspaceId variable.
grafanaId=$(az grafana show --resource-group $1 -n $5 --query id -o tsv)
#
# The fifth update the AKS cluster to be monitored by Managed Prometheus and Managed Grafana
az aks update --enable-azure-monitor-metrics -n $4 -g $1 --azure-monitor-workspace-resource-id $prometheusId --grafana-resource-id $grafanaId
