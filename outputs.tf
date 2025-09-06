output "vpn_gateway_ip" {
  value = azurerm_public_ip.vpn_gateway.ip_address
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}