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
    echo "  RESOURCE_GROUP  - Name of the Azure resource group"
    echo "  WORKSPACE_ID    - Full resource ID of the Log Analytics workspace"
    echo "  WORKSPACE_NAME  - Name of the Log Analytics workspace"
    echo "  AKS_CLUSTER     - Name of the the AKS cluster"
    echo "  MANAGED_GRAFANA - Name of the the Managed Grafana"
    echo "  PROM_NAME       - Name of the Azure Monitor Workspace(Managed Prometheus)"
    exit 1
fi
#
#echo "Choose a name for your AKS cluster:"
#read AKS_CLUSTER
#
#echo "Choose a name for your Managed Prometheus:"
#read PROM_NAME
#
#echo "Choose a name for your Managed Grafana:"
#read MANAGED_GRAFANA
#

# Assign input parameters to variables
RESOURCE_GROUP="$1"
WORKSPACE_ID="$2"
WORKSPACE_NAME="$3"
AKS_CLUSTER="$4"
MANAGED_GRAFANA="$5"
PROM_NAME="$6"

echo "========================================"
echo "Starting AKS and Managed Solutions Deployment"
echo "========================================"
echo "Resource Group: $RESOURCE_GROUP"
echo "Log Analytics Workspace: $WORKSPACE_NAME"
echo "AKS Cluster: $AKS_CLUSTER"
echo "Managed Grafana: $MANAGED_GRAFANA"
echo "Managed Prometheus: $PROM_NAME"
echo "========================================"
echo ""

# Avoid extension installing confirmation
echo "Configuring Azure CLI extensions..."
az config set extension.use_dynamic_install=yes_without_prompt
#
# Create a Managed Prometheus (Azure monitor Workspace) in the New Resource Group
echo ""
echo "Step 1/4: Creating Managed Prometheus (Azure Monitor Workspace)..."
echo "Name: $PROM_NAME"
az monitor account create -g $1 -n $6 
echo "✓ Managed Prometheus created successfully" 
#
# Create a Managed Grafana in the New Resource Group
echo ""
echo "Step 2/4: Creating Managed Grafana..."
echo "Name: $MANAGED_GRAFANA"
az grafana create --resource-group $1 --name $5
echo "✓ Managed Grafana created successfully"
#
# Create an AKS Cluster in the New Resource Group with Monitoring addon Enabled
#
echo ""
echo "Step 3/4: Creating AKS cluster with monitoring enabled..."
echo "Cluster name: $AKS_CLUSTER"
echo "Node count: 2"
echo "Retrieving Log Analytics workspace ID..."
# The first command retrieves the ID of a specified Log Analytics workspace and stores it in the workspaceId variable.
workspaceId=$(az monitor log-analytics workspace show --resource-group $1 --workspace-name $3 --query id -o tsv)
echo "Log Analytics workspace ID: $workspaceId"
#
echo "Creating AKS cluster (this may take several minutes)..."
# The second command creates an AKS cluster with monitoring enabled, linking it to the Log Analytics workspace using the retrieved ID. This setup integrates Azure Monitor for containers with the AKS cluster.
az aks create -g $1 -n $4 --node-count 2 --enable-addons monitoring --generate-ssh-keys --workspace-resource-id $workspaceId
echo "✓ AKS cluster created successfully"
#
echo ""
echo "Step 4/4: Configuring AKS cluster with Managed Prometheus and Grafana..."
echo "Retrieving Managed Prometheus ID..."
# The third command retrieves the ID of a specified Managed Prometheus and stores it in the workspaceId variable.
prometheusId=$(az monitor account show --resource-group $1 -n $6 --query id -o tsv)
echo "Prometheus ID: $prometheusId"
#
echo "Retrieving Managed Grafana ID..."
# The fourth command retrieves the ID of a specified Managed Grafana and stores it in the workspaceId variable.
grafanaId=$(az grafana show --resource-group $1 -n $5 --query id -o tsv)
echo "Grafana ID: $grafanaId"
#
echo "Updating AKS cluster to enable Azure Monitor metrics..."
# The fifth update the AKS cluster to be monitored by Managed Prometheus and Managed Grafana
az aks update --enable-azure-monitor-metrics -n $4 -g $1 --azure-monitor-workspace-resource-id $prometheusId --grafana-resource-id $grafanaId
echo "✓ AKS cluster updated with Managed Prometheus and Grafana integration"
#
echo ""
echo "========================================"
echo "✓ AKS and Managed Solutions Deployment Complete!"
echo "========================================"
echo "Resources created:"
echo "  • AKS Cluster: $AKS_CLUSTER"
echo "  • Managed Prometheus: $PROM_NAME"
echo "  • Managed Grafana: $MANAGED_GRAFANA"
echo "  • Log Analytics integration enabled"
echo "========================================"










