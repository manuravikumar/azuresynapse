# ------------------------------
# Core Infrastructure
# ------------------------------
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "adls" {
  name                     = lower(replace("${var.project}${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  allow_nested_items_to_be_public = false
  tags = var.tags
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "curated" {
  name                  = "curated"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

# ------------------------------
# Event Hubs + Capture to ADLS
# ------------------------------
resource "azurerm_eventhub_namespace" "eh_ns" {
  name                = "${var.project}-ehns-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}

resource "azurerm_eventhub" "eh" {
  name                = "${var.project}-sales"
  namespace_name      = azurerm_eventhub_namespace.eh_ns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1

  capture_description {
    enabled             = true
    encoding            = "Avro"
    interval_in_seconds = 60
    size_limit_in_bytes = 10485763
    destination {
      name = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = azurerm_storage_container.raw.name
      storage_account_id  = azurerm_storage_account.adls.id
    }
  }
}

resource "azurerm_eventhub_authorization_rule" "send" {
  name                = "send"
  namespace_name      = azurerm_eventhub_namespace.eh_ns.name
  eventhub_name       = azurerm_eventhub.eh.name
  resource_group_name = azurerm_resource_group.rg.name
  send                = true
  listen              = false
  manage              = false
}

# ------------------------------
# Synapse Workspace (with ADLS as default)
# ------------------------------
resource "azurerm_synapse_workspace" "syn" {
  name                                 = "${var.project}-syn-${random_string.suffix.result}"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_container.raw.resource_manager_id

  sql_administrator_login          = var.sql_admin_login
  sql_administrator_login_password = var.sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Allow your current client IP by default (adjust as needed)
resource "azurerm_synapse_firewall_rule" "allow_all_azure_ips" {
  name                 = "AllowAllAzureIPs"
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

# Grant Synapse MSI rights on Storage (to read/write from raw/curated)
resource "azurerm_role_assignment" "syn_to_storage_blob_data_contrib" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.syn.identity[0].principal_id
}

# Dedicated SQL Pool for curated reporting

resource "azurerm_synapse_sql_pool" "dwh" {
  name                 = "${var.project}dwh"
  synapse_workspace_id = azurerm_synapse_workspace.syn.id
  sku_name             = var.dedicated_sql_sku
  create_mode          = "Default"
  storage_account_type = "GRS" # or "LRS"
}


output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.adls.name
}

output "eventhub_namespace" {
  value = azurerm_eventhub_namespace.eh_ns.name
}

output "eventhub_name" {
  value = azurerm_eventhub.eh.name
}

output "eventhub_send_connection_string" {
  value     = azurerm_eventhub_authorization_rule.send.primary_connection_string
  sensitive = true
}

output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.syn.name
}

output "synapse_sql_pool_name" {
  value = azurerm_synapse_sql_pool.dwh.name
}
