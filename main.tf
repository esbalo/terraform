# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "Terraform" {
    name     = "Terraform"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "TerraformVnet" {
    name                = "TerraformVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.Terraform.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "TerraformSubNet" {
    name                 = "TerraformSubNet"
    resource_group_name  = azurerm_resource_group.Terraform.name
    virtual_network_name = azurerm_virtual_network.TerraformVnet.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "TerraformIP" {
    name                         = "TerraformIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.Terraform.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "TerraformSG" {
    name                = "TerraformSG"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.Terraform.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "TerraformNIC" {
    name                      = "TerraformNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.Terraform.name

    ip_configuration {
        name                          = "TerraformNICConfiguration"
        subnet_id                     = azurerm_subnet.TerraformSubNet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.TerraformIP.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.TerraformNIC.id
    network_security_group_id = azurerm_network_security_group.TerraformSG.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.Terraform.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.Terraform.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "TerraformVM" {
    name                  = "TerraformVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.Terraform.name
    network_interface_ids = [azurerm_network_interface.TerraformNIC.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbDTfqYwUi9QANFQop9ARSzO3+OFCdjOvEk7p7eJxhfDXmchQhCcoZUT1y+32zcY1IFRjtejs80eEu/0cbkyzlPF1Y1hJNZnEmQDinJQ/CoE6wFriEjo73ZP6FlQgpCo2zVE0vhTAm8npnR1fMKkFoPMpPVrXpytaGhdgJjBkGc5N6kuJdcXDM6p8mwrEiBI7Pz/A7cLmDNxaxrj2LQA3dcGQaiq8/QRIpUw1xlyMzXQCEOmcnkA/jqFpkcaCyOFfpZaDnAt3bO8zXwstHSXtjxvt0JJmGnMl4rVSJdLT8U64hWusdD+FrvWRefsjUb0LM4JQAy8gcHu73tiwVtQID esteban"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}