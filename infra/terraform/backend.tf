terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "mtfstatestorage"
    container_name       = "tfstate"
    key                  = "resume.tfstate"
  }
}
