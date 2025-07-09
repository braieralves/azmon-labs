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

# Avoid extension installing confirmation
az config set extension.use_dynamic_install=yes_without_prompt
#
# Create a Managed Prometheus (Azure monitor Workspace) in the New Resource Group
az monitor account create -g $1 -n $6 
#
# Create a Managed Grafana in the New Resource Group
az grafana create --resource-group $1 --name $5
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
#










