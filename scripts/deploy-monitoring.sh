#!/bin/bash

# -----------------------------------------------------------------------------

set -e

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
REDHAT_VM_NAME=$(jq -r '.redhat_vm_name.value' "$TF_OUTPUTS")

echo "Using resource group: $RESOURCE_GROUP"
echo "Using Log Analytics workspace: $WORKSPACE_NAME"



# Execute the Sentinel AMA forwarder install script
echo "🔧 Installing AMA Forwarder on Red Hat VM: $REDHAT_VM_NAME"


#az vm run-command invoke \
#  --resource-group "$RESOURCE_GROUP" \
#  --name "$REDHAT_VM_NAME" \
#  --command-id RunShellScript \
#  --scripts "$(cat "$HOME/azmon-labs/scripts/deploy_ama_forwarder.sh")"

