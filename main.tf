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

  subnet {
    name = "IntegrationSubnet"
    address_prefixes = ["10.0.1.0/28"]
  }

  subnet {
    name = "PrivateEndpointsSubnet"
    address_prefixes = ["10.0.2.0/24"]
  }

  subnet {
    name = "GatewaySubnet"
    address_prefixes = ["10.0.3.0/27"]
  }
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${local.vnet_name}-vpn-gateway-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${local.vnet_name}-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_virtual_network.main.id}/subnets/GatewaySubnet"
  }

  vpn_client_configuration {
    address_space = ["172.16.0.0/24"]

    vpn_client_protocols = ["OpenVPN"]

    aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"  # Azure VPN Client ID
    aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }
}