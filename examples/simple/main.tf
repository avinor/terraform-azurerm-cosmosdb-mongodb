module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  databases = {
    mydb1 = {
      throughput = 400
      collections = [{ name = "mycol1", shard_key = "somekey" }]
    }
    mydb2 = {
      throughput = 600
      collections = [{ name = "mycol2", shard_key = "someother_key" }]
    }
  }

  tags = {
    tag1 = "value1"
  }

}