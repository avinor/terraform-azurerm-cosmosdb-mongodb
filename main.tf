terraform {
  required_version = ">= 0.12.6"
}

provider "azurerm" {
  version = "~> 2.49.0"
  features {}
}

locals {

  collections = flatten([
    for db_key, db in var.databases : [
      for col in db.collections : {
        name       = col.name
        database   = db_key
        shard_key  = col.shard_key
        throughput = col.throughput
      }
    ]
  ])

  diag_cosmosdb_logs = [
    "DataPlaneRequests",
    "MongoRequests",
    "QueryRuntimeStatistics",
    "PartitionKeyStatistics",
    "PartitionKeyRUConsumption",
    "ControlPlaneRequests",
    "CassandraRequests",
    "GremlinRequests",
  ]

  diag_cosmosdb_metrics = [
    "Requests",
  ]

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "Microsoft.OperationalInsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = contains(var.diagnostics.metrics, "all") ? local.diag_cosmosdb_metrics : var.diagnostics.metrics
    log                = contains(var.diagnostics.logs, "all") ? local.diag_cosmosdb_logs : var.diagnostics.logs
    } : {
    log_analytics_id   = null
    storage_account_id = null
    event_hub_auth_id  = null
    metric             = []
    log                = []
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.name}-cosmos"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false
  ip_range_filter           = join(",", var.ip_range_to_filter)

  capabilities {
    name = "EnableMongo"
  }

  dynamic "capabilities" {
    for_each = var.capabilities != null ? var.capabilities : []
    content {
      name = capabilities.value
    }
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_mongo_database" "main" {
  for_each = var.databases

  name                = each.key
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = each.value.throughput
}

resource "azurerm_cosmosdb_mongo_collection" main {
  for_each = { for col in local.collections : col.name => col }

  name                = each.value.name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = each.value.database
  shard_key           = each.value.shard_key
  throughput          = each.value.throughput

  lifecycle {
    ignore_changes = [index]
  }

  depends_on = [azurerm_cosmosdb_mongo_database.main]
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-ns-diag"
  target_resource_id             = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  dynamic "log" {
    for_each = local.parsed_diag.log
    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = local.parsed_diag.metric
    content {
      category = metric.value

      retention_policy {
        enabled = false
      }
    }
  }
}
