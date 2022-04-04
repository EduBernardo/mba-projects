terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
  }
}

resource "azurerm_resource_group" "rg-aulainfracloud" {
  name     = "aulainfracloudterraform"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet-aulainfra" {
  name                = "vnet-aula"
  location            = azurerm_resource_group.rg-aulainfracloud.location
  resource_group_name = azurerm_resource_group.rg-aulainfracloud.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade = "Impacta"
    turma = "ES23"
  }
}