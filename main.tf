resource "azurerm_resource_group" "mediawikiTHW" {
  name     = "mediawikiTHW-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "mediawikiTHW" {
  name                = "mediawikiTHW-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mediawikiTHW.location
  resource_group_name = azurerm_resource_group.mediawikiTHW.name
}

resource "azurerm_subnet" "mediawikiTHW" {
  name                 = "mediawikiTHW-subnet"
  resource_group_name  = azurerm_resource_group.mediawikiTHW.name
  virtual_network_name = azurerm_virtual_network.mediawikiTHW.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "mediawikiTHW" {
  name                = "mediawikiTHW-nsg"
  location            = azurerm_resource_group.mediawikiTHW.location
  resource_group_name = azurerm_resource_group.mediawikiTHW.name
}

resource "azurerm_network_security_rule" "mediawikiTHW" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mediawikiTHW.name
  network_security_group_name = azurerm_network_security_group.mediawikiTHW.name
}

resource "azurerm_subnet_network_security_group_association" "mediawikiTHW" {
  subnet_id                 = azurerm_subnet.mediawikiTHW.id
  network_security_group_id = azurerm_network_security_group.mediawikiTHW.id
}

resource "azurerm_public_ip" "mediawikiTHW" {
  name                = "mediawikiTHW-pip"
  location            = azurerm_resource_group.mediawikiTHW.location
  resource_group_name = azurerm_resource_group.mediawikiTHW.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "mediawikiTHW" {
  name                = "mediawikiTHW-nic"
  location            = azurerm_resource_group.mediawikiTHW.location
  resource_group_name = azurerm_resource_group.mediawikiTHW.name

  ip_configuration {
    name                          = "mediawikiTHW-nic-configuration"
    subnet_id                     = azurerm_subnet.mediawikiTHW.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.mediawikiTHW.id
  }
}

resource "azurerm_linux_virtual_machine" "mediawikiTHW" {
  name                = "mediawikiTHW-vm"
  location            = azurerm_resource_group.mediawikiTHW.location
  resource_group_name = azurerm_resource_group.mediawikiTHW.name
  network_interface_ids = [azurerm_network_interface.mediawikiTHW.id]

  size                  = "Standard_DS2_v2"
  admin_username        = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("mediawiki.pub") # Replace with the path to your SSH public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_4"
    version   = "latest"
  }
}
