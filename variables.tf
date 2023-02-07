variable "resource_group_location" {
  default     = "West US"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_name" {
  default = "CP-DemoResourceGroup"
}

# based on main.tf format
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name