# terraform/modules/networking/main.tf
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Subnets para cada microservicio
resource "azurerm_subnet" "microservices" {
  for_each = var.microservices

  name                 = "${each.key}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.subnet_cidr]
}

# NSG para cada subnet (optimizado para estudiante - reglas básicas)
resource "azurerm_network_security_group" "microservices" {
  for_each = var.microservices

  name                = "${var.prefix}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Regla SSH (puerto 22) - solo si es necesario para Container Apps
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Reglas específicas por microservicio
  dynamic "security_rule" {
    for_each = each.value.allowed_ports
    content {
      name                       = "Allow-${security_rule.value}"
      priority                   = 1100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# Asociar NSG a subnets
resource "azurerm_subnet_network_security_group_association" "microservices" {
  for_each = var.microservices

  subnet_id                 = azurerm_subnet.microservices[each.key].id
  network_security_group_id = azurerm_network_security_group.microservices[each.key].id
}