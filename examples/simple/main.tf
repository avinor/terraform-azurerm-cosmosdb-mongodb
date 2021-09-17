module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"
  capabilities        = ["DisableRateLimitingResponses"]

  ip_range_filter = ["10.221.100.10", "10.221.101.0/24"]

  databases = {
    mydb1 = {
      throughput     = 400
      max_throughput = null
      collections = [
        { name = "col0", shard_key = "somekey_0", throughput = 1000, max_throughput = null },
        { name = "col1", shard_key = "somekey_1", throughput = null, max_throughput = null }
      ]
    }
    mydb2 = {
      throughput     = null
      max_throughput = 4000
      collections    = [{ name = "mycol2", shard_key = "someother_key", throughput = null, max_throughput = null }]
    }
    mydb3 = {
      throughput     = null
      max_throughput = null
      collections    = [{ name = "mycol3", shard_key = "mycol3_key", throughput = null, max_throughput = 5000 }]
    }
  }

  tags = {
    tag1 = "value1"
  }

}
