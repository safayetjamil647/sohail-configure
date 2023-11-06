resource "azurerm_resource_group" "resourcegroup" {
    name        = var.ResourceGroup
    location    = var.Location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet.vNetName
  address_space       = var.vnet.address_space
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  
}

resource "azurerm_subnet" "subnets" {
  for_each = var.Subnets
  name                 = each.value["name"]
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value["prefix"]
  
  depends_on = [
    azurerm_virtual_network.vnet
  ] 
}


resource "azurerm_public_ip" "VPN-PublicIP" {
  name                = "pip-vgw-connectivity-001"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  allocation_method = "Dynamic"
  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_virtual_network_gateway" "VPN-Gateway" {
  name                = "vgw-connectivity-001"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vgw-config"
    public_ip_address_id          = azurerm_public_ip.VPN-PublicIP.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnets["GatewaySubnet"].id
  }
  timeouts {
    create = "120m"
  }
}

resource "azurerm_local_network_gateway" "LocalGateway" {
  name                = "lgw-onpremises-001"
  location            = azurerm_virtual_network.vnet.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  gateway_address     = var.LocalGateway.gateway_address
  address_space       = [var.LocalGateway.subnet2,var.LocalGateway.subnet1]
}

data "azurerm_key_vault" "zb-cloudninja-vpn-001" {
  name                = "zb-cloudninja-vpn-001"
  resource_group_name = "rg-keyvault-001"
}

data "azurerm_key_vault_secret" "VPNSharedSecret" {
  name         = "VPNSharedSecret"
  key_vault_id = data.azurerm_key_vault.zb-cloudninja-vpn-001.id
}

resource "azurerm_virtual_network_gateway_connection" "VPN-Connection" {
  name                = "vcn-onpremises-001"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.VPN-Gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.LocalGateway.id

  shared_key = data.azurerm_key_vault_secret.VPNSharedSecret.value

}
