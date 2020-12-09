module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  ip_range_filter = "10.221.100.10,10.221.101.0/24"

  databases = {
    mydb1 = {
      throughput  = 400
      collections = [{ name = "mycol1", shard_key = "somekey" }]
    }
    mydb2 = {
      throughput  = 600
      collections = [{ name = "mycol2", shard_key = "someother_key" }]
    }
  }

  tags = {
    tag1 = "value1"
  }

  diagnostics = {
    destination   = "test"
    eventhub_name = "diagnostics",
    logs          = ["all"],
    metrics       = ["all"],
  }

}