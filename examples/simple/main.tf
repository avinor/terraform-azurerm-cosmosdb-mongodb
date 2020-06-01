module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  databases = [
    {
      name       = "mydb1",
      throughput = 400,
    },
    {
      name       = "mydb2"
      throughput = 800,
    }
  ]

  tags = {
    tag1 = "value1"
  }

}