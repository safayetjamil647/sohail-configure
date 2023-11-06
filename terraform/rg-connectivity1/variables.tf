variable "Location" {
    type        = string
    default     = "WestEurope"  
}

variable "ResourceGroup" {
    type        = string
    default     = "rg-connectivity-network-001"   
}

variable "vnet" {
  type = any
  default = {
    "vNetName"                      = "vnet-connectivity-001"
    "address_space"                 = ["172.16.0.0/16"]
  }  
}

variable "Subnets" {
    type = any
    default = {
        "GatewaySubnet" = {
            "name"      = "GatewaySubnet"
            "prefix"    = ["172.16.0.0/26"]
            "routeTable" = "rt-vnet-connectivity-gateway-001"
        }
        "FirewallSubnet" = {
            "name" = "AzureFirewallSubnet"
            "prefix" = ["172.16.0.64/26"]
            "routeTable" = "rt-vnet-connectivity-firewall-001"
        }
    }
}

variable "LocalGateway" {
  type = map
  default = {
    "gateway_address"                 = "92.27.153.75"
    "subnet1"                         = "192.168.1.0/24"
    "subnet2"                         = "192.168.10.0/24"    
  }  
}

data "azurerm_key_vault" "zb-cloudninja-vpn-001" {
  name                = "zb-cloudninja-vpn-001"
  resource_group_name = "rg-keyvault-001"
}
