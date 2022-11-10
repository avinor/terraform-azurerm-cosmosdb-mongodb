module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  databases = {
    mydb1 = {
      throughput = 400
      collections = [
        { name = "col0", shard_key = "somekey_0" },
      ]
    }
  }

  tags = {
    tag1 = "value1"
  }

  diagnostics = {
    destination   = "test"
    eventhub_name = "diagnostics"
    logs          = ["all"]
    metrics       = ["all"]
  }

}
