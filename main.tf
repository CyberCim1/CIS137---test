resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}

data "azurerm_client_config" "current" {}

resource "random_string" "azurerm_key_vault_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

locals {
  current_user_id = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_key_vault" "vault" {
  name                       = coalesce(var.vault_name, "vault-${random_string.azurerm_key_vault_name.result}")
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.current_user_id

    key_permissions    = var.key_permissions
    secret_permissions = var.secret_permissions
  }
}

resource "random_string" "azurerm_key_vault_key_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_key_vault_key" "key" {
  name = coalesce(var.key_name, "key-${random_string.azurerm_key_vault_key_name.result}")

  key_vault_id = azurerm_key_vault.vault.id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = var.key_ops

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

resource "random_pet" "azurerm_mssql_server_name" {
  prefix = "sql"
}

resource "random_password" "admin_password" {
  count       = var.admin_password == null ? 1 : 0
  length      = 20
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

locals {
  admin_password = try(random_password.admin_password[0].result, var.admin_password)
}

resource "azurerm_mssql_server" "server" {
  name                         = random_pet.azurerm_mssql_server_name.id
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  administrator_login          = var.admin_username
  administrator_login_password = local.admin_password
  version                      = "12.0"
}

resource "azurerm_mssql_database" "db" {
  name      = var.sql_db_name
  server_id = azurerm_mssql_server.server.id
}
