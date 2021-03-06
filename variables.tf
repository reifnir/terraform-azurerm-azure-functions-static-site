variable "name" {
  type        = string
  description = "Slug is added to the name of most resources"
}

variable "location" {
  type        = string
  description = "Azure region in which resources will be located"
  default     = "eastus"
}

variable "static_content_directory" {
  type        = string
  description = "This is the path to the directory containing static resources."
}

variable "enable_app_insights" {
  type        = bool
  description = "App Insights isn't free. If you don't want App Insights attached to this site, set this value to false. You can always enable it later if you need to troubleshoot something."
  default     = false
}

variable "tags" {
  type = map(any)
  default = {
    "ManagedBy" = "Terraform"
  }
}
