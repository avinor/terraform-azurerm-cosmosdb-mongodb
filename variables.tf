variable "name" {
  description = "Name of the CosmosDB Account."
}

variable "mongo_server_version" {
  description = "The Server Version of a MongoDB account."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of resource group to deploy resources in."
}

variable "location" {
  description = "The Azure Region in which to create resource."
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover for this Cosmos DB account."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "List of databases"
  type = map(object({
    throughput     = optional(number)
    max_throughput = optional(number)
    collections = list(object({
      name           = string
      shard_key      = string
      throughput     = optional(number)
      max_throughput = optional(number)
    }))
  }))
  default = {}
}

variable "additional_geo_locations" {
  description = "List of locations the geographic locations the data is replicated to."
  type = map(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool)
  }))
  default = {}
}

variable "diagnostics" {
  description = "Diagnostic settings for those resources that support it. See README.md for details on configuration."
  type = object({
    destination   = string
    eventhub_name = optional(string)
    logs          = list(string)
    metrics       = list(string)
  })
  default = null
}

variable "ip_range_filter" {
  description = "CosmosDB Firewall Support: This value specifies the set of IP addresses or IP address ranges in CIDR form to be included as the allowed list of client IP's for a given database account."
  type        = list(string)
  default     = []
}

variable "virtual_network_rules" {
  description = "Specifies virtual_network_rules resources, used to define which subnets are allowed to access this CosmosDB account"
  type        = list(string)
  default     = []
}

variable "capabilities" {
  description = "Configures the capabilities to enable for this Cosmos DB account. Check README.md for valid values."
  type        = list(string)
  default     = null
}