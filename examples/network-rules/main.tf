module "cosmosdb" {
  source = "../.."

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  ip_range_filter = ["10.221.100.10", "10.221.101.0/24"]

  virtual_network_rules = [
    "/subscriptions/..../subnets/subnet1",
    "/subscriptions/..../subnets/subnet2",
  ]

  databases = {
    mydb = {
      throughput     = 400
      max_throughput = null
      collections    = [{ name = "mycol1", shard_key = "somekey", throughput = null, max_throughput = null }]
    }
  }

  tags = {
    tag1 = "value1"
  }
}
