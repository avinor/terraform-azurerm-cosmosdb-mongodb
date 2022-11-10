# Cosmosdb account for mongodb

Terraform module to create a CosmosDB account with mongodb in Azure with set of databases.

## Limitations

This module only support Cosmos DB API for MongoDB and capability EnableMongo can not be disabled.

## Usage

Example showing deployment of a server with two databases.

```terraform
module "cosmosdb" {
  source = "github.com/avinor/terraform-azurerm-cosmosdb-mongodb"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"
  capabilities        = ["DisableRateLimitingResponses"]


  databases = {
    mydb = {
      throughput     = 400
      max_throughput = null
      collections    = [
        { name = "col0", shard_key = "somekey_0", throughput = 1000, max_throughput = null },
        { name = "col1", shard_key = "somekey_1", throughput = null, max_throughput = null }
      ]
    }
    mydb2 = {
      throughput     = null
      max_throughput = 5000
      collections    = [{ name = "col2", shard_key = "someotherkey", throughput = null, max_throughput = null }]
    }
  }
}
```

## Diagnostics

Diagnostics settings can be sent to either storage account, event hub or Log Analytics workspace. The
variable `diagnostics.destination` is the id of receiver, ie. storage account id, event namespace authorization rule id
or log analytics resource id. Depending on what id is it will detect where to send. Unless using event namespace
the `eventhub_name` is not required, just set to `null` for storage account and log analytics workspace.

Setting `all` in logs and metrics will send all possible diagnostics to destination. If not using `all` type name of
categories to send.

## Capabilities

The variable `capabilities` can be used to enable following capabilities (list of strings, see the example above):

* AllowSelfServeUpgradeToMongo36
* DisableRateLimitingResponses
* EnableAggregationPipeline
* EnableCassandra
* EnableGremlin
* EnableTable
* EnableServerless
* MongoDBv3.4
* mongoEnableDocLevelTTL

## Throughput

There are two ways of configuring throughput (RU/s); manual or autoscale.

To use manual throughput, set `throughput` either on a database or a collection. E.g:

```terraform
mydb = {
  throughput     = 400
  max_throughput = null
  collections    = []
}
```

To use autoscale throughput, set `max_throughput` on a database or a collection. E.g:

```terraform
mydb = {
  throughput     = null
  max_throughput = 4000
  collections    = []
}
```

_Note: `throughput` and `max_throughput` cannot be used in conjunction_
