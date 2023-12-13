terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.7.0"
    }
  }
}

provider "azurerm" {
  client_id = "" # renseigner la valeur de votre id d'application
  client_secret = "" # renseigner la valeur de votre secret d'application
  subscription_id = "" # renseigner la valeur de votre id d'abonnement
  tenant_id = "" # renseigner la valeur de l'id du tenant
  features {}
}