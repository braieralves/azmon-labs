#!/bin/bash

# -----------------------------------------------------------------------------
# deploy-aks-managedsolutions.sh
# AKS and managed solutions deployment script for Azure monitoring lab
# 
# Usage: ./deploy-aks-managedsolutions.sh <RESOURCE_GROUP> <WORKSPACE_ID> <WORKSPACE_NAME>
# -----------------------------------------------------------------------------

set -e

# Check if required parameters are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <RESOURCE_GROUP> <WORKSPACE_ID> <WORKSPACE_NAME>"
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

# Display received parameters
echo "📋 Received parameters:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Workspace ID: $WORKSPACE_ID"
echo "  Workspace Name: $WORKSPACE_NAME"
echo ""

# Start AKS and managed solutions deployment
echo "🚀 Starting AKS and managed solutions deployment..."

# Example AKS deployment (customize as needed)
echo "🔧 Creating AKS cluster..."
AKS_CLUSTER_NAME="aks-azmon-lab"
AKS_NODE_COUNT=2
AKS_NODE_SIZE="Standard_B2s"

# Create AKS cluster with monitoring enabled
az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_CLUSTER_NAME" \
  --node-count $AKS_NODE_COUNT \
  --node-vm-size "$AKS_NODE_SIZE" \
  --enable-addons monitoring \
  --workspace-resource-id "$WORKSPACE_ID" \
  --generate-ssh-keys \
  --enable-managed-identity \
  --no-wait

echo "✅ AKS cluster creation initiated (running in background)"

# Enable Container Insights solution
echo "🔧 Enabling Container Insights solution..."
az monitor log-analytics solution create \
  --resource-group "$RESOURCE_GROUP" \
  --solution-type "ContainerInsights" \
  --workspace "$WORKSPACE_NAME"

echo "✅ Container Insights solution enabled"

# Enable other monitoring solutions
echo "🔧 Enabling additional monitoring solutions..."

# Security Center solution
az monitor log-analytics solution create \
  --resource-group "$RESOURCE_GROUP" \
  --solution-type "Security" \
  --workspace "$WORKSPACE_NAME" || echo "Security solution may already exist"

# Updates solution
az monitor log-analytics solution create \
  --resource-group "$RESOURCE_GROUP" \
  --solution-type "Updates" \
  --workspace "$WORKSPACE_NAME" || echo "Updates solution may already exist"

echo "✅ Additional monitoring solutions configured"

# Wait for AKS cluster to be ready
echo "⏳ Waiting for AKS cluster to be ready..."
az aks wait \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_CLUSTER_NAME" \
  --created \
  --timeout 600

echo "✅ AKS cluster is ready"

# Get AKS credentials
echo "🔑 Getting AKS credentials..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_CLUSTER_NAME" \
  --overwrite-existing

echo "✅ AKS credentials configured"

echo "🎉 AKS and managed solutions deployment completed successfully!"
echo ""
echo "📋 Resources Created:"
echo "  - AKS Cluster: $AKS_CLUSTER_NAME"
echo "  - Container Insights solution enabled"
echo "  - Additional monitoring solutions configured"
echo "  - Log Analytics workspace integration: $WORKSPACE_NAME"
echo ""
echo "🔧 Next Steps:"
echo "  - Deploy applications to AKS cluster"
echo "  - Configure additional monitoring as needed"
echo "  - Access monitoring data in Log Analytics workspace"