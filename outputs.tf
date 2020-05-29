output "id" {
  description = "The ID of the CosmosDB Account."
  value       = azurerm_cosmosdb_account.main.id
}

output "endpoint" {
  description = "The endpoint usedto coonnect to the CosmosDB account."
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "connection_strings" {
  description = "A list of connection strings available for this CosmosDB account."
  value       = azurerm_cosmosdb_account.main.connection_strings
}

