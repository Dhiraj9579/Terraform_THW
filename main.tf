provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "mediawiki" {
  name     = "mediawiki-rg"
  location = "East US"  # Change this to your desired Azure region
}

resource "azurerm_virtual_network" "mediawiki" {
  name                = "mediawiki-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name
}

resource "azurerm_subnet" "mediawiki" {
  name                 = "mediawiki-subnet"
  resource_group_name  = azurerm_resource_group.mediawiki.name
  virtual_network_name = azurerm_virtual_network.mediawiki.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "mediawiki" {
  name                = "mediawiki-nsg"
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name
}

resource "azurerm_network_security_rule" "mediawiki" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mediawiki.name
  network_security_group_name = azurerm_network_security_group.mediawiki.name
}

resource "azurerm_network_interface" "mediawiki" {
  name                = "mediawiki-nic"
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mediawiki.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "mediawiki" {
  name                = "mediawiki-vm"
  location            = azurerm_resource_group.mediawiki.location
  resource_group_name = azurerm_resource_group.mediawiki.name
  size                = "Standard_DS2_v2" # Choose an appropriate VM size
  admin_username      = "adminuser"      # Change this to your desired username

  network_interface_ids = [azurerm_network_interface.mediawiki.id]

  os_disk {
    name              = "mediawiki-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS" # Choose an appropriate storage type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"                # Change this to your desired username
    public_key = file("~/.ssh/id_rsa.pub")  # Use your public SSH key
  }
}

