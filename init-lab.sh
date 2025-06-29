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

/*
# Change to environment folder
cd azmon-labs/terraform/environments/default || {
  echo "Error: Terraform environment folder not found."
  exit 1
}

*/

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
resource_group_name = "$RESOURCE_GROUP"
location            = "$LOCATION"
workspace_name      = "$WORKSPACE_NAME"
subscription_id     = "$SUBSCRIPTION_ID"
EOF

# Display the created tfvars file
echo ""
echo "✅ terraform.tfvars has been created locally in: $ENV_DIR"
echo "🔒 This file is private to your environment and NOT uploaded to GitHub."
echo ""

echo "Current directory: $(pwd)"

# Launch Terraform
cd azmon-labs/terraform
terraform init
terraform apply -var-file="environments/default/terraform.tfvars" -auto-approve
