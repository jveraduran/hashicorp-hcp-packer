terraform {
  backend "remote" {
    organization = "smu-chile"

    workspaces {
      prefix = "hashicorp-hcp-packer-"
    }
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.16.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.38.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "2.13.0"
    }
  }
  required_version = "~> 1.2.0"
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

provider "azurerm" {

}