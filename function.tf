resource "azurerm_app_service_plan" "static_site" {
  name                = "asp-${var.name}"
  location            = azurerm_resource_group.static_site.location
  resource_group_name = azurerm_resource_group.static_site.name
  kind                = "FunctionApp" # You might think this should be Linux...
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = var.tags
}

data "azurerm_storage_account_sas" "package" {
  connection_string = azurerm_storage_account.static_site.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = local.now
  expiry = local.in_ten_years

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

resource "azurerm_function_app" "static_site" {
  name                       = var.name
  location                   = azurerm_resource_group.static_site.location
  resource_group_name        = azurerm_resource_group.static_site.name
  app_service_plan_id        = azurerm_app_service_plan.static_site.id
  storage_account_name       = azurerm_storage_account.static_site.name
  storage_account_access_key = azurerm_storage_account.static_site.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  enable_builtin_logging = false

  site_config {
    linux_fx_version          = "dotnet|3.1"
    use_32_bit_worker_process = false
    ftps_state                = "Disabled"
    http2_enabled             = false
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet"
    "FUNCTION_APP_EDIT_MODE"         = "readonly"
    "WEBSITE_RUN_FROM_PACKAGE"       = "https://${azurerm_storage_account.static_site.name}.blob.core.windows.net/${azurerm_storage_container.function_packages.name}/${azurerm_storage_blob.function.name}${data.azurerm_storage_account_sas.package.sas}"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.enable_app_insights ? azurerm_application_insights.static_site.0.instrumentation_key : ""
    "https_only"                     = true

    # Informational
    "package_creation_timestamp" = local.now
    "sha1"                       = data.archive_file.azure_function_package.output_sha
    "sha256"                     = data.archive_file.azure_function_package.output_base64sha256
    "md5"                        = data.archive_file.azure_function_package.output_md5
  }

  tags = var.tags

  depends_on = [
    azurerm_storage_blob.function,
    data.archive_file.azure_function_package
  ]
}
