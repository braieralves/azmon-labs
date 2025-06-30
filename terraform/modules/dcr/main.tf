# dcr/main.tf
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "dcr-tf-copilot"
  location            = var.location
  resource_group_name = var.resource_group_name

  data_sources {
    performance_counter {
      name                          = "basic-performance-counters"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\Memory\\Available MBytes"
      ]
    }
  }

  destinations {
    log_analytics {
      name                  = "law-destination"
      workspace_resource_id = var.workspace_id
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-destination"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "assoc" {
  name                    = "vmss-dcr-association"
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  target_resource_id      = var.target_resource_id
}