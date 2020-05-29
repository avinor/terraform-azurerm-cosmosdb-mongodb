variable "name" {
  description = "Name of the CosmosDB Account."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "sku" {
  description = "SKU settings of server, see https://www.terraform.io/docs/providers/azurerm/r/postgresql_server.html for details."
  type        = object({ capacity = number, tier = string, family = string })
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}