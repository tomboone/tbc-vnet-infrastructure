locals {
  vnet_name = "tbc-vnet"
}

# Azure Client Config
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  location = "East US 2"
  name     = "${local.vnet_name}-rg"
}

# VNet
resource "azurerm_virtual_network" "main" {
  address_space = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "integration" {
  address_prefixes     = [ "10.0.1.0/28",]
  name                 = "IntegrationSubnet"
  resource_group_name  = "tbc-vnet-rg"
  virtual_network_name = "tbc-vnet"

  delegation {
    name = "app-service-delegation"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action",]
      name    = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  address_prefixes                              = ["10.0.2.0/24",]
  name                                          = "PrivateEndpointsSubnet"
  resource_group_name                           = "tbc-vnet-rg"
  virtual_network_name                          = "tbc-vnet"
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "tbc-vnet-pe-nsg"
  resource_group_name = "tbc-vnet-rg"
  location            = "eastus2"

  security_rule {
    access                                     = "Allow"
    destination_address_prefix                 = "10.0.2.0/24"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "*"
    destination_port_ranges                    = []
    direction                                  = "Inbound"
    name                                       = "AllowIntegrationToPrivateEndpoints"
    priority                                   = 110
    protocol                                   = "*"
    source_address_prefix                      = "10.0.1.0/28"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
  }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
  subnet_id                 = azurerm_subnet.private_endpoints.id
}