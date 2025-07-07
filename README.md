# Azure Monitoring Lab

A comprehensive Azure monitoring lab environment built with Terraform and automated with Bash scripts. This lab deploys a complete monitoring infrastructure including virtual machines, Virtual Machine Scale Sets (VMSS), Log Analytics workspace, Sentinel, Data Collection Rules (DCRs), and Azure Monitor Agent (AMA).

## 🏗️ Architecture

This lab creates the following Azure resources:

- **Resource Group** with Log Analytics Workspace
- **Windows Virtual Machine Scale Set (VMSS)** for scalable monitoring scenarios
- **Ubuntu VM** with Syslog Data Collection Rule (DCR)
- **Windows VM** for Windows-specific monitoring
- **Red Hat VM** with CEF Data Collection Rule for Sentinel integration
- **Network Security Groups** with appropriate security rules
- **Data Collection Rules (DCRs)** for targeted log collection
- **Azure Monitor Agent (AMA)** deployed on all VMs
- **Auto-shutdown policies** for cost optimization

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.3.0
- Bash shell (Linux/macOS/WSL)
- jq command-line JSON processor

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd azmon-labs
```

### 2. Configure Variables

Edit the Terraform variables in `terraform/environments/default/terraform.tfvars`:

```hcl
resource_group_name = "rg-azmon-lab"
location = "East US"
workspace_name = "law-azmon-lab"
# ... other variables
```

### 3. Deploy the Lab

Run the main deployment script:

```bash
chmod +x scripts/deploy-monitoring.sh
./scripts/deploy-monitoring.sh
```

This script will:
1. Initialize and apply Terraform configuration
2. Deploy all Azure resources
3. Extract resource information from Terraform outputs
4. Pass resource parameters to post-deployment script
5. Configure Azure Monitor Agent (AMA) on all VMs
6. Set up Data Collection Rules (DCRs)
7. Install AMA Forwarder on Red Hat VM
8. Install CEF Simulator on Ubuntu VM
9. Configure auto-shutdown for all VMs and VMSS

**Note**: The `deploy-end-tasks.sh` script now accepts parameters instead of reading from JSON files, making it more flexible and reliable.

## 🔧 Script Parameters

### deploy-aks-managedsolutions.sh

The AKS and managed solutions deployment script accepts the following parameters:

```bash
./deploy-aks-managedsolutions.sh <RESOURCE_GROUP> <WORKSPACE_ID> <WORKSPACE_NAME>
```

**Parameters:**
- `RESOURCE_GROUP`: Name of the Azure resource group
- `WORKSPACE_ID`: Full resource ID of the Log Analytics workspace
- `WORKSPACE_NAME`: Name of the Log Analytics workspace

**Example:**
```bash
./deploy-aks-managedsolutions.sh "rg-azmon-lab" "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-azmon-lab/providers/Microsoft.OperationalInsights/workspaces/law-azmon-lab" "law-azmon-lab"
```

### deploy-end-tasks.sh

The post-deployment script accepts the following parameters:

```bash
./deploy-end-tasks.sh <RESOURCE_GROUP> <REDHAT_VM_NAME> <UBUNTU_VM_NAME> <WINDOWS_VM_NAME> <VMSS_NAME> <REDHAT_PRIVATE_IP> <UTC_TIME>
```

**Parameters:**
- `RESOURCE_GROUP`: Name of the Azure resource group
- `REDHAT_VM_NAME`: Name of the Red Hat virtual machine
- `UBUNTU_VM_NAME`: Name of the Ubuntu virtual machine  
- `WINDOWS_VM_NAME`: Name of the Windows virtual machine
- `VMSS_NAME`: Name of the Windows virtual machine scale set
- `REDHAT_PRIVATE_IP`: Private IP address of the Red Hat VM
- `UTC_TIME`: UTC time for auto-shutdown in HHMM format (calculated from user's local 7:00 PM)

**Example:**
```bash
./deploy-end-tasks.sh "rg-azmon-lab" "vm-redhat-001" "vm-ubuntu-001" "vm-windows-001" "vmss-windows-001" "10.0.1.100" "0000"
```

The UTC_TIME parameter represents 7:00 PM in the user's local timezone converted to UTC time.

This approach eliminates the dependency on JSON file parsing and makes the scripts more portable and testable.

## 🔧 Features

### Auto-Shutdown Configuration

The lab automatically configures auto-shutdown for all VMs and VMSS to help manage costs:

- **Shutdown Time**: 7:00 PM in your local timezone (converted to UTC automatically)
- **Notification**: 15 minutes before shutdown
- **Time Calculation**: User provides UTC offset during initialization, script calculates corresponding UTC time
- **Resources**: All VMs and VMSS are configured

During initialization, you'll be prompted to enter your UTC offset (e.g., UTC, UTC+1, UTC-5). The script will automatically calculate what 7:00 PM in your local time corresponds to in UTC and configure auto-shutdown accordingly.

**Example:**
- If you're in EST (UTC-5) and want 7:00 PM shutdown
- Script calculates: 7:00 PM EST = 12:00 AM UTC (next day)
- Auto-shutdown configured for 0000 UTC

This approach works around Azure CLI limitations with timezone parameters and ensures accurate scheduling regardless of your location.

### Monitoring and Logging

#### Data Collection Rules (DCRs)

- **CEF DCR**: Configured for Red Hat VM to collect CEF messages for Sentinel
- **Syslog DCR**: Configured for Ubuntu VM to collect all syslog facilities

#### Azure Monitor Agent (AMA)

- Deployed on all VMs with system-assigned managed identity
- Proper role assignments for metric publishing
- Automated association with appropriate DCRs

#### Network Security

- SSH access (port 22) for Linux VMs
- RDP access (port 3389) for Windows VMs
- HTTP/HTTPS access (ports 80/443)
- Syslog and CEF ports (514) for log forwarding
- Source IP restriction to your public IP

### Post-Deployment Automation

#### AMA Forwarder (Red Hat VM)

Automatically installs and configures:
- rsyslog service for CEF message forwarding
- Log rotation for /var/log/cef.log
- Service restart and enablement

#### CEF Simulator (Ubuntu VM)

Installs a CEF message generator that:
- Sends simulated security events to Red Hat VM
- Supports multiple vendor formats (PaloAlto, CyberArk, Fortinet)
- Runs every 30 seconds via cron

## 📁 Project Structure

```
azmon-labs/
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   ├── provider.tf                # Azure provider configuration
│   ├── environments/
│   │   └── default/
│   │       └── terraform.tfvars   # Default variable values
│   └── modules/
│       ├── resource_group/        # Resource group module
│       ├── log_analytics/         # Log Analytics workspace module
│       ├── network/               # Networking module
│       ├── dcr/                   # Data Collection Rules module
│       ├── vm_ubuntu/             # Ubuntu VM module
│       ├── vm_windows/            # Windows VM module
│       ├── vm_redhat/             # Red Hat VM module
│       └── vmss_windows/          # Windows VMSS module
├── scripts/
│   ├── deploy-monitoring.sh       # Main deployment script
│   ├── deploy-end-tasks.sh        # Post-deployment configuration
│   ├── deploy_ama_forwarder.sh    # AMA forwarder installation
│   └── deploy_cef_simulator.sh    # CEF simulator installation
└── README.md                      # This documentation
```

## 🔍 Verification

After deployment, verify the setup:

### 1. Check Azure Resources

```bash
# List all resources in the resource group
az resource list --resource-group rg-azmon-lab --output table

# Check VM status
az vm list --resource-group rg-azmon-lab --show-details --output table

# Check VMSS status
az vmss list --resource-group rg-azmon-lab --output table
```

### 2. Verify Auto-Shutdown

```bash
# Check auto-shutdown configuration for VMs
az vm show --resource-group rg-azmon-lab --name <vm-name> --query "scheduledEventsProfile"

# Check auto-shutdown for VMSS
az vmss show --resource-group rg-azmon-lab --name <vmss-name> --query "scheduledEventsProfile"
```

### 3. Monitor Logs

- Access Log Analytics workspace in Azure portal
- Check for incoming CEF messages from Red Hat VM
- Verify syslog data from Ubuntu VM
- Monitor Azure Monitor metrics and alerts

## 🛠️ Customization

### Modify Auto-Shutdown Time

Edit the `SHUTDOWN_TIME` variable in `scripts/deploy-end-tasks.sh`:

```bash
SHUTDOWN_TIME="2100"  # 9:00 PM
NOTIFICATION_TIME="2045"  # 8:45 PM (15 minutes before)
```

### Add Custom Data Collection Rules

Create new DCR modules in `terraform/modules/` and reference them in `main.tf`.

### Extend VM Configurations

Modify the VM modules to add:
- Additional extensions
- Custom scripts
- Different VM sizes
- Additional disks

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -var-file="environments/default/terraform.tfvars"
```

## 🔧 Troubleshooting

### Common Issues

1. **Auto-shutdown not working**: Check timezone detection and Azure CLI authentication
2. **DCR association failures**: Verify AMA is properly installed and identity configured
3. **Network connectivity**: Check NSG rules and public IP assignments
4. **Log forwarding issues**: Verify rsyslog configuration and network connectivity

### Debug Commands

```bash
# Check Terraform outputs
terraform output -json

# Verify Azure CLI login
az account show

# Check VM extensions
az vm extension list --resource-group rg-azmon-lab --vm-name <vm-name>

# View systemd logs (on VMs)
sudo journalctl -u rsyslog -f
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure documentation for specific services
3. Open an issue in the repository