#!/bin/bash

# deploy-monitoring.sh
# Initial deployment script for the Azure monitoring lab

set -e

echo "🚀 Starting Azure Monitoring Lab Deployment..."

# Change to the project directory
cd ~/azmon-labs

# Initialize and apply Terraform
echo "📦 Initializing Terraform..."
cd terraform
terraform init

echo "📋 Planning Terraform deployment..."
terraform plan -var-file="environments/default/terraform.tfvars" -out=tfplan

echo "🔧 Applying Terraform configuration..."
terraform apply tfplan

echo "💾 Saving Terraform outputs..."
terraform output -json > tf_outputs.json

echo "✅ Terraform deployment completed!"

# Load variables from the Terraform output JSON
cd ~
PWD=$(pwd)
TF_OUTPUTS="$PWD/azmon-labs/terraform/tf_outputs.json"


# Checks if the Terraform outputs file exists and loads the necessary variables.
if [ ! -f "$TF_OUTPUTS" ]; then
  echo "ERROR: Terraform outputs file not found: $TF_OUTPUTS"
  exit 1
fi


RESOURCE_GROUP=$(jq -r '.resource_group_name.value' "$TF_OUTPUTS")
WORKSPACE_ID=$(jq -r '.log_analytics_workspace_id.value' "$TF_OUTPUTS")
WORKSPACE_NAME=$(jq -r '.log_analytics_workspace_name.value' "$TF_OUTPUTS")
USER_TIMEZONE=$(jq -r '.user_timezone.value' "$TF_OUTPUTS")
REDHAT_VM_NAME=$(jq -r '.redhat_vm_name.value' "$TF_OUTPUTS")
UBUNTU_VM_NAME=$(jq -r '.ubuntu_vm_name.value' "$TF_OUTPUTS")
WINDOWS_VM_NAME=$(jq -r '.windows_vm_name.value' "$TF_OUTPUTS")
VMSS_NAME=$(jq -r '.vmss_name.value' "$TF_OUTPUTS")
REDHAT_PRIVATE_IP=$(jq -r '.redhat_vm_private_ip.value' "$TF_OUTPUTS")

# Run deployment scripts based on az cli
# This section will create aks, prometheus, grafana, and other resources as needed
echo "🔄 Running aks, azmon workspace configuration..."
cd ~/azmon-labs/scripts
chmod +x deploy-aks-managedsolutions.sh
#./deploy-aks-managedsolutions.sh "$RESOURCE_GROUP" "$WORKSPACE_ID" "$WORKSPACE_NAME"

# Run post-deployment tasks
echo "🔄 Running post-deployment configuration..."
cd ~/azmon-labs/scripts
chmod +x deploy-end-tasks.sh
./deploy-end-tasks.sh "$RESOURCE_GROUP" "$REDHAT_VM_NAME" "$UBUNTU_VM_NAME" "$WINDOWS_VM_NAME" "$VMSS_NAME" "$REDHAT_PRIVATE_IP" "$USER_TIMEZONE"

echo "🎉 Azure Monitoring Lab deployment completed successfully!"
echo ""
echo "📋 Resources Created:"
echo "  - Resource Group with Log Analytics Workspace"
echo "  - Windows Virtual Machine Scale Set (VMSS)"
echo "  - Ubuntu VM (with Syslog DCR)"
echo "  - Windows VM"
echo "  - Red Hat VM (with CEF DCR for Sentinel)"
echo "  - Network Security Groups and Public IPs"
echo "  - Data Collection Rules (DCRs)"
echo "  - Azure Monitor Agent (AMA) on all VMs"
echo "  - Auto-shutdown configured for all VMs and VMSS"
echo ""
echo "🔧 Post-Deployment Features:"
echo "  - AMA Forwarder installed on Red Hat VM"
echo "  - CEF Simulator installed on Ubuntu VM"
echo "  - Auto-shutdown scheduled for 7:00 PM (detected timezone)"
echo "  - Monitoring and log forwarding configured"
echo ""
echo "Access your resources in the Azure portal and configure additional monitoring as needed."
