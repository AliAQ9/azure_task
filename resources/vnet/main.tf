provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "azurerm_key_vault" {
  name     = "azure-project"
  location = "East US"
}

resource "azurerm_key_vault" "project_keyvault" {
  name                        = "examplekeyvault"
  location                    = azurerm_resource_group.azure_project
  resource_group_name         = azurerm_resource_group.azure_project
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}
 resource "azurerm_lb" "TestLoadBalancer" {
 name                = "TestLoadBalancer"
 location            = "Central US"
 resource_group_name = azurerm_resource_group.azure_project.name
}

resource "azurerm_public_ip" "PublicIP" {
 name                = "PublicIP"
location            = "Central US"
resource_group_name = azurerm_resource_group.azure_project.name
 allocation_method   = "Static"
}

resource "azurerm_subnet" "subnet" {
  count                = length(var.subnet_cidrs)
  name                 = "subnet${count.index}"
  resource_group_name  = azurerm_resource_group.azure_project.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs[count.index]]
}

resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}

resource "azurerm_resource_group" "azure_project" {
  name     = "traffic_manager"
  location = "West Europe"
}

resource "azurerm_traffic_manager_profile" "traffic_manager" {
  name                   = random_id.server.hex
  resource_group_name    = azurerm_resource_group.azure_project
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = random_id.server.hex
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = {
    environment = "Production"
  }
}