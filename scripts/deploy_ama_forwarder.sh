#!/bin/bash
# scripts/install_ama_forwarder.sh

set -e

sudo yum install -y python3 curl wget
sudo wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py
sudo python3 Forwarder_AMA_installer.py