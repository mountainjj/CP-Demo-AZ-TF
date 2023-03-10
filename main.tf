resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "CPDemoResourceGroup"
  tags = {
    Environment = "Terraform CP Demo"
    Team        = "Dev"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "CP_Test_network" {
  name                = "CP-Vnet"
  address_space       = ["10.240.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

# Create subnet
resource "azurerm_subnet" "CP_Test_subnet" {
  name                 = "CP-Subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.CP_Test_network.name
  address_prefixes     = ["10.240.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "CP_Test_public_ip" {
  name                = "CP-PublicIP"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "CP_Test_nsg" {
  name                = "CP-NetworkSecurityGroup"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

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
}

# Create network interface
resource "azurerm_network_interface" "CP_Test_nic" {
  name                = "CP-NIC"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "CP_Test_nic_configuration"
    subnet_id                     = azurerm_subnet.CP_Test_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.CP_Test_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.CP_Test_nic.id
  network_security_group_id = azurerm_network_security_group.CP_Test_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resource_group_name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "CP_Test_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm           = "RSA"
  rsa_bits            = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "CP_Test_vm" {
  name                  = "CP-VM"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.CP_Test_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "CP-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "CP-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.CP_Test_storage_account.primary_blob_endpoint
  }
}