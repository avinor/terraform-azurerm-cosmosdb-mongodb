terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.69.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {

  collections = flatten([
    for db_key, db in var.databases : [
      for col in db.collections : {
        name           = col.name
        database       = db_key
        shard_key      = col.shard_key
        throughput     = col.throughput
        max_throughput = col.max_throughput
      }
    ]
  ])

  diag_resource_list = var.diagnostics != null ? split("/", var.diagnostics.destination) : []
  parsed_diag = var.diagnostics != null ? {
    log_analytics_id   = contains(local.diag_resource_list, "Microsoft.OperationalInsights") ? var.diagnostics.destination : null
    storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.diagnostics.destination : null
    event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.diagnostics.destination : null
    metric             = var.diagnostics.metrics
    log                = var.diagnostics.logs
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
  tags     = var.tags
}

resource "azurerm_cosmosdb_account" "main" {
  name                              = "${var.name}-cosmos"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  offer_type                        = "Standard"
  kind                              = "MongoDB"
  enable_automatic_failover         = var.enable_automatic_failover
  ip_range_filter                   = join(",", var.ip_range_filter)
  is_virtual_network_filter_enabled = length(var.virtual_network_rules) > 0
  tags                              = var.tags
  mongo_server_version              = var.mongo_server_version

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

  dynamic "geo_location" {
    for_each = var.additional_geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules

    content {
      id                                   = virtual_network_rule.value
      ignore_missing_vnet_service_endpoint = false
    }
  }
}

resource "azurerm_cosmosdb_mongo_database" "main" {
  for_each = var.databases

  name                = each.key
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = each.value.throughput

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [each.value.max_throughput] : []
    content {
      max_throughput = autoscale_settings.value
    }
  }
}

resource "azurerm_cosmosdb_mongo_collection" "main" {
  for_each = { for col in local.collections : col.name => col }

  name                = each.value.name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = each.value.database
  shard_key           = each.value.shard_key
  throughput          = each.value.throughput

  index {
    keys   = ["_id"]
    unique = true
  }

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [each.value.max_throughput] : []
    content {
      max_throughput = autoscale_settings.value
    }
  }

  lifecycle {
    ignore_changes = [index, default_ttl_seconds]
  }

  depends_on = [azurerm_cosmosdb_mongo_database.main]
}

data "azurerm_monitor_diagnostic_categories" "default" {
  resource_id = azurerm_cosmosdb_account.main.id
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  count                          = var.diagnostics != null ? 1 : 0
  name                           = "${var.name}-ns-diag"
  target_resource_id             = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id     = local.parsed_diag.log_analytics_id
  eventhub_authorization_rule_id = local.parsed_diag.event_hub_auth_id
  eventhub_name                  = local.parsed_diag.event_hub_auth_id != null ? var.diagnostics.eventhub_name : null
  storage_account_id             = local.parsed_diag.storage_account_id

  # Enable each log category. All other categories are created with enabled = false
  # to prevent TF from showing changes happening with each plan/apply.
  # Ref: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7235
  dynamic "enabled_log" {
    for_each = {
      for k, v in data.azurerm_monitor_diagnostic_categories.default.log_category_types : k => v
      if contains(local.parsed_diag.log, "all") || contains(local.parsed_diag.log, v)
    }
    content {
      category = enabled_log.value

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  # For each available metric category, check if it should be enabled and set enabled = true if it should.
  # All other categories are created with enabled = false to prevent TF from showing changes happening with each plan/apply.
  # Ref: https://github.com/terraform-providers/terraform-provider-azurerm/issues/7235
  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.metrics
    content {
      category = metric.value
      enabled  = contains(local.parsed_diag.metric, "all") || contains(local.parsed_diag.metric, metric.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}
