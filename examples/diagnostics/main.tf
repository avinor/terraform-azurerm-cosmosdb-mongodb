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
    destination   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resource-group/providers/Microsoft.OperationalInsights/workspaces/my-workspace"
    eventhub_name = "diagnostics"
    logs          = ["all"]
    metrics       = ["all"]
  }

}
