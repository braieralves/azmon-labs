#!/bin/bash

# -----------------------------------------------------------------------------
# NOTE FOR USERS:
#
# This script collects Azure input values (e.g., resource group, region)
# to generate a local terraform.tfvars file for lab automation.
#
# ❗ No data is ever sent or uploaded back to GitHub or anywhere else.
# ❗ No telemetry, logging, or push occurs.
# ✅ All data remains local to your current shell session.
# -----------------------------------------------------------------------------


set -e

# Clone the repo (skip if already cloned)
if [ ! -d "azmon-labs" ]; then
  echo "Cloning azmon-labs repository..."
  git clone https://github.com/tiagojfernandes/azmon-labs.git
fi

# Change to environment folder
#cd azmon-labs/terraform/environments/default || {
#  echo "Error: Terraform environment folder not found."
#  exit 1
#}


# -------------------------------
# Functions
# -------------------------------

# Register Azure resource provider if not yet registered
register_provider() {
  local ns=$1
  local status=$(az provider show --namespace "$ns" --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")

  if [ "$status" != "Registered" ]; then
    echo "Registering provider: $ns ..."
    az provider register --namespace "$ns"
    until [ "$(az provider show --namespace "$ns" --query "registrationState" -o tsv)" == "Registered" ]; do
      echo "Waiting for $ns registration..."
      sleep 5
    done
    echo "Provider $ns registered successfully."
  else
    echo "Provider $ns already registered."
  fi
}

# Prompt user input with validation
prompt_input() {
  local prompt_msg=$1
  local var_name=$2
  while [ -z "${!var_name}" ]; do
    read -rp "$prompt_msg: " $var_name
  done
}

# -------------------------------
# Main Script
# -------------------------------

echo "== Azure Monitor Labs Initialization =="

# Register necessary Azure providers
for ns in Microsoft.Insights Microsoft.OperationalInsights Microsoft.Monitor Microsoft.SecurityInsights Microsoft.Dashboard; do
  register_provider "$ns"
done

# Prompt for deployment parameters
prompt_input "Enter the name for the Azure Resource Group" RESOURCE_GROUP
prompt_input "Enter the Azure location (e.g., westeurope)" LOCATION
prompt_input "Enter the name for the Log Analytics Workspace" WORKSPACE_NAME
prompt_input "Enter the name for the AKS cluster" AKS_CLUSTER
prompt_input "Enter the name for the Managed Grafana" MANAGED_GRAFANA
prompt_input "Enter the name for the Azure Monitor Workspace(Managed Prometheus)" PROM_NAME

# Prompt for timezone for auto-shutdown configuration
echo ""
echo "Auto-shutdown will be configured for all VMs and VMSS at 7:00 PM in your timezone."

# Default shutdown time
local_time="19:00"

# Prompt user for UTC offset
read -p "Enter your time zone as UTC offset (e.g., UTC, UTC+1, UTC-5): " tz_input

# Parse offset
if [[ "$tz_input" == "UTC" ]]; then
  offset="+0"
elif [[ "$tz_input" =~ ^UTC([+-][0-9]{1,2})$ ]]; then
  offset="${BASH_REMATCH[1]}"
else
  echo "Invalid UTC offset format."
  exit 1
fi
# Get today's date in YYYY-MM-DD
today=$(date +%F)

# Combine date and time
datetime="$today $local_time"

# Convert to UTC using the offset
USER_TIMEZONE=$(date -u -d "$datetime $offset" +%H%M 2>/dev/null)

if [[ -z "$USER_TIMEZONE" ]]; then
  echo "Failed to convert time. Using fallback 1900 UTC."
  USER_TIMEZONE="1900"
fi


# Fetch Azure subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
if [ -z "$SUBSCRIPTION_ID" ]; then
  echo "ERROR: Could not retrieve Azure subscription ID"
  exit 1
fi

# Write user input to tfvars file
ENV_DIR="azmon-labs/terraform/environments/default"
mkdir -p "$ENV_DIR"

cat > "$ENV_DIR/terraform.tfvars" <<EOF
# Core Configuration
resource_group_name = "$RESOURCE_GROUP"
location            = "$LOCATION"
workspace_name      = "$WORKSPACE_NAME"
subscription_id     = "$SUBSCRIPTION_ID"
user_timezone       = "$USER_TIMEZONE"
aks_name            = "$AKS_CLUSTER"
grafana_name        = "$MANAGED_GRAFANA"
prom_name           = "$PROM_NAME"

# Network Configuration
subnet_name = "vmss_subnet"

# VMSS Configuration
vmss_name      = "vmss-windows-lab"
admin_username = "adminuser"
admin_password = "P@ssw0rd123!"

# Ubuntu VM Configuration
ubuntu_vm_name         = "vm-ubuntu-lab"
ubuntu_admin_username  = "azureuser"
ubuntu_vm_size         = "Standard_B2s"
ubuntu_admin_password  = "P@ssw0rd123!"

# Windows VM Configuration
windows_vm_name         = "vm-windows-lab"
windows_admin_username  = "adminuser"
windows_admin_password  = "P@ssw0rd123!"
windows_vm_size         = "Standard_B2s"

# Red Hat VM Configuration
redhat_vm_name         = "vm-redhat-lab"
redhat_admin_username  = "azureuser"
redhat_admin_password  = "P@ssw0rd123!"
redhat_vm_size         = "Standard_B2s"
EOF

# Display the created tfvars file
echo ""
echo "✅ terraform.tfvars has been created locally in: $ENV_DIR"
echo "🔒 This file is private to your environment and NOT uploaded to GitHub."
echo ""
echo "📋 Deployment Summary:"
echo "  - Resource Group: $RESOURCE_GROUP"
echo "  - Location: $LOCATION"  
echo "  - Log Analytics Workspace: $WORKSPACE_NAME"
echo "  - Subscription ID: $SUBSCRIPTION_ID"
echo ""
echo "🎯 Features Included:"
echo "  - Windows VMSS with Azure Monitor Agent"
echo "  - Ubuntu VM with Syslog DCR"
echo "  - Windows VM for monitoring"
echo "  - Red Hat VM with CEF DCR for Sentinel"
echo "  - Auto-shutdown configured for 7:00 PM (your timezone)"
echo "  - Network security and monitoring setup"
echo ""
echo "⏰ Auto-shutdown will be configured automatically based on your system timezone."
echo "💡 All VMs and VMSS will shutdown at 7:00 PM with 15-minute notification."

cd ~/azmon-labs/scripts
chmod +x deploy-monitoring.sh
bash deploy-monitoring.sh
