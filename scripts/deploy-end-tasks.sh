#!/bin/bash

# -----------------------------------------------------------------------------
# deploy-end-tasks.sh
# Post-deployment configura# Configure auto-shutdown for all VMs
configure_vm_autoshutdown "$UBUNTU_VM_NAME" "$RESOURCE_GROUP" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$WINDOWS_VM_NAME" "$RESOURCE_GROUP" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$REDHAT_VM_NAME" "$RESOURCE_GROUP" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"

# Configure auto-shutdown for VMSS
configure_vmss_autoshutdown "$VMSS_NAME" "$RESOURCE_GROUP" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"ript for Azure monitoring lab
# 
# Usage: ./deploy-end-tasks.sh <RESOURCE_GROUP> <REDHAT_VM_NAME> <UBUNTU_VM_NAME> <WINDOWS_VM_NAME> <VMSS_NAME> <REDHAT_PRIVATE_IP>
# -----------------------------------------------------------------------------

set -e

# Check if required parameters are provided
if [ $# -ne 7 ]; then
    echo "Usage: $0 <RESOURCE_GROUP> <REDHAT_VM_NAME> <UBUNTU_VM_NAME> <WINDOWS_VM_NAME> <VMSS_NAME> <REDHAT_PRIVATE_IP> <UTC_TIME>"
    echo ""
    echo "Parameters:"
    echo "  RESOURCE_GROUP    - Name of the Azure resource group"
    echo "  REDHAT_VM_NAME    - Name of the Red Hat virtual machine"
    echo "  UBUNTU_VM_NAME    - Name of the Ubuntu virtual machine"
    echo "  WINDOWS_VM_NAME   - Name of the Windows virtual machine"
    echo "  VMSS_NAME         - Name of the Windows virtual machine scale set"
    echo "  REDHAT_PRIVATE_IP - Private IP address of the Red Hat VM"
    echo "  UTC_TIME          - UTC time for auto-shutdown (HHMM format, calculated from user's local 7:00 PM)"
    exit 1
fi

# Assign input parameters to variables
RESOURCE_GROUP="$1"
REDHAT_VM_NAME="$2"
UBUNTU_VM_NAME="$3"
WINDOWS_VM_NAME="$4"
VMSS_NAME="$5"
REDHAT_PRIVATE_IP="$6"
USER_TIMEZONE="$7"

# Display received parameters
echo "📋 Received parameters:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Red Hat VM: $REDHAT_VM_NAME"
echo "  Ubuntu VM: $UBUNTU_VM_NAME"
echo "  Windows VM: $WINDOWS_VM_NAME"
echo "  VMSS: $VMSS_NAME"
echo "  Red Hat Private IP: $REDHAT_PRIVATE_IP"
echo "  User Timezone: $USER_TIMEZONE"
echo ""


# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the Sentinel AMA forwarder install script
echo "🔧 Installing AMA Forwarder on Red Hat VM: $REDHAT_VM_NAME"

az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REDHAT_VM_NAME" \
  --command-id RunShellScript \
  --scripts "$(cat "$SCRIPT_DIR/deploy_ama_forwarder.sh")"


# Deploy the CEF simulator script on Ubuntu machine
echo "🔧 Installing CEF Simulator on Ubuntu VM: $UBUNTU_VM_NAME"

az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP" \
  --name "$UBUNTU_VM_NAME" \
  --command-id RunShellScript \
  --scripts "$(cat "$SCRIPT_DIR/deploy_cef_simulator.sh")" \
  --parameters "redhatip_input=$REDHAT_PRIVATE_IP"


# Use the provided UTC time directly
# User UTC time is already calculated in init-lab.sh based on their local timezone offset
echo "🕐 Using UTC time for auto-shutdown: $USER_TIMEZONE"
echo "This corresponds to 7:00 PM in your local timezone"

SHUTDOWN_TIME="$USER_TIMEZONE"  # UTC time in HHMM format (e.g., 1900, 0000, 1200)
# Calculate notification time (15 minutes before shutdown)
NOTIFICATION_TIME=$(date -u -d "$(date -u -d "today $SHUTDOWN_TIME" +"%Y-%m-%d %H:%M") - 15 minutes" +%H%M)

echo "Configured shutdown time (UTC): $SHUTDOWN_TIME"
echo "Notification time (UTC): $NOTIFICATION_TIME (15 minutes before shutdown)"

# Configure auto-shutdown for all VMs and VMSS
echo "🔧 Configuring auto-shutdown for all VMs and VMSS..."

# Function to configure auto-shutdown for a VM
configure_vm_autoshutdown() {
  local vm_name=$1
  local resource_group=$2
  local shutdown_time=$3
  local notification_time=$4
  
  echo "  📝 Configuring auto-shutdown for VM: $vm_name"
  
  # Enable auto-shutdown (using UTC time, no timezone parameter)
  az vm auto-shutdown \
    --resource-group "$resource_group" \
    --name "$vm_name" \
    --time "$shutdown_time" \
    --notification-time "$notification_time" \
    --notification-email-recipient "admin@example.com" \
    --enable-auto-shutdown true
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Auto-shutdown configured successfully for VM: $vm_name"
  else
    echo "  ❌ Failed to configure auto-shutdown for VM: $vm_name"
  fi
}

# Function to configure auto-shutdown for VMSS
configure_vmss_autoshutdown() {
  local vmss_name=$1
  local resource_group=$2
  local shutdown_time=$3
  local notification_time=$4
  
  echo "  📝 Configuring auto-shutdown for VMSS: $vmss_name"
  
  # Enable auto-shutdown for VMSS (using UTC time, no timezone parameter)
  az vmss auto-shutdown \
    --resource-group "$resource_group" \
    --name "$vmss_name" \
    --time "$shutdown_time" \
    --notification-time "$notification_time" \
    --notification-email-recipient "admin@example.com" \
    --enable-auto-shutdown true
  
  if [ $? -eq 0 ]; then
    echo "  ✅ Auto-shutdown configured successfully for VMSS: $vmss_name"
  else
    echo "  ❌ Failed to configure auto-shutdown for VMSS: $vmss_name"
  fi
}

# Configure auto-shutdown for all VMs
configure_vm_autoshutdown "$UBUNTU_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE_VALIDATED" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$WINDOWS_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE_VALIDATED" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$REDHAT_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE_VALIDATED" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"

# Configure auto-shutdown for VMSS
configure_vmss_autoshutdown "$VMSS_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE_VALIDATED" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"

echo "🎉 Auto-shutdown configuration completed!"
echo ""
echo "📋 Summary:"
echo "  - Shutdown time (UTC): $SHUTDOWN_TIME (corresponds to 7:00 PM in your local timezone)"
echo "  - Notification time (UTC): $NOTIFICATION_TIME (15 minutes before shutdown)"
echo "  - VMs configured: $UBUNTU_VM_NAME, $WINDOWS_VM_NAME, $REDHAT_VM_NAME"
echo "  - VMSS configured: $VMSS_NAME"
echo "  - All resources will automatically shutdown at the calculated UTC time with 15-minute notification"

