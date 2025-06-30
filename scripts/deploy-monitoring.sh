#!/bin/bash

# -----------------------------------------------------------------------------

# Load variables from the Terraform output JSON
TF_OUTPUTS="~/azmon-labs/terraform/tf_outputs.json"


# Checks if the Terraform outputs file exists and loads the necessary variables.
if [ ! -f "$TF_OUTPUTS" ]; then
  echo "ERROR: Terraform outputs file not found: $TF_OUTPUTS"
  exit 1
fi


RESOURCE_GROUP=$(jq -r '.resource_group_name.value' "$TF_OUTPUTS")
WORKSPACE_ID=$(jq -r '.log_analytics_workspace_id.value' "$TF_OUTPUTS")
WORKSPACE_NAME=$(jq -r '.log_analytics_workspace_name.value' "$TF_OUTPUTS")

echo "Using resource group: $RESOURCE_GROUP"
echo "Using Log Analytics workspace: $WORKSPACE_NAME"
