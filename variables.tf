variable "name" {
  description = "Name of the CosmosDB Account."
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "List of databases"
  type = list(object(
    {
      name       = string,
      throughput = number
    }
  ))
  default = []
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type        = object({ destination = string, eventhub_name = string, logs = list(string), metrics = list(string) })
  default     = null
}