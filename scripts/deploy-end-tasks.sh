#!/bin/bash

# -----------------------------------------------------------------------------
# deploy-end-tasks.sh
# Post-deployment configura# Configure auto-shutdown for all VMs
configure_vm_autoshutdown "$UBUNTU_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$WINDOWS_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"
configure_vm_autoshutdown "$REDHAT_VM_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"

# Configure auto-shutdown for VMSS
configure_vmss_autoshutdown "$VMSS_NAME" "$RESOURCE_GROUP" "$USER_TIMEZONE" "$SHUTDOWN_TIME" "$NOTIFICATION_TIME"ript for Azure monitoring lab
# 
# Usage: ./deploy-end-tasks.sh <RESOURCE_GROUP> <REDHAT_VM_NAME> <UBUNTU_VM_NAME> <WINDOWS_VM_NAME> <VMSS_NAME> <REDHAT_PRIVATE_IP>
# -----------------------------------------------------------------------------

set -e

# Check if required parameters are provided
if [ $# -ne 7 ]; then
    echo "Usage: $0 <RESOURCE_GROUP> <REDHAT_VM_NAME> <UBUNTU_VM_NAME> <WINDOWS_VM_NAME> <VMSS_NAME> <REDHAT_PRIVATE_IP> <USER_TIMEZONE>"
    echo ""
    echo "Parameters:"
    echo "  RESOURCE_GROUP    - Name of the Azure resource group"
    echo "  REDHAT_VM_NAME    - Name of the Red Hat virtual machine"
    echo "  UBUNTU_VM_NAME    - Name of the Ubuntu virtual machine"
    echo "  WINDOWS_VM_NAME   - Name of the Windows virtual machine"
    echo "  VMSS_NAME         - Name of the Windows virtual machine scale set"
    echo "  REDHAT_PRIVATE_IP - Private IP address of the Red Hat VM"
    echo "  USER_TIMEZONE     - User's timezone for auto-shutdown configuration"
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


# Use the provided timezone directly
# User timezone is already validated through init-lab.sh selection
echo "🕐 Using timezone: $USER_TIMEZONE"
echo "This timezone will be used for auto-shutdown configuration at 7:00 PM"

SHUTDOWN_TIME="1900"  # 7:00 PM (24-hour format)
NOTIFICATION_TIME="1845"  # 15 minutes before shutdown

echo "Configured timezone: $USER_TIMEZONE"
echo "Auto-shutdown time: $SHUTDOWN_TIME (7:00 PM)"
echo "Notification time: $NOTIFICATION_TIME (6:45 PM)"

# Configure auto-shutdown for all VMs and VMSS
echo "🔧 Configuring auto-shutdown for all VMs and VMSS..."

# Function to configure auto-shutdown for a VM
configure_vm_autoshutdown() {
  local vm_name=$1
  local resource_group=$2
  local timezone=$3
  local shutdown_time=$4
  local notification_time=$5
  
  echo "  📝 Configuring auto-shutdown for VM: $vm_name"
  
  # Enable auto-shutdown
  az vm auto-shutdown \
    --resource-group "$resource_group" \
    --name "$vm_name" \
    --time "$shutdown_time" \
    --timezone "$timezone" \
    --notification-time "$notification_time" \
    --notification-email-recipient "admin@example.com" \
    --notification-webhook-url "" \
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
  local timezone=$3
  local shutdown_time=$4
  local notification_time=$5
  
  echo "  📝 Configuring auto-shutdown for VMSS: $vmss_name"
  
  # Enable auto-shutdown for VMSS
  az vmss auto-shutdown \
    --resource-group "$resource_group" \
    --name "$vmss_name" \
    --time "$shutdown_time" \
    --timezone "$timezone" \
    --notification-time "$notification_time" \
    --notification-email-recipient "admin@example.com" \
    --notification-webhook-url "" \
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
echo "  - Shutdown time: $SHUTDOWN_TIME ($USER_TIMEZONE)"
echo "  - Notification time: $NOTIFICATION_TIME ($USER_TIMEZONE)"
echo "  - VMs configured: $UBUNTU_VM_NAME, $WINDOWS_VM_NAME, $REDHAT_VM_NAME"
echo "  - VMSS configured: $VMSS_NAME"
echo "  - All resources will automatically shutdown at 7:00 PM with 15-minute notification"

