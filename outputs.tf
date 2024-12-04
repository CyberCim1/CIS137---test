output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "azurerm_key_vault_name" {
  value = azurerm_key_vault.vault.name
}

output "azurerm_key_vault_id" {
  value = azurerm_key_vault.vault.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.server.name
}

output "admin_password" {
  sensitive = true
  value     = local.admin_password
}