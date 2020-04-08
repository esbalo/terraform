# terraform backend configuration
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "PruebasEsteban"

    workspaces {
      prefix = "Azure-"
    }
  }
}