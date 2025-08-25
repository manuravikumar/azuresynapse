variable "project" {
  description = "Short project name (lowercase, letters/numbers)."
  type        = string
  default     = "retailrt"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "Australia East"
}

variable "sql_admin_login" {
  description = "Synapse SQL admin username."
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Synapse SQL admin password (meet Azure complexity)."
  type        = string
  sensitive   = true
}

variable "dedicated_sql_sku" {
  description = "SKU for Synapse dedicated SQL pool (e.g., DW100c)."
  type        = string
  default     = "DW100c"
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    project = "synapse-portfolio"
    owner   = "you"
  }
}