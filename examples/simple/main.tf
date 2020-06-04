module "cosmosdb" {
  source = "../../"

  name                = "cosmosdb"
  resource_group_name = "cosmosdb-rg"
  location            = "westeurope"

  databases = {
    mydb1 = {
      throughput = 400
    }
    mydb2 = {
      throughput = 800
    }
  }

  tags = {
    tag1 = "value1"
  }

}