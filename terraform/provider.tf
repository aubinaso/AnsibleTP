# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.7.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-ito-maz-prd-neu-management"
    storage_account_name = "stitoaztfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  skip_provider_registration = true
  use_msi                    = true
}

provider "azapi" {
}